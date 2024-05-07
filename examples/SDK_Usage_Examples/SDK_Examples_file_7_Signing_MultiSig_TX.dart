// examples\SDK_Usage_Examples\SDK_Examples_file_7_Signing_MultiSig_TX.dart
import 'dart:async';
import 'dart:convert';
import 'package:hex/hex.dart';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
import 'SDK_Examples_file_1_lite_identities.dart';
import 'SDK_Examples_file_2_Accumulate_Identities_(ADI).dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);
int delayBeforePrintSeconds = 180;

Future<void> main() async {
  print(endPoint);
  await testFeatures();
}

Future<void> delayBeforePrint() async {
  await Future.delayed(Duration(seconds: delayBeforePrintSeconds));
}

Future<void> testFeatures() async {
  Ed25519KeypairSigner signer1 = Ed25519KeypairSigner.generate();
  LiteIdentity lid = LiteIdentity(signer1);
  printKeypairDetails(signer1);

  Ed25519KeypairSigner signer2 = Ed25519KeypairSigner.generate();
  LiteIdentity secondLid = LiteIdentity(signer2);
  printKeypairDetails(signer2);

  // First lite token account
  print("First lite account URL: ${lid.acmeTokenAccount}\n");
  await addFundsToAccount(lid.acmeTokenAccount, times: 4);

  // Pause to allow the faucet txs to settle for lid
  print("Pausing to allow faucet tx to settle for lid...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Second lite token account
  print("Second lite account URL: ${secondLid.acmeTokenAccount}\n");
  await addFundsToAccount(secondLid.acmeTokenAccount, times: 4);

  // Pause to allow the faucet txs to settle for secondLid
  print("Pausing to allow faucet tx to settle for secondLid...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Retrieve oracle value for credit calculation
  final oracle = await client.valueFromOracle();

  // Add 2000 credits to the first lite account
  await addCredits(lid, 200000, oracle);

  // Add 2000 credits to the first lite account
  await addCredits(secondLid, 100000, oracle);

  // Pause to allow the add credits txs to settle
  print("Pausing to allow add credits txs to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Create first ADI
  String adiName1 = "custom-adi-name1-${DateTime.now().millisecondsSinceEpoch}";
  Ed25519KeypairSigner adiSigner1 = Ed25519KeypairSigner.generate();
  printKeypairDetails(adiSigner1);
  await createAdi(
    lid,
    adiSigner1,
    adiName1,
  );

  // Add credits to adiName1 key book's key page
  String keyPageUrl1 =
      "acc://$adiName1.acme/book/1"; // Adjust based on actual key page URL
  print("keyPageUrl Name: $keyPageUrl1");
  await addCreditsToAdiKeyPage(
      lid, keyPageUrl1, 200000, oracle); // Adjust the credit amount as needed

  // Create second ADI
  String adiName2 = "custom-adi-name2-${DateTime.now().millisecondsSinceEpoch}";
  Ed25519KeypairSigner adiSigner2 = Ed25519KeypairSigner.generate();
  printKeypairDetails(adiSigner2);
  await createAdi(
    secondLid,
    adiSigner2,
    adiName2,
  );

  // Add credits to adiName2 key book's key page
  String keyPageUrl2 =
      "acc://$adiName2.acme/book/1"; // Adjust based on actual key page URL
  print("keyPageUrl Name: $keyPageUrl2");
  await addCreditsToAdiKeyPage(secondLid, keyPageUrl2, 10000,
      oracle); // Adjust the credit amount as needed

  // Pause to allow the addCredits transactions to settle for adiName1 & adiName2
  print("Pausing to allow addCredits transactions to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Create an adiName1 Data Account
  String identityUrl1 = "acc://$adiName1.acme";
  String dataAccountUrl1 = "$identityUrl1/data-account";
  await createAdiDataAccount(
      adiSigner1, identityUrl1, keyPageUrl1, dataAccountUrl1);

  // Pause to allow the Create an ADI Data Account transaction to settle
  print(
      "Pausing to allow the Create an ADI Data Account transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Adding keyBook of adiName2 to keyPage of adiName1
  final String UpdatekeyPageUrl = keyPageUrl1;
  final String keyBookUrl2 = "acc://$adiName2.acme/book";
  // Generate or specify the new public key you want to add to the key page
  String newPublicKey = keyBookUrl2;

  // Prepare the update operation
  UpdateKeyPageParam updateKeyPageParam = UpdateKeyPageParam()
    ..operations = [
      KeyOperation()
        ..type = KeyPageOperationType.Add
        ..key = (KeySpec()..delegate = newPublicKey)
    ];

  // Call the update key page function
  Map<String, dynamic> response = await updateAdiKeyPage(
    client,
    UpdatekeyPageUrl,
    updateKeyPageParam,
    adiSigner1,
  );
  print("Update key page response: $response");

  // Add Data Entries to the Data Account
  List<Uint8List> dataEntries = [
    utf8.encode("========First test entry========").asUint8List(),
    utf8.encode("========Second test entry========").asUint8List(),
  ];
  // Adjusted instantiation to directly set properties to write data to data account
  WriteDataParam writeDataParam = WriteDataParam()
    ..data = dataEntries
    ..scratch = false
    ..writeToState = true;
  await addDataToAdiDataAccount(
      client, adiSigner1, keyPageUrl1, dataAccountUrl1, writeDataParam);
}

// Create Data function & signature
Future<void> createAdiDataAccount(Ed25519KeypairSigner adiSigner1,
    String identityUrl, String keyPageUrl, String dataAccountUrl) async {
  CreateDataAccountParam dataAccountParams = CreateDataAccountParam();
  dataAccountParams.url = dataAccountUrl;
  dataAccountParams.scratch =
      false; // true enables entires to be "forgotton" by network over time

  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner1);
  var res =
      await client.createDataAccount(identityUrl, dataAccountParams, txSigner);
  print("Create ADI Data Account response: $res");
}

// Write Data Funcitons & Signautre
Future<void> addDataToAdiDataAccount(
    ACMEClient client,
    Ed25519KeypairSigner adiSigner1,
    String keyPageUrl,
    String dataAccountUrl,
    WriteDataParam writeDataParam) async {
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner1);

  var r = await client.queryUrl(txSigner.url); // check for key page version
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  try {
    var res = await client.writeData(dataAccountUrl, writeDataParam, txSigner);
    print("Write Data to ADI Data Account response: $res");
  } catch (error) {
    print("An error occurred while writing data: $error");
  }
}

void printKeypairDetails(Ed25519KeypairSigner signer) {
  String publicKeyHex = HEX.encode(signer.publicKey());
  String privateKeyHex = HEX.encode(signer.secretKey());
  String mnemonic = signer.mnemonic();

  print("Public Key: $publicKeyHex");
  print("Private Key: $privateKeyHex");
  print("Mnemonic: $mnemonic\n");
}

// Update a key page function
Future<Map<String, dynamic>> updateAdiKeyPage(
    ACMEClient client,
    String keyPageUrl,
    UpdateKeyPageParam updateKeyPageParam,
    Ed25519KeypairSigner signer) async {
  // Convert the Ed25519KeypairSigner to TxSigner
  TxSigner txSigner = TxSigner(AccURL.toAccURL(keyPageUrl), signer);
  var r = await client.queryUrl(txSigner.url); // check for key page version
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  // Now call the updateKeyPage method on the client
  return client.updateKeyPage(
    AccURL.toAccURL(keyPageUrl),
    updateKeyPageParam,
    txSigner,
  );
}
