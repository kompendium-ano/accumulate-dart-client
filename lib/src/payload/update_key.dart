import "dart:typed_data";
import '../utils.dart';

import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class UpdateKeyParam {
  late Uint8List newKeyHash;
}

class UpdateKey extends BasePayload {
  late Uint8List _newKeyHash;

  UpdateKey(UpdateKeyParam updateKeyParam) : super() {
    _newKeyHash = updateKeyParam.newKeyHash;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateKey, 1));
    forConcat.addAll(bytesMarshalBinary(_newKeyHash, 2));

    return forConcat.asUint8List();
  }
}
