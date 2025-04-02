// C:\Accumulate_Stuff\accumulate-dart-client\examples\archived\previous_exmaple_tests\calc_staking_awards_script.dart

import 'dart:convert';
import 'dart:io';

import 'package:accumulate_api/src/acme_client.dart';
import 'package:accumulate_api/src/model/api_types.dart';

Future<void> main() async {
  // Use the testnet v3 endpoint.
  final String endpoint = 'https://mainnet.accumulatenetwork.io/v3';
  final ACMEClient client = ACMEClient(endpoint);

  // Token account URL to query.
  final String tokenAccountUrl = 'acc://280a527c7077934624fd70648bd28acbffe87770c871e527/acme';

  // We'll paginate through the entire "main" chain.
  const int count = 500;
  int start = 0;
  double totalACME = 0.0;
  int totalRecords = 0;

  print('Querying transaction history for $tokenAccountUrl ...');

  while (true) {
    final Map<String, dynamic> queryParams = {
      "scope": tokenAccountUrl,
      "query": {
        "queryType": "chain",
        "name": "main",
        "range": {
          "start": start,
          "count": count,
          "expand": true,
        }
      }
    };

    print('Sending query with parameters: ${jsonEncode(queryParams)}');

    try {
      final Map<String, dynamic> response = await client.call("query", queryParams);
      // Uncomment the next line to inspect the full response:
      // print(JsonEncoder.withIndent('  ').convert(response));

      // Get the total number of records from the result.
      totalRecords = response['result']?['total'] ?? 0;
      print('Records ${start} to ${start + count} (of $totalRecords)');

      final List<dynamic> records = response['result']?['records'] ?? [];
      if (records.isEmpty) {
        print('No more records found.');
        break;
      }

      // Iterate over each record in this page.
      for (final record in records) {
        final dynamic value = record['value'];
        if (value == null) continue;
        final dynamic message = value['message'];
        if (message == null) continue;
        if (message['type'] != 'transaction') continue;
        final dynamic transaction = message['transaction'];
        if (transaction == null) continue;
        final dynamic body = transaction['body'];
        if (body == null) continue;
        // Process only syntheticDepositTokens transactions.
        if (body['type'] != 'syntheticDepositTokens') continue;
        // Only count if the source is exactly "acc://ACME".
        if (body['source'] != 'acc://ACME') continue;

        final String amountStr = body['amount']?.toString() ?? "0";
        final int amountInt = int.tryParse(amountStr) ?? 0;
        // Divide by 1e8 (100,000,000) to get the ACME value.
        final double amountACME = amountInt / 1e8;
        totalACME += amountACME;
      }

      start += records.length;
      if (start >= totalRecords) {
        break;
      }
    } catch (e) {
      print('Error during query call: $e');
      break;
    }
  }

  print('\nTotal syntheticDepositTokens from acc://ACME: $totalACME ACME');
}
