import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

//import '../lib/src/lite_identity.dart';
import '../lib/src/model/receipt_model.dart';

import '../lib/src/api_types.dart';
import '../lib/src/receipt.dart';

import '../lib/src/tx_types.dart';

import '../lib/src/payload/create_key_page.dart';


import '../lib/src/payload/update_account_auth.dart';

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
import '../lib/src/signing/ed25519_keypair.dart';
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

  int waitTimeInSeconds = 60;

  LiteIdentity lid;
  String identityUrl;
  TxSigner identityKeyPageTxSigner;

  final oracle = await client.valueFromOracle();

  lid = LiteIdentity(Ed25519KeypairSigner.generate());

  print("new account ${lid.acmeTokenAccount.toString()}");
  print("\n");
  await Future.wait([
      client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),
    client.faucet(lid.acmeTokenAccount),
    Future.delayed(const Duration(seconds: 10)),


  ]);
  dynamic res = await client.faucet(lid.acmeTokenAccount);
  print(res);
  print("\n");
  sleep(Duration(seconds: 10));
  String txId = res["result"]["txid"];
  print("faucet txId $txId");

  //bool status = await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
  //print("transaction $status");
 // sleep(Duration(seconds: 60));


  print("\n");
  res = await client.queryUrl(lid.url);
  print(res);

  print("\n");
  res = await client.queryUrl(lid.acmeTokenAccount);
  print(res);
  print("\n");
  int creditAmount = 50000*10;
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;
  addCreditsParam.memo = "Add credits memo test";
  addCreditsParam.metadata = utf8.encode("Add credits metadata test").asUint8List();
print(addCreditsParam.amount);
  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("addCredits res $res");

  txId = res["result"]["txid"];
  print("addCredits txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
  res = await client.queryTx(txId);



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

  sleep(Duration(seconds: waitTimeInSeconds));

  //await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
 // print("transaction complete");

  //res = await client.queryUrl(identityUrl);


  final keyPageUrl = bookUrl + "/1";

  creditAmount = 90000*10;

  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8))~/ oracle;
  addCreditsParam.oracle = oracle;

  res  = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $keyPageUrl txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));


  final tokenUrl = identityUrl + "/JTok";
  CreateTokenParam createTokenParam = CreateTokenParam();
  createTokenParam.url = tokenUrl;
  createTokenParam.symbol = "JT";
  createTokenParam.precision = 0;

  identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);

  res = await client.createToken(identityUrl, createTokenParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("CustomToken txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
/*
  var recipient = LiteIdentity(Ed25519KeypairSigner.generate()).url.append(tokenUrl);
  print("recipient $recipient");
  var amount = 123;
  IssueTokensParam issueTokensParam = IssueTokensParam();
  TokenRecipientParam tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = recipient;
  tokenRecipientParam.amount = amount;
  issueTokensParam.to = [tokenRecipientParam];

  res = await client.issueTokens(tokenUrl, issueTokensParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("issueTokens txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));


  BurnTokensParam burnTokensParam = BurnTokensParam();
  burnTokensParam.amount = 100;

  res = await client.burnTokens(lid.acmeTokenAccount, burnTokensParam, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("burnTokens txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
*/

  identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);
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


  var page2Url = newKeyBookUrl + "/jimpage";

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

  /*
  //Send Token
  recipient =
      LiteIdentity(Ed25519KeypairSigner.generate()).acmeTokenAccount;

   amount = 12000;

  SendTokensParam sendTokensParam = SendTokensParam();
  tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = recipient;
  tokenRecipientParam.amount = amount;
  sendTokensParam.to = [tokenRecipientParam];

  res = await client.sendTokens(lid.acmeTokenAccount, sendTokensParam, lid);

  txId = res["result"]["txid"];
  print("Send Token $txId");

  res = await client.queryTx(txId);
sleep(Duration(seconds: 60));*/

/*
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

  sleep(Duration(seconds: 60));*/

/*

  var txn0url = '${tokenUrl}#txn/0';

  QueryOptions queryOptions = QueryOptions();
  queryOptions.prove = true;
  res = await client.queryUrl(txn0url, queryOptions);
  print("\n");
  print("$txn0url $res");

  ReceiptModel receiptModel = ReceiptModel.fromMap(res);
  receiptModel.result.receipts

  // Get a chain proof (from any chain, ends in a BVN anchor)
  if (receiptModel.result!.receipts!.length == 0) {
    print("No proof found");
    return;
  }
  const proof2 = receipts[0].proof;

  // Convert the response to a Transaction
  if (transaction.body.type != "createToken") {
    throw new Error(
    `Expected first transaction of ${issuer} to be createToken but got ${transaction.body.type}`
    );
  }
  const header = new Header(transaction.header.principal, {
    initiator: Buffer.from(transaction.header.initiator, "hex"),
    memo: transaction.header.memo,
    metadata: transaction.header.metadata
        ? Buffer.from(transaction.header.metadata, "hex")
        : undefined,
  });
  const body = new CreateToken(transaction.body);
  const txn = new Transaction(body, header);

  // Prove that the body is part of the transaction
  const proof1: Receipt = {
  start: body.hash(),
  startIndex: 0,
  end: body.hash(),
  endIndex: 0,
  anchor: txn.hash(),
  entries: [
  {
  hash: sha256(header.marshalBinary()),
  right: false,
  },
  ],
  };

  // Prove the BVN anchor
  const anchorRes = await client.queryAnchor(proof2.anchor);
  const proof3 = anchorRes.receipt.proof;

  // Assemble the full proof
  const receipt = combineReceipts(combineReceipts(proof1, proof2), proof3);

  */

/*
  // Create a token account for the TEST token
  var tokenAccountUrl = identityUrl + "/JimTokenAcc";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = tokenUrl;
  TokenIssuerProofParam tokenIssuerProofParam = TokenIssuerProofParam();
  Receipt receipt = Receipt();
  receipt.
  tokenIssuerProofParam.receipt =
  createTokenAccountParam.proof
  const createTokenAccount = {
    url: tokenAccountUrl,
    tokenUrl,
    proof: await constructIssuerProof(client, tokenUrl),
  };
  res = await client.createTokenAccount(identityUrl, createTokenAccount, identityKeyPageTxSigner);

  await client.waitOnTx(res.txid, { timeout: 10_000 });

  res = await client.queryUrl(tokenAccountUrl);
*/

  print("DONE");
}
