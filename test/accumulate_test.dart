import 'dart:typed_data';

import 'package:accumulate_api/accumulate.dart';
import 'package:accumulate_api/src/model/address.dart';
import 'package:accumulate_api/src/v2/api.dart';
import 'package:test/test.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('A group of tests', () {
    final acmeAPI = ACMEApiV2("https://testnet.accumulatenetwork.io", "v2");

    setUp(() async {
      // Additional setup goes here.
      // 1. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey  = ed.public(privateKey);

      // 2. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.URL = currentURL;

      // 3. Initiate API class instance and register address on the network with faucet
      final acmeAPI = ACMEApiV2("https://testnet.accumulatenetwork.io", "v2");
      final resp = await acmeAPI.callFaucet(liteAccount);
    });

    test('First Test', () {
      expect(acmeAPI.toString(), isTrue);
    });
  });
}