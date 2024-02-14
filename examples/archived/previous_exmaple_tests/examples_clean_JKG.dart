// example\examples_clean_JKG.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:accumulate_api/accumulate_api.dart';
// Ensure this is correctly imported
import 'package:hex/hex.dart';


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
  await addFundsToAccount(lid.acmeTokenAccount, times: 20);

  // Second lite token account
  print("Second lite account URL: ${secondLid.acmeTokenAccount}\n");
  await addFundsToAccount(secondLid.acmeTokenAccount, times: 5);

  // Retrieve oracle value for credit calculation
  final oracle = await client.valueFromOracle();

  // Add 2000 credits to the first lite account
  await addCredits(lid, 2000000, oracle);

  // Add 1000 credits to the second lite account
  await addCredits(secondLid, 10000, oracle);
  



  // Sending 7 tokens from lid to secondLid
  await sendTokens(
    fromType: AccountType.lite,
    fromAccount: lid.acmeTokenAccount.toString(),
    toType: AccountType.lite,
    toAccount: secondLid.acmeTokenAccount.toString(),
    amount: 7,
    signer: signer1,
  );

  // Create an ADI
  String adiName = "custom-adi-name-${DateTime.now().millisecondsSinceEpoch}";
  Ed25519KeypairSigner adiSigner = Ed25519KeypairSigner.generate();
  // Print ADI Signer Key Details
  printKeypairDetails(adiSigner);
  print("the adiSigner: $adiSigner");
  await createAdi(lid, adiSigner, adiName, );

  // Add credits to custom-adi-name key book's key page
  String keyPageUrl = "acc://$adiName.acme/book/1"; // Adjust based on actual key page URL
  print("keyPageUrl Name: $keyPageUrl");
  await addCreditsToAdiKeyPage(lid, keyPageUrl, 7000000, oracle); // Adjust the credit amount as needed

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow addCredits transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Create a Key Book for the ADI
  String keyBookUrl = "acc://$adiName.acme/book2";
  await createAdiKeyBook(client, adiSigner, "acc://$adiName.acme", keyBookUrl);
  // Prepare a list of public keys for the new key page
  List<Uint8List> keys = [adiSigner.publicKey()];
  
  // Create a Key Page in the Key Book
  await createAdiKeyPage(client, adiSigner, keyBookUrl, keys);

  // Step 1: Generate a new key signer for the new key
  Ed25519KeypairSigner newKeySigner = Ed25519KeypairSigner.generate();

  // Step 2: Create the key operation for adding the new key to the key page
  KeyOperation addKeyOperation = KeyOperation()
    ..type = KeyPageOperationType.Add
    ..key = (KeySpec()..keyHash = newKeySigner.publicKey());

  // Prepare the UpdateKeyPageParam with the operation
  UpdateKeyPageParam updateKeyPageParam = UpdateKeyPageParam()
    ..operations = [addKeyOperation];

  // Step 3: Call the `updateKeyPage` method with the necessary parameters
  // Assuming `adiSigner` is the signer with authority to update the key page,
  // and you have created a `TxSigner` instance using `adiSigner`

  // Correctly creating a TxSigner with the Ed25519KeypairSigner
  TxSigner txSigner = TxSigner(AccURL.toAccURL("yourPrincipal"), adiSigner);

  await client.updateKeyPage(
    AccURL.toAccURL(keyPageUrl), // Convert keyPageUrl to AccURL
    updateKeyPageParam,
    txSigner, // Pass the correct TxSigner instance
  );

  // Create the first ADI ACME token account
  String identityUrl = "acc://$adiName.acme";
  String tokenAccountUrl1 = "$identityUrl/acme-token-account-1";
  await createAdiAcmeTokenAccount(adiSigner, identityUrl, keyPageUrl, tokenAccountUrl1);

  // Create the second ADI ACME token account
  String tokenAccountUrl2 = "$identityUrl/acme-token-account-2";
  await createAdiAcmeTokenAccount(adiSigner, identityUrl, keyPageUrl, tokenAccountUrl2);

  // Pause to allow the create token accoutns to settle
  print("Pausing to allow the create token accoutns to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Sending 30 tokens from lid to tokenAccountUrl1
  await sendTokens(
    fromType: AccountType.lite,
    fromAccount: lid.acmeTokenAccount.toString(),
    toType: AccountType.adi,
    toAccount: tokenAccountUrl1,
    amount: 30,
    signer: signer1,
  );
    print("Sending 30 tokens from lid to tokenAccountUrl1");

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow sendTokens transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

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



  // Creating an ADI Custom Token
  String customTokenUrl = "$identityUrl/my-custom-token";
  await createCustomToken(adiSigner, identityUrl, keyPageUrl, customTokenUrl, "MYTKN", 2);

  // create two custom token acounts for MYTKN
  await createCustomTokenAccount(adiSigner, identityUrl, keyPageUrl, customTokenUrl, "myCustomTokenAccount1");
  await createCustomTokenAccount(adiSigner, identityUrl, keyPageUrl, customTokenUrl, "myCustomTokenAccount2");

 // Pause to allow creation of custom token acounts for MYTKN transaction to settle
  print("Pausing to allow creation of custom token acounts for MYTKN transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // issue custom token (MYTKN) to a MYTKN custom token account
  await issueCustomTokens(adiSigner, keyPageUrl, customTokenUrl, "$identityUrl/myCustomTokenAccount1", 100000);

  // Send custom token (MYTKN) from a custom token account to second custom token account
  String fromCustomTokenAccountUrl = "$identityUrl/myCustomTokenAccount1";
  String toCustomTokenAccountUrl = "$identityUrl/myCustomTokenAccount2";
  int amountToSend = 6000; // the amount is base 100, so the amount you put is ##/100
  // Assuming `adiSigner` is your Ed25519KeypairSigner and `keyPageUrl` is the URL of the key page used for signing transactions
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

// SendTokens function Enum to define the type of account for clearer function calls
enum AccountType { lite, adi }

Future<void> sendTokens({
  required AccountType fromType,
  required String fromAccount,
  required AccountType toType,
  required String toAccount,
  required int amount,
  required Ed25519KeypairSigner signer, // Signer for the transaction
  String? keyPageUrl, // Required for ADI accounts
}) async {
  // Determine the signer based on account type
  TxSigner txSigner;
  if (fromType == AccountType.lite) {
    txSigner = TxSigner(fromAccount, signer);
  } else if (fromType == AccountType.adi && keyPageUrl != null) {
    txSigner = TxSigner(keyPageUrl, signer);
  } else {
    throw Exception("Invalid account type or missing key page URL for ADI account.");
  }

  // Construct the parameters for sending tokens
  SendTokensParam sendTokensParam = SendTokensParam();
  sendTokensParam.to = [
    TokenRecipientParam()
      ..url = toAccount
      ..amount = (amount * pow(10, 8)).toInt()
  ];
  sendTokensParam.memo = "Sending $amount ACME tokens";

  try {
    // Execute the sendTokens transaction
    var response = await client.sendTokens(fromAccount, sendTokensParam, txSigner);
    print("ACME Send tx submitted, response: $response");
  } catch (e) {
    print("Error sending ACME tokens: $e");
  }
}

Future<void> addFundsToAccount(AccURL accountUrl, {int times = 10}) async {
  for (int i = 0; i < times; i++) {
    await client.faucet(accountUrl);
    await Future.delayed(Duration(seconds: 10));
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

Future<void> addCredits(LiteIdentity lid, int creditAmount, int oracle) async {
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8).toInt()) ~/ oracle;
  addCreditsParam.oracle = oracle;
  addCreditsParam.memo = "Add credits memo test";
  // Convert metadata to Uint8List
  Uint8List metadata = Uint8List.fromList(utf8.encode("Add credits metadata test"));
  addCreditsParam.metadata = metadata;

  print("Preparing to add credits:");
  print("Recipient URL: ${addCreditsParam.recipient}");
  print("Credit Amount: ${addCreditsParam.amount}");
  print("Oracle Value: ${addCreditsParam.oracle}");
  print("Memo: ${addCreditsParam.memo}");
  print("Metadata: ${metadata.isNotEmpty ? HEX.encode(metadata) : 'None'}");

  var res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("addCredits transaction response: $res");

  if (res["result"] != null && res["result"]["txid"] != null) {
    String txId = res["result"]["txid"];
    print("addCredits Transaction ID: $txId");
    await delayBeforePrint(); // Wait for network processing

    // Query the transaction to confirm processing
    res = await client.queryTx(txId);
    print("Query Transaction Response for addCredits: $res");
  }
}

// Create an Accumulate ADI Identity 
Future<void> createAdi(LiteIdentity lid, Ed25519KeypairSigner adiSigner, String adiName) async {
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
  print("Key Hash: ${HEX.encode(adiSigner.publicKeyHash())}");

  try {
    var response = await client.createIdentity(lid.url, createIdentityParam, lid);
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
Future<void> addCreditsToAdiKeyPage(LiteIdentity lid, String keyPageUrl, int creditAmount, int oracle) async {
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8).toInt()) ~/ oracle;
  addCreditsParam.oracle = oracle;
  print("Adding credits to ADI key page: $keyPageUrl with amount: ${addCreditsParam.amount}");

  var res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("Add credits to ADI key page response: $res");
}

// Function to create an ACME token account under the ADI
Future<void> createAdiAcmeTokenAccount(Ed25519KeypairSigner adiSigner, String identityUrl, String keyPageUrl, String tokenAccountUrl) async {
  // Prepare the parameters for creating a token account
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl; // Use the specific token account URL
  createTokenAccountParam.tokenUrl = "acc://ACME";
  
  print("Creating ADI ACME token account at: $tokenAccountUrl");

  // And use the TxSigner initialized with the key from the key page
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner); // Use the signer with authority
  
  // Execute the transaction
  var res = await client.createTokenAccount(identityUrl, createTokenAccountParam, txSigner);
  
  print("Create ADI ACME token account response: $res");
}

// create a custom token
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

Future<void> createAdiKeyBook(ACMEClient client, Ed25519KeypairSigner adiSigner, String identityUrl, String keyBookUrl) async {
  // Prepare the parameters for creating a key book
  CreateKeyBookParam createKeyBookParam = CreateKeyBookParam();
  createKeyBookParam.url = keyBookUrl;
  createKeyBookParam.publicKeyHash = adiSigner.publicKeyHash();
  // Optional: Set authorities, memo, and metadata as needed

  // Initialize the TxSigner
  TxSigner txSigner = TxSigner(identityUrl, adiSigner);

  print("Creating key book at: $keyBookUrl");

  // Execute the transaction to create the key book using your ACMEClient instance
  var res = await client.createKeyBook(identityUrl, createKeyBookParam, txSigner);
  
  print("Create key book transaction response: $res");
}

Future<void> createAdiKeyPage(ACMEClient client, Ed25519KeypairSigner adiSigner, String keyBookUrl, List<Uint8List> keys) async {
  // Construct the URL for the new key page (this may vary based on your naming convention)
  String keyPageUrl = "$keyBookUrl/key-page-${DateTime.now().millisecondsSinceEpoch}";

  // Prepare the parameters for creating a key page
  CreateKeyPageParam createKeyPageParam = CreateKeyPageParam()
    ..url = keyPageUrl
    ..keys = keys; // List of public keys to include in the key page

  // Initialize the TxSigner with the ADI signer
  TxSigner txSigner = TxSigner(keyBookUrl, adiSigner);

  print("Creating key page at: $keyPageUrl");

  // Execute the transaction to create the key page
  var res = await client.createKeyPage(keyBookUrl, createKeyPageParam, txSigner);
  
  print("Create key page transaction response: $res");
}

// Update a key page function
Future<Map<String, dynamic>> updateAdiKeyPage(
    ACMEClient client,
    String keyPageUrl, 
    UpdateKeyPageParam updateKeyPageParam, 
    Ed25519KeypairSigner signer) async {
  // Convert the Ed25519KeypairSigner to TxSigner if necessary
  // This conversion logic depends on your implementation details
  TxSigner txSigner = TxSigner(AccURL.toAccURL(keyPageUrl), signer);

  // Now call the updateKeyPage method on the client directly
  return client.updateKeyPage(
    AccURL.toAccURL(keyPageUrl),
    updateKeyPageParam,
    txSigner,
  );
}


/*

  // create lite data account
  await createLiteDataAccountExample();
  print("Lite Data Account Created");

  // Call the function to add entries to the lite data account
  await addEntriesToLiteDataAccountExample();


 // Create an ADI Data Account
  String dataAccountUrl = "$identityUrl/data-account";
  await createAdiDataAccount(adiSigner, identityUrl, keyPageUrl, dataAccountUrl);

 // Pause to allow the Create an ADI Data Account transaction to settle
  print("Pausing to allow the Create an ADI Data Account transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Add Data Entries to the Data Account
  print("writing data entries");
  await addDataToAdiDataAccount(client, adiSigner, keyPageUrl, dataAccountUrl, [
    utf8.encode("First data entry").asUint8List(),
  ]);



// Function to create a lite data account
Future<void> createLiteDataAccountExample() async {
  // Assuming signer1 is an instance of Ed25519KeypairSigner you want to use
  Ed25519KeypairSigner signer = Ed25519KeypairSigner.generate();
  printKeypairDetails(signer);

  // Assuming this URL is for the principal that has the authority to create the lite data account
  String principalUrl = "acc://yourPrincipalUrl";
  AccURL principalAccURL = AccURL.toAccURL(principalUrl);

  // The URL for the new lite data account - ensure it follows your naming convention
  String liteDataAccountUrl = "acc://example.lite-data-account";

  // Parameters for creating the lite data account
  CreateLiteDataAccountParam params = CreateLiteDataAccountParam()
    ..url = liteDataAccountUrl
    ..memo = "Example Lite Data Account"
    ..metadata = utf8.encode("Initial metadata for lite data account").asUint8List();

  // Create a TxSigner instance using the principal AccURL and the signer
  TxSigner txSigner = TxSigner(principalAccURL, signer);

  try {
    // Use the TxSigner instance with the client to create the lite data account
    Map<String, dynamic> response = await client.createLiteDataAccount(
      liteDataAccountUrl, // The intended URL for the lite data account
      params,
      txSigner,
    );

    print("Lite data account creation response: $response");
  } catch (e) {
    print("Error creating lite data account: $e");
  }
}

Future<void> addEntriesToLiteDataAccountExample() async {
  // Assuming signer1 is an instance of Ed25519KeypairSigner you want to use
  Ed25519KeypairSigner signer = Ed25519KeypairSigner.generate();
  printKeypairDetails(signer);

  // Specify the data you want to write to the lite data account
  List<Uint8List> dataEntries = [
    utf8.encode("First data entry").asUint8List(),
    utf8.encode("Second data entry").asUint8List(),
    // Add more data entries as needed
  ];

  // Specify the URL of the lite data account you want to write to
  String liteDataAccountUrl = "acc://example.lite-data-account";

  // Create and configure the WriteDataToParam object
  WriteDataToParam writeDataToParam = WriteDataToParam()
    ..recepient = liteDataAccountUrl
    ..data = dataEntries
    ..writeToState = true // Set to false if you don't want to write to the state
    ..memo = "Example data write transaction"
    ..metadata = utf8.encode("Optional metadata").asUint8List();

  // Execute the transaction using your ACMEClient instance
  Map<String, dynamic> response = await client.writeDataTo(
    liteDataAccountUrl, // Principal, which is the lite data account URL in this case
    writeDataToParam,
    TxSigner(AccURL.toAccURL(liteDataAccountUrl), signer), // Create a TxSigner with the signer
  );

  print("Data write transaction response: $response");
}

// Function to create an ADI Data token under
Future<void> createAdiDataAccount(Ed25519KeypairSigner adiSigner, String identityUrl, String keyPageUrl, String dataAccountUrl) async {
  CreateDataAccountParam dataAccountParams = CreateDataAccountParam();
  dataAccountParams.url = dataAccountUrl;
  dataAccountParams.scratch = false; // true enables entires to be "forgotton" by network over time

  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);
  var res = await client.createDataAccount(identityUrl, dataAccountParams, txSigner);
  print("Create ADI Data Account response: $res");
}

// Add data to data account
Future<void> addDataToAdiDataAccount(ACMEClient client, Ed25519KeypairSigner adiSigner, String keyPageUrl, String dataAccountUrl, List<Uint8List> dataEntries) async {
  // Initialize the WriteData parameter with the data entries to be added
  WriteDataParam writeDataParam = WriteDataParam(
    data: dataEntries,
    scratch: false, // Assuming you want the data to persist
    writeToState: true, // Assuming you want to write the data to the state
  );

  // Create a transaction signer with the ADI signer and the key page URL
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);

  try {
    // Log the critical parts of the payload for debugging
    print("Data being sent: ${writeDataParam.data.map((e) => hex.encode(e)).join(", ")}");
    print("Scratch: ${writeDataParam.scratch}");
    print("WriteToState: ${writeDataParam.writeToState}");

    // Execute the transaction using the client
    var res = await client.writeData(dataAccountUrl, writeDataParam, txSigner);
    print("Write Data to ADI Data Account response: $res");
  } catch (error) {
    // Handle any errors that might occur during the transaction
    print("An error occurred while writing data: $error");
  }
}

*/