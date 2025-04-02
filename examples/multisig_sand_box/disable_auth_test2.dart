import 'dart:async';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:accumulate_api/src/payload/update_account_auth.dart';

final String endPoint = "https://testnet.accumulatenetwork.io/v2";
final ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  print("Using endpoint: $endPoint");
  await updateAuthorityTest();
}

Future<void> updateAuthorityTest() async {
  // Hard-coded identity and account information.
  final String adiUrl = "acc://custom-adi-name-1743237544219.acme";
  final String dataAccountUrl = "$adiUrl/data-account";
  // Key page URL (usually ends with /book/1)
  final String keyPageUrl = "$adiUrl/book/1";
  // The authority value we will both add and disable:
  final String authority = "$adiUrl/book";

  // Hard-coded keys (replace with your actual key values)
  final String publicKeyHex =
      "a3e471c659db395989ac22b30092f71e100099d081b282125399b3a236106847";
  final String privateKeyHex =
      "28e9b05b46fbabbcc51dc10e4b4f03a3087104cba05ec9e2318b24d56f11c7caa3e471c659db395989ac22b30092f71e100099d081b282125399b3a236106847";

  // Create the signer using the hard-coded secret key.
  Ed25519KeypairSigner adiSigner = Ed25519KeypairSigner.fromKey(privateKeyHex);

  print("Using the following keys:");
  print("Public Key: $publicKeyHex");
  print("Private Key: $privateKeyHex");

  // Print the public key hash (for reference).
  final publicKeyHash = adiSigner.publicKeyHash();
  print("Public Key Hash: ${hex.encode(publicKeyHash)}");

  // Create two update operations:
  // 1. AddAuthority operation.
  UpdateAccountAuthOperation addOperation = UpdateAccountAuthOperation();
  addOperation.type = UpdateAccountAuthActionType.AddAuthority;
  addOperation.authority = authority;

  // 2. Disable operation.
  UpdateAccountAuthOperation disableOperation = UpdateAccountAuthOperation();
  disableOperation.type = UpdateAccountAuthActionType.Disable;
  disableOperation.authority = authority;

  // Prepare the update parameters with both operations.
  UpdateAccountAuthParam updateAuthParam = UpdateAccountAuthParam();
  updateAuthParam.operations = [addOperation, disableOperation];
  updateAuthParam.memo = "Add and then disable authority for data account";

  // Create a transaction signer using the key page URL.
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);

  // Query the key page to get the current version and update the TxSigner.
  var keyPageInfo = await client.queryUrl(keyPageUrl);
  int currentVersion = keyPageInfo["result"]["data"]["version"];
  print("Current key page version: $currentVersion");
  txSigner = TxSigner.withNewVersion(txSigner, currentVersion);

  try {
    var res = await client.updateAccountAuth(dataAccountUrl, updateAuthParam, txSigner);
    print("Update Authority response: $res");
  } catch (error) {
    print("An error occurred while updating authority: $error");
  }
}
