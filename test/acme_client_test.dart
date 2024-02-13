import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart';

void main() {
  group('AccURL', () {
    test('Valid URL should parse correctly', () {
      final url = 'acc://example.com/path?query=param#fragment';
      final accUrl = AccURL.parse(url);

      expect(accUrl.authority, 'example.com');
      expect(accUrl.path, '/path');
      expect(accUrl.query, 'query=param');
      expect(accUrl.fragment, 'fragment');
    });

    test('Invalid protocol should throw InvalidProtocolException', () {
      final invalidUrl = 'http://example.com';
      expect(() => AccURL.parse(invalidUrl), throwsA(TypeMatcher<InvalidProtocolException>()));
    });

    test('Missing authority should throw MissingAuthorityException', () {
      final invalidUrl = 'acc://';
      expect(() => AccURL.parse(invalidUrl), throwsA(TypeMatcher<MissingAuthorityException>()));
    });

    test('Appending path segments should create a new AccURL', () {
      final baseUrl = 'acc://example.com';
      final accUrl = AccURL.parse(baseUrl);

      final appendedUrl1 = accUrl.append('path1');
      final appendedUrl2 = accUrl.append('/path2');
      final appendedUrl3 = accUrl.append('path3');

      expect(appendedUrl1.toString(), 'acc://example.com/path1');
      expect(appendedUrl2.toString(), 'acc://example.com/path2');
      expect(appendedUrl3.toString(), 'acc://example.com/path3');
    });

    test('Appending AccURL should create a new AccURL', () {
      final baseUrl = 'acc://example.com';
      final accUrl = AccURL.parse(baseUrl);

      print('Test - Base URL: $baseUrl');

      final appendedUrl = accUrl.append('/path');

      print('Test - Appended URL: ${appendedUrl.toString()}');

      expect(appendedUrl.toString(), 'acc://example.com/path');
    });
  });

}
