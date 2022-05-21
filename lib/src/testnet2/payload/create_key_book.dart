import 'dart:convert';
import "dart:typed_data";
import 'package:acc_lib/utils.dart';

import "../acc_url.dart" show AccURL;
import "../marshaller.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateKeyBookArg {
dynamic url;
Uint8List? publicKeyHash;
dynamic manager;
}

class CreateKeyBook extends BasePayload {
  late AccURL _url;
  late Uint8List _publicKeyHash;
  AccURL? _manager;
  CreateKeyBook(CreateKeyBookArg arg) : super() {

    _url = AccURL.toAccURL(arg.url);
    _publicKeyHash = arg.publicKeyHash!;
    _manager = arg.manager ? AccURL.toAccURL(arg.manager) : null;
  }

  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createKeyBook));

    forConcat.addAll(stringMarshalBinary(_url.toString()));

    forConcat.addAll(hashMarshalBinary(_publicKeyHash));

    if (_manager != null) {
      forConcat.addAll(stringMarshalBinary(_manager.toString()));
    }

    return forConcat.asUint8List();
  }
}
