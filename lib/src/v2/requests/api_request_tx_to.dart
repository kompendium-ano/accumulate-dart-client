import 'dart:convert';

import 'package:accumulate_api/src/utils/marshaller.dart';
import 'package:accumulate_api/src/v2/requests/api_request_adi.dart';
import 'package:accumulate_api/src/v2/requests/api_request_credit.dart';
import 'package:accumulate_api/src/v2/requests/api_request_data_account.dart';
import 'package:accumulate_api/src/v2/requests/api_request_keybook.dart';
import 'package:accumulate_api/src/v2/requests/api_request_keypage.dart';
import 'package:accumulate_api/src/v2/requests/api_request_keypage_update.dart';
import 'package:accumulate_api/src/v2/requests/api_request_raw_data.dart';
import 'package:accumulate_api/src/v2/requests/api_request_token_account.dart';
import 'package:accumulate_api/src/v2/requests/api_request_token_create.dart';
import 'package:accumulate_api/src/v2/requests/api_request_token_issue.dart';
import 'package:accumulate_api/src/v2/requests/api_request_tx_gen.dart';
import 'package:hex/hex.dart';

class ApiRequestTxToData {
  ApiRequestTxToData({
    this.to,
    this.hash,
  });

  String? hash;
  List<ApiRequestTxToDataTo>? to;

