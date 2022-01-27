import 'dart:convert';

class ApiRequestKeyPageUpdate {
  final String operation; // add, remove
  final String key; //
  final String newKey;

  ApiRequestKeyPageUpdate(this.operation, this.key, this.newKey);

  ApiRequestKeyPageUpdate.fromJson(Map<String, dynamic> json)
      : operation = json['operation'],
        key = json['key'],
        newKey = json['newKey'];

  Map<String, dynamic> toJson() => {'operation': operation, 'key': key, 'newKey': newKey};
}
