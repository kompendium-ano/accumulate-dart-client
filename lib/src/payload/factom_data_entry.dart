// lib\src\payload\factom_data_entry.dart
import 'dart:core';
import 'dart:typed_data';
import 'package:accumulate_api/src/encoding.dart';
import 'package:accumulate_api/src/payload/base_payload.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

class FactomDataEntryParam {
  Uint8List? accountId;
  Uint8List? data;
  List<Uint8List>? extIds;
}

@JsonSerializable()
class FactomDataEntry extends BasePayload {
  Uint8List? _accountId;
  Uint8List? _data;
  List<Uint8List> _extIds = [];

  FactomDataEntry(FactomDataEntryParam param) {
    _accountId = param.accountId!;
    _data = param.data!;
    _extIds = param.extIds!;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(bytesMarshalBinary(_accountId!, 1));
    //forConcat.addAll(uvarintMarshalBinary(_data!.length, 2));
    //forConcat.addAll(bytesMarshalBinary(_data!, 3));
    if (_extIds.length > 0) {
      Uint8List refsBinary = marshallExtIds();
      //forConcat.addAll(bytesMarshalBinary(refsBinary, 3));
    }

    return forConcat.asUint8List();
  }

  Uint8List marshallExtIds() {
    List<int> forConcat = [];
    for (Uint8List e in _extIds) {
      forConcat.addAll(uvarintMarshalBinary(e.length));
      forConcat.addAll(bytesMarshalBinary(e));
    }
    return forConcat.asUint8List();
  }
}
