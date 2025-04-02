// lib\src\transaction.dart

import "dart:typed_data";
import "package:crypto/crypto.dart";
import 'package:hex/hex.dart';
import 'package:logging/logging.dart';

import 'client/acc_url.dart';
import 'client/signature_type.dart';
import 'client/signer.dart';
import 'client/tx_signer.dart';
import 'encoding.dart';
import 'payload.dart';
import 'utils/utils.dart';

final Logger _logger = Logger('Transaction');

class HeaderOptions {
  int timestamp;
  String? memo;
  Uint8List? metadata;
  Uint8List? initiator;

  HeaderOptions({int? timestamp, this.memo, this.metadata, this.initiator})
      : this.timestamp = timestamp ?? DateTime.now().microsecondsSinceEpoch {
    _logger.info('LOG: HeaderOptions initialized with timestamp: $this.timestamp, memo: ${this.memo}');
  }
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

    _logger.info('LOG: Header initialized with principal: $_principal, timestamp: $_timestamp');
  }

  AccURL get principal => _principal;

  int get timestamp => _timestamp;

  String? get memo => _memo;

  Uint8List? get metadata => _metadata;

  Uint8List computeInitiator(SignerInfo signerInfo) {
    _logger.info('LOG: Computing initiator hash for signer: ${signerInfo.url}');

    List<int> binary = [];
    binary.addAll(uvarintMarshalBinary(signerInfo.type!, 1));
    binary.addAll(bytesMarshalBinary(signerInfo.publicKey!, 2));
    binary.addAll(stringMarshalBinary(signerInfo.url.toString(), 4));
    binary.addAll(uvarintMarshalBinary(signerInfo.version!, 5));
    binary.addAll(uvarintMarshalBinary(timestamp, 6));

    _initiator = sha256.convert(binary).bytes.asUint8List();

    _logger.fine('LOG: Computed initiator hash: ${HEX.encode(_initiator)}');
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

    _logger.fine('LOG: Marshalled header binary: ${HEX.encode(forConcat)}');
    return forConcat.asUint8List();
  }
}

class Transaction {
  late Header _header;
  late Uint8List _payloadBinary;
  TxSigner? _signerInUse;
  Signature? _signature;
  Uint8List? _hash;
  late Uint8List _bodyHash;

  Transaction(Payload payload, Header header, [Signature? signature]) {
    _payloadBinary = payload.marshalBinary();
    _header = header;
    _signature = signature;
    _bodyHash = payload.hash();

    _logger.info('LOG: Transaction created with payload size: ${_payloadBinary.length}, header: $_header');
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

    _logger.fine('LOG: Computed transaction hash: ${HEX.encode(_hash!)}');
    return _hash!.toList();
  }

  List<int> dataForSignature(SignerInfo signerInfo) {
    Uint8List sigHash = header.computeInitiator(signerInfo);
    _logger.fine('LOG: Computed signature hash: ${HEX.encode(sigHash)}');

    List<int> tempHash = List<int>.from(sigHash.toList());
    tempHash.addAll(hash());

    final signatureData = sha256.convert(tempHash).bytes;
    _logger.fine('LOG: Final data for signature: ${HEX.encode(signatureData)}');
    return signatureData;
  }

  Uint8List get payload => _payloadBinary;

  AccURL get principal => _header.principal;

  Header get header => _header;

  dynamic get signature => _signature;

  set signature(dynamic signature) {
    _signature = signature;
  }

  sign(TxSigner signer) {
    _logger.info('LOG: Signing transaction using signer: ${signer.url}');
    _signature = signer.sign(this);
    _signerInUse = signer;
    _logger.info('LOG: Transaction signed successfully.');
  }

  TxRequest toTxRequest({bool? checkOnly}) {
    _logger.info('LOG: Creating TxRequest for transaction with timestamp: ${header.timestamp}');

    if (_signature == null) {
      throw Exception("LOG: Unsigned transaction cannot be converted to TxRequest");
    }

    final signerInfo = _signature!.signerInfo;
    TxRequest txRequest = TxRequest();
    txRequest.checkOnly = checkOnly ?? false;
    txRequest.isEnvelope = false;
    txRequest.origin = _header.principal.toString();
    txRequest.signer = {
      "url": signerInfo!.url.toString(),
      "publicKey": HEX.encode(signerInfo.publicKey!),
      "version": signerInfo.version,
      "timestamp": _header.timestamp,
      "signatureType": "${SignatureType().marshalJSON(signerInfo.type!)}",
      "useSimpleHash": true
    };
    txRequest.signature = HEX.encode(_signature!.signature!);
    txRequest.txHash = HEX.encode(_hash!.toList());
    txRequest.payload = HEX.encode(_payloadBinary.toList());

    if (_header._memo != null) {
      txRequest.memo = _header._memo!;
    }

    if (_header._metadata != null) {
      txRequest.metadata = HEX.encode(_header.metadata!.toList());
    }

    _logger.info('TxRequest created successfully.');
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
