import "dart:typed_data";
import "dart:async";
import "acc_url.dart";
import "signer.dart" show Signature, Signer, SignerInfo;
import "transaction.dart" show Transaction;
import 'utils.dart';

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
    return TxSigner (signer.info.url.toString(), signer.signer, version);
  }

  Signer get signer => _signer;

  AccURL get url => _url;

  Uint8List get publicKey => _signer.publicKey();

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
    Signature signature = Signature();
    signature.signerInfo = info;
    signature.signature = signer.signRaw(tx.dataForSignature(info).asUint8List());
    return signature;

  }

}