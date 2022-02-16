
import 'dart:convert';

class TokenAccountGetResponse {
  TokenAccountGetResponse({
    this.data,
    this.type,
  });

  Data? data;
  String? type;

  factory TokenAccountGetResponse.fromRawJson(String str) => TokenAccountGetResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TokenAccountGetResponse.fromJson(Map<String, dynamic> json) => TokenAccountGetResponse(
    data: Data.fromJson(json["data"]),
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "data": data!.toJson(),
    "type": type,
  };

  // TokenAccountGetResponse.fromJson(Map<String, dynamic> json)
  //     : data = json['data'],
  //       type = json['type'];


}


// String url = res.result["data"]["url"];
// String tokenUrl = res.result["data"]["tokenUrl"];
// String balance = res.result["data"]["balance"];
// int txcount = res.result["data"]["txCount"];
// int nonce = res.result["data"]["nonce"];
// int creditBalance = res.result["data"]["creditBalance"];

class Data {
  Data({
    this.url,
    this.tokenUrl,
    this.balance,
    this.txcount,
    this.nonce,
    this.creditBalance
  });

  int? balance;
  int? txcount;
  int? nonce;
  int? creditBalance;
  String? tokenUrl;
  String? url;

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

class DataDirectory {
  DataDirectory({
    this.url,
    this.tokenUrl,
    this.balance,
    this.keybooksCount,
    this.tokenAccountsCount,
    this.creditBalance,
    this.entities
  });

  int? balance;
  int? keybooksCount;
  int? tokenAccountsCount;
  int? creditBalance;
  String? tokenUrl;
  String? url;
  List<String>? entities;

  factory DataDirectory.fromRawJson(String str) => DataDirectory.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DataDirectory.fromJson(Map<String, dynamic> json) => DataDirectory(
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

class DataKeybook {
  DataKeybook({
    this.url,
    this.mdroot,
  });

  String? url;
  String? mdroot;

}

class DataKeyPage {
  DataKeyPage({
    this.url,
    this.mdroot,
    this.balanceCredits,
  });

  int? balanceCredits;
  String? url;
  String? mdroot;

}