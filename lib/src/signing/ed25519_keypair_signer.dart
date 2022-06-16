import 'dart:typed_data';

import '../utils.dart';
import "package:crypto/crypto.dart";
import 'package:hex/hex.dart';
import '../signature_type.dart';
import "../signer.dart";
import "ed25519_keypair.dart";
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

class Ed25519KeypairSigner implements Signer {
  late Ed25519Keypair _keypair;

  Ed25519KeypairSigner(Ed25519Keypair ed25519keypair) {
    _keypair = ed25519keypair;
  }

  static Ed25519KeypairSigner generate() {
    return Ed25519KeypairSigner(Ed25519Keypair());
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
}
