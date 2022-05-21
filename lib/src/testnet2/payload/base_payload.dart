import "dart:typed_data";
import "../payload.dart" show Payload;

abstract class BasePayload implements Payload {
  Uint8List? _binary;
  @override
  Uint8List marshalBinary() {
    if (_binary != null) {
      return _binary!;
    }
    _binary = _marshalBinary();
    return _binary!;
  }

  Uint8List _marshalBinary();
}
