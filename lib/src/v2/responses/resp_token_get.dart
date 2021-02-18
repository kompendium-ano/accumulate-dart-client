
import 'dart:convert';

import 'package:accumulate_api/src/v2/responses/data.dart';

class TokenAccountGetResponse {
  TokenAccountGetResponse({
    this.data,
    this.type,
  });

  Data? data;
  String? type;

  factory TokenAccountGetResponse.fromRawJson(String str) => TokenAccountGetResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TokenAccountGetResponse.fromJson(Map<String, dynamic> json) => TokenAccountGetResponse(
    data: Data.fromJson(json["data"]),
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "data": data!.toJson(),
    "type": type,
  };

  // TokenAccountGetResponse.fromJson(Map<String, dynamic> json)
  //     : data = json['data'],
  //       type = json['type'];


}
