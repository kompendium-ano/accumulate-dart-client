// examples\multisig_sig_execute_test.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

// Helper function to convert hex string to bytes
Uint8List hexToBytes(String s) {
  try {
    return Uint8List.fromList(hex.decode(s));
  } catch (e) {
    print("Error decoding hex string: $s");
    rethrow;
  }
}

// Loads a signer from a Base64 encoded private key
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
  final List<TokenRecipientParam> to;

  IssueTokensParam({required this.to});
}

class TokenRecipient {
  final AccURL url;
  final int amount;

  TokenRecipient(this.url, this.amount);

  Uint8List marshalBinary() {
    List<int> binaryData = [];
    binaryData.addAll(stringMarshalBinary(url.toString()));
    binaryData.addAll(bigNumberMarshalBinary(amount));
    return Uint8List.fromList(binaryData);
  }
}

class IssueTokens extends BasePayload {
  final IssueTokensParam params;

  IssueTokens(this.params);

  @override
  Uint8List extendedMarshalBinary() {
    List<int> binaryData = [];
    binaryData.addAll(uvarintMarshalBinary(TransactionType.issueTokens));
    for (TokenRecipientParam recipient in params.to) {
      AccURL url = AccURL.toAccURL(recipient.url);
      Uint8List recipientData =
          TokenRecipient(url, recipient.amount).marshalBinary();
      binaryData.addAll(fieldMarshalBinary(2, recipientData));
    }
    return Uint8List.fromList(binaryData);
  }
}

Future<void> main() async {
  String privateKeyBase64 =
      "67f7c78e33400dd03f0d3592a18209452024929f8a91b35f007d923fba43ca6ed1e4aba8d16ceb79d1a7f6cf51a35ab244b872ddc617557ed6b1d6773bc33696";
  String txId =
      "acc://754b8d66189ab2f2f4eba22a3742ad8565f4b635e64f8ddafe24b1c5451cde16@custom-adi-name-1714153702289.acme/my-custom-token";

  final client = ACMEClient("https://testnet.accumulatenetwork.io/v2");

  try {
    var response = await client.queryTx(txId);

    print("Data from query tx: $response");

    var result = response['result'];
    if (result == null) {
      print("Error: Result data is incomplete or null.");
      return;
    }

    var transaction = result['transaction'];
    if (transaction == null ||
        !transaction.containsKey('body') ||
        !transaction['body'].containsKey('to')) {
      print("Error: Transaction body is incomplete.");
      return;
    }

    List<dynamic> toRecipients = transaction['body']['to'];
    List<TokenRecipientParam> recipients = toRecipients
        .map((item) => TokenRecipientParam(
            url: item["url"], amount: int.parse(item["amount"])))
        .toList();

    final issueTokensParams = IssueTokensParam(to: recipients);
    final payload = IssueTokens(issueTokensParams);

    final signer = loadSignerFromEncodedKey(privateKeyBase64);
    final signature = signer.signRaw(payload.extendedMarshalBinary());
    String signatureHex = hex.encode(signature);
    print("Signature: $signatureHex");
  } catch (e) {
    print("An error occurred: $e");
  }
}
