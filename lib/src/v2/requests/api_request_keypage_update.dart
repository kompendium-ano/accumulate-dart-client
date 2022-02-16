import 'dart:convert';

class ApiRequestKeyPageUpdate {
  final String? owner;
  final String? operation; // update, remove, add, set threshold
  final String? key; //
  final String? newKey;

  ApiRequestKeyPageUpdate(this.operation, this.key, this.newKey, this.owner);

  ApiRequestKeyPageUpdate.fromJson(Map<String, dynamic> json)
      : operation = json['operation'],
        key = json['key'],
        owner = json['owner'],
        newKey = json['newKey'];

  Map<String, dynamic> toJson() => {'operation': operation, 'key': key, 'newKey': newKey};
}
