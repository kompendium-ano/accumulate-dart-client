class ApiRequestTokenAccount {
  final String url;
  final String tokenUrl;
  final String keyBookUrl;

  ApiRequestTokenAccount(this.url, this.tokenUrl, this.keyBookUrl);

  ApiRequestTokenAccount.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        tokenUrl = json['tokenUrl'],
        keyBookUrl = json['keyBookUrl'];

  Map<String, dynamic> toJson() =>
      {'url': url, 'tokenUrl': tokenUrl, 'keyBookUrl': keyBookUrl};
}
