import 'dart:io';
import 'dart:math';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:test/test.dart';

@Timeout(Duration(seconds: 300))
void main() {
  group('Testnet Tests', () {
    ACMEClient client = ACMEClient("https://testnet.accumulatenetwork.io/v2/");

    setUp(() async {});

    void testFeatures() async {
      LiteIdentity lid;
      String identityUrl;
      TxSigner identityKeyPageTxSigner;

      final oracle = await client.valueFromOracle();

      lid = LiteIdentity(Ed25519KeypairSigner.generate());

      print("new account ${lid.acmeTokenAccount.toString()}");

      dynamic res = await client.faucet(lid.acmeTokenAccount);

      String txId = res["result"]["txid"];
      print("faucet txId $txId");

      await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
      print("transaction complete");

      res = await client.queryUrl(lid.url);
      print(res);

      res = await client.queryUrl(lid.acmeTokenAccount);
      print(res);

      int creditAmount = 60000;
      AddCreditsParam addCreditsParam = AddCreditsParam();
      addCreditsParam.recipient = lid.url;
      addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ 1;
      addCreditsParam.oracle = oracle;

      res = await client.addCredits(lid.url, addCreditsParam, lid);

      txId = res["result"]["txid"];
      print("addCredits txId $txId");

      identityUrl = "acc://adi-${DateTime.now().millisecondsSinceEpoch}";
      final identitySigner = Ed25519KeypairSigner.generate();
      final bookUrl = identityUrl + "/my-book";
      CreateIdentityParam createIdentity = CreateIdentityParam();

      // Create identity

      createIdentity.url = identityUrl;
      createIdentity.keyHash = identitySigner.publicKeyHash();
      createIdentity.keyBookUrl = bookUrl;

      res = await client.createIdentity(lid.url, createIdentity, lid);
      txId = res["result"]["txid"];
      print("createIdentity txId $txId");

      await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);
      print("transaction complete");

      //res = await client.queryUrl(identityUrl);

      final keyPageUrl = bookUrl + "/1";

      creditAmount = 60000;
      sleep(const Duration(seconds: 10));
      addCreditsParam = AddCreditsParam();
      addCreditsParam.recipient = keyPageUrl;
      addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;
      addCreditsParam.oracle = oracle;

      await client.addCredits(client, addCreditsParam, lid);

      identityKeyPageTxSigner = TxSigner(keyPageUrl, identitySigner);

      //Send Token
      final recipient =
          LiteIdentity(Ed25519KeypairSigner.generate()).acmeTokenAccount;

      const amount = 12000;

      SendTokensParam sendTokensParam = SendTokensParam();
      TokenRecipientParam tokenRecipientParam = TokenRecipientParam();
      tokenRecipientParam.url = recipient;
      tokenRecipientParam.amount = amount;
      sendTokensParam.to = [tokenRecipientParam];

      res = await client.sendTokens(lid.acmeTokenAccount, sendTokensParam, lid);

      txId = res["result"]["txid"];

      await client.waitOnTx(DateTime.now().millisecondsSinceEpoch, txId);

      res = await client.queryTx(txId);
      print(res);
    }

    //exit(0);
  }, timeout: Timeout(Duration(minutes: 8)));
}
