// examples\SDK_Usage_Examples\SDK_Examples_file_2_Accumulate_Identities_(ADI).dart
import 'dart:async';
import 'dart:math';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';
import 'SDK_Examples_file_1_lite_identities.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);
int delayBeforePrintSeconds = 30;

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
  await addFundsToAccount(lid.acmeTokenAccount, times: 15);

  // Retrieve oracle value for credit calculation
  final oracle = await client.valueFromOracle();

  // Add 2000 credits to the first lite account
  await addCredits(lid, 20000000, oracle);

  // Create an ADI
  String adiName = "custom-adi-name-${DateTime.now().millisecondsSinceEpoch}";
  Ed25519KeypairSigner adiSigner = Ed25519KeypairSigner.generate();
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
      lid, keyPageUrl, 40000000, oracle); // Adjust the credit amount as needed

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow addCredits transaction to settle...");
  await Future.delayed(Duration(seconds: 20)); // Pause for 40 seconds
}

// Create an Accumulate ADI Identity
Future<void> createAdi(
    LiteIdentity lid, Ed25519KeypairSigner adiSigner, String adiName) async {
  // Correct formation of the ADI URL
  final String identityUrl = "acc://$adiName.acme";
  final String bookUrl = "$identityUrl/book";

  CreateIdentityParam createIdentityParam = CreateIdentityParam();
  createIdentityParam.url = identityUrl;
  createIdentityParam.keyBookUrl = bookUrl;
  createIdentityParam.keyHash = adiSigner.publicKeyHash();

  print("Preparing to create identity:");
  print("ADI URL: $identityUrl");
  print("Key Book URL: $bookUrl");
  print("Key Hash: ${hex.encode(adiSigner.publicKeyHash())}");
  printKeypairDetails(adiSigner);

  try {
    var response =
        await client.createIdentity(lid.url, createIdentityParam, lid);
    var txId = response["result"]["txid"];
    print("Create identity transaction submitted, response: $response");
    print("Transaction ID: $txId");

    await delayBeforePrint(); // Allow time for Create Identity to finish
    var txStatus = await client.queryTx(txId);
    print("Transaction status: $txStatus");
  } catch (e) {
    print("Error creating ADI: $e");
  }
}

// Function to add credits to a key page of the ADI
Future<void> addCreditsToAdiKeyPage(
    LiteIdentity lid, String keyPageUrl, int creditAmount, int oracle) async {
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8).toInt()) ~/ oracle;
  addCreditsParam.oracle = oracle;
  print(
      "Adding credits to ADI key page: $keyPageUrl with amount: ${addCreditsParam.amount}");

  var res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("Add credits to ADI key page response: $res");
}
