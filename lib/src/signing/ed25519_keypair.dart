// lib\src\signing\ed25519_keypair.dart

import 'dart:convert';
import "dart:typed_data";
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import '../utils/utils.dart';

class Keypair {
  late Uint8List publicKey;
  late Uint8List secretKey;
  late String mnemonic;
}

class Ed25519Keypair {
  late Keypair _keypair;

  Ed25519Keypair([Keypair? keypair]) {
    if (keypair != null) {
      _keypair = keypair;
    } else {
      String mnemonic = bip39.generateMnemonic();
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);
      var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32));
      var publicKey = ed.public(privateKey);
      _keypair = Keypair();
      _keypair.secretKey = privateKey.bytes.asUint8List();
      _keypair.publicKey = publicKey.bytes.asUint8List();
      _keypair.mnemonic = mnemonic;
    }
  }

  static Ed25519Keypair generate() {
    String mnemonic = bip39.generateMnemonic();
    Uint8List seed = bip39.mnemonicToSeed(mnemonic);

    var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32));
    var publicKey = ed.public(privateKey);

    Keypair keypair = Keypair();
    keypair.secretKey = privateKey.bytes.asUint8List();
    keypair.publicKey = publicKey.bytes.asUint8List();
    keypair.mnemonic = mnemonic;
    return Ed25519Keypair(keypair);
  }

  static Ed25519Keypair fromMnemonic(String mnemonic) {
    Uint8List seed = bip39.mnemonicToSeed(mnemonic);

    var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32));
    var publicKey = ed.public(privateKey);

    Keypair keypair = Keypair();
    keypair.secretKey = privateKey.bytes.asUint8List();
    keypair.publicKey = publicKey.bytes.asUint8List();
    keypair.mnemonic = mnemonic;
    return Ed25519Keypair(keypair);
  }

  static Ed25519Keypair fromSecretKey(Uint8List secretKey,
      {bool skipValidation = true}) {
    var privateKey = ed.PrivateKey(secretKey);
    var publicKey = ed.public(privateKey);

    if (!skipValidation) {
      final message =
      utf8.encode("@accumulate/accumulate.js-validation-v1").asUint8List();
      final sig = ed.sign(privateKey, message);
      bool valid = ed.verify(publicKey, message, sig);
      if (!valid) {
        throw Exception('Invalid Private key');
      }
    }

    Keypair keypair = Keypair();
    keypair.secretKey = privateKey.bytes.asUint8List();
    keypair.publicKey = publicKey.bytes.asUint8List();
    keypair.mnemonic = "";

    return Ed25519Keypair(keypair);
  }

  static Ed25519Keypair fromSeed(Uint8List seed) {
    var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32));
    var publicKey = ed.public(privateKey);
    Keypair keypair = Keypair();
    keypair.secretKey = privateKey.bytes.asUint8List();
    keypair.publicKey = publicKey.bytes.asUint8List();
    keypair.mnemonic = "";

    return Ed25519Keypair(keypair);
  }

  Uint8List get publicKey {
    return _keypair.publicKey;
  }

  Uint8List get secretKey {
    return _keypair.secretKey;
  }

  String get mnemonic {
    return _keypair.mnemonic;
  }
}
