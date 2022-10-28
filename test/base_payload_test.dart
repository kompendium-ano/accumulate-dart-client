import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate_api6/src/payload/base_payload.dart';
import 'package:accumulate_api6/src/utils/utils.dart';
import 'package:test/test.dart';

class TestPayload extends BasePayload {
  int _counter = 0;

  @override
  Uint8List extendedMarshalBinary() {
    // TODO: implement extendedMarshalBinary
    //throw UnimplementedError();
    this._counter++;
    return utf8.encode("test").asUint8List();
  }
}

void main() {
  test('should cache marshal binary result', () {

    final payload = TestPayload();
    final bin = payload.extendedMarshalBinary();

    expect(bin, utf8.encode("test").asUint8List());
    expect(payload._counter, 1);

    final bin2 = payload.extendedMarshalBinary();

    expect(bin2, utf8.encode("test").asUint8List());
    expect(payload._counter, 1);

  });
}