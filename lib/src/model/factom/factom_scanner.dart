import 'package:bitcoin_bip44/bitcoin_bip44.dart';

class FactomScanner extends Scanner {

  String? pathToFactomDb;

  @override
  Future<bool> present(String address) {
    if (address.startsWith('FA')) {
      return Future.value(true);
    }
    return Future.value(false);
  }
}