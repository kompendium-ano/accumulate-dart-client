import 'dart:typed_data';

import 'package:accumulate_api/src/encoding.dart';
import 'package:accumulate_api/src/client/tx_types.dart';
import 'package:accumulate_api/src/utils/utils.dart';

import 'base_payload.dart';

class UpdateAccountAuthActionType {
  static const Enable = 1;
  static const Disable = 2;
  static const AddAuthority = 3;
  static const RemoveAuthority = 4;
}

class UpdateAccountAuthOperation {
  late int type;
  dynamic authority;
}

class UpdateAccountAuthParam {
  late List<UpdateAccountAuthOperation> operations;
  String? memo;
  Uint8List? metadata;
}

class UpdateAccountAuth extends BasePayload {
  late List<UpdateAccountAuthOperation> _operations;

  UpdateAccountAuth(UpdateAccountAuthParam updateAccountAuthParam) : super() {
    _operations = updateAccountAuthParam.operations;
    super.memo = updateAccountAuthParam.memo;
    super.metadata = updateAccountAuthParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateAccountAuth, 1));
    _operations.map(marshalBinaryAccountAuthOperation).forEach((b) => forConcat.addAll(bytesMarshalBinary(b, 2)));

    return forConcat.asUint8List();
  }

  Uint8List marshalBinaryAccountAuthOperation(UpdateAccountAuthOperation operation) {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(operation.type, 1));
    forConcat.addAll(stringMarshalBinary(operation.authority.toString(), 2));

    return forConcat.asUint8List();
  }
}
