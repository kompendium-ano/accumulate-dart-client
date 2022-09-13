import 'dart:typed_data';

import 'base_payload.dart';

class FactomParam{
  String? memo;
  Uint8List? metadata;
}

class Factom extends BasePayload{

  Factom(FactomParam factomParam) : super() {

    super.memo = factomParam.memo;
    super.metadata = factomParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    // TODO: implement extendedMarshalBinary
    throw UnimplementedError();
  }

}