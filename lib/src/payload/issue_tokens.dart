import "dart:typed_data";
import 'package:accumulate_api6/src/payload/send_tokens.dart';

import '../utils/utils.dart';

import '../client/acc_url.dart';
import '../encoding.dart';
import '../client/tx_types.dart';
import "base_payload.dart";
import 'token_recipient.dart';

class IssueTokensParam {
  late List<TokenRecipientParam> to;
  String? memo;
  Uint8List? metadata;
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

    super.memo = issueTokensParam.memo;
    super.metadata = issueTokensParam.metadata;
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
