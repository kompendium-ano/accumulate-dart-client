import 'dart:convert';

import 'package:hex/hex.dart';

abstract class Marshallable {
  List<int> marshalBinary();
  Map<String, dynamic> toJson();
}

var BigIntFF = BigInt.from(0xFF);

List<int> encodeUint(int value) {
  List<int> bytes = [];
  for (;;) {
    var byte = value & 0x7F;
    value = value >> 7;
    if (value == 0) {
      bytes.add(byte);
      break;
    } else {
      bytes.add(byte | 0x80);
    }
  }
  return bytes;
}

class ProtocolWriter {
  List<int> msg = [];

  void addUvarint(int value) {
    while (value > 0) {}
  }

  void writeHash(int field, String? value) {
    if (value == null) return;

    var raw = HEX.decode(value);
    if (raw.length != 32)
      throw new ArgumentError(
          "Value is not the correct length for a SHA-256 hash");

    // Skip if the hash is all zeros
    if (raw.every((v) => v == 0)) return;

    this.msg.addAll(encodeUint(field));
    this.msg.addAll(raw);
  }

  void writeUint(int field, int? value) {
    // Skip if the value is zero
    if (value == null || value == 0) return;

    this.msg.addAll(encodeUint(field));
    this.msg.addAll(encodeUint(value));
  }

  void writeBool(int field, bool? value) {
    if (value == null) return;

    this.msg.addAll(encodeUint(field));
    this.msg.addAll(encodeUint(value ? 1 : 0));
  }

  void writeHex(int field, String? value) {
    if (value == null) return;

    var raw = HEX.decode(value);
    this.msg.addAll(encodeUint(field));
    this.msg.addAll(encodeUint(raw.length));
    this.msg.addAll(raw);
  }

  void writeRawJson(int field, dynamic value) {
    if (value == null) return;

    var json = jsonEncode(value);
    this.msg.addAll(encodeUint(field));
    this.msg.addAll(encodeUint(json.length));
    this.msg.addAll(utf8.encode(json));
  }

  void writeUtf8(int field, String? value) {
    if (value == null) return;

    this.msg.addAll(encodeUint(field));
    this.msg.addAll(encodeUint(value.length));
    this.msg.addAll(utf8.encode(value));
  }

  void writeBigInt(int field, BigInt? value) {
    // Skip if the value is zero
    if (value == null || value == BigInt.zero) return;

    if (value < BigInt.zero) {
      throw new ArgumentError("Negative BigInts are unsupported");
    }

    List<int> bytes = [];
    while (value! > BigInt.zero) {
      bytes.add((value & BigIntFF).toInt());
      value = value >> 8;
    }

    this.msg.addAll(encodeUint(field));
    this.msg.addAll(encodeUint(bytes.length));
    this.msg.addAll(bytes);
  }

  void writeValue(int field, Marshallable? value) {
    if (value == null) return;

    var bytes = value.marshalBinary();
    this.msg.addAll(encodeUint(field));
    this.msg.addAll(encodeUint(bytes.length));
    this.msg.addAll(bytes);
  }
}
