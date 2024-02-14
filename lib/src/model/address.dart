import 'dart:convert' show utf8;
import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:json_annotation/json_annotation.dart';


import '../../accumulate_api.dart';

// // URL is an Accumulate URL.
// type URL struct {
//     UserInfo  string
//     Authority string
//     Path      string
//     Query     string
//     Fragment  string
// }
@JsonSerializable()
class AccumulateURL {
  String? _userInfo;
  String? _authority;
  String? _path;
  String? _query;
  String? _fragment;
  AccURL? _accURL;

  AccumulateURL() {
  }

  AccumulateURL.fromJson(Map<String, dynamic> json)
      : _userInfo = json['userInfo'],
        _authority = json['authority'],
        _path = json['path'],
        _query = json['query'],
  _accURL = json['url'],
        _fragment = json['fragment'];

  Map<String, dynamic> toJson() => {
        'userInfo': _userInfo,
        'authority': _authority,
        'path': _path,
        'query': _query,
        'fragment': _fragment,
    'url':_accURL,
      };

  String getPath() => _accURL.toString();


  // Hostname returns the hostname from the authority component.
  //   func (u *URL) Hostname() string {
  //     s, _ := splitColon(u.Authority)
  //     return s
  // }
  String hostname() {
    return authority!.split(":").first;
  }

  // ResourceChain constructs a chain identifier from the lower case hostname and
  // path. The port is not included. If the path does not begin with `/`, `/` is
  // added between the hostname and the path.
  //
  //  Chain = Hash(LowerCase(Sprintf("%s/%s", u.Host(), u.Path)))
  //
  //   func chain(s string) []byte {
  //     s = strings.ToLower(s)
  //     h := sha256.Sum256([]byte(s))
  //     return h[:]
  //  }
  //
  //  func (u *URL) ResourceChain() []byte {
  //    return chain(u.Hostname() + ensurePath(u.Path))
  //  }
  List<int> resourceChain() {
    String combo =  _accURL.toString();   //hostname() + ensurePath(path)!;
    Digest chainHash = sha256.convert(utf8.encode(combo.toLowerCase()));
    return chainHash.bytes.sublist(0, 32);
  }


  // func ensurePath(s string) string {
  // if s == "" || s[0] == '/' {
  // return s
  // }
  // return "/" + s
  // }
  String? ensurePath(String? input) {
    if (input == "" || input!.startsWith('/', 0)) {
      return input;
    } else {
      return "/" + input;
    }
  }

  //////////////////////////////////////////////////////
  String? get userInfo => _userInfo;

  set userInfo(String? value) {
    _userInfo = value;
  }

  String? get authority => _authority;

  set authority(String? value) {
    _authority = value;
  }

  String? get path => _path;

  set path(String? value) {
    _path = value;
  }

  String? get query => _query;

  set query(String? value) {
    _query = value;
  }

  String? get fragment => _fragment;

  set fragment(String? value) {
    _fragment = value;
  }

  AccURL? get accURL => _accURL;

  set accURL(AccURL? value){
    _accURL = value;
  }
}

/// // Parse parses the string as an Accumulate URL. The scheme may be omitted, in
// // which case `acc://` will be added, but if present it must be `acc`. The
// // hostname must be non-empty. RawPath, ForceQuery, and RawFragment are not
// // preserved.
// func Parse(s string) (*URL, error) {
// 	u, err := url.Parse(s)
// 	if err == nil && u.Scheme == "" {
// 		u, err = url.Parse("acc://" + s)
// 	}
// 	if err != nil {
// 		return nil, err
// 	}
//
// 	if u.Scheme != "acc" {
// 		return nil, ErrWrongScheme
// 	}
//
// 	if u.Host == "" || u.Host[0] == ':' {
// 		return nil, ErrMissingHost
// 	}
//
// 	v := new(URL)
// 	v.Authority = u.Host
// 	v.Path = u.Path
// 	v.Query = u.RawQuery
// 	v.Fragment = u.Fragment
// 	if u.User != nil {
// 		v.UserInfo = u.User.Username()
// 		if pw, _ := u.User.Password(); pw != "" {
// 			v.UserInfo += ":" + pw
// 		}
// 	}
// 	return v, nil
// }
///
Either<String, AccumulateURL> parseStringToAccumulateURL(String input) {

  Uri parsedUri = Uri.parse(input);
  if (parsedUri.scheme == "") {
    // unidentified scheme, try to make it accumulate scheme
    input = "acc://" + input;
  }

  // try to parse again
  parsedUri = Uri.parse(input);
  if (parsedUri.scheme != "acc") {
    return (Left(""));
  }

  AccURL accURL = AccURL.parse(input);

  AccumulateURL accumulateURL = new AccumulateURL();
  accumulateURL.authority = accURL.authority;
  accumulateURL.path = accURL.path;
  accumulateURL.query = accURL.query;
  accumulateURL.fragment = accURL.fragment;
  accumulateURL.accURL = accURL;

  return Right(accumulateURL);
}

@JsonSerializable()
class Address {
  String? _nickname;
  String? _spendingpass;
  late String _address;
  AccumulateURL? _URL;
  int? _amount;
  int? _amountCredits;
  String? _puk;
  List<int>? _pik;
  String? _pikHex;
  String? _mnemonic;
  List<String>? _mnemonicList;
  String? _parentAdi;
  String? _affiliatedKeybook; // path to controlling keybook
  LiteIdentity? _lid;

  /////////////////////////////////////////////////////

  String get address => _address;

  int? get amount => _amount;

  String? get nickname => _nickname;

  String? get spendingpass => _spendingpass;

  String? get puk => _puk;

  String? get pikHex => _pikHex;

  List<int>? get pik => _pik;

  int? get amountCredits => _amountCredits;

