
class ApiRequestUrl {
  final String? url;

  ApiRequestUrl(this.url);

  ApiRequestUrl.fromJson(Map<String, dynamic> json)
      : url  = json['url'];

  Map<String, dynamic> toJson() => {
    'url': url
  };

}