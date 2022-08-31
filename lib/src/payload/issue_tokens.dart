import "dart:typed_data";
import 'package:accumulate_api6/src/payload/send_tokens.dart';

import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";
import 'token_recipient.dart';

class IssueTokensParam {
  late List<TokenRecipientParam> to;
}

class IssueTokens extends BasePayload {
  List<TokenRecipient> _to = [];

  IssueTokens(IssueTokensParam issueTokensParam) : super() {
    for (TokenRecipientParam tokenRecipientParam in issueTokensParam.to) {
      AccURL url = AccURL.toAccURL(tokenRecipientParam.url);
      int amount = tokenRecipientParam.amount is int
          ? tokenRecipientParam.amount
          : int.parse(tokenRecipientParam.amount);
      _to.add(TokenRecipient(url, amount));
    }
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.issueTokens, 1));
    for (TokenRecipient tokenRecipient in _to) {
      forConcat.addAll(fieldMarshalBinary(
          4, TokenRecipient.marshalBinaryTokenRecipient(tokenRecipient)));
    }

    return forConcat.asUint8List();
  }
}
