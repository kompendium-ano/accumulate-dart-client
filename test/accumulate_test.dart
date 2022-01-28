import 'package:accumulate/accumulate.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final acmiAPI = ACMIApi();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(acmiAPI.toString(), isTrue);
    });
  });
}
