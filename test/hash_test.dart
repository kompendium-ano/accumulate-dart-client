import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate_api6/src/utils/merkle_root_builder.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  test('should construct Merkle Root', () {
    Uint8List testHash = utf8.encode("0x0f0a").asUint8List();

    final MerkleRootBuilder merkleRootBuilder = MerkleRootBuilder();
    merkleRootBuilder.addToMerkleTree(testHash);
    merkleRootBuilder.addToMerkleTree(testHash);
    Uint8List root = merkleRootBuilder.getMDRoot();

    print(testHash); // [48, 120, 48, 102, 48, 97]
    print(root);

    //expect(root, exp);
  });


}
