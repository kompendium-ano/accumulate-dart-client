import 'package:accumulate_api6/src/signing/ed25519_keypair.dart';
import 'package:test/test.dart';

void main() {
  test('should copy keypair from constructor', () {
    final Ed25519Keypair kp1 = Ed25519Keypair.generate();
    Keypair keypair = Keypair();
    keypair.secretKey = kp1.secretKey;
    keypair.publicKey = kp1.publicKey;
    keypair.mnemonic = kp1.mnemonic;

    final kp2 = Ed25519Keypair(keypair); // Ed25519Keypair and Keypair different types

    expect(kp1.publicKey, kp2.publicKey);
  });

  test('should create keypair from secret key', () {
    final kp1 = Ed25519Keypair.generate();
    final kp2 = Ed25519Keypair.fromSecretKey(kp1.secretKey);

    expect(kp1.publicKey, kp2.publicKey);
  });
}
