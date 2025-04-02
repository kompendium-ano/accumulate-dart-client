// C:\Accumulate_Stuff\accumulate-dart-client\examples\multisig_sand_box\debug_script_signer_finder.dart

import 'dart:async';
import 'dart:convert';
import 'package:accumulate_api/accumulate_api.dart'; // Ensure this package is added in your pubspec.yaml

/// -------------------------
/// Helper: URL Normalization
/// -------------------------
/// When comparing a key page URL (ending with "/1") to a delegate (a key book URL),
/// we remove the trailing "/1" for comparison.
String normalizeUrl(String url) {
  String normalized = url.endsWith('/1') ? url.substring(0, url.length - 2) : url;
  print("==> [NORMALIZE URL] Original: $url, Normalized: $normalized");
  return normalized;
}

String normalizeDelegate(String delegate) {
  String normalized = delegate.endsWith('/1') ? delegate.substring(0, delegate.length - 2) : delegate;
  print("==> [NORMALIZE DELEGATE] Original: $delegate, Normalized: $normalized");
  return normalized;
}

/// -------------------------
/// Primary Helper Functions
/// -------------------------

Future<Map<String, dynamic>> queryTransaction(String txId, ACMEClientV3 client) async {
  print("==> [QUERY TRANSACTION] txId: $txId");
  if (txId.isEmpty) {
    print("==> [QUERY TRANSACTION] Error: txId is empty.");
    return {};
  }
  Map<String, dynamic> params = {"scope": "$txId@anything"};
  try {
    var result = await client.call("query", params);
    print("==> [QUERY TRANSACTION] Result for txId $txId: ${jsonEncode(result)}");
    return result;
  } catch (e) {
    print("==> [QUERY TRANSACTION] Error querying txId $txId: $e");
    return {};
  }
}

Future<Map<String, dynamic>> queryTransactionDetails(String txHash, ACMEClientV3 client) async {
  print("==> [QUERY TRANSACTION DETAILS] txHash: $txHash");
  try {
    final response = await queryTransaction(txHash, client);
    return response["result"];
  } catch (e) {
    print("==> [QUERY TRANSACTION DETAILS] Error for txHash $txHash: $e");
    return {};
  }
}

Future<Map<String, dynamic>> queryUrlDetails(String url, ACMEClientV3 client) async {
  print("==> [QUERY URL DETAILS] url: $url");
  try {
    final response = await client.call("query", {"scope": url});
    print("==> [QUERY URL DETAILS] Response for $url: ${jsonEncode(response)}");
    return response["result"];
  } catch (e) {
    print("==> [QUERY URL DETAILS] Error for $url: $e");
    return {};
  }
}

Future<List<Map<String, dynamic>>> queryTxChain(String url, String type, ACMEClientV3 client) async {
  print("==> [QUERY TX CHAIN] url: $url, type: $type");
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
          "range": {"start": start, "count": count, "expand": true},
        },
      });
      print("==> [QUERY TX CHAIN] $type Chain Response: ${jsonEncode(response)}");
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
      print("==> [QUERY TX CHAIN] Error querying $type chain: $e");
      hasMore = false;
    }
  }
  print("==> [QUERY TX CHAIN] Total records found: ${allRecords.length}");
  return allRecords;
}

/// Process primary signatures to extract updateKeyPage signing paths.
/// We build paths using the full URL (e.g. "acc://beastmode.acme/book/1")
/// but compare delegates using the normalized URL.
Future<List<String>> processSignatures(
    ACMEClientV3 client,
    List<Map<String, dynamic>> signatures,
    String url,
    Set<String> processedTxHashes) async {
  List<String> signingPaths = [];
  print("==> [PROCESS SIGNATURES] Processing signatures for $url...");
  String compareUrl = normalizeUrl(url);
  for (var signature in signatures) {
    var signatureHash = signature['entry'];
    var txID = signature['value']?['message']?['txID'];
    if (txID != null) {
      var txHash = txID.split('@')[0].split('//')[1];
      if (processedTxHashes.contains(txHash)) continue;
      processedTxHashes.add(txHash);
      var txDetails = await queryTransactionDetails(txHash, client);
      var txType = txDetails['message']?['transaction']?['body']?['type'] ?? 'unknown';
      var principal = txDetails['message']?['transaction']?['header']?['principal'] ?? 'unknown';
      print("==> [PROCESS SIGNATURES] Found signature: $signatureHash, txHash: $txHash, principal: $principal, txType: $txType");
      if (txType == 'updateKeyPage') {
        var operations = txDetails['message']?['transaction']?['body']?['operation'] ?? [];
        for (var operation in operations) {
          var operationType = operation['type'];
          var delegate = operation['entry']?['delegate'];
          if (operationType == 'add' && delegate == compareUrl) {
            var signingPath = '$url -> $principal';
            print("==> [PROCESS SIGNATURES] PRIMARY SIGNING PATH FOUND: $signingPath");
            signingPaths.add(signingPath);
          }
        }
      }
    } else {
      print("==> [PROCESS SIGNATURES] Error: txID is null for signature: $signatureHash");
    }
  }
  print("==> [PROCESS SIGNATURES] Total primary signing paths found: ${signingPaths.length}");
  return signingPaths;
}

