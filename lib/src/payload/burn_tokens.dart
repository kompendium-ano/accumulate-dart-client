import 'dart:typed_data';

import '../utils/utils.dart';

import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class BurnTokensParam {
  dynamic amount;
  String? memo;
  Uint8List? metadata;
}

class BurnTokens extends BasePayload {
  late int _amount;

  BurnTokens(BurnTokensParam burnTokensParam) : super() {
    _amount = burnTokensParam.amount is int
        ? burnTokensParam.amount
        : int.parse(burnTokensParam.amount);

    super.memo = burnTokensParam.memo;
    super.metadata = burnTokensParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.burnTokens, 1));
    forConcat.addAll(bigNumberMarshalBinary(_amount, 2));

    return forConcat.asUint8List();
  }
}
