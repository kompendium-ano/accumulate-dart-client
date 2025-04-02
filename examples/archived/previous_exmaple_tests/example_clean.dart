// example\example_clean.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:accumulate_api/accumulate_api.dart';
import 'package:accumulate_api/src/model/receipt_model.dart' as ReceiptM;
import 'package:accumulate_api/src/transaction.dart' as trans;
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);
int delayBeforePrintSeconds =
    300; // Set this variable to adjust the delay time.

Future<void> main() async {
  print(endPoint);
  await testFeatures();
}

Future<void> delayBeforePrint() async {
  await Future.delayed(Duration(seconds: delayBeforePrintSeconds));
}

Future<void> testFeatures() async {
  int waitTimeInSeconds = 240;

  LiteIdentity lid;
  LiteIdentity secondLid;
  String identityUrl;
  TxSigner identityKeyPageTxSigner;

  final oracle = await client.valueFromOracle();

  lid = LiteIdentity(Ed25519KeypairSigner.generate());

  print("new account URL: ${lid.acmeTokenAccount.toString()}");
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
  ]);
  dynamic res = await client.faucet(lid.acmeTokenAccount);
  print("Faucet response: $res\n");
  sleep(Duration(seconds: 30));
  String txId = res["result"]["txid"];
  print("Faucet transaction ID: $txId");

  await delayBeforePrint();
  res = await client.queryUrl(lid.url);
  print("Query URL response for lid.url: $res");
  res = await client.queryUrl(lid.acmeTokenAccount);
  print("Query URL response for lid.acmeTokenAccount: $res\n");

  // Before executing the addCredits transaction, log the details
  int creditAmount = 50000 * 10;
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;
  addCreditsParam.memo = "Add credits memo test";
  addCreditsParam.metadata =
      utf8.encode("Add credits metadata test").asUint8List();

  print("Preparing to add credits:");
  print("Recipient URL: ${addCreditsParam.recipient}");
  print("Credit Amount: ${addCreditsParam.amount}");
  print("Oracle Value: ${addCreditsParam.oracle}");
  print("Memo: ${addCreditsParam.memo}");
  print(
      "Metadata: ${addCreditsParam.metadata != null ? HEX.encode(addCreditsParam.metadata!) : 'None'}");
  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);

  await delayBeforePrint(); // Wait before printing
  // After adding credits, log the response
  print("addCredits transaction response: $res");

  // Extract and log transaction ID from the response if available
  if (res != null && res["result"] != null && res["result"]["txid"] != null) {
    String addCreditsTxId = res["result"]["txid"];
    print("addCredits Transaction ID: $addCreditsTxId");
  }

  // Log the transaction ID from the addCredits response
  txId = res["result"]["txid"];
  print("addCredits Transaction ID: $txId");
  await delayBeforePrint(); // Ensure the network has processed the previous transaction

  // Query the transaction to confirm it's been processed and log the response
  res = await client.queryTx(txId);
  print("Query Transaction Response for addCredits: $res");

  await delayBeforePrint(); // Prepare for the next operation

  // Generate the ADI URL and the signer for the new identity
  identityUrl = "acc://adi-jason-${DateTime.now().millisecondsSinceEpoch}.acme";
  final identitySigner = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/jason-book";
  CreateIdentityParam createIdentity = CreateIdentityParam();

  createIdentity.url = identityUrl;
  createIdentity.keyHash = identitySigner.publicKeyHash();
  createIdentity.keyBookUrl = bookUrl;

  // Before creating the identity, log the details
  print("Preparing to create identity:");
  print("ADI URL: $identityUrl");
  print("Key Hash: ${HEX.encode(identitySigner.publicKeyHash())}");
  print("Key Book URL: $bookUrl");

  // Create the identity and log the response
  res = await client.createIdentity(lid.url, createIdentity, lid);
  txId = res["result"]["txid"];
  await delayBeforePrint(); // Allow time for Create Identity to finish
  print("Create identity transaction response: $res");
  print("Create identity transaction ID: $txId");

  ////////////////////////////////////////
  // Send Token To ADI account

  final keyPageUrl = bookUrl + "/1";

  creditAmount = 90000 * 10;

  await delayBeforePrint(); // Wait before proceeding

  // Log the attempt to add credits to a key page
  print("Attempting to add credits to key page at URL: $keyPageUrl");
  print("Credits amount: $creditAmount");
  print("Oracle price used: $oracle");

  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;
  ;

  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  await delayBeforePrint(); // Wait before printing
  print("Add credits response: $res");
  print("Add credits transaction ID: $txId");

  await delayBeforePrint(); // Ensure network processing of the addCredits transaction

  final tokenUrl = identityUrl + "/JKGok";
  CreateTokenParam createTokenParam = CreateTokenParam();
  createTokenParam.url = tokenUrl;
  createTokenParam.symbol = "JKG";
  createTokenParam.precision = 0;

  await delayBeforePrint(); // Ensure network processing of the custom token transaction

  // Preparing to create a custom token
  print("Preparing to create custom token at URL: $tokenUrl");
  print(
      "Token symbol: ${createTokenParam.symbol}, Precision: ${createTokenParam.precision}");

  identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);
  await delayBeforePrint(); // Ensure network processing of the custom token transaction

  // Before creating the token, log the key page URL and signer details
  print("Key Page URL for token creation: $keyPageUrl");
  print("Signer Public Key: ${HEX.encode(identityKeyPageTxSigner.publicKey)}");
  print(
      "Signer Public Key Hash: ${HEX.encode(identityKeyPageTxSigner.publicKeyHash)}");
  print("Signer Version: ${identityKeyPageTxSigner.version}");

  await delayBeforePrint(); // Wait for network processing

  res = await client.createToken(
      identityUrl, createTokenParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];

  await delayBeforePrint(); // Wait for network processing

  print("CreateToken response: $res");
  print("CreateToken transaction ID: $txId");

  await delayBeforePrint(); // Wait before printing

  var txn0url = '${tokenUrl}#txn/0';

  // Querying the newly created token
  print("Querying newly created token at URL: $txn0url");
  QueryOptions queryOptions = QueryOptions();
  queryOptions.prove = true;
  res = await client.queryUrl(txn0url, queryOptions);
  await delayBeforePrint(); // Wait before printing
  print("\n");
  print("Query Token Response: $txn0url $res");

  ReceiptM.ReceiptModel receiptModel = ReceiptM.ReceiptModel.fromMap(res);
  List<ReceiptM.Receipts> receipts = receiptModel.result!.receipts!;
  ReceiptM.RcpTransaction transaction = receiptModel.result!.transaction!;
  if (receiptModel.result!.receipts!.length == 0) {
    print("No proof found");
    return;
  }
  ReceiptM.Proof proof2 = receipts[0].proof!;

  if (transaction.body!.type != "createToken") {
    print(
        'Expected first transaction of ${tokenUrl} to be createToken but got ${transaction.body!.type}');
  }

  trans.HeaderOptions headerOptions = trans.HeaderOptions();
  headerOptions.initiator =
      HEX.decode(transaction.header!.initiator!).asUint8List();
  dynamic header = trans.Header(transaction.header!.principal!, headerOptions);
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
  receipt.end = body.hash();
  receipt.endIndex = 0;
  receipt.anchor = txn.hash().asUint8List();

  ReceiptEntry entry = ReceiptEntry();
  entry.hash = sha256.convert(header.marshalBinary()).bytes as Uint8List?;
  entry.right = false;
  receipt.entries = [entry];

  Receipt proof1 = receipt;

  print("Print 5 - anchorRes ${proof2.anchor!}");
  // Prove the BVN anchor
  dynamic anchorRes = await client.queryAnchor(proof2.anchor!);
  ReceiptM.Proof proof3 =
      ReceiptM.Proof.fromMap(anchorRes["result"]["receipt"]["proof"]);

  Receipt receipt2 = Receipt();
  receipt2.start = hexStringtoUint8List(proof2.start!);
  receipt2.startIndex = proof2.startIndex;
  receipt2.end = hexStringtoUint8List(proof2.end!);
  receipt2.endIndex = proof2.endIndex;
  receipt2.anchor = hexStringtoUint8List(proof2.anchor!);
  List<ReceiptEntry> entries2 = [];
  for (ReceiptM.Entry entry in proof2.entries!) {
    ReceiptEntry receiptEntry2 = ReceiptEntry();
    receiptEntry2.right = entry.right;
    receiptEntry2.hash = hexStringtoUint8List(entry.hash!);
    entries2.add(receiptEntry2);
  }
  receipt2.entries = entries2;

  Receipt receipt3 = Receipt();
  receipt3.start = hexStringtoUint8List(proof3.start!);
  receipt3.startIndex = proof3.startIndex;
  receipt3.end = hexStringtoUint8List(proof3.end!);
  receipt3.endIndex = proof3.endIndex;
  receipt3.anchor = hexStringtoUint8List(proof3.anchor!);
  List<ReceiptEntry> entries3 = [];
  for (ReceiptM.Entry entry in proof3.entries!) {
    ReceiptEntry receiptEntry3 = ReceiptEntry();
    receiptEntry3.right = entry.right;
    receiptEntry3.hash = hexStringtoUint8List(entry.hash!);
    entries3.add(receiptEntry3);
  }
  receipt3.entries = entries3;

  // Assemble the full proof
  dynamic receiptFinal =
      combineReceipts(combineReceipts(proof1, receipt2), receipt3);

  // Create a token account for the TEST token
  var tokenAccountUrl = identityUrl + "/JasonTokenAcc";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = tokenUrl;
  TokenIssuerProofParam tokenIssuerProofParam = TokenIssuerProofParam();

  tokenIssuerProofParam.receipt = receiptFinal;
  tokenIssuerProofParam.transaction = body;
  createTokenAccountParam.proof = tokenIssuerProofParam;

  res = await client.createTokenAccount(
      identityUrl, createTokenAccountParam, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("Create Custom Token Account $txId");
  await delayBeforePrint(); // Wait before printing

  res = await client.queryUrl(tokenAccountUrl);

  print("Print 6 - DONE");
}

