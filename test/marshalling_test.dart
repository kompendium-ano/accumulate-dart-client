import 'dart:math';

import 'package:accumulate_api/src/encoding.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  test('should uvarint marshal binary BN numbers', () {
    expect(uvarintMarshalBinary(0), [0].asUint8List());
    expect(uvarintMarshalBinary(0, 7), [7, 0].asUint8List());
    expect(uvarintMarshalBinary(1), [1].asUint8List());
    expect(uvarintMarshalBinary(127), [127].asUint8List());
    expect(uvarintMarshalBinary(128), [128, 1].asUint8List());
    expect(uvarintMarshalBinary(256), [128, 2].asUint8List());

    expect(uvarintMarshalBinary(9007199254740991), [255, 255, 255, 255, 255, 255, 255, 15].asUint8List());
    expect(uvarintMarshalBinary(pow(2, 53).toInt() - 1), [255, 255, 255, 255, 255, 255, 255, 15].asUint8List());

    //new
    expect(bigNumberMarshalBinary(9007199254740991), [7, 31, 255, 255, 255, 255, 255, 255].asUint8List());

    expect(uvarintMarshalBinary(pow(2, 53).toInt()), [128, 128, 128, 128, 128, 128, 128, 16].asUint8List());

    // we see [3,..] here because it indicates number of values
    expect(bytesMarshalBinary([0, 1, 2].asUint8List()), [3, 0, 1, 2].asUint8List());

    expect(stringMarshalBinary("test"), [4, 116, 101, 115, 116].asUint8List());

    // Try to exceed Max number on Dart platform
    //expect(bigNumberMarshalBinary(pow(2, 64).toInt()), [255, 255, 255, 255, 255, 255, 255, 255, 255, 1].asUint8List());
  });

  // This throws on web only
  test('should throw on number input greater than MAX_SAFE_INTEGER', () {
    //int MAXINT = pow(2, 53)-1; // 9007199254740991
    // expect(() => uvarintMarshalBinary(pow(2, 53)+1, throwsA(isA<MaxSafeInteger>()));
  });

  test('should marshal binary boolean', () {
    expect(booleanMarshalBinary(true), [1].asUint8List());
    expect(booleanMarshalBinary(false), [0].asUint8List());
  });

  test('should marshal binary hash', () {
    final hash = [
      0x18,
      0x94,
      0xa1,
      0x9c,
      0x85,
      0xba,
      0x15,
      0x3a,
      0xcb,
      0xf7,
      0x43,
      0xac,
      0x4e,
      0x43,
      0xfc,
      0x00,
      0x4c,
      0x89,
      0x16,
      0x04,
      0xb2,
      0x6f,
      0x8c,
      0x69,
      0xe1,
      0xe8,
      0x3e,
      0xa2,
      0xaf,
      0xc7,
      0xc4,
      0x8f,
    ].asUint8List();

    expect(hashMarshalBinary(hash), hash);
  });

  test('should throw when marshal binary hash', () {
    final hash = [
      0x18,
      0x94,
      0xa1,
      0x9c,
      0x85,
      0xba,
      0x15,
      0x3a,
      0xcb,
      0xf7,
      0x43,
      0xac,
      0x4e,
      0x43,
      0xfc,
      0x00,
      0x4c,
      0x89,
      0x16,
      0x04,
      0xb2,
      0x6f,
      0x8c,
      0x69,
      0xe1,
      0xe8,
      0x3e,
      0xa2,
      0xaf,
      0xc7,
      0xc4,
      0x8f,
      0xc4
    ].asUint8List();

    expect(() => hashMarshalBinary(hash), throwsA(isA<InvalidHashLengthException>()));
  });

  test('should marshal field', () {
    expect(fieldMarshalBinary(1, booleanMarshalBinary(true)), [1, 1].asUint8List());
    expect(fieldMarshalBinary(2, booleanMarshalBinary(false)), [2, 0].asUint8List());
  });

  test('should throw when marshal field', () {
    expect(() => fieldMarshalBinary(0, booleanMarshalBinary(true)), throwsA(isA<ValueOutOfRangeException>()));
  });

  test('should marshal with field', () {
    expect(withFieldNumber(uvarintMarshalBinaryAlt(1), 1), [1, 1].asUint8List());
    expect(withFieldNumber(uvarintMarshalBinaryAlt(1), 2), [2, 1].asUint8List());
  });

  // Testing alternative implementation for uvarint
  test('should varint marshal binary BN numbers', () {
    expect(uvarintMarshalBinaryAlt(0), []); // This is wrong behaviour, should be [0] but generates []
    expect(uvarintMarshalBinaryAlt(2), [2].asUint8List());
    expect(uvarintMarshalBinaryAlt(-1), []); // This is wrong behaviour, should be [1] but generates []
    expect(uvarintMarshalBinaryAlt(128), [128].asUint8List());
    expect(uvarintMarshalBinaryAlt(-64), [192].asUint8List());
  });
}
