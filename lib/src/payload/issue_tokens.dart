import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class IssueTokensParam {
  dynamic recipient;
  dynamic amount;
}

class IssueTokens extends BasePayload {
  late AccURL _recipient;
  late int _amount;

  IssueTokens(IssueTokensParam issueTokensParam) : super() {
    _recipient = AccURL.toAccURL(issueTokensParam.recipient);
    _amount = issueTokensParam.amount is int
        ? issueTokensParam.amount
        : int.parse(issueTokensParam.amount);
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.issueTokens, 1));
    forConcat.addAll(stringMarshalBinary(_recipient.toString(), 2));
    forConcat.addAll(bigNumberMarshalBinary(_amount, 3));

    return forConcat.asUint8List();
  }
}
