import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:accumulate_api/src/acme_client.dart';
import 'package:accumulate_api/src/model/api_types.dart';
import 'package:accumulate_api/src/client/lite_identity.dart';
import 'package:accumulate_api/src/payload/add_credits.dart';
import 'package:accumulate_api/src/payload/create_identity.dart';
import 'package:accumulate_api/src/payload/create_token.dart';
import 'package:accumulate_api/src/payload/create_token_account.dart';
import 'package:accumulate_api/src/payload/issue_tokens.dart';
import 'package:accumulate_api/src/payload/token_recipient.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/client/tx_signer.dart';
import 'package:accumulate_api/src/utils/utils.dart';

//final endPoint = "http://127.0.1.1:26660/v2";
final endPoint = "https://testnet.accumulatenetwork.io/v2/";
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
  TxSigner identityKeyPageTxSigner;

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
  sleep(Duration(seconds: waitTimeInSeconds));
  res = await client.queryTx(txId);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Create ADI

  identityUrl =
      "acc://adi-cosmonaut-${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}.acme";
  final keyForAdi = Ed25519KeypairSigner.generate();
  final bookUrl = identityUrl + "/cosm-book";
  final keyPageUrl = bookUrl + "/1";

  CreateIdentityParam createIdentity = CreateIdentityParam();
  createIdentity.url = identityUrl;
  createIdentity.keyHash = keyForAdi.publicKeyHash();
  createIdentity.keyBookUrl = bookUrl;

  print("======== ADI CREATE =============================");
  res = await client.createIdentity(lid.url, createIdentity, lid);

  txId = res["result"]["txid"];
  print("create ADI call:\n     tx: $txId ");

  sleep(Duration(seconds: 30));

  print("======== ADI INFO =============================");
  QueryPagination qp = QueryPagination();
  qp.start = 0;
  qp.count = 20;

  res = await client.queryDirectory(identityUrl, qp,
      null); // NB: now returns only ADI and KeyBook, no keypage
  sleep(Duration(seconds: 10));
  print(res);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ADD CREDITS TO PAGE

  creditAmount = 90000 * 10;
  addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = keyPageUrl;
  addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
  addCreditsParam.oracle = oracle;

  res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  txId = res["result"]["txid"];
  print("Add credits to page $keyPageUrl txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
  print(res);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // CREATE CUSTOM TOKEN

  final tokenName =
      "tkn-${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}";
  final tokenUrl = identityUrl + "/$tokenName";
  CreateTokenParam createTokenParam = CreateTokenParam();
  createTokenParam.url = tokenUrl;
  createTokenParam.symbol = "TKN";
  createTokenParam.precision = 4;

  identityKeyPageTxSigner = TxSigner(keyPageUrl, keyForAdi);

  res = await client.createToken(
      identityUrl, createTokenParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("CustomToken txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));

  ////////////////////////////////////////////////////////////////////////////////////
  // CREATE CUSTOM TOKEN ACCOUNT

  final tokenAccountUrl = identityUrl + "/tokenAcc-for-$tokenName";
  CreateTokenAccountParam createTokenAccountParam = CreateTokenAccountParam();
  createTokenAccountParam.url = tokenAccountUrl;
  createTokenAccountParam.tokenUrl = tokenUrl;
  //createTokenAccountParam.authorities = ;

  res = await client.createTokenAccount(
      identityUrl, createTokenAccountParam, identityKeyPageTxSigner);
  sleep(Duration(seconds: waitTimeInSeconds));

  txId = res["result"]["txid"];
  print("Create token account txId $txId");

  //////////////////////////////////////////////////////////////////////////////////////
  // ISSUE TOKENS TO TOKEN ACCOUNT

  var issuanceAmount = 1000;

  IssueTokensParam issueTokensParam = IssueTokensParam();
  TokenRecipientParam tokenRecipientParam = TokenRecipientParam();
  tokenRecipientParam.url = tokenAccountUrl;
  tokenRecipientParam.amount = issuanceAmount;
  issueTokensParam.to = [tokenRecipientParam];

  res = await client.issueTokens(
      tokenUrl, issueTokensParam, identityKeyPageTxSigner);
  txId = res["result"]["txid"];
  print("issueTokens txId $txId");
  sleep(Duration(seconds: waitTimeInSeconds));
}
