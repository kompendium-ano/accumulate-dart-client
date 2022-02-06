import 'dart:convert';

import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_adi.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_credit.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_tx_gen.dart';
import 'package:accumulate/src/utils/format.dart';

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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Signer {
  Signer({
    this.nonce,
    this.publicKey,
  });

  int nonce; //timestamp??
  String publicKey;

  factory Signer.fromRawJson(String str) => Signer.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Signer.fromJson(Map<String, dynamic> json) => Signer(
    nonce: json["nonce"],
    publicKey: json["publicKey"],
  );

  Map<String, dynamic> toJson() => {
    "nonce": nonce,
    "publicKey": publicKey,
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
    List<int> lhash = List.generate(32, (index) => 0);

    List<int> msg = [];
    msg.addAll(uint64ToBytes(TransactionType.SendTokens)); // VLQ converted type
    msg.addAll(lhash);
    // meta data
    msg.addAll([0]);
    // number of "to" values
    msg.addAll(uint64ToBytes(tx.payload.to.length));

    // in loop too values
    List<int> encodedTo = utf8.encode(tx.payload.to[0].url);
    msg.addAll(uint64ToBytes(encodedTo.length));            // converted string length
    msg.addAll(encodedTo);                                  // actual converted string

    // converted/encoded amount length as it's a big number
    List<int> encodedAmount = uint64ToBytes(tx.payload.to[0].amount);
    msg.addAll(uint64ToBytes(encodedAmount.length));
    msg.addAll(encodedAmount);

    return msg;
  }

  List<int> marshalBinaryAddCredits(ApiRequestRawTx_Credits tx) {
    List<int> lhash = List.generate(32, (index) => 0);

    List<int> msg = [];
    msg.addAll(uint64ToBytes(TransactionType.AddCredits)); // VLQ converted type
    msg.addAll(lhash);

    List<int> encodedRecipient = utf8.encode(tx.payload.url);
    msg.addAll(uint64ToBytes(encodedRecipient.length));            // converted string length
    msg.addAll(encodedRecipient);                                  // actual converted string
    msg.addAll(uint64ToBytes(tx.payload.amount));

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

