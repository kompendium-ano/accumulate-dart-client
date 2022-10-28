import 'dart:typed_data';

import 'package:accumulate_api6/src/signature_type.dart';
import 'package:accumulate_api6/src/signer.dart';
import 'package:accumulate_api6/src/signing/ed25519_keypair.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import "package:crypto/crypto.dart";
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hex/hex.dart';

class Ed25519KeypairSigner implements Signer {
  late Ed25519Keypair _keypair;

  Ed25519KeypairSigner(Ed25519Keypair ed25519keypair) {
    _keypair = ed25519keypair;
  }

  static Ed25519KeypairSigner generate() {
    return Ed25519KeypairSigner(Ed25519Keypair());
  }

  static Ed25519KeypairSigner fromMnemonic(String mnemonic) {
    return Ed25519KeypairSigner(Ed25519Keypair.fromMnemonic(mnemonic));
  }

  static Ed25519KeypairSigner fromKey(String pik) {
    return Ed25519KeypairSigner(Ed25519Keypair.fromSecretKey(HEX.decode(pik).asUint8List()));
  }

  static Ed25519KeypairSigner fromKeyRaw(Uint8List pik) {
    return Ed25519KeypairSigner(Ed25519Keypair.fromSecretKey(pik));
  }


  @override
  int get type => SignatureType.signatureTypeED25519;

  @override
  Uint8List publicKey() {
    return _keypair.publicKey;
  }

  @override
  Uint8List publicKeyHash() {
    List<int> bytes = sha256.convert(_keypair.publicKey).bytes;
    List hexBytes = [];
    for (var element in bytes) {
      hexBytes.add(HEX.encode([element]));
    }
    return sha256.convert(_keypair.publicKey).bytes.asUint8List();
  }

  @override
  Uint8List signRaw(Uint8List data) {
    var privateKey = ed.PrivateKey(_keypair.secretKey);
    return ed.sign(privateKey, data);
  }

  @override
  set type(int? _type) {}

  @override
  Uint8List secretKey() => _keypair.secretKey;

  @override
  String mnemonic() => _keypair.mnemonic;
}