  set amountCredits(int? value) {
    _amountCredits = value;
  }

  set pik(List<int>? value) {
    _pik = value;
  }

  String? get parentAdi => _parentAdi;

  set parentAdi(String? value) {
    _parentAdi = value;
  }

  List<String>? get mnemonicList => _mnemonicList;

  AccumulateURL? get URL => _URL;

  set URL(AccumulateURL? value) {
    _URL = value;
  }
  LiteIdentity? get lid => _lid;

  set lid(LiteIdentity? value) {
    _lid = value;
  }

  Address(String addr, String nick, String pass) {
    this._address = addr;
    this._nickname = nick;
    this._spendingpass = pass;
  }

  Address.fromJson(Map<String, dynamic> json)
      : _address = json['address'],
        _amount = json['amount'],
        _amountCredits = json['amountCredits'],
        _nickname = json['nickname'],
        _spendingpass = json['spendingpass'],
        _URL = json['url'],
        _puk = json['puk'],
        _pikHex = json['pikHex'],
        _pik = json['pik'],
        _parentAdi = json['parentAdi'],
  _lid = json['lid'],
        _affiliatedKeybook = json['affiliatedKeybook'];

  Map<String, dynamic> toJson() => {
        'address': _address,
        'amount': _amount,
        'amountCredits': _amountCredits,
        'nickname': _nickname,
        'spendingpass': _spendingpass,
        'url': _URL,
        'puk': _puk,
        'pikHex': _pikHex,
        'pik': _pik,
        'parentAdi': _parentAdi,
    'lid':_lid,
        'affiliatedKeybook': _affiliatedKeybook
      };

  set nickname(String? value) {
    _nickname = value;
  }

  set spendingpass(String? value) {
    _spendingpass = value;
  }

  set address(String value) {
    _address = value;
  }

  set amount(int? value) {
    _amount = value;
  }

  set puk(String? value) {
    _puk = value;
  }

  set pikHex(String? value) {
    _pikHex = value;
  }

  set mnemonicList(List<String>? value) {
    _mnemonicList = value;
  }

  String? get mnemonic => _mnemonic;

  set mnemonic(String? value) {
    _mnemonic = value;
  }

  String? get affiliatedKeybook => _affiliatedKeybook;

  set affiliatedKeybook(String? value) {
    _affiliatedKeybook = value;
  }

  // // AnonymousAddress returns an anonymous address for the given public key and
  // // token URL as `acc://<key-hash-and-checksum>/<token-url>`.
  // //
  // // Only the first 20 bytes of the public key hash is used. The checksum is
  // // equivalent to last four bytes of the resource chain ID. For an ACME anonymous
  // // token account URL for a key with a public key hash of
  // //
  // //   "aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f"
  // //
  // // The checksum is calculated as
  // //
  // //   sha256("aec070645fe53ee3b3763059376134f058cc3372/acme")[28:] == "3c63cf54"
  // //
  // // The resulting URL is
  // //
  // //   "acc://aec070645fe53ee3b3763059376134f058cc33723c63cf54/ACME"
  // func AnonymousAddress(pubKey []byte, tokenUrlStr string) (*url.URL, error) {
  // 	tokenUrl, err := url.Parse(tokenUrlStr)
  // 	if err != nil {
  // 		return nil, err
  // 	}
  //
  // 	if tokenUrl.UserInfo != "" {
  // 		return nil, errors.New("token URLs cannot include user info")
  // 	}
  // 	if tokenUrl.Port() != "" {
  // 		return nil, errors.New("token URLs cannot include a port number")
  // 	}
  // 	if tokenUrl.Query != "" {
  // 		return nil, errors.New("token URLs cannot include a query")
  // 	}
  // 	if tokenUrl.Fragment != "" {
  // 		return nil, errors.New("token URLs cannot include a fragment")
  // 	}
  //
  // 	anonUrl := new(url.URL)
  // 	keyHash := sha256.Sum256(pubKey)
  // 	anonUrl.Authority = fmt.Sprintf("%x", keyHash[:20])
  // 	anonUrl.Path = fmt.Sprintf("/%s%s", tokenUrl.Authority, tokenUrl.Path)
  //
  // 	checkSum := anonUrl.ResourceChain()[28:]
  // 	anonUrl.Authority += fmt.Sprintf("%x", checkSum)
  // 	return anonUrl, nil
  // }
  //
  // tokenUrl for now "ACME"
  AccumulateURL generateAddressViaProtocol(List<int> pubKey, String tokenUrlStr) {
    Either<String, AccumulateURL> res = parseStringToAccumulateURL(tokenUrlStr);
    if (res.isLeft())
      return new AccumulateURL();
    else {
      final AccumulateURL tokenUrl = res.toOption().toNullable()!;
      tokenUrl.authority;


      // 1. Get the hash of the public key
      Digest keyHash = sha256.convert(pubKey); // keyHash := sha256.Sum256(pubKey)

      int lengthKeyHash = keyHash.toString().length;
      String str = keyHash.toString();
      print("keyhash $str");
      print("  length  $lengthKeyHash");

      /// 2. Fill out anon address url
      ///
      AccumulateURL anonUrl = new AccumulateURL();
      AccURL accURL = LiteIdentity.computeUrl(pubKey.asUint8List());
      anonUrl.authority = accURL.authority;
      anonUrl.path = accURL.path;
      anonUrl.accURL = accURL;

      return anonUrl; //"acc://" + anonUrl.authority + anonUrl.path;
    }
  }



  bool isACMEAddress(String input) {
    if (input.length != 53) {
      return false;
    }
    // 1. get hash of the address including prefix
    return true;
  }

  @override
  String toString() {
    return lid!.acmeTokenAccount.toString();
  }
}
