import 'package:accumulate_api6/src/signing/ed25519_keypair.dart';
import 'package:test/test.dart';

void main() {
  test('should copy keypair from constructor', () {
    final MultiHash kp1 = MultiHash.generate();
    Keypair keypair = Keypair();
    keypair.secretKey = kp1.secretKey;
    keypair.publicKey = kp1.publicKey;
    keypair.mnemonic = kp1.mnemonic;

    final kp2 = MultiHash(keypair); // Ed25519Keypair and Keypair different types

    expect(kp1.publicKey, kp2.publicKey);
  });

  test('should create keypair from secret key', () {
    final kp1 = MultiHash.generate();
    final kp2 = MultiHash.fromSecretKey(kp1.secretKey);

    expect(kp1.publicKey, kp2.publicKey);
  });
}
