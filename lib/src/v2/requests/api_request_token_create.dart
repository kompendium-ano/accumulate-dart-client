class ApiRequestToken {
  final String url;
  final String keyBookUrl;
  final String tokenSymbol;
  final int precision;
  final String properties;
  final int initialSupply;
  final bool hasSupplyLimit;

  ApiRequestToken(this.url, this.tokenSymbol, this.keyBookUrl, this.precision, this.properties, this.initialSupply,
      this.hasSupplyLimit);

  ApiRequestToken.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        tokenSymbol = json['symbol'],
        keyBookUrl = json['keyBookUrl'],
        precision = json['precision'],
        properties = json['properties'],
        initialSupply = json['initialSupply'],
        hasSupplyLimit = json['hasSupplyLimit'];

  Map<String, dynamic> toJson() => {'url': url, 'symbol': tokenSymbol, 'keyBookUrl': keyBookUrl};
}
