class ApiRequestWriteDataTo {
  final String? data;
  final List<String>? extIds;
  final String? recipient;

  ApiRequestWriteDataTo(this.data, this.extIds, this.recipient);

  ApiRequestWriteDataTo.fromJson(Map<String, dynamic> json)
      : data = json['entry']['data'],
        extIds = json['entry']['extIds'],
        recipient = json['recipient'];

  Map<String, dynamic> toJson() => {
        'entry': {'data': data, 'extIds': extIds},
        'recipient': recipient,
      };
}