Receipt combineReceipts(Receipt r1, Receipt r2) {
  dynamic anchorStr = ((r1.anchor is Uint8List) || (r1.anchor is List<int>))
      ? HEX.encode(r1.anchor as List<int>)
      : r1.anchor;
  dynamic startStr = ((r2.start is Uint8List) || (r2.start is List<int>))
      ? HEX.encode(r2.start as List<int>)
      : r2.start;

  if (anchorStr != startStr) {
    print(
        "Receipts cannot be combined, anchor ${anchorStr} doesn't match root merkle tree ${startStr}");
  }

  Receipt result = cloneReceipt(r1);
  result.anchor = copyHash(r2.anchor);

  r2.entries.forEach((e) => result.entries.add(copyReceiptEntry(e)));

  return result;
}

Receipt cloneReceipt(Receipt receipt) {
  Receipt newReceipt = Receipt();
  newReceipt.start = copyHash(receipt.start);
  newReceipt.startIndex = receipt.startIndex;
  newReceipt.end = copyHash(receipt.end);
  newReceipt.endIndex = receipt.endIndex;
  newReceipt.anchor = copyHash(receipt.anchor);
  newReceipt.entries = receipt.entries.map(copyReceiptEntry).toList();

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

Uint8List copyHash(dynamic hash) {
  if ((hash is Uint8List)) {
    return hash;
  }

  if ((hash is List<int>)) {
    return hash.asUint8List();
  }
  return utf8.encode(hash).asUint8List();
}
