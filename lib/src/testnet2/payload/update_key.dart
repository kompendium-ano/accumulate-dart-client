import "dart:typed_data";
import 'package:acc_lib/utils.dart';

import "../marshaller.dart";
import "../tx_types.dart";
import "base_payload.dart";

class UpdateKeyArg  {
late Uint8List newKeyHash;
}

class UpdateKey extends BasePayload {
  late Uint8List _newKeyHash;
  UpdateKey(UpdateKeyArg arg) : super() {

    _newKeyHash = arg.newKeyHash;
  }

  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateKey));
    forConcat.addAll(hashMarshalBinary(_newKeyHash));

    return forConcat.asUint8List();
  }
}
