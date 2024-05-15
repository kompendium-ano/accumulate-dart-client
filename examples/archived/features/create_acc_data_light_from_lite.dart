import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
import 'dart:async';
import 'package:convert/convert.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  await testLiteDataAccountCreation();
}

Future<void> testLiteDataAccountCreation() async {
  Ed25519KeypairSigner signer = Ed25519KeypairSigner.generate();
  LiteIdentity lid = LiteIdentity(signer);

  print("Signer Public Key: ${hex.encode(signer.publicKey())}");
  print("Signer Public Key Hash: ${hex.encode(signer.publicKeyHash())}");
  print("lite account URL: ${lid.acmeTokenAccount}\n");

  await addFundsToAccount(lid.acmeTokenAccount, times: 2);
  await Future.delayed(Duration(seconds: 20));

  // Add 100 credits to the first lite account
  final oracle = await client.valueFromOracle();
  await addCredits(lid, 10000, oracle);
  await Future.delayed(Duration(seconds: 70));

  List<Uint8List> dataEntries = [
    Uint8List.fromList(utf8.encode("writeDataTo test1")),
    Uint8List.fromList(utf8.encode("writeDataTo test10"))
  ];

  await writeDataToExample(lid, dataEntries);
}

Future<void> writeDataToExample(LiteIdentity lid, List<Uint8List> dataEntries) async {
  TxSigner txSigner = TxSigner(lid.url, lid.signer);

  String publicKeyHex = hex.encode(lid.signer.publicKey());
  String recipientUrl = 'acc://$publicKeyHex';

  WriteDataToParam writeDataToParam = WriteDataToParam(
    recipient: recipientUrl,
    data: dataEntries
  );

  print("Transaction Parameters:");
  print("Recipient URL: $recipientUrl");
  print("Data Entries: ${dataEntries.map((e) => hex.encode(e)).join(', ')}");

  try {
    print("Sending WriteDataTo transaction...");
    var res = await client.writeDataTo(lid.acmeTokenAccount, writeDataToParam, txSigner);
    var txId = res["result"]["txid"];
    print("writeDataTo Transaction ID: $txId");

print("Fetching transaction result for TX ID: $txId");
    res = await client.queryTx(txId);
    print("Query Transaction Response - writeDataTo: $res");
  } catch (e) {
    print("Error writeDataTo: $e");
  }
}

Future<void> addFundsToAccount(AccURL accountUrl, {int times = 3}) async {
  for (int i = 0; i < times; i++) {
    await client.faucet(accountUrl);
    await Future.delayed(Duration(seconds: 10));
  }
}

Future<void> addCredits(LiteIdentity lid, int creditAmount, int oracle) async {
  AddCreditsParam addCreditsParam = AddCreditsParam();
  addCreditsParam.recipient = lid.url;
  addCreditsParam.amount = (creditAmount * pow(10, 8).toInt()) ~/ oracle;
  addCreditsParam.oracle = oracle;

  print("Preparing to add credits:");
  print("Recipient URL: ${addCreditsParam.recipient}");
  print("Credit Amount: ${addCreditsParam.amount}");
  print("Oracle Value: $oracle");

  var res = await client.addCredits(lid.acmeTokenAccount, addCreditsParam, lid);
  print("addCredits transaction response: $res");

  if (res["result"] != null && res["result"]["txid"] != null) {
    String txId = res["result"]["txid"];
    print("addCredits Transaction ID: $txId");

    await Future.delayed(Duration(seconds: 100));
    res = await client.queryTx(txId);
    print("Query Transaction Response for addCredits: $res");
  }
}
