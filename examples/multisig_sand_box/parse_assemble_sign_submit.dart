// examples\multisig_sand_box\parse_assemble_sign_submit.dart

import 'package:convert/convert.dart';
import 'dart:typed_data';
import 'package:accumulate_api/accumulate_api.dart';

class QueryResponseParser {
  RpcClient _rpcClient;

  QueryResponseParser(String endpoint) : _rpcClient = RpcClient(endpoint);

  Uint8List hexToBytes(String hexString) {
    return Uint8List.fromList(List.generate(hexString.length ~/ 2,
        (i) => int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16)));
  }

  Future<void> fetchAndParseTransaction(String txId) async {
    try {
      Map<String, dynamic> response =
          await _rpcClient.call('query-tx', {'txid': txId});
      print("Transaction fetched successfully.");

      var result = response['result'];
      String transactionHash = result['transactionHash'];
      Map<String, dynamic> transaction = result['transaction'];
      String bodyType = transaction['body']['type'];

      print("Transaction Hash: $transactionHash");
      print("Transaction Body Type: $bodyType");

      if (bodyType == 'writeData') {
        var dataEntries = (transaction['body']['entry']['data'] as List);
        List<Uint8List> decodedEntries =
            dataEntries.map((e) => hexToBytes(e)).toList();

        WriteDataParam param = WriteDataParam()
          ..data = decodedEntries
          ..writeToState = transaction['body']['writeToState'];
        Payload payload = WriteData(param);

        // Manually set timestamp to ensure consistency in transaction hash
        HeaderOptions options = HeaderOptions(
            timestamp: 1714298100261732, // Manually setting the timestamp
            memo: transaction['header']['memo'],
            metadata: transaction['header']['metadata'] != null
                ? hexToBytes(transaction['header']['metadata'])
                : null,
            initiator: transaction['header']['initiator'] != null
                ? hexToBytes(transaction['header']['initiator'])
                : null);
        Header header = Header(transaction['header']['principal'], options);

        Transaction tx = Transaction(payload, header);

        Uint8List privateKey = Uint8List.fromList(hex.decode(
            '026e5f575a40cbfec29ef9cf9de63ccc0a9289046fa80750bfb9f2d7626a30274babeda2c1feda94064997737ad7fd613b91e20546db51f97254960455673845'));
        Ed25519Keypair keypair = Ed25519Keypair.fromSecretKey(privateKey);
        Ed25519KeypairSigner signer = Ed25519KeypairSigner(keypair);

        String signerUrl = "acc://custom-adi-name-1714297678838.acme/book/1";
        TxSigner txSigner = TxSigner(signerUrl, signer);

        tx.sign(txSigner);

        print("Transaction object created:");
        print("Principal: ${header.principal}");
        print("Timestamp: ${header.timestamp}");
        print("Payload Data: ${payload}");
        print(
            "Transaction Signature: ${tx.signature.signature != null ? hex.encode(tx.signature.signature!) : 'No signature'}");
        print("Transaction Signature Info: ${tx.signature.signerInfo}");
        print("Transaction Hash: ${hex.encode(tx.hash())}");

        String endpoint = "https://testnet.accumulatenetwork.io/v2";
        RpcClient rpcClient = RpcClient(endpoint);
        Map<String, dynamic> submitResult =
            await rpcClient.call("execute", tx.toTxRequest().toMap);
        print("Submit Result: $submitResult");
      } else {
        print('Unhandled transaction type: $bodyType');
      }
    } catch (e, stacktrace) {
      print("Error fetching or parsing transaction: $e");
      print("Stack Trace: $stacktrace");
    }
  }
}

void main() {
  String endpoint = "https://testnet.accumulatenetwork.io/v2";
  String transactionId =
      "a11a8158f7d20ec580a453f7bdeb89bad610d9ae15a9be8dcd8f0bfbe14629e5";

  QueryResponseParser parser = QueryResponseParser(endpoint);
  parser.fetchAndParseTransaction(transactionId);
}
