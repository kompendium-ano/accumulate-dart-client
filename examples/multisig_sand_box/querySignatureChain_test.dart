// C:\Accumulate_Stuff\accumulate-dart-client\examples\multisig_sand_box\querySignatureChain_test.dart

import 'dart:async';
import 'dart:convert';
import 'package:accumulate_api/accumulate_api.dart';

/// Queries the entire signature chain for a given URL using pagination.
Future<List<Map<String, dynamic>>> queryAllSignatureChain(
    ACMEClientV3 client, String url) async {
  int start = 0;
  int pageSize = 100; // Adjust page size as needed.
  List<Map<String, dynamic>> allRecords = [];
  bool hasMore = true;

  while (hasMore) {
    try {
      final response = await client.call("query", {
        "scope": url,
        "query": {
          "queryType": "chain",
          "name": "signature",
          "range": {
            "start": start,
            "count": pageSize,
            "expand": true,
          },
        },
      });
      if (response["result"] != null && response["result"]["records"] != null) {
        List<Map<String, dynamic>> records =
            List<Map<String, dynamic>>.from(response["result"]["records"]);
        allRecords.addAll(records);
        if (records.length < pageSize) {
          hasMore = false;
        } else {
          start += pageSize;
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('Error querying signature chain for $url: $e');
      hasMore = false;
    }
  }
  return allRecords;
}

/// Recursively parses a nested signature object to extract the delegation chain.
///
/// The chain is built so that:
/// - The base signature returns its "signer" (if available)
/// - Each delegation layer (of type "delegated") appends its "delegator"
///
/// For example, given a nested signature structure:
///   { "type": "delegated",
///     "signature": { "type": "delegated",
///                    "signature": { "type": "ed25519", "signer": "acc://jason.acme/book/1", ... },
///                    "delegator": "acc://accumulate.acme/committee-members/2" },
///     "delegator": "acc://dn.acme/operators/2" }
///
/// This function returns:
///   [ "acc://jason.acme/book/1", "acc://accumulate.acme/committee-members/2", "acc://dn.acme/operators/2" ]
List<String> parseDelegationChain(Map signature) {
  if (signature == null) return [];
  if (signature["type"] == "delegated") {
    // Recursively parse the inner signature.
    List<String> innerChain = parseDelegationChain(signature["signature"]);
    // Only add the delegator if it is a non-null string.
    if (signature.containsKey("delegator") &&
        signature["delegator"] != null &&
        signature["delegator"] is String) {
      innerChain.add(signature["delegator"]);
    }
    return innerChain;
  } else {
    // Base signature type (e.g. ed25519) should have a "signer" field.
    var signer = signature["signer"];
    if (signer == null || signer is! String) {
      // Return an empty chain if no valid signer is found.
      return [];
    }
    return [signer];
  }
}

Future<void> main() async {
  // Define the Accumulate endpoint.
  final endPoint = "https://mainnet.accumulatenetwork.io/v3";

  // Create an instance of the ACME client.
  final client = ACMEClientV3(endPoint);

  // Provide the signer URL you wish to query.
  final signerUrl = "acc://dn.acme/operators/1";

  print("Querying the signature chain for: $signerUrl\n");

  // Query the entire signature chain.
  final allSignatures = await queryAllSignatureChain(client, signerUrl);

  if (allSignatures.isEmpty) {
    print("No signatures found for $signerUrl.");
    return;
  }

  // Sort the signatures by their 'index' in descending order (most recent first).
  allSignatures.sort((a, b) {
    int indexA = a['index'] is int
        ? a['index']
        : int.tryParse(a['index'].toString()) ?? 0;
    int indexB = b['index'] is int
        ? b['index']
        : int.tryParse(b['index'].toString()) ?? 0;
    return indexB.compareTo(indexA);
  });

  // Take only the latest 50 signatures.
  final latestSignatures = allSignatures.take(50).toList();

  print("Most recent ${latestSignatures.length} signature records:");
  latestSignatures.forEach((sig) => print(jsonEncode(sig)));

  // Build signing paths grouped by delegation level.
  // For a chain like:
  //    [base, delegator1, delegator2, ...]
  // we construct:
  //    Level 1: base -> delegator1
  //    Level 2: base -> delegator1 -> delegator2
  Map<int, Set<String>> signingPathsByLevel = {}; // level -> set of signing path strings.

  for (var sigRecord in latestSignatures) {
    // Navigate to the nested signature field.
    var message = sigRecord["value"]?["message"];
    if (message == null ||
        message["type"] != "signature" ||
        message["signature"] == null) {
      continue;
    }
    // Parse the delegation chain from the signature.
    List<String> chain = parseDelegationChain(message["signature"]);

    // Only process if there's at least one delegation (i.e. chain length > 1).
    if (chain.length < 2) continue;

    // For each delegation level, build the signing path.
    // Level 1 path uses chain[0] and chain[1], level 2 uses chain[0] -> chain[1] -> chain[2], etc.
    for (int level = 1; level < chain.length; level++) {
      List<String> subChain = chain.sublist(0, level + 1);
      String path = subChain.join(" -> ");
      signingPathsByLevel.putIfAbsent(level, () => <String>{});
      signingPathsByLevel[level]!.add(path);
    }
  }

  print("\nConstructed Signing Paths by Delegation Level:");
  if (signingPathsByLevel.isEmpty) {
    print("No signing paths discovered.");
  } else {
    // Print paths sorted by level.
    List<int> levels = signingPathsByLevel.keys.toList()..sort();
    for (int level in levels) {
      print("\nLevel $level Signing Paths:");
      for (String path in signingPathsByLevel[level]!) {
        print(path);
      }
    }
  }
}
