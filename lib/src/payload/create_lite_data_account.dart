// lib\src\payload\create_lite_data_account.dart
import 'dart:typed_data';

import '../client/acc_url.dart';
import '../encoding.dart';
import '../client/tx_types.dart';
import '../utils/utils.dart';
import "base_payload.dart";

class CreateLiteDataAccountParam {
  dynamic url;
  List<AccURL>? authorities;
  String? memo;
  Uint8List? metadata;
}

class CreateLiteDataAccount extends BasePayload {
  late AccURL _url;
  List<AccURL>? _authorities;

  CreateLiteDataAccount(CreateLiteDataAccountParam createLiteDataAccountParam) : super() {
    _url = AccURL.toAccURL(createLiteDataAccountParam.url);
    _authorities = createLiteDataAccountParam.authorities;
    super.memo = createLiteDataAccountParam.memo;
    super.metadata = createLiteDataAccountParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.CreateLiteTokenAccount, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));

    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 3));
      }
    }

    return forConcat.asUint8List();
  }
}
