import 'dart:convert';
import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class RemoveValidatorArg {
  late Uint8List publicKey;
  dynamic owner;
}

class RemoveValidator extends BasePayload {
  late Uint8List _publicKey;
  late AccURL? _owner;

  RemoveValidator(RemoveValidatorArg arg) : super() {
    _publicKey = arg.publicKey;
    _owner = arg.owner ? AccURL.toAccURL(arg.owner) : null;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.removeValidator, 1));
    forConcat.addAll(bytesMarshalBinary(_publicKey, 2));

    if (_owner != null) {
      forConcat.addAll(stringMarshalBinary(_owner.toString(), 3));
    }
    return forConcat.asUint8List();
  }
}
