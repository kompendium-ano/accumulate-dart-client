import 'dart:typed_data';

abstract class Payload{
  Uint8List marshalBinary();
  Uint8List hash();
}