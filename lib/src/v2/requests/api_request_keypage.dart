import 'dart:convert';

class KeySpecParams {
  final String? publickey;

  KeySpecParams(this.publickey);

  KeySpecParams.fromJson(Map<String, dynamic> json)
      : publickey = json['publicKey'];

  Map<String, dynamic> toJson() =>
      {'publicKey': publickey};
}

class ApiRequestKeyPage {
  final String? url;
  final List<KeySpecParams>? keys; // list of public keys to register

  ApiRequestKeyPage(this.url, this.keys);

  ApiRequestKeyPage.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        keys = json['keys'];

  Map<String, dynamic> toJson() =>
      {'url': url, 'keys': keys};
}
