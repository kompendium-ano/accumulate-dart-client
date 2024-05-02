// examples\SDK_Usage_Examples\SDK_Examples_file_1_lite_identities.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
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
  await addFundsToAccount(lid.acmeTokenAccount, times: 50);

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
    throw Exception(
        "Invalid account type or missing key page URL for ADI account.");
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
    var response =
        await client.sendTokens(fromAccount, sendTokensParam, txSigner);
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
  Uint8List metadata =
      Uint8List.fromList(utf8.encode("Add credits metadata test"));
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
