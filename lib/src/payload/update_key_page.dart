// lib\src\payload\update_key_page.dart
import 'dart:convert';
import 'dart:typed_data';

import '../utils/utils.dart';

import '../encoding.dart';
import '../client/tx_types.dart';
import 'base_payload.dart';

class KeyPageOperationType {
  static const Update = 1;
  static const Remove = 2;
  static const Add = 3;
  static const SetThreshold = 4;
  static const UpdateAllowed = 5;
}

class KeySpec {
  dynamic keyHash;
  dynamic delegate;
}

class KeyOperation {
  int? type;
  KeySpec? key;
  KeySpec? oldKey;
  KeySpec? newKey;
  int? threshold;

  List<int>? allow;
  List<int>? deny;
}

class UpdateKeyPageParam {
  late List<KeyOperation> operations;
  String? memo;
  Uint8List? metadata;
}

class UpdateKeyPage extends BasePayload {
  late List<KeyOperation> _operations;

  UpdateKeyPage(UpdateKeyPageParam updateKeyPageParam) : super() {
    _operations = updateKeyPageParam.operations;
    super.memo = updateKeyPageParam.memo;
    super.metadata = updateKeyPageParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.updateKeyPage, 1));

    this
        ._operations
        .map(marshalBinaryKeyPageOperation)
        .forEach((b) => forConcat.addAll(bytesMarshalBinary(b, 2)));

    return forConcat.asUint8List();
  }

  Uint8List marshalBinaryKeyPageOperation(KeyOperation operation) {
    switch (operation.type) {
      case KeyPageOperationType.Add:
      case KeyPageOperationType.Remove:
        return marshalBinaryAddRemoveKeyOperation(operation);
      case KeyPageOperationType.Update:
        return marshalBinaryUpdateKeyOperation(operation);
      case KeyPageOperationType.SetThreshold:
        return marshalBinarySetThresholdKeyPageOperation(operation);
      case KeyPageOperationType.UpdateAllowed:
        return marshalBinaryUpdateAllowedKeyPageOperation(operation);
      default:
        return marshalBinaryAddRemoveKeyOperation(operation);
    }
  }

  Uint8List marshalBinaryKeySpec(KeySpec keySpec) {
    List<int> forConcat = [];

    // Process keyHash if it's provided
    if (keySpec.keyHash != null) {
      forConcat.addAll(bytesMarshalBinary(getKeyHash(keySpec.keyHash), 1));
    }

    // Process delegate if it's provided
    if (keySpec.delegate != null) {
      // Marshaling the delegate as a string
      forConcat.addAll(stringMarshalBinary(keySpec.delegate.toString(), 2));
    }

    // It's important to handle the case where both are null if that's a possibility in your application
    if (keySpec.keyHash == null && keySpec.delegate == null) {
      // Handle or throw an error, or provide a default value
      throw ArgumentError("KeySpec must have at least a keyHash or a delegate");
    }

    return forConcat.asUint8List();
  }

  Uint8List marshalBinaryAddRemoveKeyOperation(KeyOperation operation) {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(operation.type!, 1));

    forConcat
        .addAll(bytesMarshalBinary(marshalBinaryKeySpec(operation.key!), 2));

    return forConcat.asUint8List();
  }

  Uint8List marshalBinaryUpdateKeyOperation(KeyOperation operation) {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(operation.type!, 1));

    forConcat
        .addAll(bytesMarshalBinary(marshalBinaryKeySpec(operation.oldKey!), 2));
    forConcat
        .addAll(bytesMarshalBinary(marshalBinaryKeySpec(operation.newKey!), 3));

    return forConcat.asUint8List();
  }

  Uint8List marshalBinarySetThresholdKeyPageOperation(KeyOperation operation) {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(operation.type!, 1));
    forConcat.addAll(uvarintMarshalBinary(operation.threshold!, 2));

    return forConcat.asUint8List();
  }

  Uint8List marshalBinaryUpdateAllowedKeyPageOperation(KeyOperation operation) {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(operation.type!, 1));
    if (operation.allow != null) {
      operation.allow!
          .forEach((a) => forConcat.addAll(uvarintMarshalBinary(a, 2)));
    }

    if (operation.deny != null) {
      operation.deny!
          .forEach((d) => forConcat.addAll(uvarintMarshalBinary(d, 3)));
    }

    return forConcat.asUint8List();
  }

  Uint8List getKeyHash(dynamic keyHash) {
    return keyHash is Uint8List ? keyHash : utf8.encode(keyHash).asUint8List();
  }
}
