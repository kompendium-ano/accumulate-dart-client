import 'dart:typed_data';

import 'package:accumulate_api6/src/utils/merkle_root_builder.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:crypto/crypto.dart';

class HashBuilder {
  late List<Uint8List> hashList;

  addValue(final List<int> value) {
    if (value != null && value.length > 0) {
      add(value);
    }
  }

  void add(final List<int> value) {
    if (value != null && value.length > 0) {
      var vl = sha256.convert(value).bytes.asUint8List();
      hashList.add(vl);
    }
  }

  List<int> merkleHash() {
    final MerkleRootBuilder merkleRootBuilder = MerkleRootBuilder();
    return [];
  }

  List<int> getCheckSum() {
    //final ByteArrayOutputStream bos = new ByteArrayOutputStream();
    for(Uint8List hv in hashList){

    }
    return []; //sha256Update(data); // bos.toByteArray()); // TODO check if this is correct
  }

}