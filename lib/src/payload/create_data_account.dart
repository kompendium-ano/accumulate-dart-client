import 'dart:typed_data';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import '../utils.dart';
import "base_payload.dart";

class CreateDataAccountParam {
  dynamic url;
  List<AccURL>? authorities;
  late bool? scratch;
  String? memo;
  Uint8List? metadata;
}

class CreateDataAccount extends BasePayload {
  late AccURL _url;
  List<AccURL>? _authorities;
  bool? _scratch;

  CreateDataAccount(CreateDataAccountParam createDataAccountParam) : super() {
    _url = AccURL.toAccURL(createDataAccountParam.url);
    _authorities = createDataAccountParam.authorities;
    _scratch = createDataAccountParam.scratch;
    super.memo = createDataAccountParam.memo;
    super.metadata = createDataAccountParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createDataAccount, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));

    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 3));
      }
    }

    if (_scratch != null) {
      forConcat.addAll(booleanMarshalBinary(_scratch!, 4));
    }

    return forConcat.asUint8List();
  }
}
