import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

// Helper function to convert hex to bytes
Uint8List hexToBytes(String s) {
  return Uint8List.fromList(hex.decode(s));
}

// Helper function to simulate your existing key parsing
Ed25519KeypairSigner loadSignerFromEncodedKey(String privateKeyBase64) {
  Uint8List privateKey = hexToBytes(privateKeyBase64);
  return Ed25519KeypairSigner.fromKeyRaw(privateKey);
}

// Helper function to get the correct signer version
Future<int> getSignerVersion(ACMEClient client, AccURL keyPageUrl) async {
  var response = await client.queryUrl(keyPageUrl);
  return response["result"]["data"]["version"];
}

class KeyNode {
  String? keyHash;
  String? publicKeyHash;
  String? url;
  List<KeyNode> delegates = [];

  KeyNode({this.keyHash, this.publicKeyHash, this.url});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      if (url != null) 'url': url,
      if (keyHash != null) 'keyHash': keyHash,
      if (publicKeyHash != null) 'publicKeyHash': publicKeyHash,
      if (delegates.isNotEmpty)
        'delegates': delegates.map((delegate) => delegate.toJson()).toList(),
    };

    return data;
  }

  Map<String, dynamic> toCustomJson() {
    final customJson = <String, dynamic>{
      if (url != null && url!.contains('/book/')) 'keyPageUrl': url,
      if (url != null && !url!.contains('/book/')) 'keyBookUrl': url,
      if (publicKeyHash != null) 'publicKeyHash': publicKeyHash,
      'delegates':
          delegates.map((delegate) => delegate.toCustomJson()).toList(),
    };

    return customJson;
  }
}

// Function to query a transaction ID and get the signer
Future<Map<String, String?>> queryTransaction(String txID) async {
  final endPoint = "https://testnet.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);

  final response = await client.call('query-tx', {"txid": txID});
  final data = response["result"];

  String? signer;
  String? origin;

  if (data.containsKey("signatures") && data["signatures"].isNotEmpty) {
    signer = data["signatures"][0]["signer"];
  }

  if (data.containsKey("origin")) {
    origin = data["origin"];
  }

  return {"signer": signer, "origin": origin};
}

// Function to query an ADI key page URL and map out the key page keys and delegates
Future<KeyNode> queryKeyPage(String keyPageUrl) async {
  final endPoint = "https://testnet.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);

  final response = await client.queryUrl(AccURL(keyPageUrl));
  final data = response["result"]["data"];

  KeyNode keyNode = KeyNode(url: keyPageUrl);

  // Extract keys and delegates from the response
  List<dynamic> keys = data["keys"];
  for (var keyData in keys) {
    if (keyData.containsKey("hash")) {
      keyNode.keyHash = keyData["hash"];
    } else if (keyData.containsKey("publicKeyHash")) {
      keyNode.publicKeyHash = keyData["publicKeyHash"];
    }

    if (keyData.containsKey("delegate")) {
      String? delegate = keyData["delegate"];
      if (delegate != null) {
        KeyNode delegateNode = await queryKeyBook(delegate);
        keyNode.delegates.add(delegateNode);
      }
    }
  }

  return keyNode;
}

// Function to query a key book URL and find all key pages
Future<KeyNode> queryKeyBook(String keyBookUrl) async {
  final endPoint = "https://testnet.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);

  final response = await client.queryUrl(AccURL(keyBookUrl));
  final data = response["result"]["data"];

  KeyNode rootNode = KeyNode(url: keyBookUrl);

  // Check the number of pages in the key book
  if (data.containsKey("pageCount") && data["pageCount"] is int) {
    int pageCount = data["pageCount"];
    for (int i = 1; i <= pageCount; i++) {
      String keyPageUrl = "$keyBookUrl/$i";
      KeyNode keyPageNode = await queryKeyPage(keyPageUrl);
      rootNode.delegates.add(keyPageNode);
    }
  }

  return rootNode;
}

