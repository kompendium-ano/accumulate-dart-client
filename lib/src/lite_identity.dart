import 'dart:convert';
import "dart:typed_data";
import 'package:hex/hex.dart';

import "acc_url.dart";
import "acme.dart";
import "package:crypto/crypto.dart";
import "signer.dart" show Signer;
import "tx_signer.dart" show TxSigner;


class LiteIdentity extends TxSigner {
  late AccURL _tokenUrl;

  LiteIdentity(Signer signer, [dynamic tokenUrl])
      : super(LiteIdentity.computeUrl(signer.publicKeyHash()), signer) {

    _tokenUrl = LiteIdentity.computeUrl(signer.publicKeyHash());
  }


  AccURL get acmeTokenAccount => AccURL.parse(_tokenUrl.toString()+"/${ACMETokenUrl.path}");


  static AccURL computeUrl(Uint8List publicKeyHash) {

    // 1. Get the hash of the public key
    Digest keyHash = sha256.convert(publicKeyHash); // keyHash := sha256.Sum256(pubKey)

    List<int> keyHashLeft = keyHash.bytes.sublist(0, 20);

    var keyStr = HEX.encode(keyHashLeft).toLowerCase();


    // 3. Calculate checksum
    Digest checkSum = sha256.convert(utf8.encode(keyStr));
    String checkStr = HEX
        .encode(checkSum.bytes.sublist(28, checkSum.bytes.length))
        .toLowerCase();

    String authority = keyStr + checkStr; // anonUrl.Authority = keyStr + checkStr

      print("acc://$authority");



    return AccURL.parse("acc://$authority");

  }

}
