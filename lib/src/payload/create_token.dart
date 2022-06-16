import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class CreateTokenParam {
  dynamic url;
  late String symbol;
  late int precision;
  dynamic properties;
  dynamic supplyLimit;
  List<AccURL>? authorities;
}

class CreateToken extends BasePayload {
  late AccURL _url;
  late String _symbol;
  late int _precision;
  AccURL? _properties;
  int? _supplyLimit;
  List<AccURL>? _authorities;

  CreateToken(CreateTokenParam createTokenParam) : super() {
    _url = AccURL.toAccURL(createTokenParam.url);
    _symbol = createTokenParam.symbol;
    _precision = createTokenParam.precision;
    _properties = createTokenParam.properties
        ? AccURL.toAccURL(createTokenParam.properties)
        : null;
    _supplyLimit = createTokenParam.supplyLimit
        ? int.parse(createTokenParam.supplyLimit)
        : null;
    _authorities = createTokenParam.authorities;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.createToken, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));

    if (_symbol.isNotEmpty) {
      forConcat.addAll(stringMarshalBinary(_symbol, 4));
    }
    if (_precision > 0) {
      forConcat.addAll(uvarintMarshalBinary(_precision, 5));
    }
    if (_properties != null) {
      forConcat.addAll(stringMarshalBinary(_properties.toString(), 6));
    }
    if (_supplyLimit != null) {
      forConcat.addAll(bigNumberMarshalBinary(_supplyLimit!, 7));
    }
    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 9));
      }
    }

    return forConcat.asUint8List();
  }
}
