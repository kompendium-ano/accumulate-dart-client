
import 'dart:convert';

class TokenAccountGetResponse {
  TokenAccountGetResponse({
    this.data,
    this.type,
  });

  Data data;
  String type;

  factory TokenAccountGetResponse.fromRawJson(String str) => TokenAccountGetResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TokenAccountGetResponse.fromJson(Map<String, dynamic> json) => TokenAccountGetResponse(
    data: Data.fromJson(json["data"]),
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "data": data.toJson(),
    "type": type,
  };

  // TokenAccountGetResponse.fromJson(Map<String, dynamic> json)
  //     : data = json['data'],
  //       type = json['type'];


}

class Data {
  Data({
    this.balance,
    this.tokenUrl,
    this.url,
  });

  String balance;
  String tokenUrl;
  String url;

  factory Data.fromRawJson(String str) => Data.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    balance: json["balance"],
    tokenUrl: json["tokenURL"],
    url: json["url"],
  );

  Map<String, dynamic> toJson() => {
    "balance": balance,
    "tokenURL": tokenUrl,
    "url": url,
  };
}
