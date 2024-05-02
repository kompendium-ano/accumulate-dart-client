import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart';

void main() {
  group('Encoding', () {
    test('Field marshal binary should handle valid field', () {
      final field = 10;
      final data = Uint8List.fromList([1, 2, 3]);
      final result = fieldMarshalBinary(field, data);

      expect(result, isNotNull);
      expect(result.length,
          equals(data.length + 1)); // Length should include the field byte
    });

    test(
        'Field marshal binary should throw ValueOutOfRangeException for invalid field',
        () {
      final field = 0;
      final data = Uint8List.fromList([1, 2, 3]);

      expect(() => fieldMarshalBinary(field, data),
          throwsA(TypeMatcher<ValueOutOfRangeException>()));
    });

    test('Uvarint marshal binary should encode integer', () {
      final value = 127;
      final result = uvarintMarshalBinary(value);

      expect(result, isNotNull);
    });

    test('Uvarint marshal binary should handle field', () {
      final value = 127;
      final field = 5;
      final result = uvarintMarshalBinary(value, field);

      expect(result, isNotNull);
    });

    // TO DO: Add more tests for other encoding methods as needed.
  });
}
