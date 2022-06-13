import 'dart:typed_data';
import 'dart:convert';

import '../utils.dart';

import "../acc_url.dart" show AccURL;
import "../encoding.dart";
import "../tx_types.dart" show TransactionType;
import "base_payload.dart" show BasePayload;


class AddCreditsArg  {
dynamic recipient;
dynamic amount;
dynamic oracle;
}

class AddCredits extends BasePayload {
  late AccURL _recipient;
  late int _amount;
  late int _oracle;
  AddCredits(AddCreditsArg arg) : super() {

    _recipient = AccURL.toAccURL(arg.recipient);
    _amount = arg.amount is int ? arg.amount : int.parse(arg.amount);
    _oracle = arg.oracle is int ? arg.oracle : int.parse(arg.oracle);
  }


  @override
  Uint8List extendedMarshalBinary() {

    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.addCredits));
    forConcat.addAll(stringMarshalBinary(_recipient.toString()));
    forConcat.addAll(uvarintMarshalBinary(_amount));

    if(_oracle > 0 ){
      forConcat.addAll(uvarintMarshalBinary(_oracle));
    }


    return forConcat.asUint8List();
  }



}
