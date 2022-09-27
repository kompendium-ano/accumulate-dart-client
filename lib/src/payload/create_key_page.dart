import 'dart:convert';
import "dart:typed_data";
import '../utils/utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateKeyPageParam {
  late List<Uint8List> keys;
  String? memo;
  Uint8List? metadata;
}

class CreateKeyPage extends BasePayload {
  late List<Uint8List> _keys;

  CreateKeyPage(CreateKeyPageParam createKeyPageParam) : super() {
    _keys = createKeyPageParam.keys;
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
