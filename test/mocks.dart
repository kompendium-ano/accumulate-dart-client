import 'package:mockito/annotations.dart';
import 'package:accumulate_api/src/client/tx_signer.dart';
import 'package:accumulate_api/src/client/signer.dart';
import 'package:accumulate_api/src/acme_client.dart'; // Adjust the import path as needed
import 'package:http/http.dart' as http;
// No need to import 'mocks.mocks.dart' here; it's the file that will be generated

@GenerateMocks(
    [TxSigner, Signer, http.Client, ACMEClient]) // Added ACMEClient here
void main() {}
