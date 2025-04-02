import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

Future<void> main() async {
  final String endPoint = "https://testnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  final String privateKeyHex =
      "1e67465a1fde2290b04d1575b68b9f0256f6475fed33411b23107f984544701cbbecf13ec50ccfcf9d86896ce8ab0260434e7a11b9c9e605bf02d68de16f70da";
  Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
  Ed25519KeypairSigner adiSigner =
      Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);

  final String keyPageUrl = "acc://custom-adi-name-1720349551259.acme/book/1";
  final String dataAccountUrl =
      "acc://custom-adi-name-1720349551259.acme/data-account";

  List<Uint8List> dataEntries = [utf8.encode("Dummy Entry_10").asUint8List()];

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
  var r = await client.queryUrl(txSigner.url); // check for key page version
  txSigner = TxSigner.withNewVersion(txSigner, r["result"]["data"]["version"]);

  try {
    var res = await client.writeData(dataAccountUrl, writeDataParam, txSigner);
    print("Write Data to ADI Data Account response: $res");
  } catch (error) {
    print("An error occurred while writing data: $error");
  }
}
