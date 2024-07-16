import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

// Helper: convert hex to bytes
Uint8List hexToBytes(String s) {
  return Uint8List.fromList(hex.decode(s));
}

// Helper: key parsing
Ed25519KeypairSigner loadSignerFromEncodedKey(String privateKeyBase64) {
  Uint8List privateKey = hexToBytes(privateKeyBase64);
  return Ed25519KeypairSigner.fromKeyRaw(privateKey);
}

// Helper: get signer version
Future<int> getSignerVersion(ACMEClient client, AccURL keyPageUrl) async {
  var response = await client.queryUrl(keyPageUrl);
  return response["result"]["data"]["version"];
}

// Sign + wrap signature with delegation
Future<Map<String, dynamic>> signTransactionWithDelegation({
  required ACMEClient client,
  required String privateKeyBase64,
  required String transactionHashHex,
  required SignerInfo sigInfo,
  required List<SignerInfo> delegators,
}) async {
  // Decode/load private key
  Ed25519KeypairSigner signer = loadSignerFromEncodedKey(privateKeyBase64);

  // Helper: sign hash
  Uint8List signHash(Uint8List hash) {
    return signer.signRaw(hash);
  }

  // Get version of initial signer
  int signerVersion = await getSignerVersion(client, sigInfo.url!);

  // Create initial signature map
  Map<String, dynamic> signature = {
    "type": "ed25519",
    "publicKey": hex.encode(sigInfo.publicKey!),
    "signer": sigInfo.url.toString(),
    "signerVersion": signerVersion,
    "timestamp": DateTime.now().microsecondsSinceEpoch,
    "memo": "Test SigMemo1",
    "data": hex.encode(utf8.encode("Test SigData1"))
  };

  // Save a reference to the inner signature
  var innerSignature = signature;

  // Wrap signature with delegators in order
  for (SignerInfo delegator in delegators) {
    // Get version for each delegator
    int delegatorVersion = await getSignerVersion(client, delegator.url!);

    // Update delegator version
    delegator.version = delegatorVersion;

    // Wrap existing signature in a delegated signature
    signature = {
      "type": "delegated",
      "signature": signature,
      "delegator": delegator.url.toString()
    };
  }

  // Calculate and sign the hash
  Uint8List metadataBytes = signatureMarshalBinary(signature);
  print('Signature: ${hex.encode(metadataBytes)}');
  Uint8List metadataHash =
      Uint8List.fromList(crypto.sha256.convert(metadataBytes).bytes);
  Uint8List transactionHash =
      Uint8List.fromList(hex.decode(transactionHashHex));
  Uint8List toSign = Uint8List.fromList([...metadataHash, ...transactionHash]);
  Uint8List finalHash = Uint8List.fromList(crypto.sha256.convert(toSign).bytes);

  // Populate signature and transactionHash on the inner signature.
  innerSignature["signature"] = hex.encode(signHash(finalHash));
  innerSignature["transactionHash"] = transactionHashHex;

  return signature;
}

Future<void> main() async {
  String privateKeyBase64 =
      "c58bc5f2643f5ed139c9434bfb772701c373d8aba766e01ff401307799e4fab9ec66e2c540db4169f24973fdf2f6451ff02215383dea790c6ec16717fe2f0d53";
  String publicKeyHex =
      "ec66e2c540db4169f24973fdf2f6451ff02215383dea790c6ec16717fe2f0d53";
  String transactionHashHex =
      "de8d0b483acecec5a7a98b188b738492500847ff6e966aac6394d4ec49320c8f";

  final sigInfo = SignerInfo()
    ..type = SignatureType.signatureTypeED25519
    ..url = AccURL("acc://custom-adi-name-1720351349389.acme/book/1")
    ..publicKey = hexToBytes(publicKeyHex);

  final endPoint = "https://testnet.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);
  final resp = await client.queryTx("acc://${transactionHashHex}@unknown");
  final rawTx = resp["result"]["transaction"];

  final delegator1 = SignerInfo()
    ..type = SignatureType.signatureTypeED25519
    ..url = AccURL("acc://custom-adi-name-1720351293054.acme/book/1")
    ..publicKey = hexToBytes(publicKeyHex);

  final delegator2 = SignerInfo()
    ..type = SignatureType.signatureTypeED25519
    ..url = AccURL("acc://custom-adi-name-1720349551259.acme/book/1")
    ..publicKey = hexToBytes(publicKeyHex);

  final signature = await signTransactionWithDelegation(
    client: client,
    privateKeyBase64: privateKeyBase64,
    transactionHashHex: transactionHashHex,
    sigInfo: sigInfo,
    delegators: [
      delegator1,
      delegator2
    ],
  );

  print("Signature: ${json.encode(signature)}");
  final executeResponse = await client.call("execute-direct", {
    "envelope": {
      "transaction": [rawTx],
      "signatures": [signature],
    },
  });
  print("Execute response: ${executeResponse}");
}

