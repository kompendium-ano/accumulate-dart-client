// lib\src\client\acc_url.dart
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
    String url = orgURL.endsWith("/") ? orgURL : "$orgURL/";
    print('AccURL append - Before: $url'); // Log before appending

    if (pathStr.length > 0) {
      if (pathStr.startsWith("acc://")) {
        // Assuming this scenario should not directly append but rather be handled differently
        // For example, extracting the path from the AccURL and appending it to the current URL
        url += pathStr.substring(6);
      } else if (pathStr[0] == "/") {
        url += pathStr.substring(1); // Remove the leading slash to avoid double slashes
      } else {
        url += pathStr;
      }
    }

    print('AccURL append - After: $url'); // Log after appending
    return AccURL.parse(url);
  }

  static AccURL toAccURL(dynamic arg) {
    if (arg == null) {
      throw ArgumentError("AccURL.toAccURL argument must not be null.");
    }
    if (!(arg is String || arg is AccURL)) {
      throw ArgumentError("AccURL.toAccURL argument must be a String or AccURL.");
    }
    return arg is AccURL ? arg : AccURL.parse(arg as String);
  }

  static AccURL parse(String url) {
    return AccURL(url);
  }

  @override
  String toString() {
    return "acc://$authority$path";
  }
}
