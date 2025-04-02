// examples\SDK_Usage_Examples\SDK_Examples_file_6_Key_Management.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:crypto/crypto.dart';
import 'SDK_Examples_file_1_lite_identities.dart';
import 'SDK_Examples_file_2_Accumulate_Identities.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);
int delayBeforePrintSeconds = 60;

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
  await createAdi(
    lid,
    adiSigner,
    adiName,
  );

  // Add credits to custom-adi-name key book's key page
  String keyPageUrl =
      "acc://$adiName.acme/book/1"; // Adjust based on actual key page URL
  print("keyPageUrl Name: $keyPageUrl");
  String keyBookUrl = "acc://$adiName.acme/book";
  await addCreditsToAdiKeyPage(
      lid, keyPageUrl, 7000000, oracle); // Adjust the credit amount as needed

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow addCredits transaction to settle...");
  await Future.delayed(Duration(seconds: 120)); // Pause for 2 minutes

  // Create new keypage and add to exisitng key book
  // Generate a new keypair for the new key page
  Ed25519Keypair newKeypair2 = Ed25519Keypair.generate();
  // Use the public key from the newly generated keypair for the new key page
  List<Uint8List> newKeys2 = [newKeypair2.publicKey];

  // Query the existing key pages to determine the next page number
  int nextPageNumber = await getNextKeyPageNumber(client, keyBookUrl);

  // Create the new key page with the newly generated key, using the existing key for authentication
  print("creating new adi key page");
  await createAdiKeyPage2(
      client, adiSigner, keyBookUrl, newKeys2, nextPageNumber, adiName);

  // Pause to allow the addCredits transaction to settle
  print("Pausing to allow transactions to settle...");
  await Future.delayed(Duration(seconds: 60)); // Pause for 2 minutes

  // Creaet new custom Key Book
  // To create a key book, you alos need a key page, and a key for the key page
  // Squencing her eis important, as a key page can't be empty.
  // Generate a new keypair for the new key page
  Ed25519Keypair newKeypair = Ed25519Keypair.generate();
  // Conversion to Uint8List
  Uint8List publicKeyHash =
      sha256.convert(newKeypair.publicKey).bytes.asUint8List();
  //final String keyBookUrl = "acc://$adiName.acme/book";
  // You Should Query the key book to get key pages, but in we know it's new
  int nextPageNumber2 = 1;
  // Use the public key from the newly generated keypair for the new key page
  List<Uint8List> newKeys = [newKeypair.publicKey];

  // Create the new key page with the newly generated key, using the existing key for authentication
  await createAdiKeyPage(
      client, adiSigner, keyBookUrl, newKeys, nextPageNumber2, adiName);

  // Prepare necessary parameters for creating a new key book
  final String principalUrl = "acc://$adiName.acme";
  final String newKeyBookUrl =
      "acc://$adiName.acme/book2"; // Assuming you're creating a second book
  CreateKeyBookParam createKeyBookParam = CreateKeyBookParam()
    ..url = newKeyBookUrl
    ..publicKeyHash =
        publicKeyHash; // Ensure publicKeyHash is defined and correct

  print("creating new adi key book");
  await createKeyBook(
      client, principalUrl, createKeyBookParam, adiSigner, keyPageUrl);

  // Update keypage allows severals actions to include add/remove/modify keys
  // The URL of the key page you want to update
  final String UpdatekeyPageUrl = keyPageUrl;
  // Generate or specify the new public key you want to add to the key page
  Ed25519Keypair newKeypairnew =
      Ed25519Keypair.generate(); // or use a specific key
  Uint8List newPublicKey = newKeypairnew.publicKey;

  // Prepare the update operation
  UpdateKeyPageParam updateKeyPageParam = UpdateKeyPageParam()
    ..operations = [
      KeyOperation()
        ..type = KeyPageOperationType
            .Add // Define the operation type (Add, Remove, Update, etc.)
        ..key = (KeySpec()
          ..keyHash = newPublicKey) // Specify the new key to be added
    ]
    ..memo = "Adding new key to key page";

  // Call the update key page function
  Map<String, dynamic> response = await updateAdiKeyPage(
    client,
    UpdatekeyPageUrl,
    updateKeyPageParam,
    adiSigner,
  );
  print("Update key page response: $response");
}

