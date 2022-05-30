

//An Accumulate URL (e.g: 'acc://my-identity/mydata')
class AccURL {

  late String authority;
  late String path;
  late String query;
  late String fragment;

  AccURL(String url) {
    Uri parsedUri = Uri.parse(url);

    if (parsedUri.scheme != "acc") {
      throw Exception('Invalid protocol: ${parsedUri.scheme}');
    }
    if (parsedUri.host.isEmpty) {
      throw Exception("Missing authority");
    }
    authority = parsedUri.host;

    path = parsedUri.path;

    query = parsedUri.query;

    fragment  = parsedUri.fragment;
  }

  //Parse, if necessary, argument into an AccURL
  static AccURL toAccURL(dynamic arg) {

    return arg is AccURL ? arg : AccURL.parse(arg);
  }

  //Parse a string into an AccURL
  static AccURL parse(String url) {
    return AccURL(url);
  }

  @override
  String toString() {
    return "acc://$authority$path";
  }




}
