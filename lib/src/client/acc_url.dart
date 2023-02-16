import 'dart:core';

/**
 * The URL of the ACME token
 */
final ACME_TOKEN_URL = AccURL.parse("acc://acme");

/**
 * The URL of the DN
 */
final DN_URL = AccURL.parse("acc://dn.acme");

/**
 * The URL of the anchors
 */
final ANCHORS_URL = DN_URL.append("anchors");

class InvalidProtocolException implements Exception {
  late String scheme;

  InvalidProtocolException(this.scheme);

  @override
  String toString() {
    return 'Invalid protocol: ${scheme}';
  }
}

class MissingAuthorityException implements Exception {
  @override
  String toString() {
    return 'Missing authority';
  }
}

class AccURL {
  late String authority;

  late String path;

  late String query;

  late String fragment;
  late String orgURL;

  AccURL(String url) {
    Uri parsedUri = Uri.parse(url);

    if (parsedUri.scheme != "acc") {
      throw InvalidProtocolException(parsedUri.scheme);
    }
    if (parsedUri.host.isEmpty) {
      throw MissingAuthorityException();
    }
    orgURL = url;
    authority = parsedUri.host;

    path = parsedUri.path;

    query = parsedUri.query;

    fragment = parsedUri.fragment;
  }

  AccURL append(dynamic path) {
    final pathStr = path.toString();

    String url = orgURL.toString();

    if (pathStr.length > 0) {
      if (pathStr.startsWith("acc://")) {
        url += pathStr.substring(5);
      } else if (pathStr[0] == "/") {
        url += pathStr;
      } else {
        url += '/${pathStr}';
      }
    }


    return AccURL.parse(url);
  }

  static AccURL toAccURL(dynamic arg) {
    return arg is AccURL ? arg : AccURL.parse(arg);
  }

  static AccURL parse(String url) {
    return AccURL(url);
  }

  @override
  String toString() {
    return "acc://$authority$path";
  }
}
