import "dart:typed_data";
import '../tx_types.dart';
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "base_payload.dart";

class CreateIdentityParam {
  dynamic url;
  Uint8List? keyHash;
  dynamic keyBookUrl;
  List<AccURL>? authorities;
  String? memo;
  Uint8List? metadata;
}

class CreateIdentity extends BasePayload {
  late AccURL _url;
  Uint8List? _keyHash;
  AccURL? _keyBookUrl;
  List<AccURL>? _authorities;

  CreateIdentity(CreateIdentityParam createIdentityParam) : super() {
    _url = AccURL.toAccURL(createIdentityParam.url);
    _keyHash = createIdentityParam.keyHash!;
    if (createIdentityParam.keyBookUrl != null) {
      _keyBookUrl = AccURL.toAccURL(createIdentityParam.keyBookUrl);
    }

    _authorities = createIdentityParam.authorities;

    super.memo = createIdentityParam.memo;
    super.metadata = createIdentityParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.createIdentity, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));
    if (_keyHash != null) {
      forConcat.addAll(bytesMarshalBinary(_keyHash!, 3));
    }
    if (_keyBookUrl != null) {
      forConcat.addAll(stringMarshalBinary(_keyBookUrl.toString(), 4));
    }
    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 6));
      }
    }

    return forConcat.asUint8List();
  }
}
