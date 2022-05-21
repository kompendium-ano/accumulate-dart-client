import "dart:typed_data";
import "dart:async";
import 'package:acc_lib/signature_type.dart';
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

  late Uint8List _metadata;

  late int _timestamp;


  Header(dynamic principal,HeaderOptions? options ) {
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
    List<int> encodedAddress = utf8.encode(signerInfo.url.toString());
    binary.addAll(uvarintMarshalBinary(encodedAddress.length));
    binary.addAll(encodedAddress);
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
    List<int> encodedAddress = utf8.encode(_principal.toString());
    forConcat.addAll(uvarintMarshalBinary(encodedAddress.length));
    forConcat.addAll(encodedAddress);

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

  late Signature _signature;

  late Uint8List _hash;

  Transaction(Payload payload, Header header, Signature signature) {
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
    Uint8List tempHash = Uint8List.fromList(headerHash);
    tempHash.addAll(bodyHash);
    _hash = sha256.convert(tempHash.toList()).bytes.asUint8List();
    return _hash;
  }

  /**
   * Data that needs to be signed in order to submit the transaction.
   */
  List<int> dataForSignature(SignerInfo signerInfo) {
    final sigHash = header.computeInitiator(signerInfo);

    Uint8List tempHash = Uint8List.fromList(sigHash);
    tempHash.addAll(hash());

    return sha256.convert(tempHash.toList()).bytes;
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

  /**
   * Convert the Transaction into the param object for the `execute` API method
   */
  TxRequest toTxRequest(bool? checkOnly) {
    if (_signature != null) {
      throw Exception ("Unsigned transaction cannot be converted to TxRequest");
    }

    final signerInfo = _signature.signerInfo;
    TxRequest txRequest = TxRequest();
    txRequest.checkOnly = checkOnly;
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
    txRequest.signature = HEX.encode(_signature.signature!.toList());
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
}