import 'dart:typed_data';
import 'package:hex/hex.dart';

import '../utils.dart';
import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class AddCreditsParam {
  dynamic recipient;
  dynamic amount;
  dynamic oracle;
  String? memo;
  Uint8List? metadata;
}

class AddCredits extends BasePayload {
  late AccURL _recipient;
  late int _amount;
  late int _oracle;

  AddCredits(AddCreditsParam addCreditsParam) : super() {
    _recipient = AccURL.toAccURL(addCreditsParam.recipient);
    _amount = addCreditsParam.amount is int
        ? addCreditsParam.amount
        : int.parse(addCreditsParam.amount);
    _oracle = addCreditsParam.oracle is int
        ? addCreditsParam.oracle
        : int.parse(addCreditsParam.oracle);

print("addCreditsParam.memo ${addCreditsParam.memo}");
    print("addCreditsParam.metadata ${addCreditsParam.metadata}");
    super.memo = addCreditsParam.memo;
    super.metadata = addCreditsParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinaryAlt(TransactionType.addCredits, 1));
    forConcat.addAll(stringMarshalBinary(_recipient.toString(), 2));
    forConcat.addAll(bigNumberMarshalBinary(_amount, 3));

    if (_oracle > 0) {
      forConcat.addAll(uvarintMarshalBinary(_oracle, 4));
    }

    return forConcat.asUint8List();
  }


}
