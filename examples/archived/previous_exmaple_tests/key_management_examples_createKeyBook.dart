// examples\key_management_examples_createKeyBook.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:crypto/crypto.dart';

Future<void> main() async {
  final String endPoint = "https://testnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  // Existing key for authentication
  final String existingPrivateKeyHex = "0057d014ca33cf7cfc49cbc64f4824c041427e0b562e1a3900877d16872d2f8b85ae7957e28247d8ba9714dfe83210c6cd79eb7c82ede7366e4c37f86e27714d";
  Uint8List existingPrivateKeyBytes = Uint8List.fromList(hex.decode(existingPrivateKeyHex));
  Ed25519KeypairSigner existingAdiSigner = Ed25519KeypairSigner.fromKeyRaw(existingPrivateKeyBytes);

  // Generate a new keypair for the new key page
  Ed25519Keypair newKeypair = Ed25519Keypair.generate();

  // Correct calculation of publicKeyHash with explicit conversion to Uint8List
  Uint8List publicKeyHash = sha256.convert(newKeypair.publicKey).bytes.asUint8List();


  final String keyBookUrl = "acc://custom-adi-name-1707515657224.acme/book";

  // Query the existing key pages to determine the next page number
  int nextPageNumber = 1;
  
  // Use the public key from the newly generated keypair for the new key page
  List<Uint8List> newKeys = [newKeypair.publicKey];

  // Create the new key page with the newly generated key, using the existing key for authentication
  await createAdiKeyPage(client, existingAdiSigner, keyBookUrl, newKeys, nextPageNumber);

  // Create the Key Book
  final String principalUrl = "acc://custom-adi-name-1707515657224.acme";
  final String newKeyBookUrl = "acc://custom-adi-name-1707515657224.acme/book2"; // Assuming this is the correct variable name

  CreateKeyBookParam createKeyBookParam = CreateKeyBookParam()
    ..url = newKeyBookUrl
    ..publicKeyHash = publicKeyHash; // Ensure this is defined earlier

  await createKeyBook(client, principalUrl, createKeyBookParam, existingAdiSigner);
}


Future<void> createKeyBook(ACMEClient client, String principalUrl, CreateKeyBookParam createKeyBookParam, Ed25519KeypairSigner existingAdiSigner) async {
  print("Creating key book at: ${createKeyBookParam.url}");

  final String keyPageUrl = "acc://custom-adi-name-1707515657224.acme/book/1";
  TxSigner txSigner = TxSigner(keyPageUrl, existingAdiSigner);
  var r = await client.queryUrl(txSigner.url);
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  var response = await client.createKeyBook(principalUrl, createKeyBookParam, txSigner);
  print("Create key book response: $response");
}


Future<void> createAdiKeyPage(ACMEClient client, Ed25519KeypairSigner existingAdiSigner, String keyBookUrl, List<Uint8List> keys, int nextPageNumber) async {
  String newKeyPageUrl = "$keyBookUrl/$nextPageNumber";
  final String keyPageUrl = "acc://custom-adi-name-1707515657224.acme/book/1";
  TxSigner txSigner = TxSigner(keyPageUrl, existingAdiSigner);

  var r = await client.queryUrl(txSigner.url);
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  CreateKeyPageParam createKeyPageParam = CreateKeyPageParam()
    ..url = newKeyPageUrl
    ..keys = keys;

  print("Creating key page at: $newKeyPageUrl");

  var res = await client.createKeyPage(keyBookUrl, createKeyPageParam, txSigner); // Sign transaction with existing page+key
  print("Create key page transaction response: $res");
}

