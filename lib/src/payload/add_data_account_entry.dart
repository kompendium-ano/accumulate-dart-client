import 'dart:typed_data';

import "base_payload.dart";
import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import '../utils.dart';

class CreateDataAccountEntryParam {
  dynamic url;
  List<AccURL>? authorities;
  String? memo;
  Uint8List? metadata;
}

class AddDataAccountEntry extends BasePayload {
  @override
  Uint8List extendedMarshalBinary() {
    // TODO: implement extendedMarshalBinary
    throw UnimplementedError();
  }

}