import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart';

void main() {
  group('Ed25519KeypairSigner', () {
    late Ed25519Keypair keypair;
    late Ed25519KeypairSigner keypairSigner;

    setUp(() {
      keypair = Ed25519Keypair();
      keypairSigner = Ed25519KeypairSigner(keypair);
    });

    test('Generate keypair signer', () {
      final generatedSigner = Ed25519KeypairSigner.generate();
      expect(generatedSigner, isNotNull);
    });

    test('Create keypair signer from mnemonic', () {
      final mnemonic = keypair.mnemonic;
      final signer = Ed25519KeypairSigner.fromMnemonic(mnemonic);
      expect(signer, isNotNull);
    });

    test('Create keypair signer from secret key', () {
      final secretKey = keypair.secretKey;
      final signer = Ed25519KeypairSigner.fromKeyRaw(secretKey);
      expect(signer, isNotNull);
    });

    test('Get public key', () {
      final publicKey = keypairSigner.publicKey();
      expect(publicKey, isNotNull);
      expect(publicKey.length, equals(32)); // Ed25519 public key length
    });

    test('Get public key hash', () {
      final publicKeyHash = keypairSigner.publicKeyHash();
      expect(publicKeyHash, isNotNull);
      expect(publicKeyHash.length, equals(32)); // SHA-256 hash length
    });

    test('Sign data', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = keypairSigner.signRaw(data);
      expect(signature, isNotNull);
      expect(signature.length, equals(64)); // Ed25519 signature length
    });

    test('Get type', () {
      final type = keypairSigner.type;
      expect(type, equals(SignatureType.signatureTypeED25519));
    });

    test('Get secret key', () {
      final secretKey = keypairSigner.secretKey();
      expect(secretKey, isNotNull);
      expect(secretKey.length, equals(64)); // Ed25519 secret key length
    });

    test('Get mnemonic', () {
      final mnemonic = keypairSigner.mnemonic();
      expect(mnemonic, isNotNull);
      // Adjust the expected word count to 12 to match the default behavior of bip39.generateMnemonic()
      expect(mnemonic.split(' ').length, equals(12));
    });
  });

}

