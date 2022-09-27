import 'dart:core';
import 'dart:typed_data';

import 'package:accumulate_api6/src/acc_url.dart';
import 'package:accumulate_api6/src/utils/hash_builder.dart';
import 'package:accumulate_api6/src/model/factom/factom_ext_ref.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class FactomEntry {

  late List<Uint8List> data;
  late List<FactomExtRef> extRefs;

  List<Uint8List> calculateChainId(){
    var hashBuilder = HashBuilder();

    for (FactomExtRef extRef in extRefs!) {
      hashBuilder.addValue(extRef.data);
    }

    //final byte[] chainId = new byte[32];
    //System.arraycopy(hashBuilder.getCheckSum(), 0, chainId, 0, 32);
    //return chainId;
    return [];
  }

  AccURL getUrl(){
    return AccURL.parse("acc://"); // Url.parse(Hex.encodeHexString(calculateChainId()));
  }
}


