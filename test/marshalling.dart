import 'dart:math';

import 'package:accumulate_api6/src/encoding.dart';
import 'package:accumulate_api6/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test('should uvarint marshal binary BN numbers', () {
    //int MAXINT = pow(2, 53)-1; // 9007199254740991

    expect(uvarintMarshalBinary(0), [0].asUint8List());
    expect(uvarintMarshalBinary(0, 7), [7, 0].asUint8List());
    expect(uvarintMarshalBinary(1), [1].asUint8List());
    expect(uvarintMarshalBinary(127), [127].asUint8List());
    expect(uvarintMarshalBinary(128), [128, 1].asUint8List());
    expect(uvarintMarshalBinary(256), [128, 2].asUint8List());
    expect(uvarintMarshalBinary(9007199254740991), [255, 255, 255, 255, 255, 255, 255, 15].asUint8List());

  });

  test('should uvarint marshal binary BN numbers', () {
    //int MAXINT = pow(2, 53)-1; // 9007199254740991

    expect(uvarintMarshalBinaryAlt(0), [0].asUint8List());
    expect(uvarintMarshalBinaryAlt(0, 7), [7, 0].asUint8List());
    expect(uvarintMarshalBinaryAlt(1), [1].asUint8List());
    expect(uvarintMarshalBinaryAlt(127), [127].asUint8List());
    expect(uvarintMarshalBinaryAlt(128), [128, 1].asUint8List());
    expect(uvarintMarshalBinaryAlt(256), [128, 2].asUint8List());
    expect(uvarintMarshalBinaryAlt(9007199254740991), [255, 255, 255, 255, 255, 255, 255, 15].asUint8List());

  });

  test('should uvarint marshal binary BN numbers', () {
    //int MAXINT = pow(2, 53)-1; // 9007199254740991

  });

  test('should marshal field', () {
    expect(fieldMarshalBinary(1, booleanMarshalBinary(true)), [1, 1].asUint8List());
    expect(fieldMarshalBinary(2, booleanMarshalBinary(false)), [2, 0].asUint8List());
  });
}
