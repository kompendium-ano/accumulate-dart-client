import 'dart:convert';

import 'package:accumulate/src/network/client/accumulate/utils/general.dart';
import 'package:accumulate/src/network/client/accumulate/utils/marshaller.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_adi.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_credit.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_data_account.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_keybook.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_keypage.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_token_account.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_token_create.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_tx_gen.dart';

class ApiRequestTxToData {
  ApiRequestTxToData({
    this.to,
    this.hash,
  });

  String hash;
  List<ApiRequestTxToDataTo> to;

  factory ApiRequestTxToData.fromRawJson(String str) => ApiRequestTxToData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestTxToData.fromJson(Map<String, dynamic> json) => ApiRequestTxToData(
        hash: json["hash"],
        to: List<ApiRequestTxToDataTo>.from(json["to"].map((x) => ApiRequestTxToDataTo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "hash": hash,
        "to": List<dynamic>.from(to.map((x) => x.toJson())),
      };
}

class ApiRequestTxToDataTo {
  ApiRequestTxToDataTo({
    this.url,
    this.amount,
  });

  String url;
  int amount;

  factory ApiRequestTxToDataTo.fromRawJson(String str) => ApiRequestTxToDataTo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestTxToDataTo.fromJson(Map<String, dynamic> json) => ApiRequestTxToDataTo(
        url: json["url"],
        amount: json["amount"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "amount": amount.toString(),
      };
}

class ApiRequestRawTx {
  ApiRequestRawTx({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestTxToData payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx.fromRawJson(String str) => ApiRequestRawTx.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx.fromJson(Map<String, dynamic> json) => ApiRequestRawTx(
      sponsor: json["sponsor"],
      payload: ApiRequestTxToData.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
        "payload": payload.toJson(),
      };
}

class ApiRequestRawTxKeyPage {
  ApiRequestRawTxKeyPage({
    this.height,
    //this.index,
  });

  int height;

  //int index;

  factory ApiRequestRawTxKeyPage.fromRawJson(String str) => ApiRequestRawTxKeyPage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTxKeyPage.fromJson(Map<String, dynamic> json) => ApiRequestRawTxKeyPage(
        height: json["height"],
        //index: json["index"],
      );

  Map<String, dynamic> toJson() => {
        "height": height,
        //"index": index,
      };
}

class ApiRequestRawTx_Credits {
  ApiRequestRawTx_Credits({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestCredits payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_Credits.fromRawJson(String str) => ApiRequestRawTx_Credits.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_Credits.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_Credits(
      sponsor: json["sponsor"],
      payload: ApiRequestCredits.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
        "payload": payload.toJson(),
      };
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class ApiRequestRawTx_ADI {
  ApiRequestRawTx_ADI({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestADI payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_ADI.fromRawJson(String str) => ApiRequestRawTx_ADI.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_ADI.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_ADI(
      sponsor: json["sponsor"],
      payload: ApiRequestADI.fromJson(json["data"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "payload": payload.toJson(),
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
      };
}

class ApiRequestRawTx_TokenAccount {
  ApiRequestRawTx_TokenAccount({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestTokenAccount payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_TokenAccount.fromRawJson(String str) =>
      ApiRequestRawTx_TokenAccount.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_TokenAccount.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_TokenAccount(
      sponsor: json["sponsor"],
      payload: ApiRequestTokenAccount.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
        "payload": payload.toJson(),
      };
}

class ApiRequestRawTx_DataAccount {
  ApiRequestRawTx_DataAccount({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestDataAccount payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_DataAccount.fromRawJson(String str) => ApiRequestRawTx_DataAccount.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_DataAccount.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_DataAccount(
      sponsor: json["sponsor"],
      payload: ApiRequestDataAccount.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
        "payload": payload.toJson(),
      };
}

class ApiRequestRawTx_KeyPage {
  ApiRequestRawTx_KeyPage({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestKeyPage payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_KeyPage.fromRawJson(String str) => ApiRequestRawTx_KeyPage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_KeyPage.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_KeyPage(
      sponsor: json["sponsor"],
      payload: ApiRequestKeyPage.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
        "payload": payload.toJson(),
      };
}

class ApiRequestRawTx_KeyBook {
  ApiRequestRawTx_KeyBook({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestKeyBook payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_KeyBook.fromRawJson(String str) => ApiRequestRawTx_KeyBook.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_KeyBook.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_KeyBook(
      sponsor: json["sponsor"],
      payload: ApiRequestKeyBook.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
        "payload": payload.toJson(),
      };
}

class ApiRequestRawTx_Token {
  ApiRequestRawTx_Token({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool checkOnly;
  String sponsor;
  String origin;
  ApiRequestToken payload;
  Signer signer;
  String signature;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_Token.fromRawJson(String str) => ApiRequestRawTx_Token.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_Token.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_Token(
      sponsor: json["sponsor"],
      payload: ApiRequestToken.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer.toJson(),
        "signature": signature,
        "keyPage": keyPage.toJson(),
        "payload": payload.toJson(),
      };
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Signer {
  Signer({
    this.nonce,
    this.publicKey,
  });

  int nonce;
  String publicKey;

  factory Signer.fromRawJson(String str) => Signer.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Signer.fromJson(Map<String, dynamic> json) => Signer(
        nonce: json["nonce"],
        publicKey: json["publicKey"],
      );

  Map<String, dynamic> toJson() => {
        "publicKey": publicKey,
        "nonce": nonce,
      };
}

class TokenTx {
  String hash;
  String urlChain;
  List<ApiRequestTxToDataTo> to;
  String meta;

  List<int> marshalBinary() {
    return [];
  }

  List<int> marshalBinarySendTokens(ApiRequestRawTx tx) {
    /// Empty hash to fill out space
    List<int> lhash = List.generate(32, (index) => 0);

    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.SendTokens));
    msg.addAll(lhash);
    // meta data
    msg.addAll([0]);

    // number of "to" values
    msg.addAll(uint64ToBytes(tx.payload.to.length));

    // in loop too values
    for (var i = 0; i < tx.payload.to.length; i++) {
      List<int> encodedTo = utf8.encode(tx.payload.to[i].url);
      msg.addAll(uint64ToBytes(encodedTo.length)); // converted string length
      msg.addAll(encodedTo); // actual converted string

      // converted/encoded amount length as it's a big number
      List<int> encodedAmount = uint64ToBytes(tx.payload.to[i].amount);
      msg.addAll(uint64ToBytes(encodedAmount.length));
      msg.addAll(encodedAmount);
    }

    return msg;
  }

  List<int> marshalBinaryAddCredits(ApiRequestRawTx_Credits tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.AddCredits));

    ///
    List<int> encodedRecipient = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedRecipient.length)); // converted string length
    msg.addAll(encodedRecipient); // actual converted string

    ///
    msg.addAll(uint64ToBytes(tx.payload.amount));

    return msg;
  }

  List<int> marshalBinaryBurnTokens(ApiRequestRawTx_Credits tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.BurnTokens));
    msg.addAll(uint64ToBytes(tx.payload.amount));

    return msg;
  }

  List<int> marshalBinaryCreateToken(ApiRequestRawTx_Token tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateToken));

    ///
    List<int> encodedUrl = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedUrl.length));
    msg.addAll(encodedUrl);

    ///
    List<int> encodedKeyBookUrl = utf8.encode(tx.payload.keyBookUrl);
    msg.addAll(uint64ToBytes(encodedKeyBookUrl.length));
    msg.addAll(encodedKeyBookUrl);

    ///
    List<int> encodedSymbol = utf8.encode(tx.payload.tokenSymbol);
    msg.addAll(uint64ToBytes(encodedSymbol.length));
    msg.addAll(encodedSymbol);

    ///
    msg.addAll(uint64ToBytes(tx.payload.precision));

    ///
    List<int> encodedProperties = utf8.encode(tx.payload.properties);
    msg.addAll(uint64ToBytes(encodedProperties.length));
    msg.addAll(encodedProperties);

    ///
    msg.addAll(uint64ToBytes(tx.payload.initialSupply));

    ///
    msg.addAll(uint64ToBytes(boolToInt(tx.payload.hasSupplyLimit)));

    return msg;
  }

  List<int> marshalBinaryCreateIdentity(ApiRequestRawTx_ADI tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateIdentity));

    ///
    List<int> encodedAddress = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedAddress.length));
    msg.addAll(encodedAddress);

    ///
    List<int> encodedPubKey = utf8.encode(tx.payload.publicKey);
    msg.addAll(uint64ToBytes(encodedPubKey.length));
    msg.addAll(encodedPubKey);

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload.keyBookName);
    msg.addAll(uint64ToBytes(encodedKeybook.length));
    msg.addAll(encodedKeybook);

    ///
    List<int> encodedKeypage = utf8.encode(tx.payload.keyPageName);
    msg.addAll(uint64ToBytes(encodedKeypage.length));
    msg.addAll(encodedKeypage);

    ///
    return msg;
  }

  List<int> marshalBinaryCreateTokenAccount(ApiRequestRawTx_TokenAccount tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateTokenAccount));

    ///
    List<int> encodedAddress = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedAddress.length));
    msg.addAll(encodedAddress);

    ///
    List<int> encodedTokeUrl = utf8.encode(tx.payload.tokenUrl);
    msg.addAll(uint64ToBytes(encodedTokeUrl.length));
    msg.addAll(encodedTokeUrl);

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload.keyBookUrl);
    msg.addAll(uint64ToBytes(encodedKeybook.length));
    msg.addAll(encodedKeybook);

    ///
    return msg;
  }

  List<int> marshalBinaryCreateDataAccount(ApiRequestRawTx_DataAccount tx) {
    List<int> msg = [];

    // VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateDataAccount));

    /// Converted url as (length of url + url)
    List<int> encodedAddress = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedAddress.length));
    msg.addAll(encodedAddress);

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload.keyBookUrl);
    msg.addAll(uint64ToBytes(encodedKeybook.length));
    msg.addAll(encodedKeybook);

    ///
    List<int> encodedManagerKeybook = utf8.encode(tx.payload.managerKeyBookUrl);
    msg.addAll(uint64ToBytes(encodedManagerKeybook.length));
    msg.addAll(encodedManagerKeybook);

    ///
    msg.addAll(uint64ToBytes(boolToInt(tx.payload.isScratch)));

    ///
    return msg;
  }

  List<int> marshalBinaryCreateKeyPage(ApiRequestRawTx_KeyPage tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateKeyPage));

    ///
    List<int> encodedKeyPage = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedKeyPage.length));
    msg.addAll(encodedKeyPage);

    // number of "keys" values
    msg.addAll(uint64ToBytes(tx.payload.keys.length));

    // in loop keys values
    for (var i = 0; i < tx.payload.keys.length; i++) {
      List<int> encodedKeys = utf8.encode(tx.payload.keys[i].publickey);
      msg.addAll(uint64ToBytes(encodedKeys.length)); // converted string length
      msg.addAll(encodedKeys); // actual converted string
    }

    return msg;
  }

  List<int> marshalBinaryCreateKeyBook(ApiRequestRawTx_KeyBook tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateKeyBook));

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedKeybook.length));
    msg.addAll(encodedKeybook);

    // number of "pages" values
    msg.addAll(uint64ToBytes(tx.payload.pages.length));

    // in loop pages values
    for (var i = 0; i < tx.payload.pages.length; i++) {
      List<int> encodedPage = utf8.encode(tx.payload.pages[i]);
      msg.addAll(uint64ToBytes(encodedPage.length)); // converted string length
      msg.addAll(encodedPage); // actual converted string
    }

    return msg;
  }

  List<int> marshalBinaryUpdateKeyPage() {
    return [];
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deprecated - subject to removal

class ApiRequestRaw {
  ApiRequestRaw({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx tx;
  bool wait;

  factory ApiRequestRaw.fromRawJson(String str) => ApiRequestRaw.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw(tx: ApiRequestRawTx.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_ADI {
  ApiRequestRaw_ADI({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_ADI tx;
  bool wait;

  factory ApiRequestRaw_ADI.fromRawJson(String str) => ApiRequestRaw_ADI.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_ADI.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_ADI(tx: ApiRequestRawTx_ADI.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}
