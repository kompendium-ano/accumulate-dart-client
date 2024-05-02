// examples\liteData_tester.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart'; // Correct package for hex conversion
import 'package:accumulate_api/accumulate_api.dart';

Future<void> main() async {
  final String endPoint = "https://testnet.accumulatenetwork.io/v2";
  final ACMEClient client = ACMEClient(endPoint);

  final String privateKeyHex =
      "0057d014ca33cf7cfc49cbc64f4824c041427e0b562e1a3900877d16872d2f8b85ae7957e28247d8ba9714dfe83210c6cd79eb7c82ede7366e4c37f86e27714d";
  final String keyPageUrl = "acc://custom-adi-name-1707515657224.acme/book/1";
  final String dataAccountUrl =
      "acc://e553bacf3bc87d262eb8505a579c235c345dbae6e7bf95cd6ff597fb8ccfe128";

  Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
  Ed25519KeypairSigner adiSigner =
      Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
  List<Uint8List> dataEntries = [
    utf8.encode("").asUint8List(),
    utf8.encode("Testing").asUint8List(),
    utf8.encode("Lite").asUint8List(),
    utf8.encode("Data Accounts").asUint8List(),
  ];

  // NOTE - write to state is NOT ALLOWED for LDAs
  WriteDataParam writeDataParam = WriteDataParam();
  writeDataParam.data = dataEntries;

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
