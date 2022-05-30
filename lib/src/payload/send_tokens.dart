import 'dart:convert';
import "dart:typed_data";
import '../../src/utils.dart';

import "../acc_url.dart";
import "../marshaller.dart";
import "../tx_types.dart";
import "base_payload.dart";


class TokenRecipientArg{
dynamic url;
dynamic amount;

}

class TokenRecipient{
  late AccURL url;
late int amount;
  TokenRecipient(this.url,this.amount);
}

class SendTokensArg {
  late List<TokenRecipientArg> to;
  Uint8List? hash;
  Uint8List? meta;
}


class SendTokens extends BasePayload {
  late List<TokenRecipient> _to;
  late Uint8List _hash;
  late Uint8List _meta;
  SendTokens(SendTokensArg arg) : super() {

    if (arg.to.isEmpty) {
      throw Exception("Missing at least one recipient");

    }
    _to = arg.to.map((r) => TokenRecipient(AccURL.toAccURL(r.url),r.amount is int ? r.amount : int.parse(r.amount))).toList();
    _hash = arg.hash!;
    _meta = arg.meta!;
  }

  Uint8List _marshalBinary() {

    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.sendTokens));

    if (_hash.isNotEmpty) {

      if (_hash.length != 32) {
        throw Exception("Invalid hash length");
      }
      forConcat.addAll(hashMarshalBinary(_hash));
    }
    if (_meta.isNotEmpty) {
      forConcat.addAll(hashMarshalBinary(_meta));
    }

    for (var recipient in _to) {
      forConcat.addAll(stringMarshalBinary(recipient.url.toString()));
      forConcat.addAll(uvarintMarshalBinary(recipient.amount));
    }

    return forConcat.asUint8List();
  }

}

