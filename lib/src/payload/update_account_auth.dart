import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate_api6/src/utils.dart';

import '../encoding.dart';
import '../tx_types.dart';
import 'base_payload.dart';

class AccountAuthOperationType {
  static const Enable = 1;
  static const Disable = 2;
  static const AddAuthority = 3;
  static const RemoveAuthority = 4;

}


class AccountAuthOperation{
 late int type;
 dynamic authority;

}

class UpdateAccountAuthParam {
  late List<AccountAuthOperation> operations;
  String? memo;
  Uint8List? metadata;
}


class UpdateAccountAuth extends BasePayload{

 late List<AccountAuthOperation> _operations;

 UpdateAccountAuth(UpdateAccountAuthParam updateAccountAuthParam) : super() {
   _operations = updateAccountAuthParam.operations;
   super.memo = updateAccountAuthParam.memo;
   super.metadata = updateAccountAuthParam.metadata;
 }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateAccountAuth, 1));

    this._operations
        .map(marshalBinaryAccountAuthOperation)
        .forEach((b) => forConcat.addAll(bytesMarshalBinary(b, 2)));

    return forConcat.asUint8List();
  }

 Uint8List marshalBinaryAccountAuthOperation(AccountAuthOperation operation){
   List<int> forConcat = [];

   forConcat.addAll(uvarintMarshalBinary(operation.type, 1));
   forConcat.addAll(stringMarshalBinary(operation.authority.toString(), 2));


   return forConcat.asUint8List();
 }




}