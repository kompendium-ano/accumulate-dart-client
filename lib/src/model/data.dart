import 'dart:convert';

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

class DataChain {
  DataChain({
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

  factory DataChain.fromRawJson(String str) => DataChain.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DataChain.fromJson(Map<String, dynamic> json) => DataChain(
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