Future<Transaction> unmarshalTx(
    dynamic data, String txHash, int timestamp) async {
  final hopts = HeaderOptions()
    ..initiator = maybeDecodeHex(data["header"]["initiator"])
    ..memo = data["header"]["memo"]
    ..metadata = maybeDecodeHex(data["header"]["metadata"]);

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
                ?.map((s) => Uint8List.fromList(hex.decode(s as String)))
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
  return Uint8List.fromList(hex.decode(s));
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

int signatureTypeCode(String type) {
  switch (type.toLowerCase()) {
    case "legacyed25519":
      return 1;
    case "ed25519":
      return 2;
    case "rcd1":
      return 3;
    case "btc":
      return 8;
    case "btclegacy":
      return 9;
    case "eth":
      return 10;
    case "delegated":
      return 11;
  }
  throw Exception("Invalid signature type ${type}");
}

int voteTypeCode(String? type) {
  if (type == null || type == "") {
    return 0;
  }
  switch (type.toLowerCase()) {
    case "accept":
      return 0;
    case "reject":
      return 1;
    case "abstain":
      return 2;
    case "suggest":
      return 3;
  }
  throw Exception("Invalid signature type ${type}");
}

Uint8List signatureMarshalBinary(Map<String, dynamic> signature) {
  List<int> data = [];

  var type = signatureTypeCode(signature["type"]);
  var vote = voteTypeCode(signature["vote"]);
  switch (type) {
    case 1: // legacy
      throw Exception("Legacy ED25519 signatures are not supported");

    case 11: // delegated
      data.addAll(uvarintMarshalBinary(type, 1));
      if (signature["signature"] != null) {
        data.addAll(bytesMarshalBinary(
            signatureMarshalBinary(signature["signature"]), 2));
      }
      if (signature["delegator"] != null) {
        data.addAll(stringMarshalBinary(signature["delegator"], 3));
      }
      break;

    default:
      data.addAll(uvarintMarshalBinary(type, 1));
      if (signature["publicKey"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["publicKey"]).asUint8List(), 2));
      }
      if (signature["signature"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["signature"]).asUint8List(), 3));
      }
      if (signature["signer"] != null) {
        data.addAll(stringMarshalBinary(signature["signer"], 4));
      }
      if (signature["signerVersion"] != null) {
        data.addAll(uvarintMarshalBinary(signature["signerVersion"], 5));
      }
      if (signature["timestamp"] != null) {
        data.addAll(uvarintMarshalBinary(signature["timestamp"], 6));
      }
      if (vote != 0) {
        data.addAll(uvarintMarshalBinary(vote, 7));
      }
      if (signature["transactionHash"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["transactionHash"]).asUint8List(), 8));
      }
      if (signature["memo"] != null) {
        data.addAll(stringMarshalBinary(signature["memo"], 9));
      }
      if (signature["data"] != null) {
        data.addAll(bytesMarshalBinary(
            hex.decode(signature["data"]).asUint8List(), 10));
      }
  }

  return data.asUint8List();
}
