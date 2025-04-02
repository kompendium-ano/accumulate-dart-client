// lib\src\client\lite_identity.dart

import 'dart:convert';
import "dart:typed_data";
import "package:crypto/crypto.dart";
import 'package:hex/hex.dart';
import 'acc_url.dart';
import 'signer.dart';
import 'tx_signer.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LiteIdentity');

class LiteIdentity extends TxSigner {
  LiteIdentity(Signer signer)
      : super(LiteIdentity.computeUrl(signer.publicKeyHash()), signer) {
    _logger.info('LOG: LiteIdentity instantiated with signer: ${signer.runtimeType}');
  }

  AccURL get acmeTokenAccount {
    final tokenUrl = url.append(ACME_TOKEN_URL);
    _logger.fine('LOG: Generated acmeTokenAccount URL: $tokenUrl');
    return tokenUrl;
  }

  static AccURL computeUrl(Uint8List publicKeyHash) {
    _logger.info('LOG: Computing URL with publicKeyHash: ${HEX.encode(publicKeyHash)}');

    final pkHash = publicKeyHash.sublist(0, 20);
    _logger.fine('LOG: Extracted first 20 bytes of publicKeyHash: ${HEX.encode(pkHash)}');

    final checkSum = sha256.convert(utf8.encode(HEX.encode(pkHash).toLowerCase())).bytes;
    _logger.fine('LOG: Computed SHA-256 checksum: ${HEX.encode(checkSum)}');

    final checkSumSlice = checkSum.sublist(checkSum.length - 4);
    _logger.fine('LOG: Extracted last 4 bytes of checksum: ${HEX.encode(checkSumSlice)}');

    List<int> forConcat = [];
    forConcat.addAll(pkHash);
    forConcat.addAll(checkSumSlice);
    _logger.fine('LOG: Concatenated pkHash and checksum slice: ${HEX.encode(forConcat)}');

    final authority = HEX.encode(forConcat).toLowerCase();
    final accUrl = AccURL.parse('acc://${authority}');
    _logger.info('LOG: Computed AccURL: $accUrl');

    return accUrl;
  }
}
