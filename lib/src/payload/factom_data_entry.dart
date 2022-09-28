import 'dart:core';
import 'dart:typed_data';

import 'package:accumulate_api6/src/encoding.dart';
import 'package:accumulate_api6/src/payload/base_payload.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

class FactomDataEntryParam {
  Uint8List? accountId;
  Uint8List? data;
  List<Uint8List>? extIds;
}

@JsonSerializable()
class FactomDataEntry extends BasePayload {
  Uint8List accountId = Uint8List.fromList([]);
  Uint8List data = Uint8List.fromList([]);
  List<Uint8List> extIds = [];

  FactomDataEntry(FactomDataEntryParam param) {
    data = param.data!;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    Uint8List refsBinary = marshallExtIds();

    forConcat.addAll(bytesMarshalBinary(accountId));
    forConcat.addAll(uvarintMarshalBinary(refsBinary.length));
    forConcat.addAll(bytesMarshalBinary(refsBinary));
    forConcat.addAll(bytesMarshalBinary(data));

    return forConcat.asUint8List();
  }

  Uint8List marshallExtIds() {
    List<int> forConcat = [];
    for (Uint8List e in extIds) {
      forConcat.addAll(uvarintMarshalBinary(e.length));
      forConcat.addAll(bytesMarshalBinary(e));
    }
    return forConcat.asUint8List();
  }
}
