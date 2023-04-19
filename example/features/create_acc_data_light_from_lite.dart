import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:accumulate_api/src/acme_client.dart';
import 'package:accumulate_api/src/client/lite_identity.dart';
import 'package:accumulate_api/src/model/factom/factom_entry.dart';
import 'package:accumulate_api/src/payload/add_credits.dart';
import 'package:accumulate_api/src/payload/factom_data_entry.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/utils/utils.dart';

//final endPoint = "http://127.0.1.1:26660/v2";
final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  testLiteDataAccountCreation();
}

void testLiteDataAccountCreation() async {
  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Re-Usable Variable
  String txId = "";
  dynamic res;
  int waitTimeInSeconds = 20;
  LiteIdentity lid;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Generate Light Token Account

  lid = LiteIdentity(Ed25519KeypairSigner.generate());
  print("new account ${lid.acmeTokenAccount.toString()}");
  print("\n");

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Add Credits to allow actions

  for (int i = 0; i < 2; i++) {
    dynamic res = await client.faucet(lid.acmeTokenAccount);
    sleep(Duration(seconds: 10));
    print("faucet call: #$i");
    txId = res["result"]["txid"];
    print("    txId: $txId");
  }

  res = await client.faucet(lid.acmeTokenAccount);
  txId = res["result"]["txid"];
  print("faucet txId $txId");

  print("\n");
  res = await client.queryUrl(lid.url);
  print(res);

  print("\n");
  res = await client.queryUrl(lid.acmeTokenAccount);
  print(res);
  print("\n");

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Add Credits to Light Account to allow actions

  // Get conversion value from Oracle
  final oracle = await client.valueFromOracle();

  // Construct parameters structure
  int creditAmount = 50000 * 10;
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;
  addCreditsParam.memo = "MEMO";
  addCreditsParam.metadata = utf8.encode("METADATA").asUint8List();
  print(addCreditsParam.amount);

  // execute
  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("addCredits res $res");

  txId = res["result"]["txid"];
  print("addCredits txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
  res = await client.queryTx(txId);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Create Lite Data Account
  print("======== Lite Data CREATE =============================");

  FactomEntry fe = FactomEntry(utf8.encode(lid.acmeTokenAccount.toString()).asUint8List());
  //fe.addExtRef("Kompendium");
  //fe.addExtRef("Test val");

  FactomDataEntryParam factomDataEntryParam = FactomDataEntryParam();
  factomDataEntryParam.data = fe.data;
  //factomDataEntryParam.extIds = fe.getExtRefs();
  factomDataEntryParam.accountId = fe.calculateChainId();

  res = await client.factom(lid.acmeTokenAccount, factomDataEntryParam, lid);
  txId = res["result"]["txid"];
  print("Lite Data write $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  res = await client.queryData(txId);
  print("tx $res");

}