  factory ApiRequestTxToData.fromRawJson(String str) => ApiRequestTxToData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestTxToData.fromJson(Map<String, dynamic> json) => ApiRequestTxToData(
        hash: json["hash"],
        to: List<ApiRequestTxToDataTo>.from(json["to"].map((x) => ApiRequestTxToDataTo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "hash": hash,
        "to": List<dynamic>.from(to!.map((x) => x.toJson())),
      };
}

class ApiRequestTxToDataTo {
  ApiRequestTxToDataTo({
    this.url,
    this.amount,
  });

  String? url;
  int? amount;

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

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestTxToData? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTxKeyPage {
  ApiRequestRawTxKeyPage({
    this.height,
    this.index,
  });

  int? height;
  int? index;

  factory ApiRequestRawTxKeyPage.fromRawJson(String str) => ApiRequestRawTxKeyPage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTxKeyPage.fromJson(Map<String, dynamic> json) => ApiRequestRawTxKeyPage(
        height: json["height"],
        index: json["index"],
      );

  Map<String, dynamic> toJson() => {
        "height": height,
        "index": index,
      };
}

class ApiRequestRawTx_Credits {
  ApiRequestRawTx_Credits({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestCredits? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class ApiRequestRawTx_ADI {
  ApiRequestRawTx_ADI({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestADI? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "payload": payload!.toJson(),
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
      };
}

class ApiRequestRawTx_TokenAccount {
  ApiRequestRawTx_TokenAccount({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestTokenAccount? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTx_DataAccount {
  ApiRequestRawTx_DataAccount({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestDataAccount? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTx_KeyBook {
  ApiRequestRawTx_KeyBook({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestKeyBook? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTx_KeyPage {
  ApiRequestRawTx_KeyPage({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestKeyPage? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTx_KeyPageUpdate {
  ApiRequestRawTx_KeyPageUpdate({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestKeyPageUpdate? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

  factory ApiRequestRawTx_KeyPageUpdate.fromRawJson(String str) =>
      ApiRequestRawTx_KeyPageUpdate.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_KeyPageUpdate.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_KeyPageUpdate(
      sponsor: json["sponsor"],
      payload: ApiRequestKeyPageUpdate.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTx_Token {
  ApiRequestRawTx_Token({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestToken? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

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
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTx_TokenIssue {
  ApiRequestRawTx_TokenIssue({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestTokenIssue? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

  factory ApiRequestRawTx_TokenIssue.fromRawJson(String str) => ApiRequestRawTx_TokenIssue.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_TokenIssue.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_TokenIssue(
      sponsor: json["sponsor"],
      payload: ApiRequestTokenIssue.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

class ApiRequestRawTx_WriteData {
  ApiRequestRawTx_WriteData({this.origin, this.sponsor, this.payload, this.signer, this.signature, this.keyPage});

  bool? checkOnly;
  String? sponsor;
  String? origin;
  ApiRequestData? payload;
  Signer? signer;
  String? signature;
  ApiRequestRawTxKeyPage? keyPage;

  factory ApiRequestRawTx_WriteData.fromRawJson(String str) => ApiRequestRawTx_WriteData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_WriteData.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_WriteData(
      sponsor: json["sponsor"],
      payload: ApiRequestData.fromJson(json["payload"]),
      signer: Signer.fromJson(json["signer"]),
      signature: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "origin": origin,
        "sponsor": sponsor,
        "signer": signer!.toJson(),
        "signature": signature,
        "keyPage": keyPage!.toJson(),
        "payload": payload!.toJson(),
      };
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Signer {
  Signer({
    this.nonce,
    this.publicKey,
  });

  int? nonce;
  String? publicKey;

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
  String? hash;
  String? urlChain;
  List<ApiRequestTxToDataTo>? to;
  String? meta;

  List<int> marshalBinarySendTokens(ApiRequestRawTx tx) {
    /// Empty hash to fill out space
    List<int> lhash = List.generate(32, (index) => 0);

    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.SendTokens));
    msg.addAll(lhash);

    /// meta data
    msg.addAll([0]);

    /// number of "to" values
    msg.addAll(uint64ToBytesAlt(tx.payload!.to!.length));

    /// in loop "to" values
    for (var i = 0; i < tx.payload!.to!.length; i++) {
      List<int> encodedTo = utf8.encode(tx.payload!.to![i].url!);
      msg.addAll(uint64ToBytesAlt(encodedTo.length)); // converted string length
      msg.addAll(encodedTo); // actual converted string

      // converted/encoded amount length as it's a big number
      List<int> encodedAmount = uint64ToBytesAlt(tx.payload!.to![i].amount!);
      msg.addAll(uint64ToBytesAlt(encodedAmount.length));
      msg.addAll(encodedAmount);
    }

    return msg;
  }

  List<int> marshalBinaryAddCredits(ApiRequestRawTx_Credits tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.AddCredits));

    /// Converted recipient
    List<int> encodedRecipient = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytesAlt(encodedRecipient.length)); // converted string length
    msg.addAll(encodedRecipient); // actual converted string

    /// Converted amount
    msg.addAll(uint64ToBytesNonce(tx.payload!.amount!));
    // List<int> encodedAmount = uint64ToBytesAlt(tx.payload.amount);
    // msg.addAll(uint64ToBytesAlt(encodedAmount.length));
    // msg.addAll(encodedAmount);

    return msg;
  }

  /*
  List<int> marshalBinaryCreateToken(ApiRequestRawTx_Token tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateToken));

    ///
    List<int> encodedUrl = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytes(encodedUrl.length));
    msg.addAll(encodedUrl);

    ///
    List<int> encodedKeyBookUrl = utf8.encode(tx.payload!.keyBookUrl!);
    msg.addAll(uint64ToBytes(encodedKeyBookUrl.length));
    msg.addAll(encodedKeyBookUrl);

    ///
    List<int> encodedSymbol = utf8.encode(tx.payload!.tokenSymbol!);
    msg.addAll(uint64ToBytes(encodedSymbol.length));
    msg.addAll(encodedSymbol);

    ///
    msg.addAll(uint64ToBytes(tx.payload!.precision!));

    ///
    List<int> encodedProperties = utf8.encode(tx.payload!.properties!);
    msg.addAll(uint64ToBytes(encodedProperties.length));
    msg.addAll(encodedProperties);

    ///
    msg.addAll(uint64ToBytes(tx.payload!.initialSupply!));

    ///
    msg.addAll(uint64ToBytes(boolToInt(tx.payload!.hasSupplyLimit!)));

    return msg;
  }
  */

  List<int> marshalBinaryCreateToken(ApiRequestRawTx_Token tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.CreateToken));

    ///
    List<int> encodedUrl = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytes(encodedUrl.length));
    msg.addAll(encodedUrl);

    ///
    List<int> encodedSymbol = utf8.encode(tx.payload!.tokenSymbol!);
    msg.addAll(uint64ToBytes(encodedSymbol.length));
    msg.addAll(encodedSymbol);

    ///
    msg.addAll(uint64ToBytes(tx.payload!.precision!));

    ///
    List<int> encodedInitialSupply = utf8.encode(tx.payload!.initialSupply!);
    msg.addAll(uint64ToBytes(encodedInitialSupply.length));
    msg.addAll(encodedInitialSupply);

    return msg;
  }

  List<int> marshalBinaryIssueTokens(ApiRequestRawTx_TokenIssue tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.IssueTokens));

    ///
    List<int> encodedRecipient = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytes(encodedRecipient.length)); // converted string length
    msg.addAll(encodedRecipient); // actual converted string

    ///
    msg.addAll(uint64ToBytes(tx.payload!.amount!));

    return msg;
  }

  List<int> marshalBinaryBurnTokens(ApiRequestRawTx_Credits tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.BurnTokens));

    ///
    msg.addAll(uint64ToBytes(tx.payload!.amount!));

    return msg;
  }

  List<int> marshalBinaryCreateIdentity(ApiRequestRawTx_ADI tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.CreateIdentity));

    ///
    List<int> encodedAddress = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytesAlt(encodedAddress.length));
    msg.addAll(encodedAddress);

    ///
    List<int> encodedPubKey = HEX.decode(tx.payload!.publicKey!);
    msg.addAll(uint64ToBytesAlt(encodedPubKey.length));
    msg.addAll(encodedPubKey);

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload!.keyBookName!);
    msg.addAll(uint64ToBytesAlt(encodedKeybook.length));
    msg.addAll(encodedKeybook);

    ///
    List<int> encodedKeypage = utf8.encode(tx.payload!.keyPageName!);
    msg.addAll(uint64ToBytesAlt(encodedKeypage.length));
    msg.addAll(encodedKeypage);

    ///
    return msg;
  }

  List<int> marshalBinaryCreateTokenAccount(ApiRequestRawTx_TokenAccount tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.CreateTokenAccount));

    ///
    List<int> encodedAddress = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytesAlt(encodedAddress.length));
    msg.addAll(encodedAddress);

    ///
    List<int> encodedTokeUrl = utf8.encode(tx.payload!.tokenUrl!);
    msg.addAll(uint64ToBytesAlt(encodedTokeUrl.length));
    msg.addAll(encodedTokeUrl);

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload!.keyBookUrl!);
    msg.addAll(uint64ToBytesAlt(encodedKeybook.length));
    msg.addAll(encodedKeybook);

    ///
    if (tx.payload!.isScratch!) {
      msg.add(1);
    } else {
      msg.add(0);
    }

    ///
    return msg;
  }

  List<int> marshalBinaryCreateDataAccount(ApiRequestRawTx_DataAccount tx) {
    List<int> msg = [];

    // VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.CreateDataAccount));

    /// Converted url as (length of url + url)
    List<int> encodedAddress = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytesAlt(encodedAddress.length));
    msg.addAll(encodedAddress);

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload!.keyBookUrl!);
    if (encodedKeybook.length > 0) {
      msg.addAll(uint64ToBytesAlt(encodedKeybook.length));
      msg.addAll(encodedKeybook);
    } else {
      msg.add(0);
    }

    ///
    List<int> encodedManagerKeybook = utf8.encode(tx.payload!.managerKeyBookUrl!);
    if (encodedManagerKeybook.length > 0) {
      msg.addAll(uint64ToBytesAlt(encodedManagerKeybook.length));
      msg.addAll(encodedManagerKeybook);
    } else {
      msg.add(0);
    }

    ///
    if (tx.payload!.isScratch!) {
      msg.add(1);
    } else {
      msg.add(0);
    }

    ///
    return msg;
  }

  List<int> marshalBinaryCreateKeyBook(ApiRequestRawTx_KeyBook tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.CreateKeyBook));

    ///
    List<int> encodedKeybook = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytesAlt(encodedKeybook.length));
    msg.addAll(encodedKeybook);

    // number of "pages" values
    msg.addAll(uint64ToBytesAlt(tx.payload!.pages!.length));

    // in loop pages values
    for (var i = 0; i < tx.payload!.pages!.length; i++) {
      List<int> encodedPage = utf8.encode(tx.payload!.pages![i]);
      msg.addAll(uint64ToBytesAlt(encodedPage.length));
      msg.addAll(encodedPage);
    }

    return msg;
  }

  List<int> marshalBinaryCreateKeyPage(ApiRequestRawTx_KeyPage tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.CreateKeyPage));

    ///
    List<int> encodedKeyPage = utf8.encode(tx.payload!.url!);
    msg.addAll(uint64ToBytesAlt(encodedKeyPage.length));
    msg.addAll(encodedKeyPage);

    // number of "keys" values
    msg.addAll(uint64ToBytesAlt(tx.payload!.keys!.length));

    // in loop keys values
    for (var i = 0; i < tx.payload!.keys!.length; i++) {
      List<int> encodedKeys = HEX.decode(tx.payload!.keys![i].publickey!);
      msg.addAll(uint64ToBytesAlt(encodedKeys.length));
      msg.addAll(encodedKeys);
    }

    return msg;
  }

  List<int> marshalBinaryKeyPageUpdate(ApiRequestRawTx_KeyPageUpdate tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytesAlt(TransactionType.UpdateKeyPage));

    /// Save Operation type
    switch (tx.payload!.operation) {
      case "update":
        msg.addAll(uint64ToBytesAlt(1));
        break;
      case "remove":
        msg.addAll(uint64ToBytesAlt(2));
        break;
      case "add":
        msg.addAll(uint64ToBytesAlt(3));
        break;
    }

    /// Key
    List<int> encodedKey = HEX.decode(tx.payload!.key!);
    msg.addAll(uint64ToBytesAlt(encodedKey.length));
    msg.addAll(encodedKey);

    /// New Key
    List<int> encodedNewKey = HEX.decode(tx.payload!.newKey!);
    msg.addAll(uint64ToBytesAlt(encodedNewKey.length));
    msg.addAll(encodedNewKey);

    /// owner TODO: update as it variable value
    // List<int> encodedKeyPage = utf8.encode(tx.payload.owner);
    // msg.addAll(uint64ToBytesAlt(encodedKeyPage.length));
    // msg.addAll(encodedKeyPage);
    msg.add(0);

    /// threshold TODO: change to value
    //msg.addAll(uint64ToBytesAlt(encodedNewKey.length));
    msg.add(0);

    return msg;
  }

  List<int> marshalBinaryWriteData(ApiRequestRawTx_WriteData tx) {
    List<int> msg = [];

    /// VLQ converted transaction type
    msg.addAll(uint64ToBytes(TransactionType.WriteData));

    /// number of "extIDs" values
    msg.addAll(uint64ToBytes(tx.payload!.extIds!.length));

    // in loop pages values
    for (var i = 0; i < tx.payload!.extIds!.length; i++) {
      List<int> encodedExtId = utf8.encode(tx.payload!.extIds![i]);
      msg.addAll(uint64ToBytes(encodedExtId.length));
      msg.addAll(encodedExtId);
    }

    ///
    List<int> encodedData = utf8.encode(tx.payload!.data!);
    msg.addAll(uint64ToBytes(encodedData.length));
    msg.addAll(encodedData);

    return msg;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deprecated - subject to removal

class ApiRequestRaw {
  ApiRequestRaw({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx? tx;
  bool? wait;

  factory ApiRequestRaw.fromRawJson(String str) => ApiRequestRaw.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw(tx: ApiRequestRawTx.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx!.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_ADI {
  ApiRequestRaw_ADI({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_ADI? tx;
  bool? wait;

  factory ApiRequestRaw_ADI.fromRawJson(String str) => ApiRequestRaw_ADI.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_ADI.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_ADI(tx: ApiRequestRawTx_ADI.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx!.toJson(),
        "wait": wait,
      };
}
