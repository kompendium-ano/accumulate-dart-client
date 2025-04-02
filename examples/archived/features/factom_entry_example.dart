import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';
import 'dart:async';
import 'package:convert/convert.dart';

Future<void> testFactomFunction() async {
  // Mock principal URL

  String principal =
      '3e81762ce2ecd5a1ab5e153ec7544d7dae950aabdfc198f506552d9c8688e355';

  final Uint8List privateKeyBytes = Uint8List.fromList(hex.decode(
      "0ef5c455b2c05313d758e6b4e85fa452cec088fce6f0ab9afa067d07024703d22fe75075325860681febc68484167e51f7b432f8fecc9690ac4985a7622d3c8b"));
  final Ed25519KeypairSigner signer =
      Ed25519KeypairSigner.fromKeyRaw(privateKeyBytes);
  // public key: '2fe75075325860681febc68484167e51f7b432f8fecc9690ac4985a7622d3c8b';

  LiteIdentity lid = LiteIdentity(signer);
  String lid2 = 'acc://6c4ef3edb2b614e38949613444dda2defa7cd3fc838ce3f7';
  String LTA = 'acc://6c4ef3edb2b614e38949613444dda2defa7cd3fc838ce3f7/acme';
  final TxSigner txSigner = TxSigner(lid2, signer);

  // Create a FactomDataEntryParam with sample data
  FactomDataEntryParam factomParam = FactomDataEntryParam()
    ..accountId = Uint8List.fromList(List.generate(32, (index) => index + 1))
    ..data = Uint8List.fromList(List.generate(64, (index) => index + 2))
    ..extIds = [
      Uint8List.fromList(List.generate(8, (index) => index + 3)),
      Uint8List.fromList(List.generate(8, (index) => index + 4))
    ];

  // Call the factom function
  Map<String, dynamic> result = await factom(principal, factomParam, txSigner);

  // Print the result
  print('Factom function result: $result');
}

Future<Map<String, dynamic>> factom(
    dynamic principal, FactomDataEntryParam factomParam, TxSigner signer) {
  // Mock _execute function implementation
  return Future.value({
    'status': 'success',
    'data': {
      'principal': principal,
      'factomParam': factomParam,
      'signer': signer.info.url.toString()
    }
  });
}

void main() {
  testFactomFunction();
}
