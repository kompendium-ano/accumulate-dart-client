import 'package:accumulate/accumulate.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final acmiAPI = ACMIApi("https://testnet.accumulatenetwork.io", "v1");

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(acmiAPI.toString(), isTrue);
    });
  });
}
