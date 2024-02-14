// examples\SDK_Usage_Examples\SDK_Examples_file_5_Custom_Tokens.dart
import 'dart:async';
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

  // First lite token account
  print("First lite account URL: ${lid.acmeTokenAccount}\n");
  await addFundsToAccount(lid.acmeTokenAccount, times: 20);

  // Retrieve oracle value for credit calculation
  final oracle = await client.valueFromOracle();

  // Add 2000 credits to the first lite account
  await addCredits(lid, 2000000, oracle);

  // Create an ADI
  String adiName = "custom-adi-name-${DateTime.now().millisecondsSinceEpoch}";
  Ed25519KeypairSigner adiSigner = Ed25519KeypairSigner.generate();
  await createAdi(lid, adiSigner, adiName, );

  // Add credits to custom-adi-name key book's key page
  String keyPageUrl = "acc://$adiName.acme/book/1"; // Adjust based on actual key page URL
  print("keyPageUrl Name: $keyPageUrl");
  await addCreditsToAdiKeyPage(lid, keyPageUrl, 7000000, oracle); // Adjust the credit amount as needed

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow addCredits transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Creating an ADI Custom Token
  String identityUrl = "acc://$adiName.acme";
  String customTokenUrl = "$identityUrl/my-custom-token";
  await createCustomToken(adiSigner, identityUrl, keyPageUrl, customTokenUrl, "MYTKN", 2);

  // Create two custom token acounts for MYTKN
  await createCustomTokenAccount(adiSigner, identityUrl, keyPageUrl, customTokenUrl, "myCustomTokenAccount1");
  await createCustomTokenAccount(adiSigner, identityUrl, keyPageUrl, customTokenUrl, "myCustomTokenAccount2");

 // Pause to allow creation of custom token acounts for MYTKN transaction to settle
  print("Pausing to allow creation of custom token acounts for MYTKN transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Issue custom token (MYTKN) to a MYTKN custom token account
  await issueCustomTokens(adiSigner, keyPageUrl, customTokenUrl, "$identityUrl/myCustomTokenAccount1", 100000);

  // Send custom token (MYTKN) from a custom token account to second custom token account
  String fromCustomTokenAccountUrl = "$identityUrl/myCustomTokenAccount1";
  String toCustomTokenAccountUrl = "$identityUrl/myCustomTokenAccount2";
  int amountToSend = 6000; // the amount is base 100, so the amount you put is ##/100
  // Assumes `adiSigner` is your Ed25519KeypairSigner and `keyPageUrl` is the URL of the key page used for signing transactions
  await sendCustomTokens(
    fromAccount: fromCustomTokenAccountUrl,
    toAccount: toCustomTokenAccountUrl,
    amount: amountToSend,
    signer: adiSigner,
    tokenUrl: customTokenUrl,
    keyPageUrl: "$identityUrl/book/1", // Adjust based on your ADI's key book structure
  );
  print("Sent $amountToSend MYTKN from $fromCustomTokenAccountUrl to $toCustomTokenAccountUrl");
}

Future<void> createCustomToken(Ed25519KeypairSigner adiSigner, String identityUrl, String keyPageUrl, String tokenUrl, String symbol, int precision) async {
  CreateTokenParam createTokenParam = CreateTokenParam();
  createTokenParam.url = tokenUrl;
  createTokenParam.symbol = symbol;
  createTokenParam.precision = precision;
  // Optional: Set properties, supply limit, authorities, memo, and metadata as needed
  // createTokenParam.properties = ...;
  // createTokenParam.supplyLimit = ...;
  // createTokenParam.authorities = ...;
  // createTokenParam.memo = "Custom Token Creation";
  // createTokenParam.metadata = ...;

  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);
  
  print("Creating custom token: $symbol at $tokenUrl");
  var res = await client.createToken(identityUrl, createTokenParam, txSigner);
  var txId = res["result"]["txid"];
  print("Custom token creation submitted, Transaction ID: $txId");

  // Optionally, wait for transaction to be confirmed
  await delayBeforePrint();
  
  // Query and log the result of token creation
  // This is to check the status of the created token, similar to the given examples
}

// create a token account for a custom token
Future<void> createCustomTokenAccount(Ed25519KeypairSigner adiSigner, String identityUrl, String keyPageUrl, String tokenUrl, String accountName) async {
  String tokenAccountUrl = "$identityUrl/$accountName";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = tokenUrl; // Custom token URL

  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);

  print("Creating custom token account at: $tokenAccountUrl for token: $tokenUrl");
  var res = await client.createTokenAccount(identityUrl, createTokenAccountParam, txSigner);
  print("Custom token account creation response: $res");
}

// issue a custom token to a cusotm token account
Future<void> issueCustomTokens(Ed25519KeypairSigner adiSigner, String keyPageUrl, String tokenUrl, String recipientAccountUrl, int amount) async {
  IssueTokensParam issueTokensParam = IssueTokensParam();
  issueTokensParam.to = [
    TokenRecipientParam()
      ..url = recipientAccountUrl
      ..amount = amount
  ];

  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);

  print("Issuing $amount tokens to: $recipientAccountUrl from token: $tokenUrl");
  var res = await client.issueTokens(tokenUrl, issueTokensParam, txSigner);
  print("Token issuance response: $res");
}

// Send Custom token to a cusotm token account
Future<void> sendCustomTokens({
  required String fromAccount,
  required String toAccount,
  required int amount,
  required Ed25519KeypairSigner signer, // Signer for the transaction
  required String tokenUrl, // Token URL to specify which token to send
  required String keyPageUrl, // Required for ADI accounts
}) async {
  // Construct the parameters for sending tokens
  SendTokensParam sendTokensParam = SendTokensParam();
  sendTokensParam.to = [
    TokenRecipientParam()
      ..url = toAccount
      ..amount = amount
  ];
  sendTokensParam.memo = "Sending $amount $tokenUrl tokens";

  // Use the TxSigner initialized with the key from the ADI's key page
  TxSigner txSigner = TxSigner(keyPageUrl, signer);

  try {
    // Execute the sendTokens transaction for the custom token
    var response = await client.sendTokens(fromAccount, sendTokensParam, txSigner); // Notice the tokenUrl parameter
    print("Custom Token Send tx submitted, response: $response");
  } catch (e) {
    print("Error sending custom tokens: $e");
  }
}
