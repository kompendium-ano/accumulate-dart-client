import 'dart:core';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class FactomExtRef {

  late List<Uint8List> data;

  FactomExtRef (Uint8List _data){
    this.data = data;
  }

}