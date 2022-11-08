import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Transaction {
  String? _type;     // name of the transaction type inside wallet
  String? _subtype;  // for better tx identification
  String? _typeNode; // name of the transaction inside node
  String? _txid;     // remote tx value
  String? _from;
  String? _to;
  int? _amount;
  String? _tokenUrl; //
  int? _created;
  String? _status;


  String? get status => _status;

  set status(String? value) {
    _status = value;
  }

  Transaction(String? type, String subtype, String? txid, String? from, String? to, int? amount, String? tokenUrl, [String? status]) {
    this._type = type;
    this._subtype = subtype;
    this._txid = txid;
    this._from = from;
    this._to = to;
    this._amount = amount;
    this._tokenUrl = tokenUrl;
    this._status = status;
  }

  Transaction.fromJson(Map<String, dynamic> json)
      : _type = json['type'],
        _subtype = json['subtype'],
        _txid = json['txid'],
        _from = json['from'],
        _to = json['to'],
        _amount = json['amount'],
        _tokenUrl = json['tokenUrl'],
        _typeNode = json['typeNode'],
        _created = json['created'];

  Map<String, dynamic> toJson() => {
        'type': _type,
        'subtype': _subtype,
        'txid': _txid,
        'from': _from,
        'to': _to,
        'amount': _amount,
        'tokenUrl': _tokenUrl,
        'typeNode': _typeNode,
        'created': _created,
      };

  String? get type => _type;

  set type(String? value) {
    _type = value;
  }

  String? get subtype => _subtype;

  set subtype(String? value) {
    _subtype = value;
  }

  String? get txid => _txid;

  set txid(String? value) {
    _txid = value;
  }

  String? get from => _from;

  set from(String? value) {
    _from = value;
  }

  String? get to => _to;

  set to(String? value) {
    _to = value;
  }

  int? get amount => _amount;

  set amount(int? value) {
    _amount = value;
  }

  String? get typeNode => _typeNode;

  set typeNode(String? value) {
    _typeNode = value;
  }

  String? get tokenUrl => _tokenUrl;

  set tokenUrl(String? value) {
    _tokenUrl = value;
  }

  int? get created => _created;

  set created(int? value) {
    _created = value;
  }

}
