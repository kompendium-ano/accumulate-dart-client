// lib\src\client\tx_signer.dart

import "dart:typed_data";
import 'acc_url.dart';
import 'signer.dart';
import 'package:accumulate_api/src/transaction.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

class TxSigner {
  late AccURL _url;

  late Signer _signer;

  late int _version;

  TxSigner(dynamic url, Signer signer, [int? version]) {
    _url = AccURL.toAccURL(url);
    _signer = signer;
    _version = version ?? 1;
  }

  static TxSigner withNewVersion(TxSigner signer, int version) {
    return TxSigner(signer.info.url.toString(), signer.signer, version);
  }

  Signer get signer => _signer;

  AccURL get url => _url;
  set url(AccURL value) {
    _url = value;
  }

  Uint8List get publicKey => _signer.publicKey();
  Uint8List get secretKey => _signer.secretKey();
  String get mnemonic => _signer.mnemonic();

  Uint8List get publicKeyHash => _signer.publicKeyHash();

  int get version => _version;

  SignerInfo get info {
    SignerInfo signerInfo = SignerInfo();
    signerInfo.url = url;
    signerInfo.publicKey = publicKey;
    signerInfo.version = _version;
    signerInfo.type = _signer.type;
    return signerInfo;
  }

  Signature sign(Transaction tx) {
    print("Signing with timestamp: ${tx.header.timestamp}");
    Signature signature = Signature();
    signature.signerInfo = info;
    signature.signature =
        signer.signRaw(tx.dataForSignature(info).asUint8List());
    return signature;
  }

  // TODO debug method for multisig transaction
  Signature signMultisigTransaction(String txHash) {
    // Construct the signature metadata
    Map<String, dynamic> metadata = {
      'type': 'ed25519',
      'publicKey': HEX.encode(publicKey),
      'signer': _url.toString() + '/book/1',
      'signerVersion': _version,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    };

    // Encode metadata to JSON + compute its hash
    Uint8List metadataHash =
        sha256.convert(utf8.encode(json.encode(metadata))).bytes.asUint8List();

    // Concatenate metadata hash with provided transaction hash
    Uint8List txHashBytes = HEX.decode(txHash).asUint8List();
    Uint8List combinedHash =
        Uint8List.fromList([...metadataHash, ...txHashBytes]);

    // Hash combination
    Uint8List finalHash = sha256.convert(combinedHash).bytes.asUint8List();

    // Sign resultant final hash
    Uint8List signature = _signer.signRaw(finalHash);

    // Create, return the signature object
    Signature multisigSignature = Signature();
    multisigSignature.signerInfo = info;
    multisigSignature.signature = signature;
    return multisigSignature;
  }
}