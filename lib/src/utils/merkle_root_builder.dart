// lib\src\utils\merkle_root_builder.dart
import 'dart:typed_data';

import 'package:accumulate_api/src/utils/utils.dart';
import 'package:crypto/crypto.dart';

class MerkleRootBuilder {
  late int count;
  late List<Uint8List> pending = [];
  late List<Uint8List> hashList = [];
  Uint8List emptyUint8List = Uint8List.fromList([]);

  MerkleRootBuilder() {
    count = 0;
  }

  Uint8List addToMerkleTree(Uint8List sourceHash) {
    Uint8List hash = sourceHash;
    hashList.add(hash);
    count++;
    padPending();
    for (int i = 0; i < pending.length; i++) {
      Uint8List v = pending.elementAt(i);
      if (compareUint8Lists(v, emptyUint8List)) {
        pending[i] = hash;
        return hash;
      }

      Uint8List data = concatTwoUint8Lists(v, hash);
      var digest = sha256.convert(data.toList());
      hash = digest.bytes.asUint8List();

      pending[i] = emptyUint8List;
    }
    return hash;
  }

  void padPending() {
    if (pending.isEmpty ||
        !compareUint8Lists(
            pending.elementAt(pending.length - 1), emptyUint8List)) {
      pending.add(emptyUint8List);
    }
  }

  Uint8List getMDRoot() {
    Uint8List mdRoot = emptyUint8List;
    if (count == 0) {
      return mdRoot;
    }

    for (Uint8List pendingHash in pending) {
      if (compareUint8Lists(pendingHash, emptyUint8List)) continue;

      if (mdRoot.isEmpty) {
        mdRoot = concatTwoUint8Lists(mdRoot, pendingHash);
      } else {
        mdRoot = sha256Update(concatTwoUint8Lists(pendingHash, mdRoot));
      }
    }

    return mdRoot;
  }
}