// Function to check if a public key is in the key nodes and retrieve key page URL
bool isPublicKeyInKeyNodes(
    KeyNode keyNode, String publicKeyHash, List<String> path,
    {String? keyPageUrl}) {
  if (keyNode.publicKeyHash == publicKeyHash) {
    if (keyPageUrl != null && !path.contains(keyPageUrl)) path.add(keyPageUrl);
    return true;
  }
  for (var delegate in keyNode.delegates) {
    if (isPublicKeyInKeyNodes(delegate, publicKeyHash, path,
        keyPageUrl: keyNode.url != null ? keyNode.url! + "/1" : null)) {
      if (keyNode.url != null && !path.contains(keyNode.url! + "/1"))
        path.add(keyNode.url! + "/1"); // Use key page URL
      return true;
    }
  }
  return false;
}

// Function to get the signing path using the key tree structure JSON
List<String> getSigningPath(Map<String, dynamic> node, String publicKeyHash) {
  List<String> path = [];
  _findPath(node, publicKeyHash, path);
  return path;
}

bool _findPath(
    Map<String, dynamic> node, String publicKeyHash, List<String> path) {
  if (node['publicKeyHash'] == publicKeyHash) {
    if (node['keyPageUrl'] != null && !path.contains(node['keyPageUrl'])) {
      path.add(node['keyPageUrl']);
    }
    return true;
  }
  if (node.containsKey('delegates')) {
    for (var delegate in node['delegates']) {
      if (_findPath(delegate, publicKeyHash, path)) {
        if (node['keyPageUrl'] != null && !path.contains(node['keyPageUrl'])) {
          path.insert(0, node['keyPageUrl']);
        }
        return true;
      }
    }
  }
  return false;
}

// Function to check if the provided public key can sign the transaction and get details
Future<List<Map<String, String>>> getEligibleSigners(
    String adiUrl, String publicKeyHash, String keyTreeStructure) async {
  final endPoint = "https://testnet.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);

  final response = await client.queryUrl(AccURL(adiUrl));
  final data = response["result"]["data"];

  List<Map<String, String>> eligibleSigners = [];

  // Check the key books associated with the ADI
  if (data.containsKey("authorities")) {
    for (var authority in data["authorities"]) {
      String keyBookUrl = authority["url"];
      KeyNode keyBookNode = await queryKeyBook(keyBookUrl);
      List<String> path = [];
      if (isPublicKeyInKeyNodes(keyBookNode, publicKeyHash, path,
          keyPageUrl: keyBookUrl + "/1")) {
        path = getSigningPath(jsonDecode(keyTreeStructure), publicKeyHash);
        eligibleSigners.add({
          'Key Book': keyBookUrl,
          'Key Page': path.last,
          'Public Key Hash': publicKeyHash,
          'Signing Path': path.join(' -> ')
        });
      }
    }
  }

  return eligibleSigners;
}

// Sign + wrap signature with delegation
Future<Map<String, dynamic>> signTransactionWithDelegation({
  required ACMEClient client,
  required String privateKeyBase64,
  required String transactionHashHex,
  required SignerInfo sigInfo,
  required List<SignerInfo> delegators,
}) async {
  // Decode/load private key
  Ed25519KeypairSigner signer = loadSignerFromEncodedKey(privateKeyBase64);

  // Helper: sign hash
  Uint8List signHash(Uint8List hash) {
    return signer.signRaw(hash);
  }

  // Get version of initial signer
  int signerVersion = await getSignerVersion(client, sigInfo.url!);

  // Create initial signature map
  Map<String, dynamic> signature = {
    "type": "ed25519",
    "publicKey": hex.encode(sigInfo.publicKey!),
    "signer": sigInfo.url.toString(),
    "signerVersion": signerVersion,
    "timestamp": DateTime.now().microsecondsSinceEpoch,
  };

  // Save a reference to the inner signature
  var innerSignature = signature;

  // Wrap signature with delegators in order
  for (SignerInfo delegator in delegators) {
    // Get version for each delegator
    int delegatorVersion = await getSignerVersion(client, delegator.url!);

    // Update delegator version
    delegator.version = delegatorVersion;

    // Wrap existing signature in a delegated signature
    innerSignature = {
      "type": "delegated",
      "signature": innerSignature,
      "delegator": delegator.url.toString()
    };
  }

  // Calculate and sign the hash
  Uint8List metadataBytes = signatureMarshalBinary(innerSignature);
  print('Signature: ${hex.encode(metadataBytes)}');
  Uint8List metadataHash =
      Uint8List.fromList(crypto.sha256.convert(metadataBytes).bytes);
  Uint8List transactionHash =
      Uint8List.fromList(hex.decode(transactionHashHex));
  Uint8List toSign = Uint8List.fromList([...metadataHash, ...transactionHash]);
  Uint8List finalHash = Uint8List.fromList(crypto.sha256.convert(toSign).bytes);

  // Debugging: Print intermediate hashes
  print('Metadata Hash: ${hex.encode(metadataHash)}');
  print('Transaction Hash: ${transactionHashHex}');
  print('Final Hash to Sign: ${hex.encode(finalHash)}');

  // Populate signature and transactionHash on the inner signature.
  signature["signature"] = hex.encode(signHash(finalHash));
  signature["transactionHash"] = transactionHashHex;

  // Debugging: Print inner signature details
  print('Inner Signature: ${json.encode(innerSignature)}');

  return innerSignature;
}

