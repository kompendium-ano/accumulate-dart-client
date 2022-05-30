import 'dart:typed_data';
import '../../src/utils.dart';
import '../marshaller.dart';
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


  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateValidatorKey));
    forConcat.addAll(hashMarshalBinary(_publicKey));
    forConcat.addAll(hashMarshalBinary(_newPublicKey));

    return forConcat.asUint8List();
  }
}
