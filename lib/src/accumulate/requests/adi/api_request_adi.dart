class ApiRequestADI {
  final String url;
  final String publicKey;
  String keyBookName; // optional
  String keyPageName; // optional

  ApiRequestADI(this.url, this.publicKey, this.keyBookName, this.keyPageName);

  ApiRequestADI.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        publicKey = json['publicKey'];

  Map<String, dynamic> toJson() =>
      {'url': url, 'publicKey': publicKey, 'keyBookName': keyBookName, 'keyPageName': keyPageName};
}