/// -------------------------
/// Secondary (Signature-Chain) Discovery
/// -------------------------

Future<List<Map<String, dynamic>>> queryAllSignatureChain(
    ACMEClientV3 client, String url) async {
  print("==> [QUERY ALL SIGNATURE CHAIN] url: $url");
  int start = 0;
  int pageSize = 100;
  List<Map<String, dynamic>> allRecords = [];
  bool hasMore = true;
  while (hasMore) {
    try {
      final response = await client.call("query", {
        "scope": url,
        "query": {
          "queryType": "chain",
          "name": "signature",
          "range": {"start": start, "count": pageSize, "expand": true},
        },
      });
      if (response["result"] != null && response["result"]["records"] != null) {
        List<Map<String, dynamic>> records =
            List<Map<String, dynamic>>.from(response["result"]["records"]);
        allRecords.addAll(records);
        print("==> [QUERY ALL SIGNATURE CHAIN] Fetched ${records.length} records at start $start");
        if (records.length < pageSize) {
          hasMore = false;
        } else {
          start += pageSize;
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      print("==> [QUERY ALL SIGNATURE CHAIN] Error for $url: $e");
      hasMore = false;
    }
  }
  print("==> [QUERY ALL SIGNATURE CHAIN] Total records found: ${allRecords.length}");
  return allRecords;
}

/// Recursively parse a nested signature object to extract the delegation chain.
/// For example, returns: [ "acc://baseSigner", "acc://delegator1", "acc://delegator2", ... ]
List<String> parseDelegationChain(Map signature) {
  if (signature == null) return [];
  if (signature["type"] == "delegated") {
    List<String> innerChain = parseDelegationChain(signature["signature"]);
    if (signature.containsKey("delegator") &&
        signature["delegator"] != null &&
        signature["delegator"] is String) {
      innerChain.add(signature["delegator"]);
    }
    return innerChain;
  } else {
    var signer = signature["signer"];
    if (signer == null || signer is! String) return [];
    return [signer];
  }
}

/// Uses the secondary method to discover signing paths from a given signer URL.
/// This method queries the entire signature chain, sorts the latest 50 records,
/// then parses each delegation chain and builds sub‑chains.
Future<List<String>> secondarySignerSearch(
    ACMEClientV3 client, String signerUrl) async {
  print("==> [SECONDARY SEARCH] Querying all signature chain for $signerUrl");
  final allSignatures = await queryAllSignatureChain(client, signerUrl);
  if (allSignatures.isEmpty) return [];
  allSignatures.sort((a, b) {
    int indexA = a['index'] is int ? a['index'] : int.tryParse(a['index'].toString()) ?? 0;
    int indexB = b['index'] is int ? b['index'] : int.tryParse(b['index'].toString()) ?? 0;
    return indexB.compareTo(indexA);
  });
  final latestSignatures = allSignatures.take(50).toList();
  print("==> [SECONDARY SEARCH] Latest 50 signatures count: ${latestSignatures.length}");
  Set<String> secondaryPaths = {};
  for (var sigRecord in latestSignatures) {
    var message = sigRecord["value"]?["message"];
    if (message == null ||
        message["type"] != "signature" ||
        message["signature"] == null) {
      continue;
    }
    List<String> chain = parseDelegationChain(message["signature"]);
    if (chain.length < 2) continue;
    // Build sub‑chains for each delegation level.
    for (int level = 1; level < chain.length; level++) {
      List<String> subChain = chain.sublist(0, level + 1);
      String path = subChain.join(" -> ");
      secondaryPaths.add(path);
    }
  }
  print("==> [SECONDARY SEARCH] Secondary signing paths found: ${secondaryPaths.length}");
  return secondaryPaths.toList();
}

/// -------------------------
/// Integration: Combining Primary & Secondary Results
/// -------------------------
///
/// In this updated version, after primary discovery we run secondary search not only on the initial URL,
/// but also on each primary signing path’s individual segments (excluding the provider’s base).
/// For each secondary result, we “rebase” it so that the provider’s base (the initial URL) is prefixed.
/// This ensures that every final signing path starts with the provider’s own signer.
Future<List<String>> combinedSigningPaths(
    ACMEClientV3 client, String initialUrl,
    Set<String> processedUrls, Set<String> processedTxHashes) async {
  print("==> [COMBINED] Starting combined discovery for $initialUrl");
  // Primary discovery.
  List<String> primaryPaths = await collectData(initialUrl, processedUrls, processedTxHashes, client);
  print("==> [COMBINED] Primary discovered signing paths: $primaryPaths");

  // For each primary path (except level 0), run secondary search on each segment after the provider’s base.
  Set<String> additionalSecondaryPaths = {};
  for (String primary in primaryPaths) {
    List<String> segments = primary.split("->").map((s) => s.trim()).toList();
    // Skip the provider's own base (level 0)
    for (int i = 1; i < segments.length; i++) {
      String segment = segments[i];
      print("==> [COMBINED] Running secondary search on segment: $segment");
      List<String> secPaths = await secondarySignerSearch(client, segment);
      print("==> [COMBINED] Secondary discovered signing paths for $segment: $secPaths");
      // For each secondary path discovered on this segment, rebase it by prefixing with the provider’s base.
      for (String sec in secPaths) {
        // If sec starts with the same segment, remove that prefix.
        String rebased;
        if (sec.startsWith(segment)) {
          String remainder = sec.substring(segment.length).trim();
          if (remainder.startsWith("->")) {
            remainder = remainder.substring(2).trim();
          }
          rebased = "$initialUrl -> $segment -> $remainder";
        } else {
          rebased = "$initialUrl -> $sec";
        }
        additionalSecondaryPaths.add(rebased);
      }
    }
  }
  print("==> [COMBINED] Total additional secondary signing paths (rebased): ${additionalSecondaryPaths.toList()}");

  // Combine primary paths with additional secondary results.
  Set<String> combined = {...primaryPaths, ...additionalSecondaryPaths};
  print("==> [COMBINED] Combined signing paths (deduplicated): ${combined.toList()}");
  return combined.toList();
}

/// -------------------------
/// Validation
/// -------------------------
/// For each adjacent pair in the signing path, the key page (right segment)
/// should list a key whose delegate (normalized) matches the normalized left segment.
Future<bool> validateSigningPath(ACMEClientV3 client, String path) async {
  List<String> segments = path.split('->').map((s) => s.trim()).toList();
  for (int i = segments.length - 1; i > 0; i--) {
    String delegate = segments[i - 1];
    String keyPage = segments[i];
    String normalizedDelegate = normalizeUrl(delegate);
    print("==> [VALIDATE] Validating segment: $delegate -> $keyPage");
    var keyPageDetails = await queryUrlDetails(keyPage, client);
    var keys = keyPageDetails['account']?['keys'] ?? [];
    bool delegateFound = keys.any((key) =>
        normalizeDelegate(key['delegate'] ?? '') == normalizedDelegate);
    if (delegateFound) {
      print("==> [VALIDATE] Delegate $delegate found in $keyPage");
    } else {
      print("==> [VALIDATE] Delegate $delegate NOT found in $keyPage");
      return false;
    }
  }
  return true;
}

Future<List<String>> validateAllSigningPaths(ACMEClientV3 client, List<String> signingPaths) async {
  List<String> validatedPaths = [];
  for (String path in signingPaths) {
    print("==> [VALIDATE ALL] Validating path: $path");
    bool isValid = await validateSigningPath(client, path);
    if (isValid) {
      print("==> [VALIDATE ALL] Path validated: $path");
      validatedPaths.add(path);
    } else {
      print("==> [VALIDATE ALL] Path invalidated: $path");
    }
  }
  return validatedPaths;
}

/// -------------------------
/// Overall Collection (Primary)
/// -------------------------
/// The collectData function uses the primary discovery method to build signing paths.
Future<List<String>> collectData(
    String initialUrl, Set<String> processedUrls, Set<String> processedTxHashes, ACMEClientV3 client) async {
  print("==> [COLLECT DATA] Starting primary discovery for $initialUrl");
  List<String> allSigningPaths = [];
  Map<String, dynamic> initialDetails = await queryUrlDetails(initialUrl, client);
  if (initialDetails.isEmpty) {
    print("==> [COLLECT DATA] Error: Failed to fetch initial details for $initialUrl.");
    return allSigningPaths;
  }
  print("==> [COLLECT DATA] Details for $initialUrl: ${jsonEncode(initialDetails)}");
  String? initialType = initialDetails['account']?['type'];
  if (initialType == null) {
    print("==> [COLLECT DATA] Error: Unable to determine the type of $initialUrl.");
    return allSigningPaths;
  }
  String? initialKeyBookUrl;
  List<Map<String, dynamic>> signatures = [];
  if (initialType == 'keyBook') {
    initialKeyBookUrl = initialUrl;
    signatures = await queryTxChain(initialKeyBookUrl, 'signature', client);
  } else if (initialType == 'keyPage') {
    initialKeyBookUrl = initialDetails['account']?['keyBook'];
    if (initialKeyBookUrl == null) {
      print("==> [COLLECT DATA] Error: Key book URL is null for key page $initialUrl.");
      return allSigningPaths;
    }
    signatures = await queryTxChain(initialUrl, 'signature', client);
  } else {
    print("==> [COLLECT DATA] Error: Initial URL is neither a key book nor a key page.");
    return allSigningPaths;
  }
  print("==> [COLLECT DATA] Signatures: ");
  signatures.forEach((sig) => print(jsonEncode(sig)));
  // For processing primary signatures, if the account is a key page, use the key book URL for comparison.
  String compareUrl = (initialType == 'keyPage') ? initialKeyBookUrl! : initialUrl;
  List<String> signingPaths = await processSignatures(client, signatures, compareUrl, processedTxHashes);
  print("==> [COLLECT DATA] Primary discovered updateKeyPage signing paths:");
  signingPaths.forEach((p) => print(p));
  // Add the initial URL as level 0.
  if (!processedUrls.contains(initialUrl)) {
    processedUrls.add(initialUrl);
    allSigningPaths.add(initialUrl);
    print("==> [COLLECT DATA] Added level 0 signing path: $initialUrl");
  }
  // Add primary discovered paths.
  allSigningPaths.addAll(signingPaths);
  print("==> [COLLECT DATA] Total primary signing paths collected: ${allSigningPaths.length}");
  return allSigningPaths;
}

/// -------------------------
/// Overall Update & Validation
/// -------------------------
Future<void> main() async {
  // Use "acc://beastmode.acme/book/1" as the provided initial URL.
  String initialUrl = "acc://beastmode.acme/book/1";
  print("==> [SCRIPT] Starting signer finder debug script for: $initialUrl");

  // Define the Accumulate endpoint.
  final endPoint = "https://mainnet.accumulatenetwork.io/v3";
  // Create an instance of the ACME client.
  final client = ACMEClientV3(endPoint);

  // Sets to keep track of processed URLs and transaction hashes.
  Set<String> processedUrls = {};
  Set<String> processedTxHashes = {};

  // Get combined signing paths (primary + secondary).
  List<String> allSigningPaths = await combinedSigningPaths(client, initialUrl, processedUrls, processedTxHashes);
  if (allSigningPaths.isEmpty) {
    print("==> [SCRIPT] No signing paths collected.");
    return;
  }
  print("==> [SCRIPT] Combined signing paths collected: $allSigningPaths");

  // Validate the signing paths.
  List<String> validatedSigningPaths = await validateAllSigningPaths(client, allSigningPaths);
  if (validatedSigningPaths.isEmpty) {
    print("==> [SCRIPT] No valid signing paths found.");
    return;
  }
  print("==> [SCRIPT] Validated signing paths: $validatedSigningPaths");

  // Print final results.
  print("\nFinal Validated Signing Paths:");
  validatedSigningPaths.forEach((path) => print(path));
}
