import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:accumulate_api6/accumulate_api6.dart';
import 'package:accumulate_api6/src/acme_client.dart';
import 'package:accumulate_api6/src/api_types.dart';
import 'package:accumulate_api6/src/lite_identity.dart';
import 'package:accumulate_api6/src/payload/add_credits.dart';
import 'package:accumulate_api6/src/payload/create_identity.dart';
import 'package:accumulate_api6/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api6/src/utils/utils.dart';

//final endPoint = "http://127.0.1.1:26660/v2";
final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  testAuthorityActions();
}

void testAuthorityActions() async {

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Re-Usable Variable
  String txId = "";
  dynamic res;
  int waitTimeInSeconds = 60;
  String identityUrl, identityUrl_2;
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
  addCreditsParam.memo = "Cosmos MEMO";
  addCreditsParam.metadata = utf8.encode("Cosmos METADATA").asUint8List();
  print(addCreditsParam.amount);

  // execute
  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("addCredits res $res");

  txId = res["result"]["txid"];
  print("addCredits txId $txId");
  sleep(Duration(seconds: 10));
  res = await client.queryTx(txId);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // CREATE ADI #1

  identityUrl = "acc://adi-cosmonaut-${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}.acme";
  final keyForAdi = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/cosm-book";

  CreateIdentityParam createIdentity = CreateIdentityParam();
  createIdentity.url = identityUrl;
  createIdentity.keyHash = keyForAdi.publicKeyHash();
  createIdentity.keyBookUrl = bookUrl;

  print("======== ADI CREATE =============================");
  res = await client.createIdentity(lid.url, createIdentity, lid);

  txId = res["result"]["txid"];
  print("create ADI call:\n     tx: $txId ");

  sleep(Duration(seconds: 10));

  print("======== ADI INFO =============================");
  QueryPagination qp = QueryPagination();
  qp.start = 0;
  qp.count = 20;

  res = await client.queryDirectory(identityUrl, qp, null); // NB: now returns only ADI and KeyBook, no keypage
  sleep(Duration(seconds: 2));
  print(res);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ADD SIGNER FOR ADI #1

  final keyPageUrl_for_ADI1 = bookUrl + "/1";
  TxSigner identityKeyPageTxSigner = TxSigner(keyPageUrl_for_ADI1, keyForAdi);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ADD CREDITS FOR ADI #1 DEFAULT KEYPAGE

  creditAmount = 90000 * 10;
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl_for_ADI1;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $keyPageUrl_for_ADI1 txId $txId");
  sleep(Duration(seconds: 10));
  print(res);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // CREATE NEW KEYBOOK FOR ADI1

  final keyForNewBook = Ed25519KeypairSigner.generate();

  final newKeyBookUrl = identityUrl + "/newBook";
  CreateKeyBookParam createKeyBookParam = CreateKeyBookParam();
  createKeyBookParam.url = newKeyBookUrl;
  createKeyBookParam.publicKeyHash = keyForNewBook.publicKeyHash();

  res = await client.createKeyBook(identityUrl, createKeyBookParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("Create keybook txId $txId");

  sleep(Duration(seconds: 2));

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ADD LOCAL AUTHORITY (ADI2 BOOK to ADI1)

  UpdateAccountAuthOperation accountAuthOperation = UpdateAccountAuthOperation();
  accountAuthOperation.authority = newKeyBookUrl;
  accountAuthOperation.type = UpdateAccountAuthActionType.AddAuthority;

  UpdateAccountAuthParam updateAccountAuthParam = UpdateAccountAuthParam();
  updateAccountAuthParam.operations = [accountAuthOperation];

  //res = await client.updateAccountAuth(bookUrl, updateAccountAuthParam, identityKeyPageTxSigner);
  res = await client.updateAccountAuth(identityUrl, updateAccountAuthParam, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("updateAccountAuth txId: $txId");

  sleep(Duration(seconds: 2));


  /////////////////////////////////////////////////////////////////////////////////////////////////
  // CREATE ADI #2

  identityUrl_2 = "acc://adi-astronaut-${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}.acme";
  final keyForAdi_2 = Ed25519KeypairSigner.generate();
  final defaultBookForAdi_2 = identityUrl_2 + "/astro-book";

  CreateIdentityParam createIdentity2 = CreateIdentityParam();
  createIdentity2.url = identityUrl_2;
  createIdentity2.keyHash = keyForAdi_2.publicKeyHash();
  createIdentity2.keyBookUrl = defaultBookForAdi_2;

  print("======== ADI CREATE =============================");
  res = await client.createIdentity(lid.url, createIdentity2, lid);

  txId = res["result"]["txid"];
  print("create ADI call:\n     tx: $txId ");

  sleep(Duration(seconds: 10));

  print("======== ADI INFO =============================");
  QueryPagination qp2 = QueryPagination();
  qp2.start = 0;
  qp2.count = 20;

  res = await client.queryDirectory(identityUrl_2, qp2, null); // NB: now returns only ADI and KeyBook, no keypage
  sleep(Duration(seconds: 2));
  print(res);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ADD REMOTE AUTHORITY (ADI2 BOOK to ADI1)

  UpdateAccountAuthOperation accountAuthOperationR1 = UpdateAccountAuthOperation();
  accountAuthOperationR1.authority = defaultBookForAdi_2;
  accountAuthOperationR1.type = UpdateAccountAuthActionType.AddAuthority;

  UpdateAccountAuthParam updateAccountAuthParamR1 = UpdateAccountAuthParam();
  updateAccountAuthParamR1.operations = [accountAuthOperationR1];

  res = await client.updateAccountAuth(bookUrl, updateAccountAuthParamR1, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("updateAccountAuth txId: $txId");

  sleep(Duration(seconds: 10));

  ///////////////////////////////////////////////////////////////////////////////////////////////
  // DISABLE AUTHORITY

  UpdateAccountAuthOperation accountAuthOperation2 = UpdateAccountAuthOperation();
  accountAuthOperation2.authority = defaultBookForAdi_2;
  accountAuthOperation2.type = UpdateAccountAuthActionType.Disable;

  UpdateAccountAuthParam updateAccountAuthParam2 = UpdateAccountAuthParam();
  updateAccountAuthParam2.operations = [accountAuthOperation2];

  res = await client.updateAccountAuth(identityKeyPageTxSigner.url, updateAccountAuthParam2, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("updateAccountAuth txId $txId");

  sleep(Duration(seconds: 10));

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ENABLE AUTHORITY

  UpdateAccountAuthOperation accountAuthOperation3 = UpdateAccountAuthOperation();
  accountAuthOperation3.authority = defaultBookForAdi_2;
  accountAuthOperation3.type = UpdateAccountAuthActionType.Enable;

  UpdateAccountAuthParam updateAccountAuthParam3 = UpdateAccountAuthParam();
  updateAccountAuthParam3.operations = [accountAuthOperation3];

  res = await client.updateAccountAuth(identityKeyPageTxSigner.url, updateAccountAuthParam3, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("updateAccountAuth txId $txId");

  sleep(Duration(seconds: 10));


  /////////////////////////////////////////////////////////////////////////////////////////////////
  // REMOVE/DELETE AUTHORITY

  UpdateAccountAuthOperation accountAuthOperation4 = UpdateAccountAuthOperation();
  accountAuthOperation4.authority = defaultBookForAdi_2;
  accountAuthOperation4.type = UpdateAccountAuthActionType.RemoveAuthority;

  UpdateAccountAuthParam updateAccountAuthParam4 = UpdateAccountAuthParam();
  updateAccountAuthParam4.operations = [accountAuthOperation4];

  //res = await client.updateAccountAuth(identityKeyPageTxSigner.url, updateAccountAuthParam4, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("updateAccountAuth txId $txId");

  sleep(Duration(seconds: 10));


}
