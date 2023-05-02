import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

extension AsUint8List on List<int> {
  Uint8List asUint8List() {
    final self = this; // Local variable to allow automatic type promotion.
    return (self is Uint8List) ? self : Uint8List.fromList(this);
  }
}

extension AsInt8List on List<int> {
  Int8List asInt8List() {
    final self = this; // Local variable to allow automatic type promotion.
    return (self is Int8List) ? self : Int8List.fromList(this);
  }
}


extension MapToJSON on Map<String, dynamic> {
  String toJson() {
    return jsonEncode(this);
  }
}

extension DynamicToJSON on dynamic {
  String toJson() {
    return jsonEncode(this);
  }
}

extension ObjectToJSON on Object {
  String toJson() {
    return jsonEncode(this);
  }
}

Uint8List sha256Update(Uint8List data) {
  return sha256.convert(data).bytes.asUint8List();
}

Uint8List concatUint8List(List<Uint8List> lists) {
  var bytesBuilder = BytesBuilder();
  lists.forEach((l) {
    bytesBuilder.add(l);
  });
  return bytesBuilder.toBytes();
}

Uint8List concatTwoUint8Lists(Uint8List a, Uint8List b) {
  var bytesBuilder = BytesBuilder();
  bytesBuilder.add(a);
  bytesBuilder.add(b);
  return bytesBuilder.toBytes();
}

bool compareUint8Lists(Uint8List bytes1, Uint8List bytes2) {
  if (identical(bytes1, bytes2)) {
    return true;
  }

  if (bytes1.lengthInBytes != bytes2.lengthInBytes) {
    return false;
  }

  // Treat the original byte lists as lists of 8-byte words.
  var numWords = bytes1.lengthInBytes ~/ 8;
  var words1 = bytes1.buffer.asUint64List(0, numWords);
  var words2 = bytes2.buffer.asUint64List(0, numWords);

  for (var i = 0; i < words1.length; i += 1) {
    if (words1[i] != words2[i]) {
      return false;
    }
  }

  // Compare any remaining bytes.
  for (var i = words1.lengthInBytes; i < bytes1.lengthInBytes; i += 1) {
    if (bytes1[i] != bytes2[i]) {
      return false;
    }
  }

  return true;
}

String toHexString(String original) {
  return original.codeUnits
      .map((c) => c.toRadixString(16).padLeft(2, '0'))
      .toList()
      .join('');
}

Uint8List hexStringtoUint8List(String val) {
  return utf8.encode(val).asUint8List();
}

