import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:accumulate_api/accumulate_api.dart';

// Convert hex to bytes with validation
Uint8List hexToBytes(String s) {
  try {
    return Uint8List.fromList(hex.decode(s));
  } catch (e) {
    print("hexToBytes error decoding hex string: $s");
    throw e;
  }
}

Ed25519KeypairSigner loadSignerFromEncodedKey(String privateKeyBase64) {
  Uint8List privateKey = hexToBytes(privateKeyBase64);
  return Ed25519KeypairSigner.fromKeyRaw(privateKey);
}

class TokenRecipientParam {
  final String url;
  final int amount;

  TokenRecipientParam({required this.url, required this.amount});
}

class IssueTokensParam {
  List<TokenRecipientParam> to;

  IssueTokensParam({required this.to});
}

class IssueTokens {
  late IssueTokensParam params;

  IssueTokens(IssueTokensParam issueTokensParams) {
    this.params = issueTokensParams;
  }

  Map<String, dynamic> toJson() {
    return {
      'to': params.to
          .map((recipient) => {
                'url': recipient.url,
                'amount': recipient.amount,
              })
          .toList(),
    };
  }
}

Future<String> signTransaction({
  required String privateKeyBase64,
  required String transactionHashHex,
  required String metadataJson,
}) async {
  Ed25519KeypairSigner signer = loadSignerFromEncodedKey(privateKeyBase64);
  Uint8List metadataBytes = utf8.encode(metadataJson);
  Uint8List metadataHash =
      crypto.sha256.convert(metadataBytes).bytes as Uint8List;
  List<int> transactionHash = hex.decode(transactionHashHex);
  Uint8List toSign = Uint8List.fromList([...metadataHash, ...transactionHash]);
  Uint8List finalHash = crypto.sha256.convert(toSign).bytes as Uint8List;
  Uint8List signature = signer.signRaw(finalHash);
  return hex.encode(signature);
}

Future<void> main() async {
  try {
    String privateKeyBase64 =
        "a7eb9f1c576107510b91e2dc048a20adca2ed275590159eed47b51f460fa4a5e8e6fae262a98aba53d3ae0863de0b67ab3fb261f8cbc0f7d00edc25bdb20a814";
    String publicKeyHex =
        "8e6fae262a98aba53d3ae0863de0b67ab3fb261f8cbc0f7d00edc25bdb20a814";
    String transactionHashHex =
        "3be7576d9342555ad22dd4872a62ded24bf7672fd71a078ae10cb009996d47a4";

    final client = ACMEClient("https://mainnet.accumulatenetwork.io/v2");
    final response =
        await client.queryTx("acc://${transactionHashHex}@unknown");
    final data = response["result"]["transaction"];
    print("Data from query tx: $data");

    List<TokenRecipientParam> recipients = List.from(data["body"]["to"])
        .map((item) => TokenRecipientParam(
              url: item["url"],
              amount: int.parse(item["amount"].toString()),
            ))
        .toList();

    final issueTokensParams = IssueTokensParam(to: recipients);
    final payload = IssueTokens(issueTokensParams);

    String signatureHex = await signTransaction(
      privateKeyBase64: privateKeyBase64,
      transactionHashHex: transactionHashHex,
      metadataJson: json.encode(payload.toJson()),
    );

    Uint8List initiatorBytes = hexToBytes(data["header"]["initiator"]);

    Map<String, dynamic> transactionEnvelope = {
      "envelope": {
        "signatures": [
          {
            "type": "ed25519",
            "publicKey": publicKeyHex,
            "signer": "acc://accumulate.acme/core-dev/book/2",
            "signerVersion": 3,
            "timestamp": DateTime.now().millisecondsSinceEpoch,
            "signature": signatureHex,
            "transactionHash": transactionHashHex,
          }
        ],
        "transaction": {
          "header": {
            "principal": data["header"]["principal"],
            "initiator": base64Encode(initiatorBytes)
          },
          "body": {"type": "IssueTokens", "data": json.encode(payload.toJson())}
        }
      }
    };

    print("Transaction JSON: ${json.encode(transactionEnvelope)}");
    var execResponse = await client.executeDirect(transactionEnvelope);
    print("Transaction response: $execResponse");
  } catch (e) {
    print('An error occurred: $e');
  }
}
