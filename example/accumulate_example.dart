import 'dart:typed_data';

import 'package:accumulate/accumulate.dart';
import 'package:accumulate/src/model/address.dart';
import 'package:test/test.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('A group of tests', () {
    final acmiAPI = ACMIApiV2("https://testnet.accumulatenetwork.io/", "v2");

    setUp(() async {

      // Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // Additional setup goes here.
      // 1. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey  = ed.public(privateKey);

      // 2. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      print(liteAccount.address);

      // 3. Initiate API class instance and register address on the network with faucet
      final acmiAPI = ACMIApiV2("https://testnet.accumulatenetwork.io/", "v2");
      final resp = await acmiAPI.callFaucet(liteAccount);
    });

    test('First Test', () {
      expect(acmiAPI.toString(), isTrue);
    });
  });
}