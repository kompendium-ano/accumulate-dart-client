
class ApiRequestUrWithPagination {
  final String url;
  final bool wait;
  final int start;
  final int limit;

  ApiRequestUrWithPagination(this.url, this.wait, this.start, this.limit);

  ApiRequestUrWithPagination.fromJson(Map<String, dynamic> json)
      : url  = json['url'],
        wait = json['wait'],
        start = json['start'],
        limit = json['limit'];

  Map<String, dynamic> toJson() => {
    'url': url,
    'wait': wait,
    'start': start,
    'limit': limit
  };

}