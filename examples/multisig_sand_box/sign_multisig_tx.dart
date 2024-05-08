// examples\sign_multisig_tx.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

// Helper function to convert hex to bytes
Uint8List hexToBytes(String s) {
  return Uint8List.fromList(hex.decode(s));
}

// Helper function to simulate existing key parsing
Ed25519KeypairSigner loadSignerFromEncodedKey(String privateKeyBase64) {
  Uint8List privateKey = hexToBytes(privateKeyBase64);
  return Ed25519KeypairSigner.fromKeyRaw(privateKey);
}

Future<String> signTransaction({
  required String privateKeyBase64,
  required String transactionHashHex,
  required String metadataJson,
}) async {
  // Decode and load the private key
  Ed25519KeypairSigner signer = loadSignerFromEncodedKey(privateKeyBase64);

  // Calculate the hash of the signature metadata
  Uint8List metadataBytes = utf8.encode(metadataJson);
  Uint8List metadataHash =
      crypto.sha256.convert(metadataBytes).bytes as Uint8List;

  // Decode transaction hash
  Uint8List transactionHash =
      Uint8List.fromList(hex.decode(transactionHashHex));

  // Concatenate metadata hash and transaction hash, then hash the result
  Uint8List toSign = Uint8List.fromList([...metadataHash, ...transactionHash]);
  Uint8List finalHash = crypto.sha256.convert(toSign).bytes as Uint8List;

  // Sign the hash
  Uint8List signature = signer.signRaw(finalHash);

  // Convert signature to hex string for display or use in JSON
  String signatureHex = hex.encode(signature);
  return signatureHex;
}

Future<void> main() async {
  String privateKeyBase64 =
      "a7eb9f1c576107510b91e2dc048a20adca2ed275590159eed47b51f460fa4a5e8e6fae262a98aba53d3ae0863de0b67ab3fb261f8cbc0f7d00edc25bdb20a814";
  String publicKeyHex =
      "8e6fae262a98aba53d3ae0863de0b67ab3fb261f8cbc0f7d00edc25bdb20a814";
  String transactionHashHex =
      "3be7576d9342555ad22dd4872a62ded24bf7672fd71a078ae10cb009996d47a4";

  final sigInfo = SignerInfo();
  sigInfo.type = SignatureType.signatureTypeED25519;
  sigInfo.url = AccURL("acc://accumulate.acme/core-dev/book/2");
  sigInfo.publicKey = hex.decode(publicKeyHex) as Uint8List?;
  sigInfo.version = 3;

  final endPoint = "https://mainnet.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);
  final data = (await client
      .queryTx("acc://${transactionHashHex}@unknown"))["result"]["transaction"];
  print("Data from query tx: $data");

  final hopts = HeaderOptions();
  hopts.timestamp = 1712853539622;
  hopts.memo = data["header"]["memo"];
  hopts.initiator = hex.decode(data["header"]["initiator"]) as Uint8List?;
  print("Data from hopts.initiator: ${hopts.initiator}");
  final header = Header(data["header"]["principal"], hopts);

  // TODO Reconstruct the payload
  final params = WriteDataParam();
  params.data = [Uint8List(0)];
  final payload = WriteData(params);
  final tx = Transaction(payload, header);

  final signer = loadSignerFromEncodedKey(privateKeyBase64);
  final signature = Signature();
  signature.signerInfo = sigInfo;
  signature.signature =
      signer.signRaw(tx.dataForSignature(sigInfo).asUint8List());
  print("Data from signature.signature: ${signature.signature}");

  print("Signature: ${hex.encode(signature.signature!)}");
}
