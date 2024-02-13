import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart';
import 'dart:convert';

void main() {
  group('FactomEntry', () {
    test('FactomEntry initialization', () {
      final entry = FactomEntry.empty();

      expect(entry.data, isNotNull);
      expect(entry.data.isEmpty, isTrue);
      expect(entry.extRefs, isNotNull);
      expect(entry.extRefs.isEmpty, isTrue);
    });

    test('FactomEntry with initial data', () {
      final initData = Uint8List.fromList([1, 2, 3]);
      final entry = FactomEntry(initData);

      expect(entry.data, isNotNull);
      expect(entry.data, equals(initData));
      expect(entry.extRefs, isNotNull);
      expect(entry.extRefs.isEmpty, isTrue);
    });

    test('Add ExtRef to FactomEntry', () {
      final entry = FactomEntry.empty();
      final extRefString = 'extRefData';

      entry.addExtRef(extRefString);

      expect(entry.extRefs.length, equals(1));
      expect(Uint8List.fromList(entry.extRefs.first.data), equals(utf8.encode(extRefString).asUint8List()));
    });

    test('Get ExtRefs from FactomEntry', () {
      final entry = FactomEntry.empty();
      final extRefStrings = ['extRef1', 'extRef2'];

      for (final extRefString in extRefStrings) {
        entry.addExtRef(extRefString);
      }

      final extRefs = entry.getExtRefs();

      expect(extRefs.length, equals(extRefStrings.length));
      for (var i = 0; i < extRefStrings.length; i++) {
        expect(Uint8List.fromList(extRefs[i]), equals(utf8.encode(extRefStrings[i]).asUint8List()));
      }
    });

    test('Calculate ChainId from FactomEntry', () {
      final entry = FactomEntry.empty();
      final extRefStrings = ['extRef1', 'extRef2'];

      for (final extRefString in extRefStrings) {
        entry.addExtRef(extRefString);
      }

      final chainId = entry.calculateChainId();

      expect(chainId, isNotNull);
    });

    test('Get URL from FactomEntry', () {
      final entry = FactomEntry.empty();
      final extRefStrings = ['extRef1', 'extRef2'];

      for (final extRefString in extRefStrings) {
        entry.addExtRef(extRefString);
      }

      final url = entry.getUrl();

      expect(url, isNotNull);
    });
  });

  group('FactomExtRef', () {
    test('FactomExtRef initialization from Uint8List', () {
      final initData = Uint8List.fromList([1, 2, 3]);
      final extRef = FactomExtRef(initData);

      expect(extRef.data, isNotNull);
      expect(extRef.data, equals(initData));
    });

    test('FactomExtRef initialization from String', () {
      final extRefString = 'extRefData';
      final extRef = FactomExtRef.fromString(extRefString);

      expect(extRef.data, isNotNull);
      expect(Uint8List.fromList(extRef.data), equals(utf8.encode(extRefString).asUint8List()));
    });
  });
}

