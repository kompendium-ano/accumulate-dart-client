import 'dart:convert';
import "dart:typed_data";
import 'package:acc_lib/utils.dart';

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


class CreateIdentity extends BasePayload {
  late AccURL _url;
  Uint8List? _keyHash;
  AccURL? _keyBookUrl;
  AccURL? _manager;
  CreateIdentity(CreateIdentityArg arg) : super() {
    _url = AccURL.toAccURL(arg.url);
    _keyHash = arg.keyHash! ;
    _keyBookUrl = arg.keyBookUrl ? AccURL.toAccURL(arg.keyBookUrl) : null;
    _manager = arg.manager ? AccURL.toAccURL(arg.manager) : null;
  }

  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createIdentity));
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
