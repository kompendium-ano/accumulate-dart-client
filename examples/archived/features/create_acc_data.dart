import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:accumulate_api/src/acme_client.dart';
import 'package:accumulate_api/src/model/api_types.dart';
import 'package:accumulate_api/src/client/lite_identity.dart';
import 'package:accumulate_api/src/payload/add_credits.dart';
import 'package:accumulate_api/src/payload/create_data_account.dart';
import 'package:accumulate_api/src/payload/create_identity.dart';
import 'package:accumulate_api/src/payload/write_data.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/client/tx_signer.dart';
import 'package:accumulate_api/src/utils/utils.dart';

//final endPoint = "http://127.0.1.1:26660/v2";
final endPoint = "https://testnet.accumulatenetwork.io/v2/";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  testDataAccountCreation();
}

void testDataAccountCreation() async {
  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Re-Usable Variable
  String txId = "";
  dynamic res;
  int waitTimeInSeconds = 6;
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

  for (int i = 0; i < 2; i++) {
    dynamic res = await client.faucet(lid.acmeTokenAccount);
    sleep(Duration(seconds: 4));
    print("faucet call: #$i");
    txId = res["result"]["txid"];
    print("    txId: $txId");
  }

  // print("\n");
  // res = await client.queryUrl(lid.url);
  // print(res);

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
  sleep(Duration(seconds: waitTimeInSeconds));
  res = await client.queryTx(txId);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Create ADI

  identityUrl =
      "acc://adi-cosmonaut-${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}.acme";
  final keyForAdi = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/cosm-book";

  CreateIdentityParam createIdentity = CreateIdentityParam();
  createIdentity.url = identityUrl;
  createIdentity.keyHash = keyForAdi.publicKeyHash();
  createIdentity.keyBookUrl = bookUrl;

  print("======== CREATE ADI =============================");
  res = await client.createIdentity(lid.url, createIdentity, lid);

  txId = res["result"]["txid"];
  print("create ADI call:\n     tx: $txId ");

  sleep(Duration(seconds: 10));

  print("======== ADI INFO =============================");
  QueryPagination qp = QueryPagination();
  qp.start = 0;
  qp.count = 20;

  res = await client.queryDirectory(identityUrl, qp,
      null); // NB: now returns only ADI and KeyBook, no keypage
  sleep(Duration(seconds: 15));
  print(res);

  print("======== KeyBook INFO =============================");
  res = await client.queryUrl(bookUrl); // NB: but here
  sleep(Duration(seconds: 5));
  print(res);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Add Credits to ADIs KeyPage to allow actions

  print("======== KeyPage CREATE =============================");
  // Protocol Automatically creates keypage with name "1"
  final keyPageUrl = bookUrl + "/1";

  creditAmount = 90000 * 10;
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $keyPageUrl txId $txId");

  sleep(Duration(seconds: 25));
  print(res);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Construct Transactions Signer

  identityKeyPageTxSigner = TxSigner(keyPageUrl, keyForAdi);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Create Data Account

  print("======== DATA ACC CREATE =============================");

  final dataAccountUrl = identityUrl +
      "/data-${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}";
  print("dataAccountUrl $dataAccountUrl");

  CreateDataAccountParam dataAccountParams = CreateDataAccountParam();
  dataAccountParams.url = dataAccountUrl;
  dataAccountParams.scratch = false;

  res = await client.createDataAccount(
      identityUrl, dataAccountParams, identityKeyPageTxSigner);

  txId = res["result"]["txid"];
  print("Create data account $txId");
  sleep(Duration(seconds: 5));

  res = await client.queryUrl(txId);
  sleep(Duration(seconds: 5));
  print(res);

  ///////////////////////////////////////////////////////////////////////////////////////////////
  // Add Data to Data Account

  WriteDataParam writeDataParam = WriteDataParam();
  writeDataParam.data = [
    utf8.encode("source=mobile").asUint8List(),
    utf8.encode("type=delegated").asUint8List(),
    utf8
        .encode("staking account= acc://tetrahedron1.acme/staking")
        .asUint8List(),
    utf8
        .encode(
            "awards=acc://a31d6d7d33a1a2b55fb84e931f98fbf72403ecfef0a453a7/acme")
        .asUint8List(),
    utf8.encode("delegation_to=acc://kompendium.acme/staking").asUint8List(),
    utf8
        .encode(
            "ref_transaction=acc://0f14e6b8ecd40db44e82a965020943be2407a3b94fbc7b542e8cc5e0efa4e11b@staking2.acme/requests")
        .asUint8List()
  ];

  res = await client.writeData(
      dataAccountUrl, writeDataParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("Data write $txId");
  await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

  res = await client.queryData(dataAccountUrl);
  print("Data account write $res");
}
