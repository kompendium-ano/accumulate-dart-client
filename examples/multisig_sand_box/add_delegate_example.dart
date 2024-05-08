// examples\multisig_sand_box\add_delegate_example.dart

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
  final keyPageUrl = "acc://custom-adi-name1-1715157265265.acme/book/1";
  final delegateKeyBook = "acc://custom-adi-name-1714297678838.acme/book";
  final privateKeyHex =
      "1e9b7585fe686749dd22332580a918f0bf68c8b91dd17824a2689eb729bba36f1821fb65b99bebe73f401991026e3ca08d5e5c77fdb585f29a2ff42a8140f62d";

  final TxSigner signer = initSigner(privateKeyHex, keyPageUrl);

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
