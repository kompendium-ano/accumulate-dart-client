import 'dart:typed_data';

import 'package:accumulate_api6/src/utils/utils.dart';

class MerkleRootBuilder {
  late int count;
  late List<Uint8List> pending = [];
  late List<Uint8List> hashList = [];

  MerkleRootBuilder(){
     count = 0;
  }

  Uint8List addToMerkleTree(Uint8List sourceHash) {
    Uint8List hash = sourceHash;
    hashList.add(hash);
    count++;
    padPending();
    for (int i = 0; i < pending.length; i++) {
      Uint8List v = pending.elementAt(i);
      if (v == Uint8List.fromList([])) {
        pending[i] = hash;
        return hash;
      }

      hash = sha256Update(concatUint8(v, hash));
      pending[i] = Uint8List.fromList([]); // same as `null`
    }
    return hash;
  }

  void padPending() {
    if (pending.isEmpty || (pending.elementAt(pending.length - 1) != Uint8List.fromList([]))) {
      pending.add(Uint8List.fromList([]));
    }
  }

  Uint8List getMDRoot() {
    Uint8List mdRoot = Uint8List.fromList([]);
    if (count == 0) {
      return mdRoot;
    }

    for (Uint8List pendingHash in pending) {
      if (pendingHash == null) continue;

      if (mdRoot.length == 0) {
         mdRoot = pendingHash;
      } else {
         mdRoot = sha256Update(concatUint8(pendingHash, mdRoot));
      }
    }

    return mdRoot;
  }

}
