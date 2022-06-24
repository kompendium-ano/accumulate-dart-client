import 'dart:convert';
import "dart:typed_data";

import 'package:hex/hex.dart';


import "acc_url.dart";
import "acme.dart";
import "package:crypto/crypto.dart";
import "signer.dart";
import "tx_signer.dart";


class LiteIdentity extends TxSigner{
  LiteIdentity(Signer signer)
      : super(LiteIdentity.computeUrl(signer.publicKeyHash()), signer);

  AccURL get acmeTokenAccount => AccURL.parse(
      url.toString() + "/${ACMETokenUrl.authority.toString().toUpperCase()}");

  static AccURL computeUrl(Uint8List publicKeyHash) {
    final pkHash = publicKeyHash.sublist(0, 20);

    var keyStr = HEX.encode(pkHash).toLowerCase();

    Digest checkSum = sha256.convert(utf8.encode(keyStr));
    String checkStr = HEX
        .encode(checkSum.bytes.sublist(28, checkSum.bytes.length))
        .toLowerCase();

    final authority = keyStr + checkStr;

    return AccURL.parse("acc://$authority");
  }
}
