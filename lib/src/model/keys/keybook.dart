// lib\src\model\keys\keybook.dart
import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class KeyBook {
  String? _nickname;
  String? _path;
  String? _address;
  String? _parentAdi;

  KeyBook(this._nickname, this._path, this._address);

  String? get nickname => _nickname;

  set nickname(String? value) {
    _nickname = value;
  }

  KeyBook.fromJson(Map<String, dynamic> json)
      : _nickname = json['nickname'],
        _path = json['path'],
        _address = json['address'],
        _parentAdi = json['parentAdi'];

  Map<String, dynamic> toJson() => {
        'nickname': _nickname,
        'path': _path,
        'address': _address,
        'parentAdi': _parentAdi
      };

  String? get path => _path;

  set path(String? value) {
    _path = value;
  }

  String? get address => _address;

  set address(String? value) {
    _address = value;
  }

  String? get parentAdi => _parentAdi;

  set parentAdi(String? value) {
    _parentAdi = value;
  }
}
