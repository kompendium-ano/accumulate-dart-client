// C:\Accumulate_Stuff\accumulate-dart-client\examples\add_credits_example.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:hex/hex.dart';
import 'package:logging/logging.dart'; // Import the logging package

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);
int delayBeforePrintSeconds = 40;

void main() {
  // ✅ Configure logging output
  Logger.root.level = Level.ALL; // Enable all log levels (INFO, FINE, WARNING, etc.)
  Logger.root.onRecord.listen((LogRecord rec) {
    print('[${rec.level.name}] ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });

  print(endPoint);
  testFeatures();
}

Future<void> delayBeforePrint() async {
  await Future.delayed(Duration(seconds: delayBeforePrintSeconds));
}

Future<void> testFeatures() async {
  Ed25519KeypairSigner signer1 = Ed25519KeypairSigner.generate();
  LiteIdentity lid = LiteIdentity(signer1);
   print('LOG: signer1');
  printKeypairDetails(signer1);

  // First lite token account
  print("LOG: Lite account URL - signer1: ${lid.acmeTokenAccount}\n");
  await addFundsToAccount(lid.acmeTokenAccount, times: 3);

  // ✅ Add a 30-second delay after the faucet calls
  print("LOG: Waiting 30 seconds before adding credits...");
  await Future.delayed(Duration(seconds: 30));

  // Retrieve oracle value for credit calculation
  final oracle = await client.valueFromOracle();

  // Add 100 credits to the first lite account
  await addCredits(lid, 10000, oracle);
}

// SendTokens function Enum to define the type of account for clearer function calls
enum AccountType { lite, adi }

Future<void> addFundsToAccount(AccURL accountUrl, {int times = 10}) async {
  for (int i = 0; i < times; i++) {
    await client.faucet(accountUrl);
    await Future.delayed(Duration(seconds: 4));
  }
}

void printKeypairDetails(Ed25519KeypairSigner signer) {
  String publicKeyHex = HEX.encode(signer.publicKey());
  String privateKeyHex = HEX.encode(signer.secretKey());
  String mnemonic = signer.mnemonic();

  print("LOG: Public Key: $publicKeyHex");
  print("LOG: Private Key: $privateKeyHex");
  print("LOG: Mnemonic: $mnemonic\n");
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

  print("LOG: Preparing to add credits:");
  print("LOG: Recipient URL: ${addCreditsParam.recipient}");
  print("LOG: Credit Amount: ${addCreditsParam.amount}");
  print("LOG: Oracle Value: ${addCreditsParam.oracle}");
  print("LOG: Memo: ${addCreditsParam.memo}");
  print("LOG: Metadata: ${metadata.isNotEmpty ? HEX.encode(metadata) : 'None'}");

  var res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("LOG: addCredits transaction response: $res");

  if (res["result"] != null && res["result"]["txid"] != null) {
    String txId = res["result"]["txid"];
    print("LOG: addCredits Transaction ID: $txId");
    await delayBeforePrint(); // Wait for network processing

    // Query the transaction to confirm processing
    res = await client.queryTx(txId);
    print("LOG: Query Transaction Response for addCredits: $res");
  }
}
