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
  return TxSigner(keyPageUrl, edSigner); // Ensure the TxSigner can accept these parameters
}

void main() async {
  final client = ACMEClient("https://testnet.accumulatenetwork.io/v2");
  final keyPageUrl = "acc://custom-adi-name-1720349551259.acme/book/1";
  final privateKeyHex =
      "1e67465a1fde2290b04d1575b68b9f0256f6475fed33411b23107f984544701cbbecf13ec50ccfcf9d86896ce8ab0260434e7a11b9c9e605bf02d68de16f70da";

  // Initialize the signer
  TxSigner signer = initSigner(privateKeyHex, keyPageUrl);

  // Update signer version
  var response = await client.queryUrl(signer.url);
  signer = TxSigner.withNewVersion(signer, response["result"]["data"]["version"]);

  // Create an operation to update the threshold
  final operation = KeyOperation()
    ..type = KeyPageOperationType.SetThreshold
    ..threshold = 2;

  final updateParams = UpdateKeyPageParam()
    ..operations = [operation]
    ..memo = "Updating key page threshold from 1 to 2";

  try {
    var result = await client.updateKeyPage(keyPageUrl, updateParams, signer);
    print("Transaction result: ${result.toString()}");
  } catch (e) {
    print("Error: $e");
  }
}
