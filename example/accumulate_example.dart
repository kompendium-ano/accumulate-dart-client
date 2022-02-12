import 'dart:io';
import 'dart:typed_data';

import 'package:accumulate/accumulate.dart';
import 'package:accumulate/src/model/address.dart';
import 'package:accumulate/src/model/adi.dart';
import 'package:test/test.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('DevNet Tests', () {
    final testnetAPI = ACMEApiV2("https://testnet.accumulatenetwork.io/", "v2");

    setUp(() async {});

    Future<String> makeFaucetTest() async {
      // Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // Additional setup goes here.
      // 1. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 2. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      print(liteAccount.address);

      // 3. Initiate API class instance and register address on the network with faucet
      final acmeAPI = ACMEApiV2("https://devnet.accumulatenetwork.io/", "v2");
      final resp = await acmeAPI.callFaucet(liteAccount);
      return resp;
    }

    Future<String> makeCreditsTest() async {
      // 1. Generate some random data for private keys
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      // 2. initiate public/private keypage
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32)); // Uint8List.fromList(List.generate(32, (index) => 0)));
      var publicKey = ed.public(privateKey);

      // 3. Create New unique ACME url based on Protocol definition
      Address liteAccount = Address("", "ACME Account", "");
      AccumulateURL currentURL = liteAccount.generateAddressViaProtocol(publicKey.bytes, "ACME");
      liteAccount.address = currentURL.getPath();
      liteAccount.URL = currentURL;

      //   3.1 Store associated private key data along with Address structure
      //       internal methods will use it to sign payloads
      liteAccount.puk = HEX.encode(publicKey.bytes);
      liteAccount.pik = privateKey.bytes;
      liteAccount.pikHex = HEX.encode(privateKey.bytes);

      print(liteAccount.address);

      // 4. Initiate API class instance and register address on the network with faucet
      final acmeAPI = ACMEApiV2("http://178.20.158.25:56660/", "v2");
      final respFaucet = await acmeAPI.callFaucet(liteAccount);
      print('faucet - ${respFaucet}');

      // 5. Wait at least 4 seconds for a transaction to settle on the network
      final sleep = await Future.delayed(Duration(seconds: 5));
      final resptx = await acmeAPI.callGetTokenTransaction(respFaucet);

      // 6. Credits are converted from ACME token
      //   6.1 Get current timestamp in microseconds it works as Nonce
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

      //   6.2 Execute actual credits call
      final respCredits = await acmeAPI.callAddCredits(liteAccount, 1000, timestamp);
      print('credits - ${respCredits}');

      //   6.3 Check that balance indeed updated
      final respAccount = await acmeAPI.callQuery(liteAccount.address);
      print(respAccount.creditBalance.toString());

      return respAccount.url;
    }

    Future<String> makeAdiTest() async {
      Address currAddr = Address("acc://dfdc4d9ec31f8dce909cdcaba2ec1d17ccd07f49fdb2bff0/acme", "web1", "");
      currAddr
        ..pikHex =
            "5aa68d91be19c570d01b2c4bb24fd4fd3e3d4fa27a0d8f3a89796c8adf2bef90efc5553bb18b3ab3a41629e72eb32fe0d6060d954b0c6d854ee7c6caae061a77"
        ..puk = "efc5553bb18b3ab3a41629e72eb32fe0d6060d954b0c6d854ee7c6caae061a77";

      IdentityADI newADI = IdentityADI("", "acc://cosmonaut1", "");
      newADI
        ..sponsor = currAddr.address
        ..puk = currAddr.puk
        ..pik = currAddr.pik
        ..countKeybooks = 1
        ..countAccounts = 0;

      // 3. add timestamp
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      //int timestampShort = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();

      final acmeAPI = ACMEApiV2("https://devnet.accumulatenetwork.io/", "v2");
      String txhash = "";
      try {
        final resp = await acmeAPI.callCreateAdi(currAddr, newADI, timestamp);
        txhash = resp;
      } catch (e) {
        e.toString();
        return "";
      }

      return txhash;
    }

    test('Faucet Test - Single Call', () async {
      final String resp = await makeFaucetTest();
      expect(resp.isNotEmpty, isTrue);
      final String respC = await makeCreditsTest();
      expect(respC.isNotEmpty, isTrue);
    });

    // test('Faucet Test - Multiple Calls Over Short Period', () async {
    //   // final String resp = await makeFaucetTest();
    //   // for (int i = 0; i < 10; i++) {
    //   //   final String resp = await makeFaucetTest();
    //   //   final sleep = await Future.delayed(Duration(seconds: 1));
    //   // }
    //   // expect(resp.isNotEmpty, isTrue);
    // });

    //exit(0);
  });
}
