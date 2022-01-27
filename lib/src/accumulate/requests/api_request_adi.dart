
class ApiRequestADI {
  final String url;
  final String publicKeyHash;

  ApiRequestADI(this.url, this.publicKeyHash);

  ApiRequestADI.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        publicKeyHash = json['publicKeyHash'];

  Map<String, dynamic> toJson() => {
    'url': url,
    'publicKeyHash':publicKeyHash
  };

}