// C:\Accumulate_Stuff\accumulate-dart-client\examples\archived\previous_exmaple_tests\remove_key_example.dart

import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

Future<void> main() async {
  final String endPoint = "https://mainnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  // The URL of the key page you want to update
  final String keyPageUrl = "acc://beastmode.acme/book/1";

  // Use an existing private key for authentication (Replace this with the actual private key in hex format)
  final String existingPrivateKeyHex = "74b975f6ae309f2adb4ac5e10bd1729ea589570e23896ca58f36940f19dbe1d54c0c3fef9fc2629c1d3dd3d78acf0aab4ae9f87fd4d3a875a48090c27ccc2c0f"; 
  Uint8List existingPrivateKeyBytes = Uint8List.fromList(hex.decode(existingPrivateKeyHex));

  Ed25519KeypairSigner existingAdiSigner = Ed25519KeypairSigner.fromKeyRaw(existingPrivateKeyBytes);

  // Specify the public key you want to remove (Ensure this is correct)
  final String removeKeyHex = "d746c1a41c1cffe19cc644a3325b8c252a5ec10a2b4195d9fe7d5932ff006eba";
  Uint8List removeKeyBytes = Uint8List.fromList(hex.decode(removeKeyHex));

  // Prepare the key removal operation
  UpdateKeyPageParam updateKeyPageParam = UpdateKeyPageParam()
    ..operations = [
      KeyOperation()
        ..type = KeyPageOperationType.Remove // Set operation type to "Remove"
        ..key = (KeySpec()
          ..keyHash = removeKeyBytes) // Specify the key to be removed
    ]
    ..memo = "Removing key from key page";

  // Initialize the signer
  TxSigner signer = initSigner(existingPrivateKeyHex, keyPageUrl);

  // Query the latest signer version from the blockchain
  var response = await client.queryUrl(signer.url);
  if (response["result"] == null || response["result"]["data"] == null) {
    print("Error: Failed to retrieve signer version.");
    return;
  }
  signer = TxSigner.withNewVersion(signer, response["result"]["data"]["version"]);

  // Call the update key page function with the updated signer
  Map<String, dynamic> txnResponse = await updateAdiKeyPage(
    client,
    keyPageUrl,
    updateKeyPageParam,
    signer,
  );

  print("Update key page response: $txnResponse");
}

// Initialize a TxSigner
TxSigner initSigner(String privateKeyHex, String keyPageUrl) {
  Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
  Ed25519KeypairSigner signer = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
  return TxSigner(AccURL.toAccURL(keyPageUrl), signer);
}

// Update a key page function
Future<Map<String, dynamic>> updateAdiKeyPage(
    ACMEClient client,
    String keyPageUrl,
    UpdateKeyPageParam updateKeyPageParam,
    TxSigner signer) async {
  
  // Now call the updateKeyPage method on the client
  return client.updateKeyPage(
    AccURL.toAccURL(keyPageUrl),
    updateKeyPageParam,
    signer,
  );
}
