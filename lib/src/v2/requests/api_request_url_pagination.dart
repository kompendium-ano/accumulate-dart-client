
class ApiRequestUrWithPagination {
  final String? url;
  final int? start;
  final int? count;

  ApiRequestUrWithPagination(this.url, this.start, this.count);

  ApiRequestUrWithPagination.fromJson(Map<String, dynamic> json)
      : url  = json['url'],
        start = json['start'],
        count = json['count'];

  Map<String, dynamic> toJson() => {
    'url': url,
    'start': start,
    'count': count
  };

}