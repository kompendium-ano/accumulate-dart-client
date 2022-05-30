import 'dart:convert';
import "dart:typed_data";
import '../../src/utils.dart';

import "../acc_url.dart";
import "../marshaller.dart";
import "../tx_types.dart";
import "base_payload.dart";


class CreateTokenAccountArg {
  dynamic url;
  dynamic tokenUrl;
  dynamic keyBookUrl;
  bool? scratch;
  dynamic manager;
}

class CreateTokenAccount extends BasePayload {
  late AccURL _url;
  late AccURL _tokenUrl;
  AccURL? _keyBookUrl;
  late bool _scratch;
  AccURL? _manager;
  CreateTokenAccount(CreateTokenAccountArg arg) : super() {

    _url = AccURL.toAccURL(arg.url);
    _tokenUrl = AccURL.toAccURL(arg.tokenUrl);
    _keyBookUrl =
        arg.keyBookUrl ? AccURL.toAccURL(arg.keyBookUrl) : null;
    _scratch = arg.scratch ?? false;
    _manager = arg.manager ? AccURL.toAccURL(arg.manager) : null;
  }


  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createTokenAccount));

    forConcat.addAll(stringMarshalBinary(_url.toString()));

    forConcat.addAll(stringMarshalBinary(_tokenUrl.toString()));


    if (_keyBookUrl != null) {
      forConcat.addAll(stringMarshalBinary(_keyBookUrl.toString()));
    }

    forConcat.addAll(booleanMarshalBinary(_scratch));



    if (_manager != null) {
      forConcat.addAll(stringMarshalBinary(_manager.toString()));
    }

    return forConcat.asUint8List();
  }
}
