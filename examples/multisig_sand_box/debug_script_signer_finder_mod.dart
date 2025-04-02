import 'dart:async';
import 'dart:convert';
import 'package:accumulate_api/accumulate_api.dart'; // Ensure this package is added in your pubspec.yaml

/// -------------------------
/// Helper: URL Normalization & Conversion to Key Page (Case Insensitive)
/// -------------------------
String toKeyPage(String url) {
  // Convert to lowercase first.
  String lowerUrl = url.toLowerCase();
  List<String> parts = lowerUrl.split("/");
  if (parts.isNotEmpty) {
    String last = parts.last;
    if (int.tryParse(last) != null) {
      // Already a key page.
      return lowerUrl;
    }
  }
  String keyPage = "$lowerUrl/1";
  print("==> [TO KEY PAGE] Converting $url to key page: $keyPage");
  return keyPage;
}

String normalizeUrl(String url) {
  // Convert to lowercase first.
  String lowerUrl = url.toLowerCase();
  // Remove trailing "/1" if present.
  String normalized = lowerUrl.endsWith('/1') ? lowerUrl.substring(0, lowerUrl.length - 2) : lowerUrl;
  print("==> [NORMALIZE URL] Original: $url, Normalized: $normalized");
  return normalized;
}

String normalizeDelegate(String delegate) {
  // Convert to lowercase first.
  String lowerDelegate = delegate.toLowerCase();
  String normalized = lowerDelegate.endsWith('/1')
      ? lowerDelegate.substring(0, lowerDelegate.length - 2)
      : lowerDelegate;
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
/// We work with key page URLs only. The signing path is built as:
/// baseKeyPage -> delegateKeyPage.
Future<List<String>> processSignatures(
    ACMEClientV3 client,
    List<Map<String, dynamic>> signatures,
    String url,
    Set<String> processedTxHashes) async {
  List<String> signingPaths = [];
  String baseKeyPage = toKeyPage(url);
  print("==> [PROCESS SIGNATURES] Processing signatures for $baseKeyPage...");
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
      String principalKeyPage = toKeyPage(principal);
      print("==> [PROCESS SIGNATURES] Found signature: $signatureHash, txHash: $txHash, principal: $principalKeyPage, txType: $txType");
      if (txType == 'updateKeyPage') {
        var operations = txDetails['message']?['transaction']?['body']?['operation'] ?? [];
        for (var operation in operations) {
          var operationType = operation['type'];
          var delegate = operation['entry']?['delegate'];
          // Compare using normalized key book URL.
          if (operationType == 'add' && delegate == normalizeUrl(url)) {
            var signingPath = '$baseKeyPage -> $principalKeyPage';
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
/// Secondary (Signature-Chain) Discovery (unchanged)
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
/// Recursive Primary Discovery
/// -------------------------
/// This function uses primary discovery recursively on each discovered delegate (key page).
Future<List<String>> recursivePrimaryDiscovery(
    ACMEClientV3 client,
    String url,
    Set<String> visited,
    Set<String> processedTxHashes,
    [int depth = 0]) async {
  if (depth > 10) {
    return [toKeyPage(url)];
  }
  String current = toKeyPage(url);
  if (visited.contains(current)) {
    return [current];
  }
  visited.add(current);
  
  // Get immediate primary paths for the current key page.
  Set<String> localVisited = {};
  List<String> immediatePaths = await collectData(current, localVisited, processedTxHashes, client);
  
  Set<String> extendedPaths = { current };
  
  // For each immediate signing path that includes a delegation, recursively query the delegate.
  for (String path in immediatePaths) {
    List<String> segments = path.split("->").map((s) => s.trim()).toList();
    if (segments.length < 2) continue;
    // The delegate is the last segment.
    String delegate = segments.last;
    String delegateKeyPage = toKeyPage(delegate);
    List<String> subPaths = await recursivePrimaryDiscovery(client, delegateKeyPage, visited, processedTxHashes, depth + 1);
    for (String sub in subPaths) {
      String extension = sub.startsWith(delegateKeyPage) ? sub.substring(delegateKeyPage.length).trim() : sub;
      if (extension.startsWith("->")) {
        extension = extension.substring(2).trim();
      }
      String fullPath = "$path" + (extension.isNotEmpty ? " -> $extension" : "");
      extendedPaths.add(fullPath);
    }
    extendedPaths.add(path);
  }
  return extendedPaths.toList();
}

/// -------------------------
/// Validation
/// -------------------------
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
/// This function remains largely as in the original script.
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
  String base = (initialType == 'keyPage') ? initialUrl : toKeyPage(initialUrl);
  List<Map<String, dynamic>> signatures = [];
  if (initialType == 'keyBook') {
    signatures = await queryTxChain(initialUrl, 'signature', client);
  } else if (initialType == 'keyPage') {
    signatures = await queryTxChain(initialUrl, 'signature', client);
  } else {
    print("==> [COLLECT DATA] Error: Initial URL is neither a key book nor a key page.");
    return allSigningPaths;
  }
  print("==> [COLLECT DATA] Signatures: ");
  signatures.forEach((sig) => print(jsonEncode(sig)));
  List<String> signingPaths = await processSignatures(client, signatures, base, processedTxHashes);
  print("==> [COLLECT DATA] Primary discovered updateKeyPage signing paths:");
  signingPaths.forEach((p) => print(p));
  if (!processedUrls.contains(base)) {
    processedUrls.add(base);
    allSigningPaths.add(base);
    print("==> [COLLECT DATA] Added level 0 signing path: $base");
  }
  allSigningPaths.addAll(signingPaths);
  print("==> [COLLECT DATA] Total primary signing paths collected: ${allSigningPaths.length}");
  return allSigningPaths;
}

/// -------------------------
/// Main
/// -------------------------
Future<void> main() async {
  // Use "acc://beastmode.acme/book/1" as the provided example URL.
  String initialUrl = "acc://beastmode.acme/book/1";
  print("==> [SCRIPT] Starting recursive signer finder debug script for: $initialUrl");

  final endPoint = "https://mainnet.accumulatenetwork.io/v3";
  final client = ACMEClientV3(endPoint);

  Set<String> visited = {};
  Set<String> processedTxHashes = {};

  List<String> allRecursivePaths = await recursivePrimaryDiscovery(client, initialUrl, visited, processedTxHashes);
  print("==> [SCRIPT] Recursive signing paths collected: $allRecursivePaths");

  List<String> validatedSigningPaths = await validateAllSigningPaths(client, allRecursivePaths);
  if (validatedSigningPaths.isEmpty) {
    print("==> [SCRIPT] No valid signing paths found.");
    return;
  }
  print("==> [SCRIPT] Validated signing paths: $validatedSigningPaths");

  print("\nFinal Validated Signing Paths:");
  validatedSigningPaths.forEach((path) => print(path));
}
