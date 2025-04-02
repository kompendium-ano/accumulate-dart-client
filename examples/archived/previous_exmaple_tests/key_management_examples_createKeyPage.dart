// examples\key_management_examples_createKeyPage.dart

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

Future<void> main() async {
  final String endPoint = "https://testnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  // Existing key for authentication
  final String existingPrivateKeyHex =
      "0057d014ca33cf7cfc49cbc64f4824c041427e0b562e1a3900877d16872d2f8b85ae7957e28247d8ba9714dfe83210c6cd79eb7c82ede7366e4c37f86e27714d";
  Uint8List existingPrivateKeyBytes =
      Uint8List.fromList(hex.decode(existingPrivateKeyHex));
  Ed25519KeypairSigner existingAdiSigner =
      Ed25519KeypairSigner.fromKeyRaw(existingPrivateKeyBytes);

  // Generate a new keypair for the new key page
  Ed25519Keypair newKeypair = Ed25519Keypair.generate();

  final String keyBookUrl = "acc://custom-adi-name-1707515657224.acme/book";

  // Query the existing key pages to determine the next page number
  int nextPageNumber = await getNextKeyPageNumber(client, keyBookUrl);

  // Use the public key from the newly generated keypair for the new key page
  List<Uint8List> newKeys = [newKeypair.publicKey];

  // Create the new key page with the newly generated key, using the existing key for authentication
  await createAdiKeyPage(
      client, existingAdiSigner, keyBookUrl, newKeys, nextPageNumber);
}

Future<int> getNextKeyPageNumber(ACMEClient client, String keyBookUrl) async {
  QueryPagination qp = QueryPagination()
    ..start = 0
    ..count = 100;
  var response = await client.queryDirectory(keyBookUrl, qp, null);

  // Adjusting the path to match the actual response structure
  var items =
      response['result']['items'] as List<dynamic>; // This line is changed

  if (items.isEmpty) {
    // If there are no items, implying no key pages exist yet
    return 1; // Return 1 to indicate the first key page should be created
  }

  // Assuming that items contain URLs of the form "acc://.../book/1"
  int highestPageNumber = items.fold<int>(0, (prev, curr) {
    var pageUrl = curr as String;
    var pageNumber = int.tryParse(pageUrl.split('/').last) ?? 0;
    return max(prev, pageNumber);
  });

  return highestPageNumber + 1; // Increment to get the next page number
}

Future<void> createAdiKeyPage(
    ACMEClient client,
    Ed25519KeypairSigner existingAdiSigner,
    String keyBookUrl,
    List<Uint8List> keys,
    int nextPageNumber) async {
  String newKeyPageUrl = "$keyBookUrl/$nextPageNumber";
  final String keyPageUrl = "acc://custom-adi-name-1707515657224.acme/book/1";
  TxSigner txSigner = TxSigner(keyPageUrl, existingAdiSigner);

  var r = await client.queryUrl(txSigner.url);
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  CreateKeyPageParam createKeyPageParam = CreateKeyPageParam()
    ..url = newKeyPageUrl
    ..keys = keys;

  print("Creating key page at: $newKeyPageUrl");

  var res = await client.createKeyPage(keyBookUrl, createKeyPageParam,
      txSigner); // Sign transaction with existing page+key
  print("Create key page transaction response: $res");
}
