import 'dart:convert';
import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateKeyPageArg {
dynamic keys;
dynamic manager;
}

class CreateKeyPage extends BasePayload {
  late List<Uint8List> _keys;
  AccURL? _manager;
  CreateKeyPage(CreateKeyPageArg arg) : super() {

    _keys = arg.keys
        .map((key) => (key is Uint8List ? key : utf8.encode(key.toString()).asUint8List()));
    _manager = arg.manager ? AccURL.toAccURL(arg.manager) : null;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createKeyPage));

    for (var key in _keys) {
      forConcat.addAll(hashMarshalBinary(key));
    }

    if (_manager != null) {
      forConcat.addAll(stringMarshalBinary(_manager.toString()));

    }

    return forConcat.asUint8List();
  }
}

