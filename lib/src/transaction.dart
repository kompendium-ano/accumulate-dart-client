import "dart:typed_data";

import "package:crypto/crypto.dart";
import 'package:hex/hex.dart';

import 'client/acc_url.dart';
import 'client/signature_type.dart';
import 'client/signer.dart';
import 'client/tx_signer.dart';
import 'encoding.dart';
import 'payload.dart';
import 'utils/utils.dart';

class HeaderOptions {
  int? timestamp;
  String? memo;
  Uint8List? metadata;
  Uint8List? initiator;
}

class Header {
  late AccURL _principal;
  late Uint8List _initiator;
  String? _memo;
  Uint8List? _metadata;
  late int _timestamp;

  Header(dynamic principal, [HeaderOptions? options]) {
    _principal = AccURL.toAccURL(principal);
    _timestamp = options?.timestamp ?? DateTime.now().microsecondsSinceEpoch;

    if (options?.initiator != null) {
      _initiator = options!.initiator!;
    }

    _memo = options?.memo;

    if (options?.metadata != null) {
      _metadata = options!.metadata!.asUint8List();
    }
  }

  AccURL get principal => _principal;

  int get timestamp => _timestamp;

  String? get memo {
    return _memo;
  }

  Uint8List? get metadata {
    return _metadata;
  }

  Uint8List computeInitiator(SignerInfo signerInfo) {
    List<int> binary = [];

    binary.addAll(uvarintMarshalBinary(signerInfo.type!, 1));
    binary.addAll(bytesMarshalBinary(signerInfo.publicKey!, 2));
    binary.addAll(stringMarshalBinary(signerInfo.url.toString(), 4));
    binary.addAll(uvarintMarshalBinary(signerInfo.version!, 5));
    binary.addAll(uvarintMarshalBinary(timestamp, 6));

    _initiator = sha256.convert(binary).bytes.asUint8List();

    return _initiator;
  }

  Uint8List marshalBinary() {
    if (_initiator.isEmpty) {
      throw Exception(
          "Initiator hash missing. Must be initialized by calling computeInitiator");
    }
    List<int> forConcat = [];

    forConcat.addAll(stringMarshalBinary(_principal.toString(), 1));
    forConcat.addAll(hashMarshalBinary(_initiator, 2));

    if (_memo != null && _memo!.isNotEmpty) {
      forConcat.addAll(stringMarshalBinary(_memo!, 3));
    }

    if (_metadata != null && _metadata!.isNotEmpty) {
      forConcat.addAll(bytesMarshalBinary(_metadata!, 4));
    }

    return forConcat.asUint8List();
  }
}

class Transaction {
  late Header _header;

  late Uint8List _payloadBinary;

  // Signer used to create transaction
  TxSigner? _signerInUse;

  Signature? _signature;

  Uint8List? _hash;
  late Uint8List _bodyHash;

  Transaction(Payload payload, Header header, [Signature? signature]) {
    _payloadBinary = payload.marshalBinary();
    _header = header;
    _signature = signature;
    _bodyHash = payload.hash();
  }

  List<int> hash() {
    if (_hash != null) {
      return _hash!.toList();
    }

    final headerHash = sha256.convert(_header.marshalBinary()).bytes;

    List<int> tempHash = [];
    tempHash.addAll(headerHash);
    tempHash.addAll(_bodyHash.toList());

    _hash = sha256.convert(tempHash).bytes.asUint8List();

    return _hash!.toList();
  }

  List<int> dataForSignature(SignerInfo signerInfo) {
    Uint8List sigHash = header.computeInitiator(signerInfo);

    List<int> tempHash = List<int>.from(sigHash.toList());

    tempHash.addAll(hash());

    return sha256.convert(tempHash).bytes;
  }

  Uint8List get payload => _payloadBinary;

  AccURL get principal => _header.principal;

  Header get header => _header;

  dynamic get signature => _signature;

  set signature(dynamic signature) {
    _signature = signature;
  }

  sign(TxSigner signer) {
    _signature = signer.sign(this);
    _signerInUse = signer;
  }

  TxRequest toTxRequest({bool? checkOnly}) {
    if (_signature == null) {
      throw Exception("Unsigned transaction cannot be converted to TxRequest");
    }

    final signerInfo = _signature!.signerInfo;
    TxRequest txRequest = TxRequest();
    txRequest.checkOnly = checkOnly ?? false;
    txRequest.isEnvelope = false;
    txRequest.origin = _header.principal.toString();
    txRequest.signer = {
      "url": signerInfo!.url.toString(),
      "publicKey": HEX.encode(signerInfo.publicKey!), //HEX.encode(_signerInUse!.publicKeyHash),
      "version": signerInfo.version,
      "timestamp": _header.timestamp,
      "signatureType": "${SignatureType().marshalJSON(signerInfo.type!)}",
      "useSimpleHash": true
    };
    txRequest.signature = HEX.encode(_signature!.signature!); //HEX.encode(sha256.convert(_signature!.signature!).bytes.asUint8List()); //
    txRequest.txHash = HEX.encode(_hash!.toList());
    txRequest.payload = HEX.encode(_payloadBinary.toList());
    if (_header._memo != null) {
      txRequest.memo = _header._memo!;
    }

    if (_header._metadata != null) {
      txRequest.metadata = HEX.encode(_header.metadata!.toList());
    }

    return txRequest;
  }
}

class TxRequest {
  bool? checkOnly;
  bool? isEnvelope;
  late String origin;

  late Map<String, dynamic> signer;
  late String signature;
  String? txHash;

  late String payload;
  String? memo;
  String? metadata;

  Map<String, dynamic> get toMap {
    Map<String, dynamic> value = {};
    if (checkOnly != null) {
      value.addAll({"checkOnly": checkOnly!});
    }

    if (isEnvelope != null) {
      value.addAll({"isEnvelope": isEnvelope!});
    }

    value.addAll({"origin": origin});
    value.addAll({"signer": signer});
    value.addAll({"signature": signature});

    if (txHash != null) {
      value.addAll({"txHash": txHash!});
    }

    value.addAll({"payload": payload});

    if (memo != null) {
      value.addAll({"memo": memo!});
    }

    if (metadata != null) {
      value.addAll({"metadata": metadata!});
    }

    return value;
  }
}
