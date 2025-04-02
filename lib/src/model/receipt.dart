// lib\src\model\receipt.dart
import 'dart:typed_data';

import 'package:accumulate_api/src/encoding.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:hex/hex.dart';

class ReceiptEntry {
  bool? right;
  dynamic hash;

  ReceiptEntry({
    this.right,
    this.hash,
  });

  factory ReceiptEntry.fromMap(Map<String, dynamic> json) => ReceiptEntry(
        right: json["right"] == null ? null : json["right"],
        hash: json["hash"] == null ? null : json["hash"],
      );

  Map<String, dynamic> toMap() => {
        "right": right == null ? null : right,
        "hash": hash == null ? null : hash,
      };
}

class Receipt {
  dynamic start;
  int? startIndex;
  dynamic end;
  int? endIndex;
  dynamic anchor;
  late List<ReceiptEntry> entries;

  Receipt() {}

  Receipt.fromProof(proof, entries2) {
    start = proof.start != null ? getBytes(proof.start) : Uint8List(0);
    startIndex = proof.startIndex;
    end = proof.end != null ? getBytes(proof.end) : Uint8List(0);
    endIndex = proof.endIndex;
    anchor = proof.anchor != null ? getBytes(proof.anchor) : Uint8List(0);
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
    if (hash == null) {
      return Uint8List(0); // Return an empty Uint8List if hash is null
    }
    if (hash is Uint8List) {
      return hash;
    }
    if (hash is List<int>) {
      return Uint8List.fromList(hash);
    }
    return Uint8List.fromList(
        HEX.decode(hash)); // Convert List<int> to Uint8List
  }
}
