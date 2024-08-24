// \lib\src\payload\update_account_auth.dart

import 'dart:typed_data';
import 'package:convert/convert.dart';
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

    // Log the initial state of the operations
    print('Initialized UpdateAccountAuth with operations: $_operations');
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    // Log the transaction type being marshalled
    print('Marshalling TransactionType: ${TransactionType.updateAccountAuth}');

    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateAccountAuth, 1));

    for (var operation in _operations) {
      var marshalledOperation = marshalBinaryAccountAuthOperation(operation);

      // Log each marshalled operation
      print('Marshalled Operation: ${hex.encode(marshalledOperation)}');

      forConcat.addAll(bytesMarshalBinary(marshalledOperation, 2));
    }

    // Log the final concatenated binary before returning
    print('Final Extended Marshal Binary: ${hex.encode(forConcat.asUint8List())}');

    return forConcat.asUint8List();
  }

  Uint8List marshalBinaryAccountAuthOperation(UpdateAccountAuthOperation operation) {
    List<int> forConcat = [];

    // Log the operation type and authority being marshalled
    print('Marshalling Operation: type=${operation.type}, authority=${operation.authority}');

    forConcat.addAll(uvarintMarshalBinary(operation.type, 1));
    forConcat.addAll(stringMarshalBinary(operation.authority.toString(), 2));

    // Log the marshalled binary for this operation
    print('Marshalled Operation Binary: ${hex.encode(forConcat.asUint8List())}');

    return forConcat.asUint8List();
  }
}
