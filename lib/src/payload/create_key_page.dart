import 'dart:convert';
import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateKeyPageParam {
  dynamic keys;
  String? memo;
  Uint8List? metadata;
}

class CreateKeyPage extends BasePayload {
  late List<Uint8List> _keys;

  CreateKeyPage(CreateKeyPageParam createKeyPageParam) : super() {
    _keys = createKeyPageParam.keys.map((key) =>
        (key is Uint8List ? key : utf8.encode(key.toString()).asUint8List()));
    super.memo = createKeyPageParam.memo;
    super.metadata = createKeyPageParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.createKeyPage, 1));
    for (var key in _keys) {
      forConcat.addAll(fieldMarshalBinary(
          2, bytesMarshalBinary(bytesMarshalBinary(key, 1))));
    }

    return forConcat.asUint8List();
  }
}
