class AccURL  {

  late String authority;

  late String path;

  late String query;

  late String fragment;
  late String orgURL;

  AccURL(String url) {
    Uri parsedUri = Uri.parse(url);

    if (parsedUri.scheme != "acc") {
      throw Exception('Invalid protocol: ${parsedUri.scheme}');
    }
    if (parsedUri.host.isEmpty) {
      throw Exception("Missing authority");
    }
    orgURL = url;
    authority = parsedUri.host;

    path = parsedUri.path;

    query = parsedUri.query;

    fragment = parsedUri.fragment;
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
