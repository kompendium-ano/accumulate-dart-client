// lib\src\utils\hash_builder.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate_api/src/client/acc_url.dart';
import 'package:accumulate_api/src/utils/merkle_root_builder.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:crypto/crypto.dart';

class HashBuilder {
  late List<Uint8List> _hashList = [];

  void addHash(Uint8List value) {
    if (value.length > 0) {
      _add(value);
    }
  }

  void addBytes(Uint8List value) {
    if (value.length > 0) {
      _add(value);
    }
  }

  void addUrl(AccURL value) {
    _add(utf8.encode(value.toString()).asUint8List());
    }

  void _add(Uint8List value) {
    if (value.length > 0) {
      var vl = sha256.convert(value).bytes.asUint8List();
      _hashList.add(vl);
    }
  }

  Uint8List merkleHash() {
    final MerkleRootBuilder merkleRootBuilder = MerkleRootBuilder();
    for (Uint8List h in _hashList) {
      merkleRootBuilder.addToMerkleTree(h);
    }
    return merkleRootBuilder.getMDRoot();
  }

  Uint8List getCheckSum() {
    var data = concatUint8List(_hashList);
    return sha256.convert(data.toList()).bytes.asUint8List(); // TODO check if this is correct
  }
}
