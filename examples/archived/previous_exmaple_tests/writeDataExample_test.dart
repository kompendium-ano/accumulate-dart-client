import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart'; // Ensure this import path is correct
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart'; // Ensure this import path is correct

Future<void> main() async {
  final String endPoint = "https://testnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  final String privateKeyHex = "0057d014ca33cf7cfc49cbc64f4824c041427e0b562e1a3900877d16872d2f8b85ae7957e28247d8ba9714dfe83210c6cd79eb7c82ede7366e4c37f86e27714d";
  Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
  Ed25519KeypairSigner adiSigner = Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);

  final String keyPageUrl = "acc://custom-adi-name-1707515657224.acme/book/1";
  final String dataAccountUrl = "acc://custom-adi-name-1707515657224.acme/data-account";

  List<Uint8List> dataEntries = [utf8.encode("Example data entry").asUint8List()];

  // Adjusted instantiation to directly set properties
  WriteDataParam writeDataParam = WriteDataParam()
    ..data = dataEntries
    ..scratch = false
    ..writeToState = true;

  await addDataToAdiDataAccount(client, adiSigner, keyPageUrl, dataAccountUrl, writeDataParam);
}

Future<void> addDataToAdiDataAccount(ACMEClient client, Ed25519KeypairSigner adiSigner, String keyPageUrl, String dataAccountUrl, WriteDataParam writeDataParam) async {
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
