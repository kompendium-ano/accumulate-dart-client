import 'dart:typed_data';

import 'base_payload.dart';

class FactomParam{

}

class Factom extends BasePayload{

  Factom(FactomParam factomParam) : super() {

  }

  @override
  Uint8List extendedMarshalBinary() {
    // TODO: implement extendedMarshalBinary
    throw UnimplementedError();
  }

}