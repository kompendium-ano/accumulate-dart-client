class ApiRequestDataAccount {
  final String url;
  final String keyBookUrl;
  final String managerKeyBookUrl;
  final bool isScratch;

  ApiRequestDataAccount(this.url, this.keyBookUrl, this.managerKeyBookUrl, this.isScratch);

  ApiRequestDataAccount.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        managerKeyBookUrl = json['managerKeyBookUrl'],
        isScratch = json['scratch'],
        keyBookUrl = json['keyBookUrl'];

  Map<String, dynamic> toJson() =>
      {'url': url, 'managerKeyBookUrl': managerKeyBookUrl, 'keyBookUrl': keyBookUrl, "scratch": isScratch};
}
