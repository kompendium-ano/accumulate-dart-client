import 'dart:core';
import 'dart:typed_data';

import 'package:accumulate_api6/src/payload/base_payload.dart';
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
    // TODO: implement extendedMarshalBinary
    throw UnimplementedError();
  }

  Uint8List marshallExtIds() {
    // TODO: implement marshallExtIds
    throw UnimplementedError();
  }

}
