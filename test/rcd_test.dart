import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate_api6/accumulate_api6.dart';
import 'package:accumulate_api6/src/model/factom/factom_scanner.dart';
import 'package:accumulate_api6/src/signing/rcd.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_bip44/bitcoin_bip44.dart';
import 'package:test/test.dart';

// seed - carry bullet century olympic core drift between axis draw pilot pluck wash
//
void main() {

  handleView(Address value){
    //print(value.publicKey.getEncoded());
    print(getFactoidAddressFromRCDHash(getRCDHashFromPublicKey(value.publicKey.getEncoded(false), 1)));
  }

  test('should construct RCD hash', () {

    String fa = "FA27j6v5HGrG987D5ksQvgHc5jpPww7dhB1VuYRSrxm9rEmANatK";
    var rcdHash = getRCDFromFactoidAddress(fa);


    AccURL? lidFromFA;
    String la;
    if(rcdHash.length > 1){
      lidFromFA = getLiteAccountFromFactoidAddress(fa);
      la = getAcmeLiteAccountFromFactoidAddress(fa);
      //var la = parseStringToAccumulateURL();
      print("LITE ACC: $la");
    }

    String fs = "Fs2yxj5FYs2VhYrpHT6VQ3n8fjaGJCCFA79n4ZKN8PiiczxHeXH7";
    var factoidInfo = getFactoidAddressRcdHashPkeyFromPrivateFs(fs);
    print("FA FROM  FS: ${factoidInfo.faAddress}");
    print("RCD from FA: $rcdHash");
    print("RCD from FS: ${factoidInfo.rcdHash}");
    print("FA FROM RCD: ${getFactoidAddressFromRCDHash(factoidInfo.rcdHash!)}");


    print("----------------------------------------------");
    print("Reconstruct ED25519");

    Ed25519Keypair ed25519keypair = Ed25519Keypair.fromSecretKey(factoidInfo.keypair!.secretKey);
    Ed25519KeypairSigner ed25519keypairSigner = Ed25519KeypairSigner(ed25519keypair);
    LiteIdentity lid = LiteIdentity(ed25519keypairSigner);

    print("PubKey from Fs:     ${factoidInfo.keypair!.publicKey.toString()}");
    print("PubKey from Rec:    ${ed25519keypair.publicKey.toString()}");
    print("PubKey from Signer: ${ed25519keypairSigner.publicKey().toString()}");
    print("----------------------------------------------");

    print("PrivKey from Fs:     ${factoidInfo.keypair!.secretKey.toString()}");
    print("PrivKey from Rec:    ${ed25519keypair.secretKey.toString()}");
    print("PrivKey from Signer: ${ed25519keypairSigner.secretKey().toString()}");
    print("----------------------------------------------");
    print("LID url from Signer: ${lid.url}");
    print("LID url from FA:     ${lidFromFA}");

    ///////////////////////////////////////////////////////////////

    var secret = getFactoidSecretFromPrivKey(factoidInfo.keypair!.secretKey);
    print("SECRET ORIGINAL  : $fs");
    print("SECRET FROM PRIVK: ${secret}");

    print("\n----------------------------------------------");
    print("| Mnemonics \n");
    // Mnemonic workflow

    String mnemonic = "carry bullet century olympic core drift between axis draw pilot pluck wash";
    List<String> seedPhraseWords =
        ["carry", "bullet", "century", "olympic", "core", "drift", "between", "axis", "draw", "pilot", "pluck", "wash"];

    // Add a scanner of your own:
    scanners = [FactomScanner()];
    var bip44 = Bip44(bip39.mnemonicToSeedHex(mnemonic));
    var bip44W = Bip44(toHexString(mnemonic));
    bip44.hashCode;
    bip44W.hashCode;

    var factoid = bip44.coins[130];
    print(factoid.path);

    for (var i = 0; i < 100; i++) {
      var account = Account(factoid, i, 0);
      account.nextUnusedAddress(0).then((value) => handleView(value));

      // ExtendedKey? key44 = account.chain.forPath("m/44'/131'/0'/0/0");
      // const String alphabet =
      //     '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
      // List<int> s = Base58Codec(alphabet).decode(key44.toString());
      // Ed25519Keypair kp = Ed25519Keypair.fromSecretKey(s.asUint8List());

    }


    var seed = bip39.mnemonicToSeed("carry bullet century olympic core drift between axis draw pilot pluck wash");
    Ed25519Keypair ed25519keypair2 = Ed25519Keypair.fromSeed(seed);
    var secret2 = getFactoidSecretFromPrivKey(ed25519keypair2.secretKey);

    print("CORRECT: Fs2yxj5FYs2VhYrpHT6VQ3n8fjaGJCCFA79n4ZKN8PiiczxHeXH7");
    print("CALC:    $secret2");

    //var rcd2 = getRCDHashFromPublicKey(ed25519keypair.publicKey, 1);
    //var addr = getFactoidAddressFromRCDHash(rcd2);
    //print("$secret2");
    print("CALC: ${factoidInfo.faAddress}");

    expect(fa, factoidInfo.faAddress);

  });



}
