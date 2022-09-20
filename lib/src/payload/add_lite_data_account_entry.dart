import 'dart:typed_data';

import "base_payload.dart";
import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import '../utils.dart';

class CreateLiteDataAccountEntryParam {
  dynamic url;
  List<AccURL>? authorities;
  String? memo;
  Uint8List? metadata;
}

class AddLiteDataAccountEntry extends BasePayload {
  @override
  Uint8List extendedMarshalBinary() {
    // TODO: implement extendedMarshalBinary
    throw UnimplementedError();
  }

}