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
        List<Uint8List> decodedEntries = [];

        for (var entry in dataEntries) {
          decodedEntries.add(hexToBytes(entry));
        }

        WriteDataParam param = WriteDataParam()
          ..data = decodedEntries
          ..writeToState = transaction['body']['writeToState'];
        Payload payload = WriteData(param);

        HeaderOptions options = HeaderOptions(); // Set actual options needed
        Header header = Header(transaction['header']['principal'], options);
        Transaction tx = Transaction(payload, header);

        print("Transaction object created:");
        print("Principal: ${header.principal}");
        print("Timestamp: ${header.timestamp}");
        print("Payload Data: ${payload}");
        print("Transaction Signature: ${tx.signature}");
      } else {
        print('Unhandled transaction type: $bodyType');
        return;
      }
    } catch (e) {
      print("Error fetching or parsing transaction: $e");
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
