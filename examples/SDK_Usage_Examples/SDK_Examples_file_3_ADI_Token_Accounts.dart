// examples\SDK_Usage_Examples\SDK_Examples_file_3_ADI_Token_Accounts.dart
import 'dart:async';
import 'package:accumulate_api/accumulate_api.dart';
import 'SDK_Examples_file_1_lite_identities.dart';
import 'SDK_Examples_file_2_Accumulate_Identities.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);
int delayBeforePrintSeconds = 45;

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
  await addFundsToAccount(lid.acmeTokenAccount, times: 20);

  // Retrieve oracle value for credit calculation
  final oracle = await client.valueFromOracle();

  // Add 2000 credits to the first lite account
  await addCredits(lid, 2000000, oracle);

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
      lid, keyPageUrl, 4000000, oracle); // Adjust the credit amount as needed

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow addCredits transaction to settle...");
  await Future.delayed(Duration(seconds: 30)); // Pause for 30 seconds

  // Create the first ADI ACME token account
  String identityUrl = "acc://$adiName.acme";
  String tokenAccountUrl1 = "$identityUrl/acme-token-account-1";
  await createAdiAcmeTokenAccount(
      adiSigner, identityUrl, keyPageUrl, tokenAccountUrl1);

  // Create the second ADI ACME token account
  String tokenAccountUrl2 = "$identityUrl/acme-token-account-2";
  await createAdiAcmeTokenAccount(
      adiSigner, identityUrl, keyPageUrl, tokenAccountUrl2);

  // Pause to allow the create token accoutns to settle
  print("Pausing to allow the create token accoutns to settle...");
  await Future.delayed(Duration(seconds: 30)); // Pause for 30 seconds

  // Sending 22 tokens from lid to tokenAccountUrl1
  await sendTokens(
    fromType: AccountType.lite,
    fromAccount: lid.acmeTokenAccount.toString(),
    toType: AccountType.adi,
    toAccount: tokenAccountUrl1,
    amount: 22,
    signer: signer1,
  );
  print("Sending 22 tokens from lid to tokenAccountUrl1");

  // Pause to allow sendTokens transaction to settlee
  print("Pausing to allow sendTokens transaction to settle...");
  await Future.delayed(Duration(seconds: 20)); // Pause for 2 minutes

  // Sending 9 from tokenAccountUrl1 to tokenAccountUrl2
  await sendTokens(
    fromType: AccountType.adi,
    fromAccount: tokenAccountUrl1, // ADI Token Account
    toType: AccountType.lite,
    toAccount: secondLid.acmeTokenAccount.toString(),
    amount: 9,
    signer: adiSigner,
    keyPageUrl: "acc://$adiName.acme/book/1", // Key page URL
  );
  print("Sending 9 from tokenAccountUrl1 to tokenAccountUrl2");

  // Sending 5 tokens from tokenAccountUrl1 to lid
  await sendTokens(
    fromType: AccountType.adi,
    fromAccount: tokenAccountUrl1, // Source ADI Token Account
    toType: AccountType.adi,
    toAccount: tokenAccountUrl2, // Destination ADI Token Account
    amount: 5,
    signer: adiSigner,
    keyPageUrl: "acc://$adiName.acme/book/1", // Key page URL for source account
  );
  print("Sending 5 tokens from tokenAccountUrl1 to lid");
}

// Function to create an ACME token account under the ADI
Future<void> createAdiAcmeTokenAccount(Ed25519KeypairSigner adiSigner,
    String identityUrl, String keyPageUrl, String tokenAccountUrl) async {
  // Prepare the parameters for creating a token account
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url =
      tokenAccountUrl; // Use the specific token account URL
  createTokenAccountParam.tokenUrl = "acc://ACME";

  print("Creating ADI ACME token account at: $tokenAccountUrl");

  // And use the TxSigner initialized with the key from the key page
  TxSigner txSigner =
      TxSigner(keyPageUrl, adiSigner); // Use the signer with authority

  // Execute the transaction
  var res = await client.createTokenAccount(
      identityUrl, createTokenAccountParam, txSigner);

  print("Create ADI ACME token account response: $res");
}
