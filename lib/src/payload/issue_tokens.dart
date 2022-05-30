import 'dart:convert';
import "dart:typed_data";
import '../../src/utils.dart';

import "../acc_url.dart";
import "../marshaller.dart";
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

  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.issueTokens));
    forConcat.addAll(stringMarshalBinary(_recipient.toString()));
    forConcat.addAll(uvarintMarshalBinary(_amount));

    return forConcat.asUint8List();
  }
}
