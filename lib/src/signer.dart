import 'dart:typed_data';
import 'acc_url.dart';

abstract class Signer{

  Uint8List signRaw(Uint8List data);

  Uint8List publicKey();

  Uint8List publicKeyHash();

  int? type;
}

class Signature {
  SignerInfo? signerInfo;
  Uint8List? signature;
}

class SignerInfo {
  int? type;
  AccURL? url;
  Uint8List? publicKey;
  int? version;

  get toMap =>
      {"url": url, "publicKey": publicKey, "version": version, "type": type};
}
