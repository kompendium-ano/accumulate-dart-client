class ApiRequestWriteData {
  final String? data;

  ApiRequestWriteData(this.data);

  ApiRequestWriteData.fromJson(Map<String, dynamic> json) : data = json['entry']['data'];

  Map<String, dynamic> toJson() => {
        'entry': {'data': data}
      };
}
