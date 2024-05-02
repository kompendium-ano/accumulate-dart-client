// lib\src\client\lite_identity.dart
import 'dart:convert';
import "dart:typed_data";

import "package:crypto/crypto.dart";
import 'package:hex/hex.dart';

import 'acc_url.dart';
import 'signer.dart';
import 'tx_signer.dart';

class LiteIdentity extends TxSigner {
  LiteIdentity(Signer signer)
      : super(LiteIdentity.computeUrl(signer.publicKeyHash()), signer);

  AccURL get acmeTokenAccount => url.append(ACME_TOKEN_URL);

  static AccURL computeUrl(Uint8List publicKeyHash) {
    final pkHash = publicKeyHash.sublist(0, 20);
    final checkSum =
        sha256.convert(utf8.encode(HEX.encode(pkHash).toLowerCase())).bytes;
    final checkSumSlice = checkSum.sublist(checkSum.length - 4);
    List<int> forConcat = [];
    forConcat.addAll(pkHash);
    forConcat.addAll(checkSumSlice);
    final authority = HEX.encode(forConcat).toLowerCase();
    return AccURL.parse('acc://${authority}');
  }
}
