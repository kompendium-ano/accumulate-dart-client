class ApiRequestWriteDataTo {
  final String? data;
  final String? recipient;

  ApiRequestWriteDataTo(this.data, this.recipient);

  ApiRequestWriteDataTo.fromJson(Map<String, dynamic> json)
      : data = json['entry']['data'],
        recipient = json['recipient'];

  Map<String, dynamic> toJson() => {
        'entry': {'data': data},
        'recipient': recipient,
      };
}
