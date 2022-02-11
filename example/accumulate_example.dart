import 'package:accumulate/accumulate.dart';
import 'package:accumulate/src/v2/api.dart';
import 'package:test/test.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('A group of tests', () {
    final acmiAPI = ACMIApiV2("https://testnet.accumulatenetwork.io", "v2");

    setUp(() {
      // Additional setup goes here.
      // 1. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed([0..32]);
      var publicKey  = ed.public(privateKey);

      // 2. Create New unique ACME url based on Protocol definition
      AccumulateURL currentURL = Address.generateAddressViaProtocol(publicKey.bytes, "ACME");
      Address liteAccount = Address(currentURL.getPath(), "ACME Account", "");
      liteAccount.URL = currentURL;

      // 3. Initiate API class instance and register address on the network with faucet
      ACMIApiV2 api = ACMIApiV2();
      final resp = await api.callFaucet(liteAccount);
    });

    test('First Test', () {
      expect(acmiAPI.toString(), isTrue);
    });
  });
}