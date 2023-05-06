import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:accumulate_api/accumulate_api.dart';
import 'package:accumulate_api/src/acme_client.dart';
import 'package:accumulate_api/src/client/lite_identity.dart';
import 'package:accumulate_api/src/client/tx_signer.dart';
import 'package:accumulate_api/src/model/api_types.dart';
import 'package:accumulate_api/src/model/receipt.dart';
import 'package:accumulate_api/src/model/receipt_model.dart';
import 'package:accumulate_api/src/payload/add_credits.dart';
import 'package:accumulate_api/src/payload/burn_tokens.dart';
import 'package:accumulate_api/src/payload/create_identity.dart';
import 'package:accumulate_api/src/payload/create_token.dart';
import 'package:accumulate_api/src/payload/create_token_account.dart';
import 'package:accumulate_api/src/payload/issue_tokens.dart';
import 'package:accumulate_api/src/payload/token_recipient.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/transaction.dart' as trans;
import 'package:accumulate_api/src/utils/proof.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:hex/hex.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2"; // "http://127.0.1.1:26660/v2"; //"";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  print(endPoint);
/*
  LiteIdentity lid,lid2;

  lid = LiteIdentity(Ed25519KeypairSigner.generate());
  String mnemonic = lid.mnemonic;
  String privateKey = HEX.encode(lid.secretKey);
  print("new account ${lid.acmeTokenAccount.toString()}");
  print("\n");

  Ed25519KeypairSigner signer = Ed25519KeypairSigner.fromMnemonic(mnemonic);
  lid2 = LiteIdentity(signer);
  print("import account mnemonic ${lid2.acmeTokenAccount}");
  print("\n");

  Uint8List secretKey = HEX.decode(privateKey).asUint8List();
  Ed25519Keypair ed25519keypair = Ed25519Keypair.fromSecretKey(secretKey);
  Ed25519KeypairSigner ed25519keypairSigner =
  Ed25519KeypairSigner(ed25519keypair);

  lid2 = LiteIdentity(ed25519keypairSigner);

  print("import account private key ${lid2.acmeTokenAccount}");
  print("\n");
*/
  testFeatures();
}

