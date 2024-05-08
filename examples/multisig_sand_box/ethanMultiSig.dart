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
      "026e5f575a40cbfec29ef9cf9de63ccc0a9289046fa80750bfb9f2d7626a30274babeda2c1feda94064997737ad7fd613b91e20546db51f97254960455673845";
  String publicKeyHex =
      "4babeda2c1feda94064997737ad7fd613b91e20546db51f97254960455673845";
  String transactionHashHex =
      "f6c4fa0f9f159d823eaded569c8b6e83a8814a9f96efeb496392a6a1107ebaea";

  final sigInfo = SignerInfo();
  sigInfo.type = SignatureType.signatureTypeED25519;
  sigInfo.url = AccURL("acc://custom-adi-name-1714297678838.acme/book/1");
  sigInfo.publicKey = hex.decode(publicKeyHex) as Uint8List?;
  sigInfo.version = 1;
  final timestamp = DateTime.now().millisecondsSinceEpoch;

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

/*
Payload decodePayload(dynamic data) {
  switch (data["type"]) {
    case "writeData":
      if (data["entry"]["type"] != "doubleHash") {
        throw "unsupported data entry type";
      }
      final params = WriteDataParam()
        ..scratch = data["scratch"] ??
            false // Assuming a default of false if not provided
        ..writeToState = data["writeToState"] ??
            false // Assuming a default of false if not provided
        ..data = data["entry"]["data"]
            .map((s) => hex.decode(s))
            .cast<Uint8List>()
            .toList();
      return WriteData(params);

    default:
      throw "unsupported transaction type";
  }
}
*/

Payload decodePayload(dynamic data) {
  switch (data["type"]) {
    case "writeData":
      if (data["entry"]["type"] != "doubleHash") {
        throw "Unsupported data entry type";
      }
      final params = WriteDataParam()
        ..scratch = data["scratch"] ?? false
        ..writeToState = data["writeToState"] ?? false
        ..data = data["entry"]["data"]
            .map((s) => hex.decode(s))
            .cast<Uint8List>()
            .toList();
      return WriteData(params);

    case "updateKeyPage":
      var operations = (data["operations"] as List).map((op) {
        var keyOperation = KeyOperation()
          ..type = op["type"]
          ..key = (op["key"] != null
              ? (KeySpec()..keyHash = op["key"]["keyHash"])
              : null)
          ..oldKey = (op["oldKey"] != null
              ? (KeySpec()..keyHash = op["oldKey"]["keyHash"])
              : null)
          ..newKey = (op["newKey"] != null
              ? (KeySpec()..keyHash = op["newKey"]["keyHash"])
              : null)
          ..threshold = op["threshold"]
          ..allow = (op["allow"] as List?)?.map<int>((a) => a).toList()
          ..deny = (op["deny"] as List?)?.map<int>((d) => d).toList();
        return keyOperation;
      }).toList();

      final updateKeyPageParams = UpdateKeyPageParam()
        ..operations = operations
        ..memo = data["memo"]
        ..metadata = data["metadata"] != null
            ? Uint8List.fromList(hex.decode(data["metadata"]))
            : null;

      return UpdateKeyPage(updateKeyPageParams);

    default:
      throw "Unsupported transaction type ${data["type"]}";
  }
}

Uint8List? maybeDecodeHex(String? s) {
  if (s == null) {
    return null;
  }
  return hex.decode(s) as Uint8List;
}

bool maybeDecodeBool(dynamic value) {
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return value ??
      false; // Default to false if null or not a recognizable string
}

int? maybeDecodeInt(String? s) {
  if (s == null) {
    return null;
  }
  return int.parse(s);
}
