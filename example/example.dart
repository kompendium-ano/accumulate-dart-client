import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:accumulate_api/src/lite_identity.dart';
import 'package:accumulate_api/src/payload/add_credits.dart';
import 'package:accumulate_api/src/payload/create_identity.dart';
import 'package:accumulate_api/src/payload/send_tokens.dart';
import 'package:accumulate_api/src/signer.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/tx_signer.dart';
import 'package:hex/hex.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import 'package:accumulate_api/src/utils.dart';

import 'package:accumulate_api/accumulate_api.dart';

ACMEClient client = ACMEClient("https://testnet.accumulatenetwork.io/v2");

Future<void> main() async {
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
  print("faucet $res");
  String txId = res["result"]["txid"];
  print("txId $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch,txId);
  print("waiting done");

  res = await client.queryUrl(lid.url);
  print(res);

  res = await client.queryUrl(lid.acmeTokenAccount);
  print(res);

  int creditAmount = 60000;
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ 1;
  addCreditsParam.oracle = oracle;

  res = await client.addCredits(lid.url, addCreditsParam, lid);

  print("addCredits $res");
  txId = res["result"]["txid"];
  print("addCredits txId $txId");

  //final resAccountType = await client.queryUrl(acc.url);
  //print("resAccountType $resAccountType");

  identityUrl = "acc://${DateTime.now().millisecondsSinceEpoch}";
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
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch,txId);
  print("waiting done");

  //res = await client.queryUrl(identityUrl);

  final keyPageUrl = bookUrl + "/1";

  creditAmount = 60000;
  sleep(const Duration(seconds: 10));
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  await client.addCredits(client, addCreditsParam, lid);

  identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);

  //Send Token
  final recipient =
      LiteIdentity(Ed25519KeypairSigner.generate()).acmeTokenAccount;

  const amount = 12;

  SendTokensParam sendTokensParam = SendTokensParam();
  TokenRecipientParam tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = recipient;
  tokenRecipientParam.amount = amount;
  sendTokensParam.to = [tokenRecipientParam];

  res = await client.sendTokens(lid.acmeTokenAccount, sendTokensParam, lid);

  txId = res["result"]["txid"];
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch,txId);

  res = await client.queryTx(txId);
  print(res);
}
