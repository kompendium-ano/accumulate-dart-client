import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';
// Import the lite and ADI identity helpers
import '../SDK_Usage_Examples/SDK_Examples_file_1_lite_identities.dart';
import '../SDK_Usage_Examples/SDK_Examples_file_2_Accumulate_Identities.dart';
// Import the update account auth payload (for updating authority)
import 'package:accumulate_api/src/payload/update_account_auth.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);
// Adjust if needed; used for optional pauses between transactions
int delayBeforePrintSeconds = 40;

Future<void> main() async {
  print("Using endpoint: $endPoint");
  await testFeatures();
}

Future<void> delayBeforePrint() async {
  await Future.delayed(Duration(seconds: delayBeforePrintSeconds));
}

Future<void> testFeatures() async {
  // ---------------------------
  // 1. Create a Lite Account
  // ---------------------------
  Ed25519KeypairSigner liteSigner = Ed25519KeypairSigner.generate();
  LiteIdentity liteId = LiteIdentity(liteSigner);
  printKeypairDetails(liteSigner);
  print("Lite Account URL: ${liteId.acmeTokenAccount}\n");

  // Fund lite account (assumes addFundsToAccount is defined in your SDK)
  await addFundsToAccount(liteId.acmeTokenAccount, times: 10);

  // ---------------------------
  // 2. Add Credits to Lite Account
  // ---------------------------
  final oracle = await client.valueFromOracle();
  await addCredits(liteId, 2000000, oracle);

  // ---------------------------
  // 3. Create an ADI
  // ---------------------------
  String adiName = "custom-adi-name-${DateTime.now().millisecondsSinceEpoch}";
  Ed25519KeypairSigner adiSigner = Ed25519KeypairSigner.generate();
  printKeypairDetails(adiSigner);
  await createAdi(liteId, adiSigner, adiName);

  // ---------------------------
  // 4. Buy Credits for the ADI Key Page
  // ---------------------------
  String keyPageUrl = "acc://$adiName.acme/book/1"; // Adjust as needed
  print("ADI Key Page URL: $keyPageUrl");
  await addCreditsToAdiKeyPage(liteId, keyPageUrl, 5000000, oracle);
  print("Pausing to allow addCredits transaction to settle...");
  await Future.delayed(Duration(seconds: 20));

  // ---------------------------
  // 5. Create ADI Data Account
  // ---------------------------
  String identityUrl = "acc://$adiName.acme";
  String dataAccountUrl = "$identityUrl/data-account";
  await createAdiDataAccount(adiSigner, identityUrl, keyPageUrl, dataAccountUrl);
  print("Pausing to allow the ADI Data Account creation to settle...");
  await Future.delayed(Duration(seconds: 20));

  // ---------------------------
  // 6. Write the First Data Entry
  // ---------------------------
  List<Uint8List> firstDataEntries = [
    utf8.encode("========First data entry before updating authority========").asUint8List(),
  ];
  WriteDataParam firstWriteParam = WriteDataParam()
    ..data = firstDataEntries
    ..scratch = false
    ..writeToState = true;
  await addDataToAdiDataAccount(client, adiSigner, keyPageUrl, dataAccountUrl, firstWriteParam);

  // ---------------------------
  // 7. Update Authority: Add then Disable keybook authority
  // ---------------------------
  await updateDataAccountAuthority(adiSigner, keyPageUrl, dataAccountUrl);
  print("Pausing to allow the update authority transaction to settle...");
  await Future.delayed(Duration(seconds: 20));

  // ---------------------------
  // 8. Write the Second Data Entry After Authority is Updated
  // ---------------------------
  List<Uint8List> secondDataEntries = [
    utf8.encode("========Second data entry after updating authority========").asUint8List(),
  ];
  WriteDataParam secondWriteParam = WriteDataParam()
    ..data = secondDataEntries
    ..scratch = false
    ..writeToState = true;
  await addDataToAdiDataAccount(client, adiSigner, keyPageUrl, dataAccountUrl, secondWriteParam);
}

/// Creates an ADI Data Account under the given identity.
Future<void> createAdiDataAccount(Ed25519KeypairSigner adiSigner,
    String identityUrl, String keyPageUrl, String dataAccountUrl) async {
  CreateDataAccountParam dataAccountParams = CreateDataAccountParam();
  dataAccountParams.url = dataAccountUrl;
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);
  var res = await client.createDataAccount(identityUrl, dataAccountParams, txSigner);
  print("Create ADI Data Account response: $res");
}

/// Writes data entries to an ADI Data Account.
Future<void> addDataToAdiDataAccount(
    ACMEClient client,
    Ed25519KeypairSigner adiSigner,
    String keyPageUrl,
    String dataAccountUrl,
    WriteDataParam writeDataParam) async {
  // Build a transaction signer using the key page URL and ADI signer.
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);
  // Retrieve the current key page version to use in the transaction.
  var r = await client.queryUrl(txSigner.url);
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);
  try {
    var res = await client.writeData(dataAccountUrl, writeDataParam, txSigner);
    print("Write Data to ADI Data Account response: $res");
  } catch (error) {
    print("An error occurred while writing data: $error");
  }
}

/// Updates the authority on the data account by first adding the keybook authority,
/// then disabling it—in a single transaction.
Future<void> updateDataAccountAuthority(
    Ed25519KeypairSigner adiSigner, String keyPageUrl, String dataAccountUrl) async {
  // Derive the ADI URL from the data account URL.
  // If dataAccountUrl is "acc://<adiName>.acme/data-account", then:
  final String adiUrl = dataAccountUrl.split("/data-account").first;
  // Define the authority value as the keybook (literal string).
  final String authority = "$adiUrl/book";

  // Build the update operations:
  // 1. Add the authority.
  UpdateAccountAuthOperation addOperation = UpdateAccountAuthOperation();
  addOperation.type = UpdateAccountAuthActionType.AddAuthority;
  addOperation.authority = authority;

  // 2. Disable the authority.
  UpdateAccountAuthOperation disableOperation = UpdateAccountAuthOperation();
  disableOperation.type = UpdateAccountAuthActionType.Disable;
  disableOperation.authority = authority;

  // Prepare the update parameters with both operations.
  UpdateAccountAuthParam updateAuthParam = UpdateAccountAuthParam();
  updateAuthParam.operations = [addOperation, disableOperation];
  updateAuthParam.memo = "Add and then disable authority for data account";

  // Build a transaction signer using the key page URL.
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

/// Utility function to print keypair details.
void printKeypairDetails(Ed25519KeypairSigner signer) {
  String publicKeyHex = hex.encode(signer.publicKey());
  String privateKeyHex = hex.encode(signer.secretKey());
  String mnemonic = signer.mnemonic();
  print("Public Key: $publicKeyHex");
  print("Private Key: $privateKeyHex");
  print("Mnemonic: $mnemonic\n");
}
