import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'dart:convert';

import 'package:accumulate_api/src/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class FactomExtRef {
  Uint8List data = Uint8List.fromList([]);

  FactomExtRef(Uint8List _data) {
    this.data = _data; // Correct assignment
  }

  FactomExtRef.fromString(String _data) {
    data = utf8.encode(_data);
  }
}
