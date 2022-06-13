import 'dart:convert';
import "dart:typed_data";
import '../utils.dart';
import 'package:hex/hex.dart';

import "../acc_url.dart";
import "../encoding.dart";
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
  late Uint8List? _hash;
  late Uint8List? _meta;
  SendTokens(SendTokensArg arg) : super() {

    if (arg.to.isEmpty) {
      throw Exception("Missing at least one recipient");

    }
    _to = arg.to.map((r) => TokenRecipient(AccURL.toAccURL(r.url),r.amount is int ? r.amount : int.parse(r.amount))).toList();
    _hash = arg.hash;
    _meta = arg.meta;
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

    for (var recipient in _to) {

      forConcat.addAll(fieldMarshalBinary(4, marshalBinaryTokenRecipient(recipient)));

    }

    return forConcat.asUint8List();
  }

  Uint8List marshalBinaryTokenRecipient(TokenRecipient tr){
    List<int> forConcat = [];
    forConcat.addAll(stringMarshalBinary(tr.url.toString(), 1));
    forConcat.addAll(bigNumberMarshalBinary(BigInt.from(tr.amount), 2));

  return bytesMarshalBinary(forConcat.asUint8List());
}



}