Future<void> main() async {
  // Step 1: Check eligibility
  String txID =
      "da97039804132e20c30cc6dbd04f45bb957fd24613a5802307673e43a8e04ed4";
  String adiUrl = "acc://custom-adi-name-1720351349389.acme";
  String publicKeyHash =
      "cb8eb8381e0ffea2fd6e5df846e642a9f6975e39b2ab3085cc845e04eac6a405";

  Map<String, String?> txInfo = await queryTransaction(txID);

  if (txInfo["signer"] != null) {
    KeyNode rootNode = await queryKeyPage(txInfo["signer"]!);

    var result = {
      'transactionId': txID,
      'origin': txInfo["origin"],
      'keyTreeStructure': rootNode.toCustomJson(),
    };

    String keyTreeStructureJson = jsonEncode(result['keyTreeStructure']);
    print(jsonEncode(result));

    List<Map<String, String>> eligibleSigners =
        await getEligibleSigners(adiUrl, publicKeyHash, keyTreeStructureJson);
    if (eligibleSigners.isNotEmpty) {
      print('Number of found eligible signers: ${eligibleSigners.length}');
      for (int i = 0; i < eligibleSigners.length; i++) {
        print('Signer #: ${i + 1}');
        print('Key Book: ${eligibleSigners[i]['Key Book']}');
        print('Key Page: ${eligibleSigners[i]['Key Page']}');
        print('Public Key Hash: ${eligibleSigners[i]['Public Key Hash']}');
        print('Signing Path:');
        print(eligibleSigners[i]['Signing Path']);
        print('');
      }

      // Step 2: Sign the transaction
      String privateKeyBase64 =
          "c58bc5f2643f5ed139c9434bfb772701c373d8aba766e01ff401307799e4fab9ec66e2c540db4169f24973fdf2f6451ff02215383dea790c6ec16717fe2f0d53";
      String publicKeyHex =
          "cb8eb8381e0ffea2fd6e5df846e642a9f6975e39b2ab3085cc845e04eac6a405";
      String transactionHashHex =
          "da97039804132e20c30cc6dbd04f45bb957fd24613a5802307673e43a8e04ed4";

      final sigInfo = SignerInfo()
        ..type = SignatureType.signatureTypeED25519
        ..url = AccURL(eligibleSigners[0]['Key Page']!)
        ..publicKey = hexToBytes(publicKeyHex);

      final endPoint = "https://testnet.accumulatenetwork.io/v2";
      final client = ACMEClient(endPoint);
      final resp = await client.queryTx("acc://${transactionHashHex}@unknown");
      final rawTx = resp["result"]["transaction"];

      final List<SignerInfo> delegators =
          eligibleSigners.sublist(1).map((signer) {
        return SignerInfo()
          ..type = SignatureType.signatureTypeED25519
          ..url = AccURL(signer['Key Page']!)
          ..publicKey = hexToBytes(publicKeyHex);
      }).toList();

      final signature = await signTransactionWithDelegation(
        client: client,
        privateKeyBase64: privateKeyBase64,
        transactionHashHex: transactionHashHex,
        sigInfo: sigInfo,
        delegators: delegators,
      );

      print("Signature: ${json.encode(signature)}");

      // Modify the signature for the RPC call to include delegator levels
      var finalSignature = signature;
      for (var i = delegators.length - 1; i >= 0; i--) {
        finalSignature = {
          "type": "delegated",
          "signature": finalSignature,
          "delegator": delegators[i].url.toString(),
        };
      }

      final executeResponse = await client.call("execute-direct", {
        "envelope": {
          "transaction": [rawTx],
          "signatures": [finalSignature],
        },
      });
      print("Execute response: ${executeResponse}");
    } else {
      print('The provided public key is not eligible to sign the transaction.');
    }
  } else {
    print('No signer found for transaction ID: $txID');
  }
}

