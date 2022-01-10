import 'dart:convert';

class ApiRequestTxTo {
  ApiRequestTxTo({
    this.tx,
    this.sig,
  });

  Tx tx;
  String sig;

  factory ApiRequestTxTo.fromRawJson(String str) => ApiRequestTxTo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestTxTo.fromJson(Map<String, dynamic> json) => ApiRequestTxTo(
    tx: Tx.fromJson(json["tx"]),
    sig: json["sig"],
  );

  Map<String, dynamic> toJson() => {
    "tx": tx.toJson(),
    "sig": sig,
  };
}

class Tx {
  Tx({
    this.data,
    this.signer,
    this.timestamp,
  });

  ApiRequestTxToData data;
  Signer signer;
  int timestamp;

  factory Tx.fromRawJson(String str) => Tx.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Tx.fromJson(Map<String, dynamic> json) => Tx(
    data: ApiRequestTxToData.fromJson(json["data"]),
    signer: Signer.fromJson(json["signer"]),
    timestamp: json["timestamp"],
  );

  Map<String, dynamic> toJson() => {
    "data": data.toJson(),
    "signer": signer.toJson(),
    "timestamp": timestamp,
  };
}

class ApiRequestTxToData {
  ApiRequestTxToData({
    this.from,
    this.to,
  });

  String from;
  List<ApiRequestTxToDataTo> to;

  factory ApiRequestTxToData.fromRawJson(String str) => ApiRequestTxToData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestTxToData.fromJson(Map<String, dynamic> json) => ApiRequestTxToData(
    from: json["from"],
    to: List<ApiRequestTxToDataTo>.from(json["to"].map((x) => ApiRequestTxToDataTo.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "from": from,
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
    "amount": amount,
  };
}

class Signer {
  Signer({
    this.url,
    this.publicKey,
  });

  String url;
  String publicKey;

  factory Signer.fromRawJson(String str) => Signer.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Signer.fromJson(Map<String, dynamic> json) => Signer(
    url: json["url"],
    publicKey: json["publicKey"],
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "publicKey": publicKey,
  };
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// // type TokenTx struct {
// //   Hash types.Bytes32    `json:"hash,omitempty" form:"hash" query:"hash" validate:"required"`
// //   From types.UrlChain   `json:"from" form:"from" query:"from" validate:"required"`
// //   To   []*TokenTxOutput `json:"to" form:"to" query:"to" validate:"required"`
// //   Meta json.RawMessage  `json:"meta,omitempty" form:"meta" query:"meta" validate:"required"`
// // }
//
// class TokenTx {
//   TokenTx({
//     this.url,
//     this.publicKey,
//   });
//
//   String hash;
//   String urlChain;  // usually a sender
//
//   factory TokenTx.fromRawJson(String str) => Signer.fromJson(json.decode(str));
//
//   String toRawJson() => json.encode(toJson());
//
//   factory TokenTx.fromJson(Map<String, dynamic> json) => Signer(
//     url: json["url"],
//     publicKey: json["publicKey"],
//   );
//
//   Map<String, dynamic> toJson() => {
//     "url": url,
//     "publicKey": publicKey,
//   };
// }