Future<void> createKeyBook(
    ACMEClient client,
    String principalUrl,
    CreateKeyBookParam createKeyBookParam,
    Ed25519KeypairSigner existingAdiSigner,
    String keyPageUrl) async {
  print("Creating key book at: ${createKeyBookParam.url}");

  // Use the keyPageUrl parameter instead of a hardcoded value
  TxSigner txSigner = TxSigner(keyPageUrl, existingAdiSigner);
  var r = await client.queryUrl(txSigner
      .url); // check for version, every keypage update changes versions!!
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);
  var rt = await client.queryUrl(txSigner
      .url); // check for version, every keypage update changes versions!!
  txSigner = TxSigner.withNewVersion(txSigner, rt["result"]["data"]["version"]);
  var response =
      await client.createKeyBook(principalUrl, createKeyBookParam, txSigner);
  print("Create key book response: $response");
}

Future<void> createAdiKeyPage(
    ACMEClient client,
    Ed25519KeypairSigner existingAdiSigner,
    String keyBookUrl,
    List<Uint8List> keys,
    int nextPageNumber,
    String adiName) async {
  // Dynamically construct newKeyPageUrl for the new key page
  String newKeyPageUrl = "$keyBookUrl/$nextPageNumber";

  // Dynamically construct keyPageUrl using adiName
  String keyPageUrl = "acc://$adiName.acme/book/1";

  // Use the dynamically constructed keyPageUrl for TxSigner
  TxSigner txSigner = TxSigner(keyPageUrl, existingAdiSigner);
  var r = await client.queryUrl(txSigner
      .url); // check for version, every keypage update changes versions!!
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  CreateKeyPageParam createKeyPageParam = CreateKeyPageParam()..keys = keys;

  print("Creating key page at: $newKeyPageUrl");

  var res = await client.createKeyPage(keyBookUrl, createKeyPageParam,
      txSigner); // Sign transaction with existing page+key
  print("Create key page transaction response: $res");
}

Future<int> getNextKeyPageNumber(ACMEClient client, String keyBookUrl) async {
  QueryPagination qp = QueryPagination()
    ..start = 0
    ..count = 100;
  var response = await client.queryDirectory(keyBookUrl, qp, null);

  // Adjusting the path to match the actual response structure
  var items =
      response['result']['items'] as List<dynamic>; // This line is changed

  if (items.isEmpty) {
    // If there are no items, implying no key pages exist yet
    return 1; // Return 1 to indicate the first key page should be created
  }

  // Assuming that items contain URLs of the form "acc://.../book/1"
  int highestPageNumber = items.fold<int>(0, (prev, curr) {
    var pageUrl = curr as String;
    var pageNumber = int.tryParse(pageUrl.split('/').last) ?? 0;
    return max(prev, pageNumber);
  });

  return highestPageNumber + 1; // Increment to get the next page number
}

Future<void> createAdiKeyPage2(
    ACMEClient client,
    Ed25519KeypairSigner existingAdiSigner,
    String keyBookUrl,
    List<Uint8List> keys,
    int nextPageNumber,
    String adiName) async {
  // Use getNextKeyPageNumber to dynamically determine the next page number
  int nextPageNumber2 = await getNextKeyPageNumber(client, keyBookUrl);

  // Ensure there's no accidental space in the constructed URL
  String newKeyPageUrl = "$keyBookUrl/$nextPageNumber2";

  // Dynamically construct keyPageUrl using adiName, ensuring it reflects the current ADI
  String keyPageUrl = "acc://$adiName.acme/book/1";

  // Prepare the TxSigner using the dynamically constructed keyPageUrl
  TxSigner txSigner = TxSigner(keyPageUrl, existingAdiSigner);
  var r = await client.queryUrl(txSigner.url);
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  // Prepare the parameters for creating a new key page
  CreateKeyPageParam createKeyPageParam = CreateKeyPageParam()..keys = keys;

  // Log the action
  print("Creating key page at: $newKeyPageUrl");

  // Execute the creation of the new key page and log the response
  var res =
      await client.createKeyPage(keyBookUrl, createKeyPageParam, txSigner);
  print("Create key page transaction response: $res");
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
