// import 'dart:typed_data';
//
// import 'package:accumulate_api6/src/client/signature_type.dart';
// import 'package:accumulate_api6/src/client/signer.dart';
// import 'package:accumulate_api6/src/signing/ed25519_keypair.dart';
// import 'package:accumulate_api6/src/signing/multihash.dart';
// import 'package:accumulate_api6/src/utils/utils.dart';
// import "package:crypto/crypto.dart";
// import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
// import 'package:hex/hex.dart';
//
// class MultihashKeypairSigner implements Signer {
//   late MultiHash _keypair;
//
//   MultihashKeypairSigner(MultiHash multihash) {
//     _keypair = multihash;
//   }
//
//   static MultihashKeypairSigner generate() {
//     return MultihashKeypairSigner(MultiHash());
//   }
//
//   static MultihashKeypairSigner fromMnemonic(String mnemonic) {
//     return MultihashKeypairSigner(MultiHash.fromMnemonic(mnemonic));
//   }
//
//   static MultihashKeypairSigner fromKey(String pik) {
//     return MultihashKeypairSigner(MultiHash.fromSecretKey(HEX.decode(pik).asUint8List()));
//   }
//
//   static MultihashKeypairSigner fromKeyRaw(Uint8List pik) {
//     return MultihashKeypairSigner(MultiHash.fromSecretKey(pik));
//   }
//
//
//   @override
//   int get type => SignatureType.signatureTypeED25519;
//
//   @override
//   Uint8List publicKey() {
//     return _keypair.publicKey;
//   }
//
//   @override
//   Uint8List publicKeyHash() {
//     List<int> bytes = sha256.convert(_keypair.publicKey).bytes;
//     List hexBytes = [];
//     for (var element in bytes) {
//       hexBytes.add(HEX.encode([element]));
//     }
//     return sha256.convert(_keypair.publicKey).bytes.asUint8List();
//   }
//
//   @override
//   Uint8List signRaw(Uint8List data) {
//     var privateKey = ed.PrivateKey(_keypair.secretKey);
//     return ed.sign(privateKey, data);
//   }
//
//   @override
//   set type(int? _type) {}
//
//   @override
//   Uint8List secretKey() => _keypair.secretKey;
//
//   @override
//   String mnemonic() => _keypair.mnemonic;
// }
