// lib\src\payload\send_tokens.dart

import "dart:typed_data";
import 'token_recipient.dart';

import '../utils/utils.dart';
import '../client/acc_url.dart';
import '../encoding.dart';
import '../client/tx_types.dart';
import "base_payload.dart";

class SendTokensParam {
  late List<TokenRecipientParam> to;
  Uint8List? hash;
  Uint8List? meta;
  String? memo;
  Uint8List? metadata;
}

class SendTokens extends BasePayload {
  late List<TokenRecipient> _to;
  late Uint8List? _hash;
  late Uint8List? _meta;

  SendTokens(SendTokensParam sendTokensParam) : super() {
    if (sendTokensParam.to.isEmpty) {
      throw Exception("Missing at least one recipient");
    }
    _to = sendTokensParam.to
        .map((r) => TokenRecipient(AccURL.toAccURL(r.url),
            r.amount is int ? r.amount : int.parse(r.amount)))
        .toList();
    _hash = sendTokensParam.hash;
    _meta = sendTokensParam.meta;
    super.memo = sendTokensParam.memo;
    super.metadata = sendTokensParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.sendTokens, 1));

    if (_hash != null) {
      if (_hash!.length != 32) {
        throw Exception("Invalid hash length");
      }

      forConcat.addAll(hashMarshalBinary(_hash!, 2));
    }
    if (_meta != null) {
      forConcat.addAll(bytesMarshalBinary(_meta!, 3));
    }

    for (TokenRecipient recipient in _to) {
      forConcat.addAll(fieldMarshalBinary(
          4, TokenRecipient.marshalBinaryTokenRecipient(recipient)));
    }

    return forConcat.asUint8List();
  }
}
