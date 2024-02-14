import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart';

void main() {
  group('RCD1KeypairSigner', () {
    late Ed25519Keypair ed25519Keypair;
    late RCD1KeypairSigner rcd1KeypairSigner;

    setUp(() {
      ed25519Keypair = Ed25519Keypair.generate(); // You can provide your own test keypair if needed
      rcd1KeypairSigner = RCD1KeypairSigner(ed25519Keypair);
    });

    test('RCD1KeypairSigner initialization', () {
      expect(rcd1KeypairSigner, isNotNull);
      expect(rcd1KeypairSigner.publicKey(), isNotNull);
      expect(rcd1KeypairSigner.secretKey(), isNotNull);
    });

    test('Get RCD1KeypairSigner type', () {
      expect(rcd1KeypairSigner.type, SignatureType.signatureTypeRCD1);
    });

    test('Get RCD1 public key hash', () {
      final publicKeyHash = rcd1KeypairSigner.publicKeyHash();
      expect(publicKeyHash, isNotNull);
      // You might want to validate the expected public key hash based on your test data.
    });

    test('Generate RCD1KeypairSigner', () {
      final generatedRCD1KeypairSigner = RCD1KeypairSigner.generate();

      expect(generatedRCD1KeypairSigner, isNotNull);
      expect(generatedRCD1KeypairSigner.type, SignatureType.signatureTypeRCD1);
      expect(generatedRCD1KeypairSigner.publicKey(), isNotNull);
      expect(generatedRCD1KeypairSigner.secretKey(), isNotNull);
    });
  });
}

