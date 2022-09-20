import 'dart:typed_data';

import "base_payload.dart";
import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import '../utils.dart';

class CreateLiteDataAccountParam {
  dynamic url;
  List<AccURL>? authorities;
  bool? scratch;
  String? memo;
  Uint8List? metadata;
}

class CreateLiteDataAccount extends BasePayload {
  late AccURL _url;
  List<AccURL>? _authorities;

  late bool _scratch;

  CreateLiteDataAccount(CreateLiteDataAccountParam createLiteDataAccountParam) : super() {
    _url = AccURL.toAccURL(createLiteDataAccountParam.url);
    _authorities = createLiteDataAccountParam.authorities;
    //_scratch = createDataAccountParam.scratch ?? false;
    super.memo = createLiteDataAccountParam.memo;
    super.metadata = createLiteDataAccountParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createDataAccount, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));

    forConcat.addAll(booleanMarshalBinary(_scratch, 5));

    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 3));
      }
    }

    return forConcat.asUint8List();
  }
}
