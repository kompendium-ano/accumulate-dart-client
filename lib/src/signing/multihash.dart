import "dart:typed_data";

import 'package:accumulate_api/accumulate_api.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:bs58/bs58.dart';
import 'package:collection/collection.dart';
import "package:crypto/crypto.dart";

class MultiHash {
  int? version;
  Uint8List? pubkey;

  hash() {
    Uint8List? _multiHash;

    Uint8List hashList = new Uint8List(pubkey!.length + 1);
    hashList.setAll(0, [1].asUint8List());
    hashList.setAll(1, pubkey!);

    _multiHash = sha256.convert(sha256.convert(hashList).bytes.asUint8List()).bytes.asUint8List();

    return _multiHash;
  }
}