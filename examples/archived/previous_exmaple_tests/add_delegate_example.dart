import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

// Helper function to convert a hex string to Uint8List
Uint8List hexToBytes(String hexString) {
  return Uint8List.fromList(hex.decode(hexString));
}

// Initialize a signer with the proper key handling
TxSigner initSigner(String privateKeyHex, String keyPageUrl) {
  Uint8List privateKeyBytes = hexToBytes(privateKeyHex);
  Ed25519KeypairSigner edSigner =
      Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);

  // Use the keyPageUrl as the URL for the TxSigner
  return TxSigner(
      keyPageUrl, edSigner); // Ensure the TxSigner can accept these parameters
}

void main() async {
  final client = ACMEClient("https://testnet.accumulatenetwork.io/v2");
  final keyPageUrl = "acc://custom-adi-name-1720351293054.acme/book/1";
  final delegateKeyBook = "acc://testtest1123.acme/book";
  final privateKeyHex =
      "b3b2b01471277fd30160a8d239b36c2e3741aca29a6177da3907b93b996e0fbaed06a050ca69313abb80feabf4e7c4b8e789d9a4f7fbe59826f2211c5ad3c747";

  TxSigner signer = initSigner(privateKeyHex, keyPageUrl);

  // Update the signer version
  var response = await client.queryUrl(signer.url);
  signer =
      TxSigner.withNewVersion(signer, response["result"]["data"]["version"]);

  // Create an operation to add a delegate
  final operation = KeyOperation()
    ..type = KeyPageOperationType.Add
    ..key = (KeySpec()..delegate = delegateKeyBook);

  final updateParams = UpdateKeyPageParam()
    ..operations = [operation]
    ..memo = "Adding delegate to key page";

  try {
    var result = await client.updateKeyPage(keyPageUrl, updateParams, signer);
    print("Transaction result: ${result.toString()}");
  } catch (e) {
    print("Error: $e");
  }
}
