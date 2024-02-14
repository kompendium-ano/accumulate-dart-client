// examples\key_management_examples_updatePage.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

Future<void> main() async {
  final String endPoint = "https://testnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  // The URL of the key page you want to update
  final String keyPageUrl = "acc://custom-adi-name-1707515657224.acme/book/1";

  // Use an existing private key for authentication
  final String existingPrivateKeyHex = "0057d014ca33cf7cfc49cbc64f4824c041427e0b562e1a3900877d16872d2f8b85ae7957e28247d8ba9714dfe83210c6cd79eb7c82ede7366e4c37f86e27714d";
  Uint8List existingPrivateKeyBytes = Uint8List.fromList(hex.decode(existingPrivateKeyHex));
  Ed25519KeypairSigner existingAdiSigner = Ed25519KeypairSigner.fromKeyRaw(existingPrivateKeyBytes);

  // Generate or specify the new public key you want to add to the key page
  Ed25519Keypair newKeypair = Ed25519Keypair.generate(); // or use a specific key
  Uint8List newPublicKey = newKeypair.publicKey;

  // Prepare the update operation
  UpdateKeyPageParam updateKeyPageParam = UpdateKeyPageParam()
    ..operations = [
      KeyOperation()
        ..type = KeyPageOperationType.Add // Define the operation type (Add, Remove, Update, etc.)
        ..key = (KeySpec()..keyHash = newPublicKey) // Specify the new key to be added
    ]
    ..memo = "Adding new key to key page";

  // Call the update key page function
  Map<String, dynamic> response = await updateAdiKeyPage(
    client,
    keyPageUrl,
    updateKeyPageParam,
    existingAdiSigner,
  );

  print("Update key page response: $response");
}

// Update a key page function
Future<Map<String, dynamic>> updateAdiKeyPage(
    ACMEClient client,
    String keyPageUrl,
    UpdateKeyPageParam updateKeyPageParam,
    Ed25519KeypairSigner signer) async {
  // Convert the Ed25519KeypairSigner to TxSigner
  TxSigner txSigner = TxSigner(AccURL.toAccURL(keyPageUrl), signer);

  // Now call the updateKeyPage method on the client
  return client.updateKeyPage(
    AccURL.toAccURL(keyPageUrl),
    updateKeyPageParam,
    txSigner,
  );
}
