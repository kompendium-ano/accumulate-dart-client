import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate_api6/accumulate_api6.dart';
import 'package:accumulate_api6/src/model/address.dart';
import 'package:accumulate_api6/src/signing/rcd.dart';
import 'package:accumulate_api6/src/utils/merkle_root_builder.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_bip44/bitcoin_bip44.dart';
import 'package:test/test.dart';


// seed - carry bullet century olympic core drift between axis draw pilot pluck wash
//
void main() {
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

    var factoidInfo = getFactoidAddressRcdHashPkeyFromPrivateFs("Fs2yxj5FYs2VhYrpHT6VQ3n8fjaGJCCFA79n4ZKN8PiiczxHeXH7");
    print(factoidInfo.faAddress);
    print("RCD from FA: $rcdHash");
    print("RCD from FS: ${factoidInfo.rcdHash}");
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
    print(secret);

    print("----------------------------------------------");
    print("| Mnemonics \n");
    // Mnemonic workflow
    String mnemonic = "";
    List<String> seedPhraseWords =
        ["carry", "bullet", "century", "olympic", "core", "drift", "between", "axis", "draw", "pilot", "pluck", "wash"];


    //var seed = bip44.mnemonicToSeed("carry bullet century olympic core drift between axis draw pilot pluck wash");
    var bip44 = Bip44(toHexString('carry bullet century olympic core drift between axis draw pilot pluck wash'));
    var factoid = bip44.coins[131];
    var account = Account(factoid, 0, changeExternal);

    account.usedAddresses(0).then(print);

    //Ed25519Keypair ed25519keypair = Ed25519Keypair.fromSeed(seed);
    //var secret2 = getFactoidSecretFromPrivKey(ed25519keypair.secretKey);

    //var rcd2 = getRCDHashFromPublicKey(ed25519keypair.publicKey, 1);
    //var addr = getFactoidAddressFromRCDHash(rcd2);
    //print("$secret2");

    expect(fa, factoidInfo.faAddress);

  });


}

String toHexString(String original) {
  return original.codeUnits
      .map((c) => c.toRadixString(16).padLeft(2, '0'))
      .toList()
      .join('');
}