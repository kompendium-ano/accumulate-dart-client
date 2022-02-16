import 'dart:convert';

class ApiRespTxTo {
  ApiRespTxTo({
    this.txid,
    this.url,
    this.amount,
  });

  String? txid;
  String? url;
  int? amount;

  factory ApiRespTxTo.fromRawJson(String str) => ApiRespTxTo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRespTxTo.fromJson(Map<String, dynamic> json) => ApiRespTxTo(
    url: json["url"],
    txid: json["txid"],
    amount: json["amount"],
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "amount": amount,
    "txid": txid,
  };
}