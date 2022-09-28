import 'dart:convert';

import 'package:accumulate_api6/src/model/factom/factom_entry.dart';
import 'package:accumulate_api6/src/payload/factom_data_entry.dart';
import 'package:accumulate_api6/src/signing/ed25519_keypair.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  test('should write Factom data', () {
    final Ed25519Keypair kp1 = Ed25519Keypair.generate();
    Keypair keypair = Keypair();
    keypair.secretKey = kp1.secretKey;
    keypair.publicKey = kp1.publicKey;
    keypair.mnemonic = kp1.mnemonic;

    final kp2 = Ed25519Keypair(keypair); // Ed25519Keypair and Keypair different types

    FactomEntry fe = FactomEntry(utf8.encode("TheData").asUint8List());
    fe.addExtRef("Kompendium");
    fe.addExtRef("Test val");

    FactomDataEntryParam factomDataEntryParam = FactomDataEntryParam();
    factomDataEntryParam.data = fe.data;
    factomDataEntryParam.extIds = fe.getExtRefs();
    factomDataEntryParam.accountId = fe.calculateChainId();
    
    expect(kp1.publicKey, kp2.publicKey);
  });


}
