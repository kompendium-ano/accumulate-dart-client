import 'package:accumulate_api6/src/acc_url.dart';
import 'package:test/test.dart';

void main() {
  test('should parse url', () {
    final u = AccURL.parse("acc://authority/path");

    expect(u.authority, "authority");
    expect(u.path, "/path");
    expect(u.toString(), "acc://authority/path");
  });

  test('should throw on non Accumulate URL', () {
    expect(() => AccURL.parse("https://kompendium.co"), throwsA(isA<InvalidProtocolException>()));
    expect(() => AccURL.parse("acc://"), throwsA(isA<MissingAuthorityException>()));
  });

  test('should append path', () {
    final u = AccURL.parse("acc://authority");
    final tokenURL = AccURL.parse("acc://105251bb367baa372c748930531ae63d6e143c9aa4470eff/my-token");

    expect(u.append("next").toString(), "acc://authority/next");
    expect(u.append("/next").toString(), "acc://authority/next");
    expect(u.append(tokenURL).toString(), "acc://authority/105251bb367baa372c748930531ae63d6e143c9aa4470eff/my-token");
  });
}
