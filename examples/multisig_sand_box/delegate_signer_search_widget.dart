import 'dart:async';
import 'dart:convert';
import 'package:accumulate_api/accumulate_api.dart';

// Function to query details for a URL
Future<Map<String, dynamic>> queryUrlDetails(
    ACMEClientV3 client, String url) async {
  final response = await client.queryUrl(url);
  return response["result"];
}

// Function to query transaction chain with pagination
Future<List<Map<String, dynamic>>> queryTxChain(
    ACMEClientV3 client, String url, String type) async {
  int start = 0;
  int count = 10;
  List<Map<String, dynamic>> allRecords = [];
  bool hasMore = true;

  while (hasMore) {
    try {
      final response = await client.call("query", {
        "scope": url,
        "query": {
          "queryType": "chain",
          "name": type,
          "range": {
            "start": start,
            "count": count,
            "expand": true,
          },
        },
      });
      print('$type Chain Response: $response');
      if (response["result"] != null && response["result"]["records"] != null) {
        List<Map<String, dynamic>> records =
            List<Map<String, dynamic>>.from(response["result"]["records"]);
        allRecords.addAll(records);
        start += count;
        if (records.length < count) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('Error querying $type chain: $e');
      hasMore = false;
    }
  }
  return allRecords;
}

// Function to query transaction details
Future<Map<String, dynamic>> queryTransactionDetails(
    ACMEClientV3 client, String txHash) async {
  try {
    final response = await client.queryTransaction(txHash);
    return response["result"];
  } catch (e) {
    print('Error querying transaction details for $txHash: $e');
    return {};
  }
}

// Function to process and print signature hashes along with transaction hashes and their types
Future<List<String>> processSignatures(ACMEClientV3 client,
    List<Map<String, dynamic>> signatures, String url) async {
  List<String> signingPaths = [];
  print('Signature Hashes, their Transaction Hashes, and Transaction Types:');
  for (var signature in signatures) {
    var signatureHash = signature['entry'];
    var txID = signature['value']?['message']?['txID'];
    if (txID != null) {
      var txHash = txID.split('@')[0].split('//')[1];
      var txDetails = await queryTransactionDetails(client, txHash);
      var txType =
          txDetails['message']?['transaction']?['body']?['type'] ?? 'unknown';
      var principal = txDetails['message']?['transaction']?['header']
              ?['principal'] ??
          'unknown';

      print('Signature Hash: $signatureHash, Transaction Hash: $txHash');
      print('Principal: $principal');
      print('Transaction Type: $txType');

      // If the transaction type is updateKeyPage, parse out the operation details
      if (txType == 'updateKeyPage') {
        var operations =
            txDetails['message']?['transaction']?['body']?['operation'] ?? [];
        for (var operation in operations) {
          var operationType = operation['type'];
          var delegate = operation['entry']?['delegate'];
          if (operationType == 'add' && delegate == url) {
            var signingPath = '$url -> $principal';
            print('Operation Type: $operationType, Delegate: $delegate');
            print('Signing Path: $signingPath');
            print(
                'This $url can sign for this external keyBook as a delegate.');
            signingPaths.add(signingPath);
          }
        }
      }
    } else {
      print('Error: txID is null for signature: $signatureHash');
    }
  }
  return signingPaths;
}

// Function to recursively query delegating books and their signing paths
Future<void> queryDelegatingBooks(
    ACMEClientV3 client,
    List<String> signingPaths,
    List<String> allSigningPaths,
    String initialPath) async {
  for (var path in signingPaths) {
    var keyPage = path.split('->')[1].trim();
    var delegatingBook = keyPage.split('/1')[0];
    var fullPath = '$initialPath -> $delegatingBook/1';
    allSigningPaths.add(fullPath);

    print('Querying delegating book: $delegatingBook');

    // Query the delegating book
    var details = await queryUrlDetails(client, delegatingBook);
    print('Details for delegating book $delegatingBook:');
    print(jsonEncode(details));

    // Collect transaction chains for the delegating book
    List<Map<String, dynamic>> signatures =
        await queryTxChain(client, delegatingBook, 'signature');

    print('Signatures for delegating book: $delegatingBook');
    signatures.forEach((sig) => print(jsonEncode(sig)));

    // Process signatures to find and handle related transactions
    List<String> newSigningPaths =
        await processSignatures(client, signatures, delegatingBook);

    // Print the list of discovered updateKeyPage signing paths
    print(
        'Discovered updateKeyPage signing paths for delegating book: $delegatingBook');
    newSigningPaths.forEach((path) => print(path));

    // Recursively query new delegating books
    await queryDelegatingBooks(
        client, newSigningPaths, allSigningPaths, fullPath);
  }
}

// Function to collect data from the key book or key page details
Future<void> collectData(ACMEClientV3 client, String initialUrl) async {
  List<String> allSigningPaths = [];

  // Query the initial URL details
  Map<String, dynamic> initialDetails =
      await queryUrlDetails(client, initialUrl);
  print('Details for $initialUrl:');
  print(jsonEncode(initialDetails));

  // Determine if the initial URL is a key book or key page
  String initialType = initialDetails['account']['type'];
  String initialKeyBookUrl;
  List<Map<String, dynamic>> signatures;

  if (initialType == 'keyBook') {
    initialKeyBookUrl = initialUrl;
    // Collect transaction chains
    signatures = await queryTxChain(client, initialKeyBookUrl, 'signature');
  } else if (initialType == 'keyPage') {
    initialKeyBookUrl = initialDetails['account']['keyBook'];
    // Collect transaction chains for the key page
    signatures = await queryTxChain(client, initialUrl, 'signature');
  } else {
    print('Error: Initial URL is neither a key book nor a key page.');
    return;
  }

  print('Signatures:');
  signatures.forEach((sig) => print(jsonEncode(sig)));

  // Process signatures to find and handle related transactions
  List<String> signingPaths =
      await processSignatures(client, signatures, initialKeyBookUrl);

  // Print the list of discovered updateKeyPage signing paths
  print('Discovered updateKeyPage signing paths:');
  signingPaths.forEach((path) => print(path));

  // Query all delegating books
  await queryDelegatingBooks(
      client, signingPaths, allSigningPaths, initialKeyBookUrl);

  // Print all discovered signing paths
  print('All discovered signing paths:');
  allSigningPaths.forEach((path) => print('Signing Path: $path'));
}

// Main function to execute the script
Future<void> main() async {
  final endPoint = "https://testnet.accumulatenetwork.io/v3";
  final client = ACMEClientV3(endPoint);
  final initialUrl =
      "acc://testtest1120.acme/book/1"; // or provide a key page URL

  // Collect and print data
  await collectData(client, initialUrl);
}
