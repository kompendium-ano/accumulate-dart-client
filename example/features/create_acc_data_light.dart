import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:accumulate_api6/src/acme_client.dart';
import 'package:accumulate_api6/src/lite_identity.dart';
import 'package:accumulate_api6/src/payload/add_credits.dart';
import 'package:accumulate_api6/src/payload/create_identity.dart';
import 'package:accumulate_api6/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api6/src/tx_signer.dart';
import 'package:accumulate_api6/src/utils.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  runLightDataCreation();
}

void runLightDataCreation() async {
  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Re-Usable Variable
  String txId = "";
  dynamic res;
  int waitTimeInSeconds = 60;
  String identityUrl;
  TxSigner identityKeyPageTxSigner;
  LiteIdentity lid;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Generate Light Token Account

  lid = LiteIdentity(Ed25519KeypairSigner.generate());
  print("new account ${lid.acmeTokenAccount.toString()}");
  print("\n");

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Add Credits to allow actions

  for (int i = 0; i <= 10; i++) {
    dynamic res = await client.faucet(lid.acmeTokenAccount);
    print("faucet call: #$i");
    txId = res["result"]["txid"];
    print("    txId: $txId");
    sleep(Duration(seconds: 10));
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
  // Add Credits to allow actions

  // Get conversion value from Oracle
  final oracle = await client.valueFromOracle();

  // Make
  int creditAmount = 50000 * 10;
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;
  addCreditsParam.memo = "Cosmos MEMO";
  addCreditsParam.metadata = utf8.encode("METADATA: cosm").asUint8List();
  print(addCreditsParam.amount);
  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("addCredits res $res");

  txId = res["result"]["txid"];
  print("addCredits txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
  res = await client.queryTx(txId);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Create ADI

  identityUrl = "acc://adi-cosmonaut-${DateTime.now().millisecondsSinceEpoch}.acme";
  final identitySigner = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/cosm-book";
  CreateIdentityParam createIdentity = CreateIdentityParam();

  createIdentity.url = identityUrl;
  createIdentity.keyHash = identitySigner.publicKeyHash();
  createIdentity.keyBookUrl = bookUrl;

  res = await client.createIdentity(lid.url, createIdentity, lid);
  txId = res["result"]["txid"];
  print("createIdentity txId $txId");
}
