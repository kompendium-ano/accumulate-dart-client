import 'dart:convert';
import 'dart:typed_data';

import 'utils.dart';

Uint8List fieldMarshalBinary(int field, Uint8List val) {
  if (field < 1 || field > 32) {
    throw Exception('Field number is out of range [1, 32]: $field');
  }

  List<int> uint8list = List<int>.from(uvarintMarshalBinary(field));

  uint8list.addAll(val);

  return uint8list.asUint8List();
}

Uint8List uvarintMarshalBinaryAlt(int val, [int? field]) {
  const int radix = 8; // Set radix value
  BigInt bigInt = BigInt.from(
      val); // converting int to BigInt for Unsigned bit data conversion
  final data = ByteData((bigInt.bitLength / radix)
      .ceil()); // Create Empty byte array with  length(in bytes) in given number
  var _bigInt = bigInt;
  var i = 0;

  for (i = 0; i < data.lengthInBytes; i++) {
    data.setUint8(
        i,
        _bigInt
            .toUnsigned(radix)
            .toInt()); // Extract last 8 bits and convert them into decimal

    _bigInt = _bigInt >> 7;
  }

  if (field != null) {
    return fieldMarshalBinary(field, data.buffer.asUint8List());
  }

  return data.buffer.asUint8List();
}

Uint8List uvarintMarshalBinary(int val, [int? field]) {
  const int radix = 8;
  BigInt bigInt = BigInt.from(val);

  List<int> numData = [];

  var _bigInt = bigInt;
  var i = 0;
  BigInt mxNum = BigInt.from(8);
  while (_bigInt > mxNum) {
    var tmpBigInt = _bigInt.toUnsigned(radix);
    if ((tmpBigInt + BigInt.from(128)) < BigInt.from(255)) {
      tmpBigInt += BigInt.from(128);
    }

    numData.add(tmpBigInt.toInt());
    _bigInt = _bigInt >> 7;
    i++;
  }

  var tmpBigInt = _bigInt.toUnsigned(radix);
  if ((tmpBigInt > BigInt.from(8)) &&
      ((tmpBigInt + BigInt.from(128)) < BigInt.from(255))) {
    tmpBigInt += BigInt.from(128);
  }

  numData.add(tmpBigInt.toInt());

  if (field != null) {
    return fieldMarshalBinary(field, numData.asUint8List());
  }

  return numData.asUint8List();
}

Uint8List bigNumberMarshalBinary(int num, [int? field]) {
  BigInt bn = BigInt.from(num);
  List<int> data = bytesMarshalBinary(bigIntToUint8List(bn));
  return withFieldNumber(data.asUint8List(), field);
}

Uint8List booleanMarshalBinary(bool b, [int? field]) {
  List<int> forConcat = [];
  if (b) {
    forConcat.add(1);
  } else {
    forConcat.add(0);
  }
  return withFieldNumber(forConcat.asUint8List(), field);
}

Uint8List stringMarshalBinary(String val, [int? field]) {
  final data = bytesMarshalBinary(utf8.encode(val).asUint8List());
  return withFieldNumber(data, field);
}

Uint8List bytesMarshalBinary(Uint8List val, [int? field]) {
  final length = uvarintMarshalBinaryAlt(val.length);
  List<int> forConcat = [];
  forConcat.addAll(length);
  forConcat.addAll(val);

  return withFieldNumber(forConcat.asUint8List(), field);
}

Uint8List hashMarshalBinary(Uint8List val, [int? field]) {
  if (val.length != 32) {
    throw Exception('Invalid length, value is not a hash');
  }

  return withFieldNumber(val, field);
}

Uint8List withFieldNumber(Uint8List data, [int? field]) {
  return field != null ? fieldMarshalBinary(field, data) : data;
}

Uint8List bigIntToUint8List(BigInt bigInt) =>
    bigIntToByteData(bigInt).buffer.asUint8List();

ByteData bigIntToByteData(BigInt bigInt) {
  final data = ByteData((bigInt.bitLength / 8).ceil());
  var _bigInt = bigInt;

  for (var i = 1; i <= data.lengthInBytes; i++) {
    data.setUint8(data.lengthInBytes - i, _bigInt.toUnsigned(8).toInt());
    _bigInt = _bigInt >> 8;
  }

  return data;
}


