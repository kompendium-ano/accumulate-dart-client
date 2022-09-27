import 'dart:core';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class FactomExtRef {

  late Uint8List data;

  FactomExtRef (List<int> _data){
    this.data = data;
  }

}