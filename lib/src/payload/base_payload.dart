import "dart:typed_data";
import '../utils.dart';
import 'package:crypto/crypto.dart';

import "../payload.dart";

abstract class BasePayload implements Payload {
  Uint8List? _binary;
  Uint8List? _payloadHash;
  String? _memo;
  Uint8List? _metadata;

  @override
  set memo(String? _memoItem) {
      _memo = _memoItem;
  }

  @override
  String? get memo => _memo;

  @override
  set metadata(Uint8List? _metadataItem) {
    _metadata = _metadataItem;
  }

  @override
  Uint8List? get metadata => _metadata;


  @override
  Uint8List marshalBinary() {
    if (_binary != null) {
      return _binary!;
    }
    _binary = extendedMarshalBinary();
    return _binary!;
  }

  @override
  Uint8List hash() {
    if (_payloadHash != null) {
      return _payloadHash!;
    }
    _payloadHash = sha256.convert(extendedMarshalBinary()).bytes.asUint8List();
    return _payloadHash!;
  }

  Uint8List extendedMarshalBinary();
}
