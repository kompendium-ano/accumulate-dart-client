import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart'; // Correct package for hex conversion
import 'package:accumulate_api/accumulate_api.dart';

// Helper function to convert hex to bytes
Uint8List hexToBytes(String s) {
  return Uint8List.fromList(hex.decode(s));
}

// Helper function to simulate your existing key parsing
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
      "27bf94f1a7aeaba6d28b661412436ffaaeca84bec3eacc6a440046396a4232c9";

  final sigInfo = SignerInfo();
  sigInfo.type = SignatureType.signatureTypeED25519;
  sigInfo.url = AccURL("acc://whatever38.acme/book/1");
  sigInfo.publicKey = hex.decode(publicKeyHex) as Uint8List?;
  sigInfo.version = 1;
  final timestamp = 1712853539622;

  final endPoint = "https://kermit.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);
  final resp = await client.queryTx("acc://${transactionHashHex}@unknown");
  final rawTx = resp["result"]["transaction"];
  final tx = await unmarshalTx(rawTx, transactionHashHex, timestamp);

  final signer = loadSignerFromEncodedKey(privateKeyBase64);
  final signature = Signature();
  signature.signerInfo = sigInfo;
  signature.signature =
      signer.signRaw(tx.dataForSignature(sigInfo).asUint8List());

  print("Signature: ${hex.encode(signature.signature!)}");
  client.call("execute-direct", {
    "envelope": {
      "transaction": [rawTx],
      "signatures": [
        {
          "type": "ed25519",
          "publicKey": publicKeyHex,
          "signature": hex.encode(signature.signature!),
          "signer": sigInfo.url.toString(),
          "signerVersion": sigInfo.version,
          "timestamp": timestamp,
          "transactionHash": transactionHashHex,
        }
      ],
    },
  });
}

Future<Transaction> unmarshalTx(
    dynamic data, String txHash, int timestamp) async {
  final hopts = HeaderOptions()
    ..initiator = maybeDecodeHex(data["header"]["initiator"])
    ..memo = data["header"]["memo"]
    ..metadata = maybeDecodeHex(data["header"]["metadata"]);

  // This does not belong here - the timestamp belongs to the signature, not the
  // transaction - but the only way to set it is via the header options, so you
  // do what you gotta do
  hopts.timestamp = timestamp;

  final header = Header(data["header"]["principal"], hopts);
  final payload = decodePayload(data["body"]);
  final tx = Transaction(payload, header);
  final hash2 = hex.encode(tx.hash());
  if (txHash != hash2) {
    throw "hash does not match";
  }
  return tx;
}

Payload decodePayload(dynamic data) {
  switch (data["type"]) {
    case "writeData":
      if (data["entry"]["type"] != "doubleHash") {
        throw "unsupported data entry type";
      }
      final params = WriteDataParam()
        ..scratch = maybeDecodeBool(data["scratch"])
        ..writeToState = maybeDecodeBool(data["writeToState"])
        ..data = data["entry"]["data"]
            .map((s) => hex.decode(s))
            .cast<Uint8List>()
            .toList() as List<Uint8List>;
      return WriteData(params);

    default:
      throw "unsupported transaction type";
  }
}

Uint8List? maybeDecodeHex(String? s) {
  if (s == null) {
    return null;
  }
  return hex.decode(s) as Uint8List;
}

int? maybeDecodeInt(String? s) {
  if (s == null) {
    return null;
  }
  return int.parse(s);
}

bool? maybeDecodeBool(String? s) {
  if (s == null) {
    return null;
  }
  return bool.parse(s);
}