// Additional utility functions
Uint8List signatureMarshalBinary(Map<String, dynamic> signature) {
  List<int> data = [];

  var type = signatureTypeCode(signature["type"]);
  var vote = voteTypeCode(signature["vote"]);
  switch (type) {
    case 1: // legacy
      throw Exception("Legacy ED25519 signatures are not supported");

    case 11: // delegated
      data.addAll(uvarintMarshalBinary(type, 1));
      if (signature["signature"] != null) {
        data.addAll(bytesMarshalBinary(
            signatureMarshalBinary(signature["signature"]), 2));
      }
      if (signature["delegator"] != null) {
        data.addAll(stringMarshalBinary(signature["delegator"], 3));
      }
      break;

    default:
      data.addAll(uvarintMarshalBinary(type, 1));
      if (signature["publicKey"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["publicKey"]).asUint8List(), 2));
      }
      if (signature["signature"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["signature"]).asUint8List(), 3));
      }
      if (signature["signer"] != null) {
        data.addAll(stringMarshalBinary(signature["signer"], 4));
      }
      if (signature["signerVersion"] != null) {
        data.addAll(uvarintMarshalBinary(signature["signerVersion"], 5));
      }
      if (signature["timestamp"] != null) {
        data.addAll(uvarintMarshalBinary(signature["timestamp"], 6));
      }
      if (vote != 0) {
        data.addAll(uvarintMarshalBinary(vote, 7));
      }
      if (signature["transactionHash"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["transactionHash"]).asUint8List(), 8));
      }
      if (signature["memo"] != null) {
        data.addAll(stringMarshalBinary(signature["memo"], 9));
      }
      if (signature["data"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["data"]).asUint8List(), 10));
      }
  }

  return data.asUint8List();
}

int signatureTypeCode(String type) {
  switch (type.toLowerCase()) {
    case "legacyed25519":
      return 1;
    case "ed25519":
      return 2;
    case "rcd1":
      return 3;
    case "btc":
      return 8;
    case "btclegacy":
      return 9;
    case "eth":
      return 10;
    case "delegated":
      return 11;
  }
  throw Exception("Invalid signature type ${type}");
}

int voteTypeCode(String? type) {
  if (type == null || type == "") {
    return 0;
  }
  switch (type.toLowerCase()) {
    case "accept":
      return 0;
    case "reject":
      return 1;
    case "abstain":
      return 2;
    case "suggest":
      return 3;
  }
  throw Exception("Invalid vote type ${type}");
}

List<int> uvarintMarshalBinary(int value, int fieldNumber) {
  List<int> result = [];
  int number = (fieldNumber << 3) | 0;
  result.add(number);
  while (value >= 0x80) {
    result.add((value & 0x7F) | 0x80);
    value >>= 7;
  }
  result.add(value);
  return result;
}

List<int> bytesMarshalBinary(Uint8List value, int fieldNumber) {
  List<int> result = [];
  int number = (fieldNumber << 3) | 2;
  result.add(number);
  result.addAll(uvarintMarshalBinary(value.length, 0));
  result.addAll(value);
  return result;
}

List<int> stringMarshalBinary(String value, int fieldNumber) {
  return bytesMarshalBinary(
      Uint8List.fromList(utf8.encode(value)), fieldNumber);
}
