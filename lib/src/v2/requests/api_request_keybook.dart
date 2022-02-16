class ApiRequestKeyBook {
  final String? url;
  final List<String>? pages;

  ApiRequestKeyBook(this.url, this.pages);

  ApiRequestKeyBook.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        pages = json['pages'];

  Map<String, dynamic> toJson() =>
      {'url': url, 'pages': pages};
}
