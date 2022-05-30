import 'dart:convert';
import "dart:typed_data";
import '../../src/utils.dart';

import "../acc_url.dart" ;
import "../marshaller.dart";
import "../tx_types.dart" show TransactionType;
import "base_payload.dart" show BasePayload;


class AddValidatorArg {
  late Uint8List publicKey;
dynamic owner;
}

class AddValidator extends BasePayload {
  late Uint8List _publicKey;
  late AccURL _owner;
  AddValidator(AddValidatorArg arg) : super() {

    _publicKey = arg.publicKey;
    _owner = AccURL.toAccURL(arg.owner);
  }


  Uint8List _marshalBinary() {

    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.addValidator));
    forConcat.addAll(hashMarshalBinary(_publicKey));

    if(_owner.toString().isNotEmpty){
      forConcat.addAll(stringMarshalBinary(_owner.toString()));
    }


    return forConcat.asUint8List();
  }
}
