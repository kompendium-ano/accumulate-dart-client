import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'package:accumulate_api/src/utils/utils.dart';


void main() {
  group('AsUint8List extension', () {
    test('Should convert List<int> to Uint8List', () {
      final list = [1, 2, 3, 4, 5];
      final uint8List = list.asUint8List();
      expect(uint8List, isA<Uint8List>());
      expect(uint8List.toList(), list);
    });
  });

  group('AsInt8List extension', () {
    test('Should convert List<int> to Int8List', () {
      final list = [1, 2, 3, 4, 5];
      final int8List = list.asInt8List();
      expect(int8List, isA<Int8List>());
      expect(int8List.toList(), list);
    });
  });

  group('sha256Update function', () {
    test('Should calculate SHA-256 hash correctly', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final hash = sha256Update(data);
      expect(hash, isA<Uint8List>());
      final expectedHash = sha256.convert(data).bytes.asUint8List();
      expect(hash, expectedHash);
    });
  });

  group('concatUint8List function', () {
    test('Should concatenate a list of Uint8List correctly', () {
      final list1 = Uint8List.fromList([1, 2, 3]);
      final list2 = Uint8List.fromList([4, 5]);
      final concatenated = concatUint8List([list1, list2]);
      expect(concatenated, isA<Uint8List>());
      expect(concatenated.toList(), [1, 2, 3, 4, 5]);
    });
  });

  group('concatTwoUint8Lists function', () {
    test('Should concatenate two Uint8List correctly', () {
      final list1 = Uint8List.fromList([1, 2, 3]);
      final list2 = Uint8List.fromList([4, 5]);
      final concatenated = concatTwoUint8Lists(list1, list2);
      expect(concatenated, isA<Uint8List>());
      expect(concatenated.toList(), [1, 2, 3, 4, 5]);
    });
  });

  group('compareUint8Lists function', () {
    test('Should compare two Uint8List correctly', () {
      final list1 = Uint8List.fromList([1, 2, 3]);
      final list2 = Uint8List.fromList([1, 2, 3]);
      final list3 = Uint8List.fromList([4, 5, 6]);

      expect(compareUint8Lists(list1, list2), isTrue);
      expect(compareUint8Lists(list1, list3), isFalse);
    });
  });

  group('toHexString function', () {
    test('Should convert string to hexadecimal string', () {
      final original = 'Hello, World!';
      final hexString = toHexString(original);
      expect(hexString, '48656c6c6f2c20576f726c6421');
    });
  });

  group('hexStringtoUint8List function', () {
    test('Should convert hexadecimal string to Uint8List', () {
      final hexString = '48656c6c6f2c20576f726c6421';
      final uint8List = hexStringtoUint8List(hexString);
      expect(uint8List, isA<Uint8List>());
      expect(uint8List.toList(), [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]);
    });
  });
}
