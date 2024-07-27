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

// Helper function to simulate your existing key parsing
Ed25519KeypairSigner loadSignerFromEncodedKey(String privateKeyBase64) {
  Uint8List privateKey = hexToBytes(privateKeyBase64);
  return Ed25519KeypairSigner.fromKeyRaw(privateKey);
}

// Helper function to get the correct signer version
Future<int> getSignerVersion(ACMEClient client, AccURL keyPageUrl) async {
  var response = await client.queryUrl(keyPageUrl);
  return response["result"]["data"]["version"];
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
      "b3b2b01471277fd30160a8d239b36c2e3741aca29a6177da3907b93b996e0fbaed06a050ca69313abb80feabf4e7c4b8e789d9a4f7fbe59826f2211c5ad3c747";
  String publicKeyHex =
      "ed06a050ca69313abb80feabf4e7c4b8e789d9a4f7fbe59826f2211c5ad3c747";
  String transactionHashHex =
      "d8601570db73bda6d1d6319b3a73a4abb156136f18b01a2279a3da927ecfad6e";

  final sigInfo = SignerInfo();
  sigInfo.type = SignatureType.signatureTypeED25519;
  sigInfo.url = AccURL("acc://custom-adi-name-1720351293054.acme/book/1");
  sigInfo.publicKey = hex.decode(publicKeyHex) as Uint8List?;

  final endPoint = "https://testnet.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);

  // Update the signer version
  int signerVersion = await getSignerVersion(client, sigInfo.url!);
  sigInfo.version = signerVersion;

  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final resp = await client.queryTx("acc://${transactionHashHex}@unknown");
  final rawTx = resp["result"]["transaction"];
  final tx = await unmarshalTx(rawTx, transactionHashHex, timestamp);

  final signer = loadSignerFromEncodedKey(privateKeyBase64);
  final signature = Signature();
  signature.signerInfo = sigInfo;
  signature.signature =
      signer.signRaw(tx.dataForSignature(sigInfo).asUint8List());

  print("Signature: ${hex.encode(signature.signature!)}");
  await client.call("execute-direct", {
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
  // transaction - but the only way to set it is via the header options
  hopts.timestamp = timestamp;

  final header = Header(data["header"]["principal"], hopts);
  final payload = decodePayload(data["body"]);
  final tx = Transaction(payload, header);
  final hash2 = hex.encode(tx.hash());
  if (txHash != hash2) {
    throw "hash does not match: expected $txHash, but got $hash2";
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
        ..scratch =
            data["scratch"] == null ? null : maybeDecodeBool(data["scratch"])
        ..writeToState = data["writeToState"] == null
            ? null
            : maybeDecodeBool(data["writeToState"])
        ..data = (data["entry"]["data"] as List<dynamic>?)
                ?.map((s) => hex.decode(s as String))
                .cast<Uint8List>()
                .toList() ??
            [];
      return WriteData(params);

    default:
      throw "unsupported transaction type ${data['type']}";
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

bool maybeDecodeBool(dynamic value) {
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return value ?? false;
}
