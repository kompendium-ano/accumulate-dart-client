import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
part 'acc_url.g.dart';

@HiveType(typeId: 100)
class AccURL  extends HiveObject with EquatableMixin {
  @HiveField(0)
  late String authority;
  @HiveField(1)
  late String path;
  @HiveField(2)
  late String query;
  @HiveField(3)
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

  @override

  List<Object?> get props => [authority, path, query, fragment];
}
