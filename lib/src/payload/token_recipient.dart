import 'dart:typed_data';

import '../utils.dart';

import '../acc_url.dart';
import '../encoding.dart';



class TokenRecipientParam{
dynamic url;
dynamic amount;
}

class TokenRecipient {
  late AccURL url;
  late int amount;

  TokenRecipient(this.url, this.amount);

  static Uint8List marshalBinaryTokenRecipient(TokenRecipient tr) {
print("marshalBinaryTokenRecipient");
print("tr.url ${tr.url}");
print("tr.amount ${tr.amount}");
    List<int> forConcat = [];
    forConcat.addAll(stringMarshalBinary(tr.url.toString(), 1));
    forConcat.addAll(bigNumberMarshalBinary(tr.amount, 2));

    return bytesMarshalBinary(forConcat.asUint8List());
  }
}