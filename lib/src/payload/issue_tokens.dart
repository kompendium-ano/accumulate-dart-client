import 'dart:convert';
import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class IssueTokensArg {
dynamic recipient;
dynamic amount;
}

class IssueTokens extends BasePayload {
  late AccURL _recipient;
  late int _amount;

  IssueTokens(IssueTokensArg arg) : super() {
    _recipient = AccURL.toAccURL(arg.recipient);
    _amount = arg.amount is int ? arg.amount : int.parse(arg.amount);
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.issueTokens));
    forConcat.addAll(stringMarshalBinary(_recipient.toString()));
    forConcat.addAll(uvarintMarshalBinary(_amount));

    return forConcat.asUint8List();
  }
}
