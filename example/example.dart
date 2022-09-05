import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

//import '../lib/src/lite_identity.dart';
import '../lib/src/payload/add_credits.dart';
import '../lib/src/payload/create_identity.dart';
import '../lib/src/payload/send_tokens.dart';
import '../lib/src/payload/token_recipient.dart';
import '../lib/src/signer.dart';
import '../lib/src/signing/ed25519_keypair_signer.dart';
import '../lib/src/tx_signer.dart';
import 'package:hex/hex.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import '../lib/src/utils.dart';

import '../lib/accumulate_api6.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  print(endPoint);
  testFeatures();
}

void testFeatures() async {
  LiteIdentity lid;
  String identityUrl;
  TxSigner identityKeyPageTxSigner;

  final oracle = await client.valueFromOracle();

  lid = LiteIdentity(Ed25519KeypairSigner.generate());
  print("new account ${lid.acmeTokenAccount.toString()}");

  dynamic res = await client.faucet(lid.acmeTokenAccount);
  sleep(Duration(seconds: 10));
  String txId = res["result"]["txid"];
  print("faucet txId $txId");

  bool status = await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
  print("transaction $status");
 // sleep(Duration(seconds: 60));


/*
  res = await client.queryUrl(lid.url);
  print(res);

  res = await client.queryUrl(lid.acmeTokenAccount);
  print(res);
*/
  int creditAmount = 60000;
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);


  txId = res["result"]["txid"];
  print("addCredits txId $txId");
  sleep(Duration(seconds: 45));


  identityUrl = "acc://adi-${DateTime.now().millisecondsSinceEpoch}.acme";
  final identitySigner = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/my-book";
  CreateIdentityParam createIdentity = CreateIdentityParam();

  // Create identity

  createIdentity.url = identityUrl;
  createIdentity.keyHash = identitySigner.publicKeyHash();
  createIdentity.keyBookUrl = bookUrl;

  res = await client.createIdentity(lid.url, createIdentity, lid);
  txId = res["result"]["txid"];
  print("createIdentity txId $txId");

  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
  print("transaction complete");

  //res = await client.queryUrl(identityUrl);

  final keyPageUrl = bookUrl + "/1";

  creditAmount = 60000;
  sleep(const Duration(seconds: 10));
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);

  identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);

  //Send Token
  final recipient =
      LiteIdentity(Ed25519KeypairSigner.generate()).acmeTokenAccount;

  const amount = 12000;

  SendTokensParam sendTokensParam = SendTokensParam();
  TokenRecipientParam tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = recipient;
  tokenRecipientParam.amount = amount;
  sendTokensParam.to = [tokenRecipientParam];

  res = await client.sendTokens(lid.acmeTokenAccount, sendTokensParam, lid);

  txId = res["result"]["txid"];

  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

  res = await client.queryTx(txId);
  print(res);
}
