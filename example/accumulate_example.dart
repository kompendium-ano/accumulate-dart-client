import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:accumulate_api/src/lite_identity.dart';
import 'package:accumulate_api/src/payload/add_credits.dart';
import 'package:accumulate_api/src/payload/create_identity.dart';
import 'package:accumulate_api/src/payload/send_tokens.dart';
import 'package:accumulate_api/src/signer.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/tx_signer.dart';
import 'package:hex/hex.dart';
import 'package:accumulate_api/src/client.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import 'package:accumulate_api/src/utils.dart';


import 'package:accumulate_api/accumulate_api.dart';
import 'package:test/test.dart';

@Timeout(Duration(seconds: 300))
void main() {
  group('DevNet Tests', () {
    Client client = Client("https://testnet.accumulatenetwork.io/v2");

    setUp(() async {});

    Future<int> valueFromOracle() async{

      final oracle = await client.queryAcmeOracle();
      String priceHex = oracle["result"]["data"]["entry"]["data"][0];
      print(priceHex);
      dynamic priceInfo = jsonDecode(utf8.decode(HEX.decode(priceHex)));
      int price = priceInfo["price"];
      print(price);

      return price;
    }
    void testFeatures() async {
      LiteIdentity lid;
      String identityUrl;
      TxSigner identityKeyPageTxSigner;

      print("inside test app");
      final oracle = await valueFromOracle();

      lid = LiteIdentity(Ed25519KeypairSigner.generate());

      print("new account ${lid.acmeTokenAccount.toString()}");
      dynamic res = await client.faucet(lid.acmeTokenAccount);
      print("faucet $res");
      String txId = res["result"]["txid"];
      print("txId $txId");
      await client.waitOnTx(txId);
      print("waiting done");

      res = await client.queryUrl(lid.url);
      print(res);

      res = await client.queryUrl(lid.acmeTokenAccount);
      print(res);

      int creditAmount = 60000;
      sleep(const Duration(seconds: 10));
      AddCreditsArg addCreditsArg = AddCreditsArg();
      addCreditsArg.recipient = lid.url;
      addCreditsArg.amount = (creditAmount * pow(10, 8)) ~/ oracle;
      addCreditsArg.oracle = oracle;

      res = await client.addCredits(lid.url, addCreditsArg, lid);

      print("addCredits $res");
      txId = res["result"]["txid"];
      print("addCredits txId $txId");

      //final resAccountType = await client.queryUrl(acc.url);
      //print("resAccountType $resAccountType");

      identityUrl = "acc://${DateTime.now().millisecondsSinceEpoch}";
      final identitySigner = Ed25519KeypairSigner.generate();
      final bookUrl = identityUrl + "/my-book";
      CreateIdentityArg createIdentity = CreateIdentityArg();

      // Create identity

      createIdentity.url = identityUrl;
      createIdentity.keyHash = identitySigner.publicKeyHash();
      createIdentity.keyBookUrl = bookUrl;

      res = await client.createIdentity(lid.url, createIdentity, lid);
      txId = res["result"]["txid"];
      print("createIdentity txId $txId");
      await client.waitOnTx(txId);
      print("waiting done");

      //res = await client.queryUrl(identityUrl);

      final keyPageUrl = bookUrl + "/1";

      creditAmount = 60000;
      sleep(const Duration(seconds: 10));
      addCreditsArg = AddCreditsArg();
      addCreditsArg.recipient = keyPageUrl;
      addCreditsArg.amount = (creditAmount * pow(10, 8)) ~/ oracle;
      addCreditsArg.oracle = oracle;

      await client.addCredits(client, addCreditsArg, lid);

      identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);

      //Send Token
      final recipient =
          LiteIdentity(Ed25519KeypairSigner.generate()).acmeTokenAccount;

      const amount = 12;

      SendTokensArg sendTokensArg = SendTokensArg();
      TokenRecipientArg tokenRecipientArg = TokenRecipientArg();
      tokenRecipientArg.url = recipient;
      tokenRecipientArg.amount = amount;
      sendTokensArg.to = [tokenRecipientArg];

      res = await client.sendTokens(lid.acmeTokenAccount, sendTokensArg, lid);

      txId = res["result"]["txid"];
      await client.waitOnTx(txId);

      res = await client.queryTx(txId);
      print(res);
    }

    //exit(0);
  }, timeout: Timeout(Duration(minutes: 8)));
}
