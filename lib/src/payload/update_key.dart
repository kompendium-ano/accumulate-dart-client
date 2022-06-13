import "dart:typed_data";
import '../utils.dart';

import "../encoding.dart";
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

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateKey));
    forConcat.addAll(hashMarshalBinary(_newKeyHash));

    return forConcat.asUint8List();
  }
}
