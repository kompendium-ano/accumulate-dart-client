import 'dart:convert';
import "dart:typed_data";
import '../../src/utils.dart';

import "../acc_url.dart";
import "../marshaller.dart";
import "../tx_types.dart";
import "base_payload.dart";


class CreateTokenArg {
  dynamic url;
  dynamic keyBookUrl;
  late String symbol;
  late int precision;
  dynamic properties;
  dynamic initialSupply;
  bool? hasSupplyLimit;
  dynamic manager;
}

class CreateToken extends BasePayload {
  late AccURL _url;
  AccURL? _keyBookUrl;
  late String _symbol;
  late int _precision;
  AccURL? _properties;
  int? _initialSupply;
  late bool _hasSupplyLimit;
  AccURL? _manager;
  CreateToken(CreateTokenArg arg) : super() {

    _url = AccURL.toAccURL(arg.url);
    _keyBookUrl =
        arg.keyBookUrl ? AccURL.toAccURL(arg.keyBookUrl) : null;
    _symbol = arg.symbol;
    _precision = arg.precision;
    _properties =
        arg.properties ? AccURL.toAccURL(arg.properties) : null;
    _initialSupply =
        arg.initialSupply ? int.parse(arg.initialSupply) : null;
    _hasSupplyLimit = arg.hasSupplyLimit ?? false;
    _manager = arg.manager ? AccURL.toAccURL(arg.manager) : null;
  }

  Uint8List _marshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.createToken));

    forConcat.addAll(stringMarshalBinary(_url.toString()));


    if (_keyBookUrl != null) {
      forConcat.addAll(stringMarshalBinary(_keyBookUrl.toString()));
    }

    if (_symbol.isNotEmpty) {
      forConcat.addAll(stringMarshalBinary(_symbol.toString()));
    }

    if (_precision > 0) {
      forConcat.addAll(uvarintMarshalBinary(_precision));
    }

    if (_properties != null) {
      forConcat.addAll(stringMarshalBinary(_properties.toString()));
    }

    if (_initialSupply != null) {
      forConcat.addAll(uvarintMarshalBinary(_initialSupply!));
    }

    forConcat.addAll(booleanMarshalBinary(_hasSupplyLimit));



    if (_manager != null) {
      forConcat.addAll(stringMarshalBinary(_manager.toString()));
    }

    return forConcat.asUint8List();
  }
}
