import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateTokenAccountParam {
  dynamic url;
  dynamic tokenUrl;
  bool? scratch;
  List<AccURL>? authorities;
}

class CreateTokenAccount extends BasePayload {
  late AccURL _url;
  late AccURL _tokenUrl;
  late bool _scratch;
  List<AccURL>? _authorities;

  CreateTokenAccount(CreateTokenAccountParam createTokenAccountParam)
      : super() {
    _url = AccURL.toAccURL(createTokenAccountParam.url);
    _tokenUrl = AccURL.toAccURL(createTokenAccountParam.tokenUrl);
    _scratch = createTokenAccountParam.scratch ?? false;
    _authorities = createTokenAccountParam.authorities;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat
        .addAll(uvarintMarshalBinary(TransactionType.createTokenAccount, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));
    forConcat.addAll(stringMarshalBinary(_tokenUrl.toString(), 3));

    forConcat.addAll(booleanMarshalBinary(_scratch, 5));

    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 7));
      }
    }

    return forConcat.asUint8List();
  }
}
