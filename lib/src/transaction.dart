import "dart:typed_data";
import "dart:async";
import 'signature_type.dart';
import 'package:hex/hex.dart';

import "acc_url.dart";
import "package:crypto/crypto.dart";
import "payload.dart";
import "signer.dart";
import "tx_signer.dart";
import 'utils.dart';
import 'marshaller.dart';
import 'dart:convert';


class HeaderOptions {
int? timestamp;
String? memo;
Uint8List? metadata;
}

class Header {
  late AccURL _principal;

 late Uint8List _initiator;

  late String _memo;

  Uint8List _metadata = List<int>.from([]).asUint8List();

  late int _timestamp;


  Header(dynamic principal,[HeaderOptions? options] ) {
    _principal = AccURL.toAccURL(principal);
    _timestamp = options?.timestamp ?? DateTime.now().microsecondsSinceEpoch;

     _memo = options?.memo ?? "" ;
     //_metadata = Uint8List(0);
     if(options?.metadata! != null){
       _metadata = options!.metadata!.asUint8List();
     }

  }

  AccURL get principal => _principal;

  int get timestamp =>_timestamp;


  dynamic  get memo {
    return _memo;
  }

  dynamic  get metadata {
    return _metadata;
  }

  Uint8List computeInitiator(SignerInfo signerInfo) {
    List<int> binary = [];
    binary.addAll(uvarintMarshalBinary(signerInfo.type!));
    binary.add(bytesMarshalBinary(signerInfo.publicKey!.toList()));
    binary.addAll(stringMarshalBinary(signerInfo.url.toString()));
    binary.addAll(uvarintMarshalBinary(signerInfo.version!));
    binary.addAll(uvarintMarshalBinary(_timestamp));

    _initiator = sha256.convert(binary).bytes.asUint8List();
    return _initiator;
  }

  Uint8List marshalBinary() {
    if (_initiator.isEmpty) {
      throw Exception (
          "Initiator hash missing. Must be initilized by calling computeInitiator");
    }
    List<int> forConcat = [];
    forConcat.addAll(stringMarshalBinary(_principal.toString()));
    forConcat.addAll(_initiator);

    if(_memo.isNotEmpty){
      List<int> encodedMemo = utf8.encode(_memo);
      forConcat.addAll(uvarintMarshalBinary(encodedMemo.length));
      forConcat.addAll(encodedMemo);
    }

    if(_metadata.isNotEmpty){
      forConcat.addAll(_metadata);
    }

    return forConcat.asUint8List();
  }
}
/**
 * An Accumulate Transaction
 */
class Transaction {
  late Header _header;

  late Uint8List _payloadBinary;

  Signature? _signature;

  Uint8List _hash = List<int>.from([]).asUint8List();

  Transaction(Payload payload, Header header, [ Signature? signature]) {
    _payloadBinary = payload.marshalBinary();
    _header = header;
    _signature = signature;
  }

  /**
   * Compute the hash of the transaction
   */
  List<int> hash() {
    if (_hash.isNotEmpty) {
      return _hash;
    }

    final headerHash = sha256.convert(_header.marshalBinary()).bytes;
    final bodyHash = sha256.convert(_payloadBinary).bytes;
    List<int> tempHash = [];
    tempHash.addAll(headerHash);
    tempHash.addAll(bodyHash);
    _hash = sha256.convert(tempHash).bytes.asUint8List();
    return _hash;
  }

  /**
   * Data that needs to be signed in order to submit the transaction.
   */
  List<int> dataForSignature(SignerInfo signerInfo) {
    Uint8List sigHash = header.computeInitiator(signerInfo);

    List<int> tempHash = List<int>.from(sigHash.toList()).toList();

    tempHash.addAll(hash().toList());

    return sha256.convert(tempHash).bytes;
  }

  Uint8List get payload  => _payloadBinary;


  AccURL get principal => _header.principal;


  Header get header => _header;


  dynamic get signature => _signature;


  set signature(dynamic /* Signature | */ signature) {
    _signature = signature;
  }

  Future sign(TxSigner signer) async{
    _signature = await signer.sign(this);
  }


  TxRequest toTxRequest({bool? checkOnly}) {
    if (_signature == null) {
      throw Exception ("Unsigned transaction cannot be converted to TxRequest");
    }

    final signerInfo = _signature!.signerInfo;
    TxRequest txRequest = TxRequest();
    txRequest.checkOnly = checkOnly ?? false;
    txRequest.isEnvelope = false;
    txRequest.origin = _header.principal.toString();
    txRequest.signer =  {
      "url" : signerInfo!.url.toString(),
      "publicKey" : HEX.encode(signerInfo!.publicKey!.toList()),
      "version" : signerInfo.version,
      "timestamp" : _header.timestamp,
      "signatureType" : SignatureType().marshalJSON(signerInfo!.type!),
      "useSimpleHash" : true
    };
    txRequest.signature = HEX.encode(_signature!.signature!.toList());
    txRequest.txHash = HEX.encode(_hash!.toList());
    txRequest.payload = HEX.encode(_payloadBinary!.toList());
    txRequest.memo = _header._memo;
    txRequest.metadata = HEX.encode(_header.metadata!.toList());

    return txRequest;
  }
}

class TxRequest{
  bool? checkOnly;
  bool? isEnvelope;
  late String origin;

  late Map<String,dynamic> signer;
  late String signature;
  String? txHash;
  late String payload;
  String? memo;
  String? metadata;

  Map<String, dynamic> get toMap {
    Map<String, dynamic> value = {};
    if(checkOnly != null){
      value.addAll({"checkOnly":checkOnly!});
    }

    if(isEnvelope != null){
      value.addAll({"isEnvelope":isEnvelope!});
    }

    value.addAll({"origin":origin});
    value.addAll({"signer":signer});
    value.addAll({"signature":signature});

    if(txHash != null){
      value.addAll({"txHash":txHash!});
    }

    value.addAll({"payload":payload});

    if(memo != null){
      value.addAll({"memo":memo!});
    }

    if(metadata != null){
      value.addAll({"metadata":metadata!});
    }

    return value;

  }
}