import 'dart:convert';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
import 'dart:async';
import 'package:convert/convert.dart';

final endPoint = "https://testnet.accumulatenetwork.io/v2";
ACMEClient client = ACMEClient(endPoint);

Future<void> main() async {
  final Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(
      "0ef5c455b2c05313d758e6b4e85fa452cec088fce6f0ab9afa067d07024703d22fe75075325860681febc68484167e51f7b432f8fecc9690ac4985a7622d3c8b"));
  final Ed25519KeypairSigner signer = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
  // public key: '2fe75075325860681febc68484167e51f7b432f8fecc9690ac4985a7622d3c8b';

  LiteIdentity lid = LiteIdentity(signer);
  String lid2 = 'acc://6c4ef3edb2b614e38949613444dda2defa7cd3fc838ce3f7';
  String LTA = 'acc://6c4ef3edb2b614e38949613444dda2defa7cd3fc838ce3f7/acme';
  final TxSigner txSigner = TxSigner(lid2, signer);

  List<Uint8List> dataEntries = [
    Uint8List.fromList(utf8.encode("writeDataTo test1 with want url")),
    Uint8List.fromList(utf8.encode("writeDataTo test100!"))
  ];

  // Ensure the recipient URL is correct
  String recipientUrl = 'acc://e553bacf3bc87d262eb8505a579c235c345dbae6e7bf95cd6ff597fb8ccfe128';
  WriteDataToParam writeDataToParam = WriteDataToParam(
    recipient: recipientUrl,
    data: dataEntries
  );

  print("Transaction Parameters:");
  print("Recipient URL: $recipientUrl");
  print("Data Entries: ${dataEntries.map((e) => hex.encode(e)).join(', ')}");

  try {
    print("Sending WriteDataTo transaction...");
    var res = await client.writeDataTo(LTA, writeDataToParam, txSigner);
    var txId = res["result"]["txid"];
    print("writeDataTo Transaction ID: $txId");

    print("Fetching transaction result for TX ID: $txId");
    res = await client.queryTx(txId);
    print("Query Transaction Response - writeDataTo: $res");
  } catch (e) {
    print("Error writeDataTo: $e");
  }
}
