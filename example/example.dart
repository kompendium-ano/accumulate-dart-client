import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:accumulate_api6/accumulate_api6.dart';
import 'package:accumulate_api6/src/model/receipt_model.dart' as ReceiptM;
import 'package:accumulate_api6/src/payload/add_credits.dart';
import 'package:accumulate_api6/src/payload/create_identity.dart';
import 'package:accumulate_api6/src/payload/create_token.dart';
import 'package:accumulate_api6/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api6/src/transaction.dart' as trans;
import 'package:accumulate_api6/src/tx_signer.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

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



  var txn0url = '${tokenUrl}#txn/0';

  QueryOptions queryOptions = QueryOptions();
  queryOptions.prove = true;
  res = await client.queryUrl(txn0url, queryOptions);
  print("\n");
  print("$txn0url $res");

  ReceiptM.ReceiptModel receiptModel = ReceiptM.ReceiptModel.fromMap(res);
  List<ReceiptM.Receipts> receipts = receiptModel.result!.receipts!;
  ReceiptM.Transaction transaction = receiptModel.result!.transaction!;
  // Get a chain proof (from any chain, ends in a BVN anchor)
  if (receiptModel.result!.receipts!.length == 0) {
    print("No proof found");
    return;
  }
  ReceiptM.Proof proof2 = receipts[0].proof!;

  // Convert the response to a Transaction
  if (transaction.body!.type != "createToken") {
    print('Expected first transaction of ${tokenUrl} to be createToken but got ${transaction.body!.type}');
  }

  trans.HeaderOptions headerOptions = trans.HeaderOptions();
  headerOptions.initiator = HEX.decode(transaction.header!.initiator!).asUint8List();
  dynamic header = trans.Header(transaction.header!.principal!,headerOptions);
  createTokenParam = CreateTokenParam();
  createTokenParam.url = transaction.body!.url!;
  createTokenParam.symbol = transaction.body!.symbol!;
  createTokenParam.precision = 0;

  CreateToken body = CreateToken(createTokenParam);
  trans.Transaction txn = trans.Transaction(body, header);

  // Prove that the body is part of the transaction
  Receipt receipt = Receipt();
  receipt.start = body.hash();

  receipt.startIndex = 0;
  receipt.end =  body.hash();
  receipt.endIndex= 0;
  receipt.anchor =  txn.hash();

  ReceiptEntry entry = ReceiptEntry();
  entry.hash = sha256.convert(header.marshalBinary()).bytes;
  entry.right = false;

  receipt.entries= [entry];

  Receipt proof1 = receipt;

  print("anchorRes ${proof2.anchor!}");
  // Prove the BVN anchor
  dynamic anchorRes = await client.queryAnchor(proof2.anchor!);
  ReceiptM.Proof proof3 = ReceiptM.Proof.fromMap(anchorRes["result"]["receipt"]["proof"]);

  Receipt receipt2 = Receipt();
  receipt2.start = proof2.start;
  receipt2.startIndex = proof2.startIndex;
  receipt2.end = proof2.end;
  receipt2.endIndex = proof2.endIndex;
  receipt2.anchor = proof2.anchor;
  List<ReceiptEntry> entries2 = [];
  for(ReceiptM.Entry entry in proof2.entries!){
    ReceiptEntry receiptEntry2 = ReceiptEntry();
    receiptEntry2.right = entry.right;
    receiptEntry2.hash = entry.hash;
  }
  receipt2.entries = entries2;


  Receipt receipt3 = Receipt();
  receipt3.start = proof3.start;
  receipt3.startIndex = proof3.startIndex;
  receipt3.end = proof3.end;
  receipt3.endIndex = proof3.endIndex;
  receipt3.anchor = proof3.anchor;
  List<ReceiptEntry> entries3 = [];
  for(ReceiptM.Entry entry in proof3.entries!){
    ReceiptEntry receiptEntry2 = ReceiptEntry();
    receiptEntry2.right = entry.right;
    receiptEntry2.hash = entry.hash;
  }
  receipt3.entries = entries3;

  // Assemble the full proof
  dynamic receiptFinal = combineReceipts(combineReceipts(proof1, receipt2), receipt3);


  // Create a token account for the TEST token
  var tokenAccountUrl = identityUrl + "/JimTokenAcc";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = tokenUrl;
  TokenIssuerProofParam tokenIssuerProofParam = TokenIssuerProofParam();


  tokenIssuerProofParam.receipt = receiptFinal;
  tokenIssuerProofParam.transaction = body;
  createTokenAccountParam.proof = tokenIssuerProofParam;

  res = await client.createTokenAccount(identityUrl, createTokenAccountParam, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("Create Custom Token Account $txId");
  sleep(Duration(seconds: 60));

  res = await client.queryUrl(tokenAccountUrl);


  print("DONE");
}

Receipt combineReceipts(Receipt r1,Receipt r2){

  dynamic anchorStr = ((r1.anchor is Uint8List) || (r1.anchor is List<int>)) ? HEX.encode(r1.anchor) : r1.anchor;
  dynamic startStr =
    ((r2.start is Uint8List) || (r2.start is List<int>)) ? HEX.encode(r2.start) : r2.start;

if (anchorStr != startStr) {
  print("Receipts cannot be combined, anchor ${anchorStr} doesn't match root merkle tree ${startStr}");
  }

  Receipt result = cloneReceipt(r1);
  result.anchor = copyHash(r2.anchor);

  r2.entries.forEach((e) => result.entries.add(copyReceiptEntry(e)));

  return result;
}

Receipt cloneReceipt(Receipt receipt){
  Receipt newReceipt = Receipt();
  newReceipt.start = copyHash(receipt.start);
  newReceipt.startIndex = receipt.startIndex;
  newReceipt.end = copyHash(receipt.end);
  newReceipt.endIndex =  receipt.endIndex;
  newReceipt.anchor =  copyHash(receipt.anchor);
  newReceipt.entries =  receipt.entries.map(copyReceiptEntry).toList();

return newReceipt;
}

ReceiptEntry copyReceiptEntry(ReceiptEntry re) {
  ReceiptEntry result = ReceiptEntry();
  result.hash = copyHash(re.hash);

if (re.right != null && re.right!) {
   result.right = true;
   }
return result;
}

Uint8List copyHash(dynamic hash){
  if((hash is Uint8List)){
    return hash;

  }

  if((hash is List<int>)){
    return hash.asUint8List();

  }
return utf8.encode(hash).asUint8List();
}

