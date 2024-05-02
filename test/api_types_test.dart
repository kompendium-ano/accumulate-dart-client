import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart'; // Adjust the import path as necessary.

void main() {
  group('QueryPagination Tests', () {
    test('toMap returns correct map', () {
      final queryPagination = QueryPagination()
        ..start = 1
        ..count = 10;

      final map = queryPagination.toMap;

      expect(map, isA<Map<String, dynamic>>());
      expect(map['start'], equals(1));
      expect(map['count'], equals(10));
    });
  });

  group('QueryPaginationForBlocks Tests', () {
    test('toMap returns correct map', () {
      final queryPaginationForBlocks = QueryPaginationForBlocks()
        ..start = 1
        ..limit = 10;

      final map = queryPaginationForBlocks.toMap;

      expect(map, isA<Map<String, dynamic>>());
      expect(map['start'], equals(1));
      expect(map['count'], equals(10)); // Assuming 'count' is the intended key.
    });
  });

  group('QueryOptions Tests', () {
    test('toMap includes all set properties', () {
      final queryOptions = QueryOptions()
        ..expand = true
        ..height = 100
        ..prove = false
        ..scratch = true;

      final map = queryOptions.toMap;

      expect(map['expand'], isTrue);
      expect(map['height'], equals(100));
      expect(map['prove'], isFalse);
      expect(map['scratch'], isTrue);
    });
  });

  group('TxQueryOptions Tests', () {
    test('toMap includes all set properties', () {
      final txQueryOptions = TxQueryOptions()
        ..expand = true
        ..height = 100
        ..prove = false
        ..scratch = true
        ..wait = 10
        ..ignorePending = true;

      final map = txQueryOptions.toMap;

      expect(map['expand'], isTrue);
      expect(map['height'], equals(100));
      expect(map['prove'], isFalse);
      expect(map['scratch'], isTrue);
      expect(map['wait'], equals(10));
      expect(map['ignorePending'], isTrue);
    });
  });

  group('TxHistoryQueryOptions Tests', () {
    test('toMap includes set property', () {
      final txHistoryQueryOptions = TxHistoryQueryOptions()..scratch = true;

      final map = txHistoryQueryOptions.toMap;

      expect(map['scratch'], isTrue);
    });
  });

  group('MinorBlocksQueryOptions Tests', () {
    test('toMap includes all set properties with correct values', () {
      final minorBlocksQueryOptions = MinorBlocksQueryOptions()
        ..txFetchMode = 0
        ..blockFilterMode = 1;

      final map = minorBlocksQueryOptions.toMap;

      expect(map['TxFetchMode'], equals('Expand'));
      expect(map['BlockFilterMode'], equals('ExcludeEmpty'));
    });
  });

  group('WaitTxOptions Tests', () {
    test('toMap includes all set properties with default values', () {
      final waitTxOptions = WaitTxOptions();

      final map = waitTxOptions.toMap;

      expect(map['timeout'], equals(30000));
      expect(map['pollInterval'], equals(500));
      expect(map['ignoreSyntheticTxs'], isFalse);
    });

    test('toMap includes all set properties with custom values', () {
      final waitTxOptions = WaitTxOptions()
        ..timeout = 10000
        ..pollInterval = 100
        ..ignoreSyntheticTxs = true;

      final map = waitTxOptions.toMap;

      expect(map['timeout'], equals(10000));
      expect(map['pollInterval'], equals(100));
      expect(map['ignoreSyntheticTxs'], isTrue);
    });
  });

  group('TxError Tests', () {
    test('toString returns formatted error message', () {
      final txError = TxError('tx123', 'Pending');

      final stringRepresentation = txError.toString();

      expect(stringRepresentation, contains('txId:tx123'));
      expect(stringRepresentation, contains('status:Pending'));
    });
  });
}
