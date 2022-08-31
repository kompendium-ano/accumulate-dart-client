import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class AddValidatorParam {
  late Uint8List publicKey;
  dynamic owner;
}

class AddValidator extends BasePayload {
  late Uint8List _publicKey;
  AccURL? _owner;

  AddValidator(AddValidatorParam addValidatorParam) : super() {
    _publicKey = addValidatorParam.publicKey;
    if(addValidatorParam.owner != null)
    {
      _owner = AccURL.toAccURL(addValidatorParam.owner);
    }

  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.addValidator, 1));
    forConcat.addAll(bytesMarshalBinary(_publicKey, 2));

    if (_owner != null && _owner.toString().isNotEmpty) {
      forConcat.addAll(stringMarshalBinary(_owner.toString(), 3));
    }

    return forConcat.asUint8List();
  }
}
