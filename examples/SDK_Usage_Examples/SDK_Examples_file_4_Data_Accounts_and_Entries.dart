// examples\SDK_Usage_Examples\SDK_Examples_file_4_Data_Accounts_and_Entries.dart
import 'dart:async';
import 'dart:convert';
import 'package:hex/hex.dart';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
import 'SDK_Examples_file_1_lite_identities.dart';
import 'SDK_Examples_file_2_Accumulate_Identities.dart';

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

  // First lite token account
  print("First lite account URL: ${lid.acmeTokenAccount}\n");
  await addFundsToAccount(lid.acmeTokenAccount, times: 10);

  // Retrieve oracle value for credit calculation
  final oracle = await client.valueFromOracle();

  // Add 2000 credits to the first lite account
  await addCredits(lid, 2000000, oracle);

  // Create an ADI
  String adiName = "custom-adi-name-${DateTime.now().millisecondsSinceEpoch}";
  Ed25519KeypairSigner adiSigner = Ed25519KeypairSigner.generate();
  printKeypairDetails(adiSigner);
  await createAdi(
    lid,
    adiSigner,
    adiName,
  );

  // Add credits to custom-adi-name key book's key page
  String keyPageUrl =
      "acc://$adiName.acme/book/1"; // Adjust based on actual key page URL
  print("keyPageUrl Name: $keyPageUrl");
  await addCreditsToAdiKeyPage(
      lid, keyPageUrl, 7000000, oracle); // Adjust the credit amount as needed

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow addCredits transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Create an ADI Data Account
  String identityUrl = "acc://$adiName.acme";
  String dataAccountUrl = "$identityUrl/data-account";
  await createAdiDataAccount(
      adiSigner, identityUrl, keyPageUrl, dataAccountUrl);

  // Pause to allow the Create an ADI Data Account transaction to settle
  print(
      "Pausing to allow the Create an ADI Data Account transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Add Data Entries to the Data Account
  List<Uint8List> dataEntries = [
    utf8.encode("========First data entry========").asUint8List(),
    utf8.encode("========Second data entry========").asUint8List(),
  ];
  // Adjusted instantiation to directly set properties to write data to data account
  WriteDataParam writeDataParam = WriteDataParam()
    ..data = dataEntries
    ..scratch = false
    ..writeToState = true;
  await addDataToAdiDataAccount(
      client, adiSigner, keyPageUrl, dataAccountUrl, writeDataParam);

  // Use writeDataTo a lite token account to create a lite data account & add data entires
  final String dataAccountUrl2 =
      "acc://e553bacf3bc87d262eb8505a579c235c345dbae6e7bf95cd6ff597fb8ccfe128";
  List<Uint8List> dataEntries2 = [
    utf8.encode("").asUint8List(),
    utf8.encode("Testing").asUint8List(),
    utf8.encode("Lite").asUint8List(),
    utf8.encode("Data Accounts").asUint8List(),
  ];

  // NOTE - write to state is NOT ALLOWED for LDAs
  WriteDataParam writeDataParam2 = WriteDataParam();
  writeDataParam2.data = dataEntries2;

  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);

  try {
    var res =
        await client.writeData(dataAccountUrl2, writeDataParam2, txSigner);
    print("Write Data to ADI Data Account response: $res");
  } catch (error) {
    print("An error occurred while writing data: $error");
  }
}

// Create Data function & signature
Future<void> createAdiDataAccount(Ed25519KeypairSigner adiSigner,
    String identityUrl, String keyPageUrl, String dataAccountUrl) async {
  CreateDataAccountParam dataAccountParams = CreateDataAccountParam();
  dataAccountParams.url = dataAccountUrl;
  dataAccountParams.scratch =
      false; // true enables entires to be "forgotton" by network over time

  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);
  var res =
      await client.createDataAccount(identityUrl, dataAccountParams, txSigner);
  print("Create ADI Data Account response: $res");
}

// Write Data Funcitons & Signautre
Future<void> addDataToAdiDataAccount(
    ACMEClient client,
    Ed25519KeypairSigner adiSigner,
    String keyPageUrl,
    String dataAccountUrl,
    WriteDataParam writeDataParam) async {
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);

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
