// lib\src\model\receipt.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate_api/src/encoding.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:hex/hex.dart';

class ReceiptEntry {
  bool? right;
  dynamic hash;
}

class Receipt {
  dynamic start;
  int? startIndex;
  dynamic end;
  int? endIndex;
  dynamic anchor;
  late List<ReceiptEntry> entries;

  Receipt(){
  }

  Receipt.fromProof(proof, entries2){
    start = getBytes(proof.start);
    startIndex = proof.startIndex;
    end = getBytes(proof.end);
    endIndex = proof.endIndex;
    anchor = getBytes(proof.anchor);
    entries = entries2;
  }

  static Uint8List marshalBinaryReceipt(Receipt receipt) {
    List<int> forConcat = [];
    forConcat.addAll(bytesMarshalBinary(getBytes(receipt.start), 1));
    if (receipt.startIndex != null) {
      forConcat.addAll(uvarintMarshalBinary(receipt.startIndex!, 2));
    }
    forConcat.addAll(bytesMarshalBinary(getBytes(receipt.end), 3));
    if (receipt.endIndex != null) {
      forConcat.addAll(uvarintMarshalBinary(receipt.endIndex!, 4));
    }
    forConcat.addAll(bytesMarshalBinary(getBytes(receipt.anchor), 5));

    receipt.entries.forEach((entry) =>
        forConcat.addAll(bytesMarshalBinary(marshalBinaryEntry(entry), 6)));

    return forConcat.asUint8List();
  }

  static Uint8List marshalBinaryEntry(ReceiptEntry re) {
    List<int> forConcat = [];

    if (re.right != null) {
      forConcat.addAll(booleanMarshalBinary(re.right!, 1));
    }

    forConcat.addAll(bytesMarshalBinary(getBytes(re.hash), 2));

    return forConcat.asUint8List();
  }

  static Uint8List getBytes(dynamic hash) {
    if((hash is Uint8List)){
      return hash;

    }

    if((hash is List<int>)){
      return hash.asUint8List();

    }
    return HEX.decode(hash).asUint8List();//utf8.encode(hash).asUint8List();
  }
}
