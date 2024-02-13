// lib\src\payload.dart

import 'dart:typed_data';

abstract class Payload{
  Uint8List marshalBinary();
  Uint8List hash();
  String? memo;
  Uint8List? metadata;
}