import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateKeyBookParam {
  dynamic url;
  Uint8List? publicKeyHash;
  List<AccURL>? authorities;
}

class CreateKeyBook extends BasePayload {
  late AccURL _url;
  late Uint8List _publicKeyHash;
  List<AccURL>? _authorities;

  CreateKeyBook(CreateKeyBookParam createKeyBookParam) : super() {
    _url = AccURL.toAccURL(createKeyBookParam.url);
    _publicKeyHash = createKeyBookParam.publicKeyHash!;
    _authorities = createKeyBookParam.authorities;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.createKeyBook, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));
    forConcat.addAll(bytesMarshalBinary(_publicKeyHash, 3));
    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 5));
      }
    }

    return forConcat.asUint8List();
  }
}
