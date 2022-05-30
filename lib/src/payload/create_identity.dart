import 'dart:convert';
import "dart:typed_data";
import '../../src/utils.dart';

import "../acc_url.dart";
import "../marshaller.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateIdentityArg {
dynamic url;
Uint8List? keyHash;
dynamic keyBookUrl;
dynamic manager;
}


class CreateIdentity implements BasePayload {
  late AccURL _url;
  Uint8List? _keyHash;
  AccURL? _keyBookUrl;
  AccURL? _manager;
  CreateIdentity(CreateIdentityArg arg) : super() {
    _url = AccURL.toAccURL(arg.url);
    _keyHash = arg.keyHash! ;
    if(arg.keyBookUrl != null){
      _keyBookUrl = AccURL.toAccURL(arg.keyBookUrl);
    }

    if(arg.manager != null){
      _manager = AccURL.toAccURL(arg.manager);
    }

  }

  @override
  Uint8List marshalBinary() {
    List<int> forConcat = [];
    //forConcat.addAll(uvarintMarshalBinary(TransactionType.createIdentity));
    forConcat.addAll(stringMarshalBinary("1"));
    forConcat.addAll(stringMarshalBinary(_url.toString()));


    if (_keyHash != null && _keyHash!.isNotEmpty) {
      forConcat.addAll(hashMarshalBinary(_keyHash!));

    }

    if (_keyBookUrl != null) {
      forConcat.addAll(stringMarshalBinary(_keyBookUrl.toString()));

    }

    if (_manager != null) {
      forConcat.addAll(stringMarshalBinary(_manager.toString()));
    }

    return forConcat.asUint8List();
  }
}
