// lib\src\signing\ed25519_keypair_signer.dart

import 'dart:typed_data';
import 'package:logging/logging.dart';

import 'package:accumulate_api/accumulate_api.dart';
import "package:crypto/crypto.dart";
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hex/hex.dart';

final Logger _logger = Logger('Ed25519KeypairSigner');

class Ed25519KeypairSigner implements Signer {
  late Ed25519Keypair _keypair;

  Ed25519KeypairSigner(Ed25519Keypair ed25519keypair) {
    _keypair = ed25519keypair;
    _logger.info('Ed25519KeypairSigner initialized.');
  }

  static Ed25519KeypairSigner generate() {
    _logger.info('Generating new Ed25519 keypair.');
    return Ed25519KeypairSigner(Ed25519Keypair());
  }

  static Ed25519KeypairSigner fromMnemonic(String mnemonic) {
    _logger.info('Creating keypair signer from mnemonic (hidden for security).');
    return Ed25519KeypairSigner(Ed25519Keypair.fromMnemonic(mnemonic));
  }

  static Ed25519KeypairSigner fromKey(String pik) {
    _logger.info('Creating keypair signer from secret key (hex).');
    return Ed25519KeypairSigner(
        Ed25519Keypair.fromSecretKey(HEX.decode(pik).asUint8List()));
  }

  static Ed25519KeypairSigner fromKeyRaw(Uint8List pik) {
    _logger.info('Creating keypair signer from raw secret key (Uint8List).');
    return Ed25519KeypairSigner(Ed25519Keypair.fromSecretKey(pik));
  }

  @override
  int get type => SignatureType.signatureTypeED25519;

  @override
  Uint8List publicKey() {
    _logger.fine('Retrieving public key.');
    return _keypair.publicKey;
  }

  @override
  Uint8List publicKeyHash() {
    _logger.info('Generating public key hash.');

    List<int> bytes = sha256.convert(_keypair.publicKey).bytes;
    _logger.fine('Computed SHA-256 hash of public key: ${HEX.encode(bytes)}');

    List<String> hexBytes = [];
    for (var element in bytes) {
      hexBytes.add(HEX.encode([element]));
    }

    Uint8List pkHash = sha256.convert(_keypair.publicKey).bytes.asUint8List();
    _logger.fine('Final public key hash (Uint8List): ${HEX.encode(pkHash)}');
    
    return pkHash;
  }

  @override
  Uint8List signRaw(Uint8List data) {
    _logger.info('Signing raw data with Ed25519 keypair.');
    _logger.fine('Data to be signed: ${HEX.encode(data)}');

    var privateKey = ed.PrivateKey(_keypair.secretKey);
    Uint8List signature = ed.sign(privateKey, data);

    _logger.info('Signature generated successfully.');
    _logger.fine('Signature: ${HEX.encode(signature)}');

    return signature;
  }

  @override
  set type(int? _type) {
    _logger.warning('Attempted to set type, but this setter is intentionally left unimplemented.');
  }

  @override
  Uint8List secretKey() {
    _logger.fine('Retrieving secret key (hidden for security).');
    return _keypair.secretKey;
  }

  @override
  String mnemonic() {
    _logger.fine('Retrieving mnemonic (hidden for security).');
    return _keypair.mnemonic;
  }
}
