class ApiRequestData {
  final String data;
  final List<String> extIds;

  ApiRequestData(this.data, this.extIds);

  ApiRequestData.fromJson(Map<String, dynamic> json)
      : data = json['url'],
        extIds = json['extIDs'];

  Map<String, dynamic> toJson() =>
      {'url': data, 'extIDs': extIds};
}
