import 'dart:typed_data';
import '../utils.dart';
import '../encoding.dart';
import "../tx_types.dart";
import "base_payload.dart";

class UpdateValidatorKeyParam {
  late Uint8List publicKey;
  late Uint8List newPublicKey;
}

class UpdateValidatorKey extends BasePayload {
  late Uint8List _publicKey;
  late Uint8List _newPublicKey;

  UpdateValidatorKey(UpdateValidatorKeyParam updateValidatorKeyParam)
      : super() {
    _publicKey = updateValidatorKeyParam.publicKey;
    _newPublicKey = updateValidatorKeyParam.newPublicKey;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat
        .addAll(uvarintMarshalBinary(TransactionType.updateValidatorKey, 1));
    forConcat.addAll(bytesMarshalBinary(_publicKey, 2));
    forConcat.addAll(bytesMarshalBinary(_newPublicKey, 3));

    return forConcat.asUint8List();
  }
}
