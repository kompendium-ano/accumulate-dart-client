import 'package:flutter/foundation.dart';

//An Accumulate URL (e.g: 'acc://my-identity/mydata')
class AccURL {

  late Uri _url;
  AccURL(String url) {

    Uri parsedUri = Uri.parse(url);

    if (parsedUri.scheme != "acc") {
      throw Exception('Invalid protocol: ${parsedUri.scheme}');
    }
    if (parsedUri.host.isEmpty) {
      throw Exception("Missing authority");
    }
    _url = parsedUri;
  }

  //Parse, if necessary, argument into an AccURL
  static AccURL toAccURL(dynamic arg) {
    return arg is AccURL ? arg : AccURL.parse(arg);
  }

  //Parse a string into an AccURL
  static AccURL parse(String url) {
    return AccURL(url);
  }

  String get authority => _url.host;

  String get path => _url.path;

  String get query => _url.query;

  String get fragment => _url.fragment;

}
