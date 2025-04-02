// lib\src\client\tx_signer.dart

import "dart:typed_data";
import 'package:logging/logging.dart';

import 'acc_url.dart';
import 'signer.dart';
import 'package:accumulate_api/src/transaction.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

final Logger _logger = Logger('TxSigner');

class TxSigner {
  late AccURL _url;
  late Signer _signer;
  late int _version;

  TxSigner(dynamic url, Signer signer, [int? version]) {
    _url = AccURL.toAccURL(url);
    _signer = signer;
    _version = version ?? 1;

    _logger.info('TxSigner initialized with URL: $_url, version: $_version, signer: ${_signer.runtimeType}');
  }

  static TxSigner withNewVersion(TxSigner signer, int version) {
    _logger.info('Creating new TxSigner with updated version: $version (previous: ${signer.version})');
    return TxSigner(signer.info.url.toString(), signer.signer, version);
  }

  Signer get signer => _signer;

  AccURL get url => _url;
  set url(AccURL value) {
    _logger.fine('Updating URL from $_url to $value');
    _url = value;
  }

  Uint8List get publicKey {
    final pk = _signer.publicKey();
    _logger.fine('Retrieved public key: ${HEX.encode(pk)}');
    return pk;
  }

  Uint8List get secretKey {
    final sk = _signer.secretKey();
    _logger.fine('Retrieved secret key (hidden for security)');
    return sk;
  }

  String get mnemonic {
    final mnemonic = _signer.mnemonic();
    _logger.fine('Retrieved mnemonic (hidden for security)');
    return mnemonic;
  }

  Uint8List get publicKeyHash {
    final pkHash = _signer.publicKeyHash();
    _logger.fine('Retrieved public key hash: ${HEX.encode(pkHash)}');
    return pkHash;
  }

  int get version => _version;

  SignerInfo get info {
    SignerInfo signerInfo = SignerInfo();
    signerInfo.url = url;
    signerInfo.publicKey = publicKey;
    signerInfo.version = _version;
    signerInfo.type = _signer.type;

    _logger.fine('Generated SignerInfo: '
        'URL=${signerInfo.url}, '
        'Public Key=${signerInfo.publicKey}, '
        'Version=${signerInfo.version}, '
        'Type=${signerInfo.type}');

    return signerInfo;
  }

  Signature sign(Transaction tx) {
    _logger.info('Signing transaction with timestamp: ${tx.header.timestamp}');
    
    Signature signature = Signature();
    signature.signerInfo = info;
    
    Uint8List signData = tx.dataForSignature(info).asUint8List();
    _logger.fine('Data for signature computed (${signData.length} bytes)');

    signature.signature = signer.signRaw(signData);
    _logger.info('Transaction signed successfully.');

    return signature;
  }

  // Debug method for multisig transaction
  Signature signMultisigTransaction(String txHash) {
    _logger.info('Signing multisig transaction with txHash: $txHash');

    // Construct the signature metadata
    Map<String, dynamic> metadata = {
      'type': 'ed25519',
      'publicKey': HEX.encode(publicKey),
      'signer': _url.toString() + '/book/1',
      'signerVersion': _version,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    };

    _logger.fine('Multisig metadata: ${json.encode(metadata)}');

    // Encode metadata to JSON + compute its hash
    Uint8List metadataHash = sha256.convert(utf8.encode(json.encode(metadata))).bytes.asUint8List();
    _logger.fine('Computed SHA-256 hash of metadata: ${HEX.encode(metadataHash)}');

    // Concatenate metadata hash with provided transaction hash
    Uint8List txHashBytes = HEX.decode(txHash).asUint8List();
    Uint8List combinedHash = Uint8List.fromList([...metadataHash, ...txHashBytes]);
    _logger.fine('Combined metadata hash and transaction hash: ${HEX.encode(combinedHash)}');

    // Hash combination
    Uint8List finalHash = sha256.convert(combinedHash).bytes.asUint8List();
    _logger.fine('Final hashed data to sign: ${HEX.encode(finalHash)}');

    // Sign resultant final hash
    Uint8List signatureBytes = _signer.signRaw(finalHash);
    _logger.info('Multisig transaction successfully signed.');

    // Create and return the signature object
    Signature multisigSignature = Signature();
    multisigSignature.signerInfo = info;
    multisigSignature.signature = signatureBytes;

    return multisigSignature;
  }
}
