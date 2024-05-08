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
  final timestamp = DateTime.now().microsecondsSinceEpoch;

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

int? parseOperationType(String? operationType) {
  if (operationType == null) return null;

  switch (operationType.toLowerCase()) {
    case 'update':
      return KeyPageOperationType.Update;
    case 'remove':
      return KeyPageOperationType.Remove;
    case 'add':
      return KeyPageOperationType.Add;
    case 'setthreshold':
      return KeyPageOperationType.SetThreshold;
    case 'updateallowed':
      return KeyPageOperationType.UpdateAllowed;
    default:
      print("Unknown operation type: $operationType");
      return null;
  }
}

Payload decodePayload(dynamic data) {
  switch (data["type"]) {
    case "writeData":
      if (data["entry"]["type"] != "doubleHash") {
        throw "Unsupported data entry type";
      }
      final params = WriteDataParam()
        ..scratch = data["scratch"] ?? false
        ..writeToState = data["writeToState"] ?? false
        ..data = (data["entry"]["data"] as List<dynamic>?)
                ?.map((s) => hex.decode(s as String))
                .cast<Uint8List>()
                .toList() ??
            [];
      return WriteData(params);

    case "updateKeyPage":
      print("Decoding updateKeyPage payload");
      var operationsData = data["operation"] as List<dynamic>?;
      print("Operations Data: ${jsonEncode(operationsData)}");

      var operations = operationsData?.map((op) {
            print("Processing operation: ${jsonEncode(op)}");
            var keyOperation = KeyOperation()
              ..type = parseOperationType(op["type"] as String?)
              ..key = (op["entry"] != null
                  ? (KeySpec()..delegate = op["entry"]["delegate"])
                  : null);

            print("KeyOperation created with type: ${keyOperation.type}");
            print("Delegate: ${keyOperation.key?.delegate}");

            return keyOperation;
          }).toList() ??
          [];

      print("Total operations processed: ${operations.length}");

      final updateKeyPageParams = UpdateKeyPageParam()
        ..operations = operations
        ..memo = data["memo"] as String?
        ..metadata =
            data["metadata"] != null ? maybeDecodeHex(data["metadata"]) : null;

      print(
          "UpdateKeyPageParam created with memo: ${updateKeyPageParams.memo}");
      if (updateKeyPageParams.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return UpdateKeyPage(updateKeyPageParams);

    default:
      throw "Unsupported transaction type ${data['type']}";
  }
}

Uint8List? maybeDecodeHex(String? hexString) {
  if (hexString == null) return null;
  try {
    return Uint8List.fromList(hex.decode(hexString));
  } catch (e) {
    print("Failed to decode hex: $e");
    return null;
  }
}

bool maybeDecodeBool(dynamic value) {
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return value ?? false;
}

int? maybeDecodeInt(String? s) {
  if (s == null) {
    return null;
  }
  try {
    return int.parse(s);
  } catch (e) {
    print("Failed to parse int: $e");
    return null;
  }
}
