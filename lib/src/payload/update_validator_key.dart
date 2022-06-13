import 'dart:typed_data';
import '../utils.dart';
import '../encoding.dart';
import "../tx_types.dart" show TransactionType;
import "base_payload.dart" show BasePayload;

class UpdateValidatorKeyArg {
late Uint8List publicKey;
late Uint8List newPublicKey;
}

class UpdateValidatorKey extends BasePayload {
  late Uint8List  _publicKey;
  late Uint8List  _newPublicKey;
  UpdateValidatorKey(UpdateValidatorKeyArg arg) : super() {

    _publicKey = arg.publicKey;
    _newPublicKey = arg.newPublicKey;
  }


  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateValidatorKey));
    forConcat.addAll(hashMarshalBinary(_publicKey));
    forConcat.addAll(hashMarshalBinary(_newPublicKey));

    return forConcat.asUint8List();
  }
}
