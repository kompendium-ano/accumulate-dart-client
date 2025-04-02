// C:\Accumulate_Stuff\accumulate-dart-client\examples\archived\previous_exmaple_tests\write_to_staking.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

Future<void> main() async {
  final String endPoint = "https://mainnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  final String privateKeyHex =
      "74b975f6ae309f2adb4ac5e10bd1729ea589570e23896ca58f36940f19dbe1d54c0c3fef9fc2629c1d3dd3d78acf0aab4ae9f87fd4d3a875a48090c27ccc2c0f";
  Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
  Ed25519KeypairSigner adiSigner =
      Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);

  final String keyPageUrl = "acc://beastmode.acme/book/1";
  final String dataAccountUrl =
      "acc://staking.acme/requests";

  // Add multiple data entries in one transaction
  List<Uint8List> dataEntries = [
    utf8.encode("Accu2").asUint8List(),
    utf8.encode("AddAccount").asUint8List(),
    utf8.encode("Account=acc://beastmode.acme/staking").asUint8List(),
    utf8.encode("Type=delegated").asUint8List(),
    utf8.encode("Payout=acc://beastmode.acme/tokens").asUint8List(),
    utf8.encode("Delegate=acc://kompendium.acme").asUint8List(),
    utf8.encode("request_txid=acc://1cbccc2f5306f1677ece607ff0e97fa4a7fb1b3d3db50f756cda1d0955d1b0c0@beastmode.acme").asUint8List()
  ];

  WriteDataParam writeDataParam = WriteDataParam()
    ..data = dataEntries
    ..scratch = false
    ..writeToState = true;

  await addDataToAdiDataAccount(
      client, adiSigner, keyPageUrl, dataAccountUrl, writeDataParam);
}

Future<void> addDataToAdiDataAccount(
    ACMEClient client,
    Ed25519KeypairSigner adiSigner,
    String keyPageUrl,
    String dataAccountUrl,
    WriteDataParam writeDataParam) async {
  TxSigner txSigner = TxSigner(keyPageUrl, adiSigner);

  // Query signer version to avoid transaction rejection
  var r = await client.queryUrl(txSigner.url);
  if (r["result"] == null || r["result"]["data"] == null) {
    print("Error: Failed to retrieve signer version.");
    return;
  }
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  try {
    var res = await client.writeData(dataAccountUrl, writeDataParam, txSigner);
    print("Write Data to ADI Data Account response: $res");
  } catch (error) {
    print("An error occurred while writing data: $error");
  }
}
