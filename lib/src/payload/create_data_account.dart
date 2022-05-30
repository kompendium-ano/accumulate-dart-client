import 'dart:convert';
import 'dart:typed_data';

import '../../src/utils.dart';

import "../acc_url.dart" show AccURL;
import "../marshaller.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateDataAccountArg {
  dynamic url;
  dynamic keyBookUrl;
  dynamic managerKeyBookUrl;
  bool? scratch;
}

class CreateDataAccount extends BasePayload {
  late AccURL _url;
  AccURL? _keyBookUrl;
  AccURL? _managerKeyBookUrl;
  late bool _scratch;

  CreateDataAccount(CreateDataAccountArg arg) : super() {
    _url = AccURL.toAccURL(arg.url);
    _keyBookUrl = arg.keyBookUrl ? AccURL.toAccURL(arg.keyBookUrl) : null;
    _managerKeyBookUrl =
        arg.managerKeyBookUrl ? AccURL.toAccURL(arg.managerKeyBookUrl) : null;
    _scratch = arg.scratch ?? false;
  }

  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createDataAccount));
    forConcat.addAll(stringMarshalBinary(_url.toString()));


    if (_keyBookUrl != null) {
      forConcat.addAll(stringMarshalBinary(_keyBookUrl.toString()));

    }

    if (_managerKeyBookUrl != null) {
      forConcat.addAll(stringMarshalBinary(_managerKeyBookUrl.toString()));

    }

    forConcat.addAll(booleanMarshalBinary(_scratch));


    return forConcat.asUint8List();
  }
}
