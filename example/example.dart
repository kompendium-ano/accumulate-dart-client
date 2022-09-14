import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

//import '../lib/src/lite_identity.dart';
import '../lib/src/payload/create_key_book.dart';
import '../lib/src/payload/update_key.dart';
import '../lib/src/payload/update_key_page.dart';

import '../lib/src/acc_url.dart';

import '../lib/src/encoding.dart';

import '../lib/src/payload/burn_tokens.dart';
import '../lib/src/payload/create_token.dart';
import '../lib/src/payload/create_token_account.dart';
import '../lib/src/payload/issue_tokens.dart';

import '../lib/src/payload/create_data_account.dart';
import '../lib/src/payload/write_data.dart';

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

  //String url = "acc://ab8313657dc153edaa12e9f9ee6319b31fecf220f2184400/8cbc82cd058456e667c0f477.acme/TEST";
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

  //bool status = await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
  //print("transaction $status");
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
  addCreditsParam.memo = "Add credits memo test";
  addCreditsParam.metadata = utf8.encode("Add credits metadata test").asUint8List();

  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);

  txId = res["result"]["txid"];
  print("addCredits txId $txId");
  sleep(Duration(seconds: 45));
  res = await client.queryTx(txId);
  print("addCredits res $res");
return;

  identityUrl = "acc://adi-${DateTime.now().millisecondsSinceEpoch}.acme";
  final identitySigner = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/jimmy-book";
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

  creditAmount = 600000;

  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res  = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $keyPageUrl txId $txId");
  sleep(Duration(seconds: 60));
  identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);
/*
  final tokenAccountUrl = identityUrl + "/ACME";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = ACME_TOKEN_URL;

  res = await client.createTokenAccount(
      identityUrl,
      createTokenAccountParam,
      identityKeyPageTxSigner
  );

  txId = res["result"]["txid"];
  print("Create token account txId $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
*/

  final page1Signer = Ed25519KeypairSigner.generate();
  final newKeyBookUrl = identityUrl + "/" + "${DateTime.now().millisecondsSinceEpoch}";
  CreateKeyBookParam createKeyBookParam = CreateKeyBookParam();
  createKeyBookParam.url = newKeyBookUrl;
  createKeyBookParam.publicKeyHash = page1Signer.publicKeyHash();


  res = await client.createKeyBook(identityUrl, createKeyBookParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("Create keybook txId $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
  sleep(Duration(seconds: 60));

  final page1Url = newKeyBookUrl + "/1";

  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res  = await client.addCredits(page1Url, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $page1Url txId $txId");
  sleep(Duration(seconds: 60));


  final keyPage1TxSigner = new TxSigner(page1Url, page1Signer);

  // Add new key to keypage
  final newKey = Ed25519KeypairSigner.generate();
  UpdateKeyPageParam updateKeyPageParam = UpdateKeyPageParam();
  KeyOperation keyOperation = KeyOperation();
  keyOperation.type = KeyPageOperationType.Add;
  KeySpec keySpec = KeySpec();
  keySpec.keyHash = newKey.publicKeyHash();
  keyOperation.key = keySpec;
  updateKeyPageParam.operations = [keyOperation];

  res = await client.updateKeyPage(page1Url, updateKeyPageParam, keyPage1TxSigner);

  txId = res["result"]["txid"];
  print("Add new key to page $page1Url txId $txId");

  print("done");
  return;



/*
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
  print("Send Token $txId");

  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

  res = await client.queryTx(txId);*/
sleep(Duration(seconds: 60));
  // Create data account
  final dataAccountUrl = identityUrl + "/jimmy-data";
  print("dataAccountUrl $dataAccountUrl");
  CreateDataAccountParam createDataAccountParam = CreateDataAccountParam();
  createDataAccountParam.url = dataAccountUrl;


  res = await client.createDataAccount(
      identityUrl,
      createDataAccountParam,
      identityKeyPageTxSigner
  );

  txId = res["result"]["txid"];
  print("Create data account $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

  //res = await client.queryUrl(dataAccountUrl);

  sleep(Duration(seconds: 60));

  // Write data
  WriteDataParam writeDataParam = WriteDataParam();

  writeDataParam.data = [utf8.encode("Jimmy").asUint8List()];


  res = await client.writeData(dataAccountUrl, writeDataParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("Data write $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

  res = await client.queryData(dataAccountUrl);
  print("Data account write $res");

  sleep(Duration(seconds: 60));

  final tokenUrl = identityUrl + "/JimToken";
  CreateTokenParam createTokenParam = CreateTokenParam();
  createTokenParam.url = tokenUrl;
  createTokenParam.symbol = "JimT";
  createTokenParam.precision = 8;


  res = await client.createToken(identityUrl, createTokenParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("Create Token $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

  sleep(Duration(seconds: 60));

  final recipient = LiteIdentity(Ed25519KeypairSigner.generate()).url.append(tokenUrl);
  print("recipient $recipient");
  var amount = 123;
  IssueTokensParam issueTokensParam = IssueTokensParam();
  TokenRecipientParam tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = recipient;
  tokenRecipientParam.amount = amount;
  issueTokensParam.to = [tokenRecipientParam];


  res = await client.issueTokens(tokenUrl, issueTokensParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("Issue Token $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

  sleep(Duration(seconds: 60));

  amount = 15;
  BurnTokensParam burnTokensParam = BurnTokensParam();
  burnTokensParam.amount = amount;

  res = await client.burnTokens(lid.acmeTokenAccount, burnTokensParam, lid);

  txId = res["result"]["txid"];
  print("Burn Token $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

/*
  // Create a token account for the TEST token
  final tokenAccountUrl = identityUrl + "/JimTokenAcc";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = tokenUrl;
  TokenIssuerProofParam tokenIssuerProofParam = TokenIssuerProofParam();
  tokenIssuerProofParam.receipt
  createTokenAccountParam.proof
  const createTokenAccount = {
    url: tokenAccountUrl,
    tokenUrl,
    proof: await constructIssuerProof(client, tokenUrl),
  };
  res = await client.createTokenAccount(identityUrl, createTokenAccount, identityKeyPageTxSigner);

  await client.waitOnTx(res.txid, { timeout: 10_000 });

  res = await client.queryUrl(tokenAccountUrl);*/


  print("DONE");
}
