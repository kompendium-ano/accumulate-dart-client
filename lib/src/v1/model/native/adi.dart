import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class IdentityADI {
  String _type;
  String _path;
  String _sponsor; // address
  String _puk;
  List<int> _pik;
  String _pikHex;
  int _amount;
  int _amountCredit;
  int _countAccounts;
  int _countKeybooks;

  IdentityADI(this._type, this._path, this._sponsor);

  String get type => _type;

  set type(String value) {
    _type = value;
  }

  IdentityADI.fromJson(Map<String, dynamic> json)
      : _type = json['type'],
        _path = json['path'],
        _sponsor = json['address'],
        _amount = json['amount'],
        _puk = json['puk'],
        _pikHex = json['pikHex'],
        _pik = json['pik'],
        _amountCredit = json['amountCredit'],
        _countAccounts = json['countAccounts'],
        _countKeybooks = json['countKeybooks'];

  Map<String, dynamic> toJson() => {
        'type': _type,
        'path': _path,
        'address': _sponsor,
        'amount': _amount,
        'puk': _puk,
        'pikHex': _pikHex,
        'pik': _pik,
        'amountCredit': _amountCredit,
        'countAccounts': _countAccounts,
        'countKeybooks': _countKeybooks
      };

  String get path => _path;

  set path(String value) {
    _path = value;
  }

  String get sponsor => _sponsor;

  set sponsor(String value) {
    _sponsor = value;
  }

  int get amount => _amount;

  set amount(int value) {
    _amount = value;
  }

  int get amountCredit => _amountCredit;

  set amountCredit(int value) {
    _amountCredit = value;
  }

  int get countKeybooks => _countKeybooks;

  set countKeybooks(int value) {
    _countKeybooks = value;
  }

  int get countAccounts => _countAccounts;

  set countAccounts(int value) {
    _countAccounts = value;
  }

  List<int> get pik => _pik;

  set pik(List<int> value) {
    _pik = value;
  }

  String get pikHex => _pikHex;

  set pikHex(String value) {
    _pikHex = value;
  }

  String get puk => _puk;

  set puk(String value) {
    _puk = value;
  }

}
