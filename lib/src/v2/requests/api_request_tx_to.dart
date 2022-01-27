
// CheckOnly bool        `json:"checkOnly,omitempty" form:"checkOnly" query:"checkOnly"`
// Origin    string      `json:"origin,omitempty" form:"origin" query:"origin" validate:"required,acc-url"`
// Signer    Signer      `json:"signer,omitempty" form:"signer" query:"signer" validate:"required"`
// Signature []byte      `json:"signature,omitempty" form:"signature" query:"signature" validate:"required"`
// KeyPage   KeyPage     `json:"keyPage,omitempty" form:"keyPage" query:"keyPage" validate:"required"`
// Payload   interface{} `json:"payload,omitempty" form:"payload" query:"payload" validate:"required"`
// }

import 'dart:convert';

import 'package:accumulate/src/network/client/accumulate/requests/adi/api_request_adi.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_tx_to.dart';

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