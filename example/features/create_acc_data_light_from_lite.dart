import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:accumulate_api6/src/acme_client.dart';
import 'package:accumulate_api6/src/api_types.dart';
import 'package:accumulate_api6/src/lite_identity.dart';
import 'package:accumulate_api6/src/payload/add_credits.dart';
import 'package:accumulate_api6/src/payload/create_identity.dart';
import 'package:accumulate_api6/src/payload/create_key_page.dart';
import 'package:accumulate_api6/src/payload/create_lite_data_account.dart';
import 'package:accumulate_api6/src/payload/write_data.dart';
import 'package:accumulate_api6/src/payload/write_data_to.dart';
import 'package:accumulate_api6/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api6/src/tx_signer.dart';
import 'package:accumulate_api6/src/utils.dart';

final endPoint = "http://127.0.1.1:26660/v2";
//final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  testLiteDataAccountCreation();
}

void testLiteDataAccountCreation() async {
  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Re-Usable Variable
  String txId = "";
  dynamic res;
  int waitTimeInSeconds = 60;
  LiteIdentity lid;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Generate Light Token Account

  lid = LiteIdentity(Ed25519KeypairSigner.generate());
  print("new account ${lid.acmeTokenAccount.toString()}");
  print("\n");

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Add Credits to allow actions

  for (int i = 0; i < 4; i++) {
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
  // Create Light Data Account

  var newDataAcc = "acc://2c1b046a34c40e08739ba5ac00bea740024f16999ed5c6fb889cd11133be8f97"; //test value must compute from FactomEntry.calculateChainId(
  WriteDataToParam writeDataToParam = WriteDataToParam();
  writeDataToParam.recepient = newDataAcc; //destination
  writeDataToParam.data = [utf8.encode("FA2CKnvUpPnNpMwiYEcF44oBG24vQ5eCe9gHximhxqVpCN8A7NH2").asUint8List()];

  res = await client.writeDataTo(lid.acmeTokenAccount, writeDataToParam, lid);
  txId = res["result"]["txid"];
  print("Lite Data write $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  res = await client.queryData(txId);
  print("tx $res");

}
