import "dart:typed_data";
import "package:crypto/crypto.dart";

import "ed25519_keypair.dart";
import "ed25519_keypair_signer.dart";
import '../utils.dart';
import '../signature_type.dart';

class RCD1KeypairSigner extends Ed25519KeypairSigner {
  late Uint8List? _rcd1Hash;

  RCD1KeypairSigner(Ed25519Keypair ed25519keypair) : super(ed25519keypair);

  @override
  Uint8List publicKeyHash() {
    if (_rcd1Hash != null) {
      return _rcd1Hash!;
    }
    Uint8List hashList = Uint8List(publicKey().length + 1);
    hashList.addAll(Uint8List(1));
    hashList.addAll(publicKey());

    _rcd1Hash = sha256.convert(sha256.convert(hashList).bytes.asUint8List()).bytes.asUint8List();
    return _rcd1Hash!;
  }

  static RCD1KeypairSigner generate() {
    return RCD1KeypairSigner(Ed25519Keypair());
  }

  @override
  int get type {
    return SignatureType.signatureTypeRCD1;
  }
}
