// lib\src\model\keys\keypage.dart

import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class KeyPage {
  String? _type;
  String? _path;
  String? _address;
  String? _parentKeyBook;
  int? _parentKeyBookPriority;
  int? _keysRequired; // number of key signatures require to establish full signature
  int? _keysRequiredOf; // total number of keys needed
  String? _networkName;
  int? _amountCredits;

  KeyPage(this._parentKeyBook, this._path, this._address);

  String? get type => _type;

  set type(String? value) {
    _type = value;
  }

  KeyPage.fromJson(Map<String, dynamic> json)
      : _type = json['type'],
        _path = json['path'],
        _address = json['address'],
        _keysRequired = json['keysRequired'],
        _keysRequiredOf = json['keysRequiredOf'],
        _parentKeyBook = json['parentKeyBook'],
        _parentKeyBookPriority = json['parentKeyBookPriority'],
        _networkName = json['networkName'],
        _amountCredits = json['amountCredits'];

  Map<String, dynamic> toJson() => {
        'type': _type,
        'path': _path,
        'address': _address,
        'keysRequired': _keysRequired,
        'keysRequiredOf': _keysRequiredOf,
        'parentKeyBook': _parentKeyBook,
        'parentKeyBookPriority': _parentKeyBookPriority,
        'networkName': _networkName,
        'amountCredits': _amountCredits,
      };

  String? get path => _path;

  set path(String? value) {
    _path = value;
  }

  String? get address => _address;

  set address(String? value) {
    _address = value;
  }

  String? get parentKeyBook => _parentKeyBook;

  set parentKeyBook(String? value) {
    _parentKeyBook = value;
  }

  int? get keysRequired => _keysRequired;

  set keysRequired(int? value) {
    _keysRequired = value;
  }

  int? get parentKeyBookPriority => _parentKeyBookPriority;

  set parentKeyBookPriority(int? value) {
    _parentKeyBookPriority = value;
  }

  int? get keysRequiredOf => _keysRequiredOf;

  set keysRequiredOf(int? value) {
    _keysRequiredOf = value;
  }

  String? get networkName => _networkName;

  set networkName(String? value) {
    _networkName = value;
  }


  int? get amountCredits => _amountCredits;

  set amountCredits(int? value) {
    _amountCredits = value;
  }
}
