import 'dart:typed_data';

import '../utils.dart';

import "../encoding.dart";
import "../tx_types.dart" show TransactionType;
import "base_payload.dart" show BasePayload;

class BurnTokensArg  {
dynamic amount;
}

class BurnTokens extends BasePayload {
  late int _amount;
  BurnTokens(BurnTokensArg arg) : super() {

    _amount = arg.amount is int ? arg.amount : int.parse(arg.amount);
  }


  @override
  Uint8List extendedMarshalBinary() {

    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.burnTokens));

    forConcat.addAll(uvarintMarshalBinary(_amount));

    return forConcat.asUint8List();
  }
}
