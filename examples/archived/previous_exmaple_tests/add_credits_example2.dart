// C:\Accumulate_Stuff\accumulate-dart-client\examples\add_credits_example2.dart

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
  // Configure logging output
  Logger.root.level = Level.ALL;
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
  // Use a hardcoded Ed25519 keypair (fixed)
  Uint8List privateKey = Uint8List.fromList(
    HEX.decode(
      // New hardcoded private key
      "967cbba8bd6e8ff27d2635d3b54e92a69f872d14d3c40474a57e141b6d352832d439ffdf9e6be0fb3c547a8a11bc1646688aa5568a3ca6e64661517bc7c6fdcf"
    )
  );
  Ed25519KeypairSigner signer1 = Ed25519KeypairSigner.fromKeyRaw(privateKey);

  // Use a hardcoded Lite Identity URL (this account must exist on‑chain)
  // In our system the lite identity URL is computed from the public key hash.
  // Here we hardcode the expected value.
  String liteIdentityUrl = "acc://341e36ec8d8796b13c88fc391476b7553904397b121b08ba";
  LiteIdentity lid = LiteIdentity(signer1);

  print('LOG: Using hardcoded signer1');
  printKeypairDetails(signer1);

  // Use a hardcoded Lite token account (simply appending "/acme" to the identity)
  AccURL liteTokenAccount = AccURL.parse("acc://341e36ec8d8796b13c88fc391476b7553904397b121b08ba/acme");
  print("LOG: Using hardcoded Lite token account: $liteTokenAccount\n");

  // Use a fixed oracle value (for example, 500000)
  final int oracle = 500000;

  // Now, build the addCredits transaction manually.
  // All parameters are fixed except the timestamp, which is generated dynamically.
  await addCreditsManually(lid, 10000, oracle);
}

enum AccountType { lite, adi }

void printKeypairDetails(Ed25519KeypairSigner signer) {
  String publicKeyHex = HEX.encode(signer.publicKey());
  String privateKeyHex = HEX.encode(signer.secretKey());
  print("LOG: Public Key: $publicKeyHex");
  print("LOG: Private Key: $privateKeyHex (Hardcoded)\n");
}

Future<void> addCreditsManually(LiteIdentity lid, int creditAmount, int oracle) async {
  // Prepare the addCredits parameters (all fixed)
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url; // Fixed lite identity URL
  // Amount is computed as (creditAmount * 10^8) / oracle, all fixed numbers
  addCreditsParam.amount = (creditAmount * pow(10, 8).toInt()) ~/ oracle;
  addCreditsParam.oracle = oracle;
  addCreditsParam.memo = "Add credits memo test";
  addCreditsParam.metadata = Uint8List.fromList(utf8.encode("Add credits metadata test"));

  print("LOG: Preparing to add credits:");
  print("LOG: Recipient URL: ${addCreditsParam.recipient}");
  print("LOG: Credit Amount: ${addCreditsParam.amount}");
  print("LOG: Oracle Value: ${addCreditsParam.oracle}");
  print("LOG: Memo: ${addCreditsParam.memo}");
  print("LOG: Metadata: ${addCreditsParam.metadata != null ? HEX.encode(addCreditsParam.metadata!) : 'None'}");

  // Here we do NOT hard-code the timestamp – we allow HeaderOptions to use the current time.
  HeaderOptions headerOptions = HeaderOptions(
    memo: addCreditsParam.memo,
    metadata: addCreditsParam.metadata,
    // timestamp is left undefined so that it defaults to DateTime.now().microsecondsSinceEpoch
  );

  // Build the payload from the addCredits parameters (all fixed)
  AddCredits payload = AddCredits(addCreditsParam);

  // Create the transaction header using the fixed lite token account and dynamic timestamp
  Header header = Header(lid.acmeTokenAccount, headerOptions);

  // Build the transaction
  Transaction tx = Transaction(payload, header);

  // Sign the transaction using the lite identity (which is also our TxSigner)
  tx.sign(lid);

  // Submit the transaction
  var res = await client.execute(tx);
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
