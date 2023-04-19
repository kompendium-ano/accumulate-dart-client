import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:accumulate_api/src/acme_client.dart';
import 'package:accumulate_api/src/model/api_types.dart';
import 'package:accumulate_api/src/client/lite_identity.dart';
import 'package:accumulate_api/src/payload/add_credits.dart';
import 'package:accumulate_api/src/payload/create_identity.dart';
import 'package:accumulate_api/src/payload/create_token_account.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/client/tx_signer.dart';
import 'package:accumulate_api/src/utils/utils.dart';

//final endPoint = "http://127.0.1.1:26660/v2";
final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  testAdiCreation();
}

void testAdiCreation() async {
  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Re-Usable Variable
  String txId = "";
  dynamic res;
  int waitTimeInSeconds = 60;
  String identityUrl;
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
  int creditAmount = 50000 * 10; // web shows 10 to 10,000 credits which is wrong conversion
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

  sleep(Duration(seconds: 150));
  res = await client.queryTx(txId);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Create ADI

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

  sleep(Duration(seconds: 60));

  print("======== ADI INFO =============================");
  QueryPagination qp = QueryPagination();
  qp.start = 0;
  qp.count = 20;

  res = await client.queryDirectory(identityUrl, qp, null); // NB: now returns only ADI and KeyBook, no keypage
  sleep(Duration(seconds: 10));
  print(res);

  /// Add Credits to a page
  ///
  AddCreditsParam addCreditsParamForPage = AddCreditsParam();
  addCreditsParamForPage.recipient = bookUrl+"/1"; // this is default keypage
  addCreditsParamForPage.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParamForPage.oracle = oracle;
  print(addCreditsParam.amount);

  // execute
  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  sleep(Duration(seconds: 10));
  print("addCredits res $res");

  print("======== ADI TOKEN ACCOUNT CREATE =============================");

  final tokenAccountUrl = identityUrl + "/acc-acme";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = "acc://acme";

  TxSigner identityKeyPageTxSigner = TxSigner(bookUrl+"/1", keyForAdi);

  res = await client.createTokenAccount(identityUrl, createTokenAccountParam, identityKeyPageTxSigner);
  sleep(Duration(seconds: waitTimeInSeconds));

  txId = res["result"]["txid"];
  print("Create token account txId $txId");

}
