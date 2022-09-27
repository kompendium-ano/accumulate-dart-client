import 'dart:convert';
import 'dart:typed_data';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

extension AsUint8List on List<int> {
  Uint8List asUint8List() {
    final self = this; // Local variable to allow automatic type promotion.
    return (self is Uint8List) ? self : Uint8List.fromList(this);
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

Uint8List concatUint8(Uint8List a, Uint8List b) {
  var bytesBuilder = BytesBuilder();
  bytesBuilder.add(a);
  bytesBuilder.add(b);
  return bytesBuilder.toBytes();
}