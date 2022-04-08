class ApiRequestWriteData {
  final String? data;
  final List<String>? extIds;

  /*
  ApiRequestWriteData(this.data,this.extIds);

  ApiRequestWriteData.fromJson(Map<String, dynamic> json) : data = json['entry']['data'],
        extIds = json['extIDs'];

  Map<String, dynamic> toJson() => {
        'entry': {'data': data}
      };*/

  ApiRequestWriteData(this.data, this.extIds);

  ApiRequestWriteData.fromJson(Map<String, dynamic> json)
      : data = json['url'],
        extIds = json['extIDs'];

  Map<String, dynamic> toJson() => {'url': data, 'extIDs': extIds};
}