void testFeatures() async {
  int waitTimeInSeconds = 11;

  LiteIdentity lid;
  String identityUrl;
  TxSigner identityKeyPageTxSigner;

  final oracle = await client.valueFromOracle();

  lid = LiteIdentity(Ed25519KeypairSigner.generate());

  print("new account ${lid.acmeTokenAccount.toString()}");
  print("\n");

  String txId = "";
  dynamic res;

  for (int i = 0; i <= 2; i++) {
    dynamic res = await client.faucet(lid.acmeTokenAccount);
    print("faucet call: #$i");
    txId = res["result"]["txid"];
    print("    txId: $txId");
    sleep(Duration(seconds: 10));
  }

  res = await client.faucet(lid.acmeTokenAccount);
  txId = res["result"]["txid"];
  print("faucet txId $txId");

  sleep(Duration(seconds: 50));
  print("\n");
  res = await client.queryUrl(lid.url);
  print(res);

  print("\n");
  res = await client.queryUrl(lid.acmeTokenAccount);
  print(res);
  print("\n");

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

  identityUrl = "acc://adi-cosmonaut-1-${DateTime.now().millisecondsSinceEpoch}.acme";
  final identitySigner = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/book0";

  // Create identity /////////////////////////

  CreateIdentityParam createIdentity = CreateIdentityParam();
  createIdentity.url = identityUrl;
  createIdentity.keyHash = identitySigner.publicKeyHash();
  createIdentity.keyBookUrl = bookUrl;

  res = await client.createIdentity(lid.url, createIdentity, lid);
  txId = res["result"]["txid"];
  print("createIdentity txId $txId");

  sleep(Duration(seconds: waitTimeInSeconds));

  ////////////////////////////////////////
  //Send Token To ADI acc
  var recipient = LiteIdentity(Ed25519KeypairSigner.generate()).acmeTokenAccount;
  int amount = 1;

  TokenRecipientParam tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = identityUrl;
  tokenRecipientParam.amount = (amount.toDouble() * 100000000).toInt();

  SendTokensParam sendTokensParam = SendTokensParam();
  sendTokensParam.to = [tokenRecipientParam];
  sendTokensParam.memo = "Send Tokens Memo";
  sendTokensParam.metadata = utf8.encode("METADATA: 0x2E3").asUint8List();

  res = await client.sendTokens(lid.acmeTokenAccount, sendTokensParam, lid);

  txId = res["result"]["txid"];
  print("Send Token $txId");

  sleep(Duration(seconds: waitTimeInSeconds));
  res = await client.queryTx(txId);

  //await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
  // print("transaction complete");

  //res = await client.queryUrl(identityUrl);

  final keyPageUrl = bookUrl + "/1";

  creditAmount = 90000 * 10;

  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $keyPageUrl txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  final tokenUrl = identityUrl + "/cosmos";
  CreateTokenParam createTokenParam = CreateTokenParam();
  createTokenParam.url = tokenUrl;
  createTokenParam.symbol = "ATOM";
  createTokenParam.precision = 8;
  //createTokenParam.supplyLimit = 100000;

  identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);

  res = await client.createToken(identityUrl, createTokenParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("CustomToken txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  recipient = LiteIdentity(Ed25519KeypairSigner.generate()).url.append(tokenUrl);
  print("recipient $recipient");
  amount = 123 * 10 ^ 12;
  IssueTokensParam issueTokensParam = IssueTokensParam();
  tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = recipient;
  tokenRecipientParam.amount = amount;
  issueTokensParam.to = [tokenRecipientParam];

  res = await client.issueTokens(tokenUrl, issueTokensParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("issueTokens txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

/*  BurnTokensParam burnTokensParam = BurnTokensParam();
  burnTokensParam.amount = 100;

  res = await client.burnTokens(lid.acmeTokenAccount, burnTokensParam, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("burnTokens txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));*/

  /*
  AccountAuthOperation accountAuthOperation = AccountAuthOperation();
  accountAuthOperation.authority = identityKeyPageTxSigner.url;
  accountAuthOperation.type = AccountAuthOperationType.Disable;

  UpdateAccountAuthParam updateAccountAuthParam = UpdateAccountAuthParam();
  updateAccountAuthParam.operations = [accountAuthOperation];

  res  = await client.updateAccountAuth(identityKeyPageTxSigner.url, updateAccountAuthParam, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("updateAccountAuth txId $txId");

  sleep(Duration(seconds: waitTimeInSeconds));
*/

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
  sleep(Duration(seconds: waitTimeInSeconds));

  txId = res["result"]["txid"];
  print("Create token account txId $txId");

*/

  /*
  final page1Signer = Ed25519KeypairSigner.generate();
  final newKeyBookUrl = identityUrl + "/" + "${DateTime.now().millisecondsSinceEpoch}";
  CreateKeyBookParam createKeyBookParam = CreateKeyBookParam();
  createKeyBookParam.url = newKeyBookUrl;
  createKeyBookParam.publicKeyHash = page1Signer.publicKeyHash();


  res = await client.createKeyBook(identityUrl, createKeyBookParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("Create keybook txId $txId");
  //await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
  sleep(Duration(seconds: waitTimeInSeconds));

  final page1Url = newKeyBookUrl + "/1";

  creditAmount = 20000;
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = page1Url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res  = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $page1Url txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  var keyPage1TxSigner = TxSigner(page1Url, page1Signer);
  var version = await client.querySignerVersion(keyPage1TxSigner,keyPage1TxSigner.publicKeyHash);

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
  sleep(Duration(seconds: 60));



  version = await client.querySignerVersion(keyPage1TxSigner,keyPage1TxSigner.publicKeyHash);
  keyPage1TxSigner = TxSigner.withNewVersion(keyPage1TxSigner, version);
  var page2Signer = Ed25519KeypairSigner.generate();
  CreateKeyPageParam createKeyPageParam = CreateKeyPageParam();
  createKeyPageParam.keys = [page2Signer.publicKey()];


  res = await client.createKeyPage(newKeyBookUrl, createKeyPageParam, keyPage1TxSigner);
  txId = res["result"]["txid"];
  print("createKeyPage txId $txId");
  sleep(Duration(seconds: 60));


  var page2Url = newKeyBookUrl + "/page1";

  // Update allowed
  updateKeyPageParam = UpdateKeyPageParam();
  keyOperation = KeyOperation();
  keyOperation.type = KeyPageOperationType.UpdateAllowed;
  keyOperation.allow = [TransactionType.updateKeyPage];
  updateKeyPageParam.operations = [keyOperation];

  res = await client.updateKeyPage(page2Url, updateKeyPageParam, keyPage1TxSigner);
  txId = res["result"]["txid"];
  print("updateKeyPage $page2Url txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  creditAmount = 20000;
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = page2Url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res  = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $page2Url txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
*/

  // Create data account
  // final dataAccountUrl = identityUrl + "/test-data";
  // print("dataAccountUrl $dataAccountUrl");
  // CreateDataAccountParam createDataAccountParam = CreateDataAccountParam();
  // createDataAccountParam.url = dataAccountUrl;
  // createDataAccountParam.scratch = false;
  //
  //
  // res = await client.createDataAccount(
  //     identityUrl,
  //     createDataAccountParam,
  //     identityKeyPageTxSigner
  // );
  //
  // txId = res["result"]["txid"];
  // print("Create data account $txId");
  // await client.waitOnTx(DateTime
  //     .now()
  //     .millisecondsSinceEpoch, txId);
  //
  // //res = await client.queryUrl(dataAccountUrl);
  //
  // sleep(Duration(seconds: 60));
  //
  // // Write data
  // WriteDataParam writeDataParam = WriteDataParam();
  //
  // writeDataParam.data = [utf8.encode("test123").asUint8List()];
  //
  //
  // res = await client.writeData(dataAccountUrl, writeDataParam, identityKeyPageTxSigner);
  // txId = res["result"]["txid"];
  // print("Data write $txId");
  // await client.waitOnTx(DateTime
  //     .now()
  //     .millisecondsSinceEpoch, txId);
  //
  // res = await client.queryData(dataAccountUrl);
  // print("Data account write $res");
  //
  // sleep(Duration(seconds: 60));
  //

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Assemble Prood of Token Existence

  var proof = await constructIssuerProof(client, tokenUrl);
  var receiptFinal = proof.value1;
  var body = proof.value2;

  var tokenAccountUrl = identityUrl + "/acc-${createTokenParam.symbol.toLowerCase()}";

  TokenIssuerProofParam tokenIssuerProofParam1 = TokenIssuerProofParam();
  tokenIssuerProofParam1.receipt = receiptFinal;
  tokenIssuerProofParam1.transaction = body;

  CreateTokenAccountParam createTokenAccountParam1 = CreateTokenAccountParam();
  createTokenAccountParam1.url = tokenAccountUrl;
  createTokenAccountParam1.tokenUrl = tokenUrl;
  createTokenAccountParam1.proof = tokenIssuerProofParam1;

  res = await client.createTokenAccount(identityUrl, createTokenAccountParam1, identityKeyPageTxSigner);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////

  var lid2 = LiteIdentity(Ed25519KeypairSigner.generate());
  res = await client.faucet(lid2.acmeTokenAccount);
  res = await client.faucet(lid2.acmeTokenAccount);
  res = await client.faucet(lid2.acmeTokenAccount);

  sleep(Duration(seconds: waitTimeInSeconds));

  creditAmount = 50000 * 10;
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid2.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;
  print(addCreditsParam.amount);
  res = await client.addCredits(lid2.acmeTokenAccount, addCreditsParam, lid2);
  print("addCredits ANOTHER $res");

  sleep(Duration(seconds: waitTimeInSeconds));

  //////////////////////////////////////////////////////////////////////////////////////

  var anotherIdentityUrl = "acc://adi-cosmonaut-2-${DateTime.now().millisecondsSinceEpoch}.acme";
  final keyForAnotherAdi = Ed25519KeypairSigner.generate();
  var idk1 = keyForAnotherAdi.publicKey();
  var idk2 = HEX.encode(keyForAnotherAdi.publicKeyHash());

  // Create identity
  CreateIdentityParam createIdentity2 = CreateIdentityParam();
  createIdentity2.url = anotherIdentityUrl;
  createIdentity2.keyHash = keyForAnotherAdi.publicKeyHash();
  createIdentity2.keyBookUrl = anotherIdentityUrl + "/book0";

  res = await client.createIdentity(lid2.url, createIdentity2, lid2);
  txId = res["result"]["txid"];

  print("////// CREATE IDENTITY txId $txId //////////////////////////////////");
  sleep(Duration(seconds: waitTimeInSeconds));

  var identityKeyPageTxSigner2 = TxSigner(anotherIdentityUrl + "/book0/1", keyForAnotherAdi);

  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = anotherIdentityUrl + "/book0/1";
  addCreditsParam.amount = (100000 * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res = await client.addCredits(lid2.acmeTokenAccount, addCreditsParam, lid2);
  txId = res["result"]["txid"];
  print("Add credits to page $anotherIdentityUrl/book0/1 txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  ////////////////////////////////////////////

  CreateTokenAccountParam createTokenAccountParamAcc = CreateTokenAccountParam();
  createTokenAccountParamAcc.url = anotherIdentityUrl + "/acc-acme";
  createTokenAccountParamAcc.tokenUrl = "acc://acme";

  TxSigner sgnr = TxSigner("$anotherIdentityUrl/book0/1", keyForAnotherAdi);
  res = await client.createTokenAccount(anotherIdentityUrl, createTokenAccountParamAcc, sgnr);
  txId = res["result"]["txid"];

  /// Make version signer
  ///
  print("==== Construct Versioned Signer");
  var version = await client.querySignerVersion(identityKeyPageTxSigner2, keyForAnotherAdi.publicKeyHash());
  sleep(Duration(seconds: 4));
  var identityKeyPageTxSigner2WithVersion = TxSigner.withNewVersion(identityKeyPageTxSigner2, version);

  // Create a token account for the TEST token
  var tokenAccountUrlNew =
      anotherIdentityUrl + "/acc-${createTokenParam.symbol.toLowerCase()}"; //${DateTime.now().millisecondsSinceEpoch}";

  TokenIssuerProofParam tokenIssuerProofParam = TokenIssuerProofParam();
  tokenIssuerProofParam.receipt = receiptFinal;
  tokenIssuerProofParam.transaction = body;

  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrlNew;
  createTokenAccountParam.tokenUrl = tokenUrl;
  createTokenAccountParam.proof = tokenIssuerProofParam;
  createTokenAccountParam.authorities = [AccURL("$identityUrl/book0"), AccURL("$anotherIdentityUrl/book0")];

  print("==== ATTEMPT TO CREATE TOKEN ACCOUNT ============================================");

  // check this TxSigner(keyPageUrl, keyForAdi)
  // TxSigner(anotherIdentityUrl, keyForAnotherAdi)
  res =
      await client.createTokenAccount(anotherIdentityUrl, createTokenAccountParam, identityKeyPageTxSigner2WithVersion);

  txId = res["result"]["txid"];
  print("Create Custom Token Account $txId");
  sleep(Duration(seconds: 20));

  try {
    res = await client.queryUrl(tokenAccountUrl);
  } catch (e) {
    e.toString();
  }
}
