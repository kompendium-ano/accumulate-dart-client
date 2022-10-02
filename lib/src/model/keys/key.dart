import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Key {
  String? _nickname;
  String? _puk;
  List<int>? _pik;
  String? _pikHex;
  String? _mnemonic;
  List<String>? _mnemonicList;
  String? _parentKeyPage;

  /////////////////////////////////////////////////////

  String? get nickname => _nickname;

  String? get puk => _puk;

  String? get pikHex => _pikHex;

  List<int>? get pik => _pik;

  set pik(List<int>? value) {
    _pik = value;
  }

  Key(String nick, String puk, String pik) {
    this._nickname = nick;
    this.puk = puk;
    this.pikHex = pik;
  }

  Key.fromJson(Map<String, dynamic> json)
      : _nickname = json['nickname'],
        _puk = json['puk'],
        _pikHex = json['pikHex'],
        _pik = json['pik'],
        _parentKeyPage = json['parentKeyPage'];

  Map<String, dynamic> toJson() =>
      {'nickname': _nickname, 'puk': _puk, 'pikHex': _pikHex, 'pik': _pik, 'parentKeyPage': _parentKeyPage};

  set nickname(String? value) {
    _nickname = value;
  }

  set puk(String? value) {
    _puk = value;
  }

  set pikHex(String? value) {
    _pikHex = value;
  }

  set mnemonicList(List<String> value) {
    _mnemonicList = value;
  }

  String? get mnemonic => _mnemonic;

  set mnemonic(String? value) {
    _mnemonic = value;
  }

  String? get parentKeyPage => _parentKeyPage;

  set parentKeyPage(String? value) {
    _parentKeyPage = value;
  }
}
