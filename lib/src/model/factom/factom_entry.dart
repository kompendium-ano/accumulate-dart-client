import 'dart:core';
import 'dart:typed_data';

import 'package:accumulate_api6/src/acc_url.dart';
import 'package:accumulate_api6/src/model/factom/factom_ext_ref.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class FactomEntry {

  late List<Uint8List> data;
  late List<FactomExtRef> extRefs;

  List<Uint8List> calculateChainId(){

    return [];
  }

  AccURL getUrl(){
    return AccURL.parse("acc://"); // Url.parse(Hex.encodeHexString(calculateChainId()));
  }
}