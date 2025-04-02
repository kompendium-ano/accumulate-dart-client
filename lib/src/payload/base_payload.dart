// lib\src\payload\base_payload.dart
import "dart:typed_data";
import 'package:logging/logging.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import '../utils/utils.dart';
import '../payload.dart';

final Logger _logger = Logger('BasePayload');

abstract class BasePayload implements Payload {
  Uint8List? _binary;
  Uint8List? _payloadHash;
  String? _memo;
  Uint8List? _metadata;

  @override
  set memo(String? _memoItem) {
    _logger.fine('Setting memo: ${_memoItem ?? "null"}');
    _memo = _memoItem;
  }

  @override
  String? get memo {
    _logger.fine('Retrieving memo: ${_memo ?? "null"}');
    return _memo;
  }

  @override
  set metadata(Uint8List? _metadataItem) {
    _logger.fine('Setting metadata: ${_metadataItem != null ? "Provided (${_metadataItem.length} bytes)" : "null"}');
    _metadata = _metadataItem;
  }

  @override
  Uint8List? get metadata {
    _logger.fine('Retrieving metadata: ${_metadata != null ? "Available (${_metadata!.length} bytes)" : "null"}');
    return _metadata;
  }

  @override
  Uint8List marshalBinary() {
    if (_binary != null) {
      _logger.fine('Returning cached marshaled binary data (${_binary!.length} bytes)');
      return _binary!;
    }

    _logger.info('Marshaling binary data.');
    _binary = extendedMarshalBinary();
    _logger.fine('Binary data marshaled successfully (${_binary!.length} bytes)');
    return _binary!;
  }

  @override
  Uint8List hash() {
    if (_payloadHash != null) {
      _logger.fine('Returning cached payload hash: ${_payloadHash != null ? "Available (${_payloadHash!.length} bytes)" : "null"}');
      return _payloadHash!;
    }

    _logger.info('Computing payload hash.');
    Uint8List marshaledData = extendedMarshalBinary();
    _payloadHash = sha256.convert(marshaledData).bytes.asUint8List();
    _logger.fine('Payload hash computed: ${_payloadHash != null ? HEX.encode(_payloadHash!) : "null"}');

    return _payloadHash!;
  }

  Uint8List extendedMarshalBinary();
}
