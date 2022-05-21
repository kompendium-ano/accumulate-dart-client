import 'dart:convert';
import 'dart:typed_data';


int bytesMarshalBinary(List<int> bytes) {
  const MaxVarintLen64 = 10; // Max byte length as specified in go lang library
  BigInt x = BigInt.from(0); // Starting with zero
  int s = 0;

  for(var i = 0; i< bytes.length; i++){
    if (i == MaxVarintLen64) {
      return 0 ;//Return 0 if overflow
    }
    if (bytes[i] < 0) {
      if (i == MaxVarintLen64-1 && bytes[i] > 1 ){
        return 0; //Return 0 if overflow
      }
      return (x | BigInt.from(bytes[i])<<s).toInt() ; //, i + 1
    }
    /*
    Loop byte array from first to last (0 to N)

    0x7F = 127 = 1111111

    bytes[i] & 0x7F  : if number is greater then 127 truncate all extra bits, only right most 8 bits are left

    BigInt.from(bytes[i] & 0x7F ) ) << s  : shift right b 7*i bits where i = [0 to n] (position of current byte in array)
    i.e 1111111 becomes 11111110000000

    x |= (BigInt.from(bytes[i] & 0x7F ) ) << s;

    taking bitwise or with last value
    1000100000000000000
         11111111100011
    1000111111111100011

    */

    x |= (BigInt.from(bytes[i] & 0x7F ) ) << s;
    s += 7;
  }
  return x.toInt();
}

List<int> uvarintMarshalBinary(int number) {
  const int radix = 8; // Set radix value
  BigInt bigInt = BigInt.from(number); // converting int to BigInt for Unsigned bit data conversion
  final data = ByteData((bigInt.bitLength / radix).ceil()); // Create Empty byte array with  length(in bytes) in given number
  var _bigInt = bigInt;
  /*  Explaination
    Loop through bytes from left to right (0 to N)
      Step 1. Set each byte with 1 byte(of given number) from right
        i.e. In binary below
        10111110001100100001001000111111111100011

        we take                         |11100011|
        and set it to byte array at zero
      Step 2. right shift bit by 7
        i.e for binary
        10111110001100100001001000111111111100011
        becomes
        1011111000110010000100100011111111
      loop till zero is left
  */
  for (var i = 0; i < data.lengthInBytes; i++) {
    // i : position of byte
    data.setUint8(i, _bigInt.toUnsigned(radix).toInt()); // Extract last 8 bits and convert them into decimal
    _bigInt = _bigInt >> 8;
  }
  // Return List of type int
  return data.buffer.asUint8List().toList().reversed.toList();
}
List<int> hashMarshalBinary(List<int> hash){
  List<int> forConcat = [];
  forConcat.addAll(uvarintMarshalBinary(hash.length));
  forConcat.addAll(hash);
  return forConcat;
}
List<int> stringMarshalBinary(String content){
  return hashMarshalBinary(utf8.encode(content));
}
List<int> booleanMarshalBinary(bool value){

  List<int> forConcat = [];
  if (value) {
    forConcat.add(1);
  } else {
    forConcat.add(0);
  }

  return forConcat;
}

Uint8List uint64ToBytesNonce(int v) {
  final buf = BytesBuilder();
  final b128 = BigInt.from(0x80);

  BigInt bigV = BigInt.from(v).toUnsigned(64);
  for (var i = 0; bigV >= b128; i++) {
    buf.addByte((bigV | b128).toUnsigned(8).toInt());
    bigV >>= 7;
  }
  buf.addByte((bigV).toUnsigned(8).toInt());

  return buf.toBytes();
}