
class ApiRequestUrl {
  final String url;
  final bool wait;

  ApiRequestUrl(this.url, this.wait);

  ApiRequestUrl.fromJson(Map<String, dynamic> json)
      : url  = json['url'],
        wait = json['wait'];

  Map<String, dynamic> toJson() => {
    'url': url,
    'wait': wait
  };

}