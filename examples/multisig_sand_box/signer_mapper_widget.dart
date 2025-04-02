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

  final response = await client.queryTx("acc://$txID@unknown");
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
        path = getSigningPath(publicKeyHash, keyTreeStructure, path);
        eligibleSigners.add({
          'Key Book': keyBookUrl,
          'Key Page': keyBookUrl + "/1", // Assuming the Key Page is always /1
          'Public Key Hash': publicKeyHash,
          'Signing Path': path.join(' -> ') // Keep the order as is
        });
      }
    }
  }

  return eligibleSigners;
}

// Function to get the signing path using the key tree structure JSON
List<String> getSigningPath(
    String publicKeyHash, String keyTreeStructure, List<String> path) {
  Map<String, dynamic> keyTree = jsonDecode(keyTreeStructure);
  _traverseKeyTree(keyTree, publicKeyHash, path);
  return path.toSet().toList(); // Ensure unique paths
}

bool _traverseKeyTree(
    Map<String, dynamic> node, String publicKeyHash, List<String> path) {
  if (node['publicKeyHash'] == publicKeyHash) {
    if (node['keyPageUrl'] != null && !path.contains(node['keyPageUrl'])) {
      path.add(node['keyPageUrl']);
    }
    return true;
  }
  if (node.containsKey('delegates')) {
    for (var delegate in node['delegates']) {
      if (_traverseKeyTree(delegate, publicKeyHash, path)) {
        if (node['keyPageUrl'] != null && !path.contains(node['keyPageUrl'])) {
          path.add(node['keyPageUrl']);
        }
        return true;
      }
    }
  }
  return false;
}

Future<void> main() async {
  String txID =
      "0ba9ff4f2605ba23e12481b3be0374641636c3c24792ef7877105e039ebba116";
  String adiUrl = "acc://custom-adi-name-1720351293054.acme";
  String publicKeyHash =
      "b48c9ba2e68ca80d6078a4c1bd0e3dda4d8d67df71f3ed02245422f2d274b372";

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
    } else {
      print('The provided public key is not eligible to sign the transaction.');
    }
  } else {
    print('No signer found for transaction ID: $txID');
  }
}
