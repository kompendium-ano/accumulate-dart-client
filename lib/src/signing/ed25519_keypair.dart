import "dart:typed_data";
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import '../../src/utils.dart';
import 'package:hex/hex.dart';

class Keypair {
late Uint8List publicKey;
late Uint8List secretKey;
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
    }
  }
  /**
   * Generate a new random keypair
   */
  static Ed25519Keypair generate() {
    String mnemonic = bip39.generateMnemonic();
    Uint8List seed = bip39.mnemonicToSeed(mnemonic);

    var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32));
    var publicKey = ed.public(privateKey);

    Keypair keypair = Keypair();
    keypair.secretKey = privateKey.bytes.asUint8List();
    keypair.publicKey = publicKey.bytes.asUint8List();
    return Ed25519Keypair(keypair);
  }


  static Ed25519Keypair fromSecretKey(Uint8List secretKey, [dynamic options]) {


    var privateKey = ed.PrivateKey(secretKey);
    var publicKey = ed.public(privateKey);

    Keypair keypair = Keypair();
    keypair.secretKey = privateKey.bytes.asUint8List();
    keypair.publicKey = publicKey.bytes.asUint8List();

    return Ed25519Keypair(keypair);
  }


  static Ed25519Keypair fromSeed(Uint8List seed) {

    var privateKey = ed.newKeyFromSeed(seed.sublist(0, 32));
    var publicKey = ed.public(privateKey);
    Keypair keypair = Keypair();
    keypair.secretKey = privateKey.bytes.asUint8List();
    keypair.publicKey = publicKey.bytes.asUint8List();

    return Ed25519Keypair(keypair);
  }

  /**
   * The raw public key for this keypair
   */
  Uint8List get publicKey {
    return _keypair.publicKey;
  }

  /**
   * The raw secret key for this keypair
   */
  Uint8List get secretKey {
    return _keypair.secretKey;
  }
}
