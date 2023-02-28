import "dart:typed_data";

import 'package:accumulate_api6/accumulate_api6.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:bs58/bs58.dart';
import 'package:collection/collection.dart';
import "package:crypto/crypto.dart";

class RCD {
  int? version;
  Uint8List? pubkey;

  hash() {
    Uint8List? _rcd1Hash;

    Uint8List hashList = new Uint8List(pubkey!.length + 1);
    hashList.setAll(0, [1].asUint8List());
    hashList.setAll(1, pubkey!);

    _rcd1Hash = sha256.convert(sha256.convert(hashList).bytes.asUint8List()).bytes.asUint8List();

    return _rcd1Hash;
  }
}

class Factoid {
  String? faAddress;
  Uint8List? rcdHash;
  MultiHash? keypair;
}

Uint8List getRCDHashFromPublicKey(Uint8List pubkey, int version) {
  var r = RCD();
  r.pubkey = pubkey;
  r.version = version;

  return r.hash();
}

Uint8List getRCDFromFactoidAddress(String faAddress) {
  Uint8List? _rcd1Hash = Uint8List(1);

  if (faAddress.length != 52) {
    print("invalid factoid address length");
    return _rcd1Hash;
  }

  if (!faAddress.startsWith("FA")) {
    print("invalid factoid address prefix: $faAddress");
    return _rcd1Hash;
  }

  Uint8List faPrefix = [0x5f, 0xb1].asUint8List();
  var decodedFA = base58.decode(faAddress);

  if (!( ListEquality().equals(decodedFA.sublist(0, 2), faPrefix))) {
    print("invalid factoid base58 encoding prefix: $faAddress");
    return _rcd1Hash;
  }

  var checksumPre  = sha256.convert(decodedFA.sublist(0, 34));
  var checksum =  sha256.convert(checksumPre.bytes.asUint8List()).bytes.asUint8List();

  if( !(ListEquality().equals(decodedFA.sublist(34), checksum.sublist(0,4)) )){
    print("invalid checksum on factoid address: $faAddress");
    return _rcd1Hash;
  }

  _rcd1Hash = decodedFA.sublist(2, 34);
  return _rcd1Hash;
}

AccURL getLiteAccountFromFactoidAddress(String address) {
  Uint8List rcd1Hash = getRCDFromFactoidAddress(address);
  AccURL liteTokenAddressFromHash = LiteIdentity.computeUrl(rcd1Hash);
  return liteTokenAddressFromHash;
}

// Additional
String getAcmeLiteAccountFromFactoidAddress(String address){
  Uint8List rcd1Hash = getRCDFromFactoidAddress(address);
  AccURL liteTokenAddressFromHash = LiteIdentity.computeUrl(rcd1Hash);
  return "${liteTokenAddressFromHash.toString()}/acme";
}

// Additional
LiteIdentity getLiteIdentityFromFactoidFs(String fs){
  Factoid factoidInfo = getFactoidAddressRcdHashPkeyFromPrivateFs(fs);
  MultiHash ed25519keypair = MultiHash.fromSecretKey(factoidInfo.keypair!.secretKey);
  Ed25519KeypairSigner ed25519keypairSigner = Ed25519KeypairSigner(ed25519keypair);
  LiteIdentity lid = LiteIdentity(ed25519keypairSigner);
  return lid;
}

LiteIdentity getLiteIdentityFromFactoidFs_Ext(String fs){
  Factoid factoidInfo = getFactoidAddressRcdHashPkeyFromPrivateFs(fs);
  RCD1KeypairSigner rcdKeyPairSigner = RCD1KeypairSigner(factoidInfo.keypair!);
  LiteIdentity lid = LiteIdentity(rcdKeyPairSigner);
  return lid;
}

String getFactoidAddressFromRCDHash(Uint8List rcd1Hash) {

  if (rcd1Hash.length != 32) {
    print("invalid RCH Hash length must be 32 bytes");
    return "";
  }

  // hash := make([]byte, 34)
  Uint8List hash = Uint8List(34);
  // faPrefix := []byte{0x5f, 0xb1}
  Uint8List faPrefix = [0x5f, 0xb1].asUint8List();

  // copy(hash[:2], faPrefix)
  // copy(hash[2:], rcd[:])
  hash.setAll(0, faPrefix);
  hash.setAll(2, rcd1Hash);

  // checkSum := sha256.Sum256(hash[:])
  // checkSum = sha256.Sum256(checkSum[:])
  var checksumPre  = sha256.convert(hash);
  var checksum =  sha256.convert(checksumPre.bytes.asUint8List()).bytes.asUint8List();

  // fa := make([]byte, 38)
  Uint8List fa = Uint8List(38);

  // copy(fa[:34], hash)
  // copy(fa[34:], checkSum[:4])
  fa.setAll(0, hash);
  fa.setAll(34, checksum.sublist(0,4));

  // FA := base58.Encode(fa)
  String faAddress = base58.encode(fa);

  if(!faAddress.startsWith("FA")){
    print("invalid factoid address prefix, expecting FA but $faAddress");
    return "";
  }

  return faAddress;
}

// This function takes in the Factoid Private Key Fs
// and returns Factoid Address FA, RCDHash ,privatekey(64bits)
Factoid getFactoidAddressRcdHashPkeyFromPrivateFs(String fsAddress) {
  Factoid f = Factoid();

  if (fsAddress.length != 52) {
    print("invalid factoid address length");
    return f;
  }

  if (!fsAddress.startsWith("Fs")) {
    print("invalid factoid address prefix: $fsAddress");
    return f;
  }

  Uint8List fsPrefix = [0x64, 0x78].asUint8List();
  var decodedFS = base58.decode(fsAddress);

  if (!( ListEquality().equals(decodedFS.sublist(0, 2), fsPrefix))) {
    print("invalid factoid base58 encoding prefix: $fsAddress");
    return f;
  }

  var checksumPre  = sha256.convert(decodedFS.sublist(0, 34));
  var checksum =  sha256.convert(checksumPre.bytes.asUint8List()).bytes.asUint8List();

  if( !(ListEquality().equals(decodedFS.sublist(34), checksum.sublist(0,4)) )){
    print("invalid checksum on factoid address: $fsAddress");
    return f;
  }

  var seed = decodedFS.sublist(2, 34);
  var keyPair = MultiHash.fromSeed(seed);
  var rcdHash = getRCDHashFromPublicKey(keyPair.publicKey, 1);
  var faAddress = getFactoidAddressFromRCDHash(rcdHash);

  Factoid f2 = Factoid();
  f2..faAddress = faAddress
    ..keypair = keyPair
    ..rcdHash = rcdHash;

  return f2;
}

String getFactoidSecretFromPrivKey(Uint8List pk) {

  if (pk.length != 64) {
    print("invalid private key must be 64 bytes long");
    return "";
  }

  Uint8List faPrefix = [0x64, 0x78].asUint8List();

  Uint8List hash = Uint8List(34);
  hash.setAll(0, faPrefix);
  hash.setAll(2, pk.sublist(0, 32));

  var checksumPre  = sha256.convert(hash);
  var checksum = sha256.convert(checksumPre.bytes.asUint8List()).bytes.asUint8List();

  Uint8List fsraw = Uint8List(38);
  fsraw.setAll(0, hash);
  fsraw.setAll(34, checksum.sublist(0,4));

  String fs = base58.encode(fsraw);
  return fs;
}
