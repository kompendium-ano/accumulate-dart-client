import 'dart:convert';

import 'package:accumulate_api/src/utils/marshaller.dart';
import 'package:hex/hex.dart';

abstract class Marshallable {
  List<int> marshalBinary();
}

var BigIntFF = BigInt.from(0xFF);

class ProtocolWriter {
  List<int> msg = [];

  void writeHash(int field, String? value) {
    if (value == null) return;

    var raw = HEX.decode(value);
    if (raw.length != 32)
      throw new ArgumentError(
          "Value is not the correct length for a SHA-256 hash");

    this.msg.addAll(uint64ToBytesAlt(field));
    this.msg.addAll(raw);
  }

  void writeUint(int field, int? value) {
    if (value == null) return;

    this.msg.addAll(uint64ToBytesAlt(field));
    this.msg.addAll(uint64ToBytesAlt(value));
  }

  void writeBool(int field, bool? value) {
    if (value == null) return;

    this.msg.addAll(uint64ToBytesAlt(field));
    this.msg.addAll(uint64ToBytesAlt(value ? 1 : 0));
  }

  void writeBytes(int field, String? value) {
    if (value == null) return;

    var raw = HEX.decode(value);
    this.msg.addAll(uint64ToBytesAlt(field));
    this.msg.addAll(uint64ToBytesAlt(raw.length));
    this.msg.addAll(raw);
  }

  void writeString(int field, String? value) {
    if (value == null) return;

    this.msg.addAll(uint64ToBytesAlt(field));
    this.msg.addAll(uint64ToBytesAlt(value.length));
    this.msg.addAll(utf8.encode(value));
  }

  void writeBigInt(int field, BigInt? value) {
    if (value == null) return;

    if (value < BigInt.zero) {
      throw new ArgumentError("Negative BigInts are unsupported");
    }

    List<int> bytes = [];
    while (value! > BigInt.zero) {
      bytes.add((value & BigIntFF).toInt());
      value = value >> 8;
    }

    this.msg.addAll(uint64ToBytesAlt(field));
    this.msg.addAll(uint64ToBytesAlt(bytes.length));
    this.msg.addAll(bytes);
  }

  void writeValue(int field, Marshallable? value) {
    if (value == null) return;

    var bytes = value.marshalBinary();
    this.msg.addAll(uint64ToBytesAlt(field));
    this.msg.addAll(uint64ToBytesAlt(bytes.length));
    this.msg.addAll(bytes);
  }
}
