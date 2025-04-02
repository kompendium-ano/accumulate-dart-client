import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart'; // Ensure this is your actual Accumulate API package
import 'package:convert/convert.dart';

Future<void> main() async {
  print("Starting...");
  await testFeatures();
}

Future<void> testFeatures() async {
  final String endPoint = "https://testnet.accumulatenetwork.io/v2";
  ACMEClient client = ACMEClient(endPoint);

  final Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(
      "bad3ff4445a2d2f234cb83f241b018b6fb9b9bd5c494faba2a7f800a2b2395acd79c26c255607a2388b0207548c5b7a857b4faa32f9f5dc4e6fb757e73fc2577"));
  final Ed25519KeypairSigner signer =
      Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);

  LiteIdentity lid = LiteIdentity(
      signer); // Assuming LiteIdentity takes a signer in its constructor
  String LTA = "acc://668370fa7f13191dfd52ddaa57440c038a86516a02f490b7/acme";

  final TxSigner txSigner = TxSigner(
      LTA, signer); // Assuming TxSigner constructor takes these arguments

  print("Using LID: ${lid.url}");
  print("Using LTA: $LTA");

  // Add funds to the first lite token account
  await addFundsToAccount(client, LTA, times: 200);

  // Add credits using the LiteIdentity and the transaction signer
  String tokenAccountURL =
      "acc://668370fa7f13191dfd52ddaa57440c038a86516a02f490b7/acme";
  await addCredits(client, tokenAccountURL, 100000, txSigner);
}

Future<void> addFundsToAccount(ACMEClient client, String accountURL,
    {int times = 1}) async {
  for (int i = 0; i < times; i++) {
    await client.faucetSimple(accountURL);
    print("Funds added to $accountURL");
  }
}

Future<void> addCredits(ACMEClient client, String tokenAccountURL,
    int creditAmount, TxSigner txSigner) async {
  // Retrieve the current oracle value and log it
  final int oracle = await client.valueFromOracle();
  print("Oracle price: $oracle");

  // Calculate credits to add, log the calculation details
  int creditsToAdd = (creditAmount * pow(10, 8).toInt()) ~/ oracle;
  print("Credits to add: $creditsToAdd based on credit amount: $creditAmount");

  // Log the recipient (Token Account URL)
  print("Recipient (Token Account URL): $tokenAccountURL");

  // Construct AddCreditsParam with the calculated and retrieved values
  AddCreditsParam addCreditsParam = AddCreditsParam()
    ..recipient = tokenAccountURL
    ..amount = creditsToAdd
    ..oracle = oracle;

  // Log the entire AddCreditsParam object (or its important parts)
  print(
      "AddCreditsParam: Recipient = ${addCreditsParam.recipient}, Amount = ${addCreditsParam.amount}, Oracle = ${addCreditsParam.oracle}");

  // Execute the transaction and log the response
  var response =
      await client.addCredits(tokenAccountURL, addCreditsParam, txSigner);
  print("Transaction response: $response");
}

// To run: dart run accu2CreditsTokenAdd.dart
