import 'dart:math';
import 'package:decimal/decimal.dart';
import 'dart:typed_data' show ByteData, Uint8List;

final Map<String, num> fees = {
  "DAI": 1,
  "USDT": 1,
  "USDC": 1,
  "EURS": 1,
  "TUSD": 1,
};

String reduce(dynamic formatedValue) {
  if (formatedValue == null) return '0';
  Decimal decimalValue = Decimal.parse(formatedValue.toString());
  return num.parse(decimalValue.toString()).compareTo(num.parse('0.001')) != 1
      ? decimalValue.toStringAsFixed(1)
      : decimalValue.isInteger
          ? decimalValue.toString()
          : decimalValue.precision > 9
              ? decimalValue.toStringAsFixed(2)
              : decimalValue.toString();
}

String formatValue(BigInt value, int decimals,
    {int fractionDigits = 2, bool withPrecision = false}) {
  if (value == null || decimals == null) return '0';
  double formatedValue = value / BigInt.from(pow(10, decimals));
  if (withPrecision) return formatedValue.toString();
  return reduce(formatedValue);
}

String calcValueInDollar(BigInt value, int decimals) {
  if (value == null || decimals == null) return '0';
  double formatedValue1 = (value / BigInt.from(pow(10, decimals)) / 100);
  Decimal decimalValue = Decimal.parse(formatedValue1.toString());
  return decimalValue.toStringAsFixed(1);
}

String getFiatValue(BigInt value, int decimals, double price,
    {bool withPrecision = false}) {
  if (value == null || decimals == null) return '0';
  double formatedValue = (value / BigInt.from(pow(10, decimals))) * price;
  if (withPrecision) return formatedValue.toString();
  return reduce(formatedValue);
}

String formatAddress(String address) {
  if (address == null || address.isEmpty) return '';
  return '${address.substring(0, 6)}...${address.substring(address.length - 4, address.length)}';
}

BigInt toBigInt(dynamic value, int decimals) {
  if (value == null || decimals == null) return BigInt.zero;
  Decimal tokensAmountDecimal = Decimal.parse(value.toString());
  Decimal decimalsPow = Decimal.parse(pow(10, decimals).toString());
  return BigInt.parse((tokensAmountDecimal * decimalsPow).toString());
}

////////////////////////////////////
// DATA TYPES CONVERSIONS

Uint8List uint64ToBytes(int number) {
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
    _bigInt = _bigInt >> 7;
  }
  // Return List of type int
  return data.buffer.asUint8List();//.toList();
}

int bytesToUint64(List<int> bytes) {
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

// main() {
//   print("Start");
//   var res1 = marshal(5);
//   print(res1);
//   print(unmarshal(res1));
//
//   res1 = marshal(1633767686115);
//   print(res1);
//   print(unmarshal(res1));
//
// }

