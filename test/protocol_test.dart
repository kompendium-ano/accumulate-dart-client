import 'dart:convert';
import 'dart:io';

import 'package:accumulate_api/src/protocol/transactions.dart';
import 'package:test/test.dart';

class TestCase {
  final List<int> binary;
  final dynamic json;

  TestCase(this.binary, this.json);

  TestCase.fromJson(Map<String, dynamic> json)
      : binary = base64Decode(json['binary']),
        json = json['json'];
}

class TestCaseGroup {
  final String name;
  final List<TestCase> cases;

  TestCaseGroup(this.name, this.cases);

  TestCaseGroup.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        cases = (json['cases'] as List<dynamic>)
            .map((v) => TestCase.fromJson(v))
            .toList();
}

void main() async {
  var file = File('test/protocol-test-data/protocol.1.json');
  var contents = await file.readAsString();
  var raw = jsonDecode(contents)['transactions'] as List<dynamic>;
  var tests = raw.map((v) => TestCaseGroup.fromJson(v));

  group('transactions', () {
    tests.forEach((tcg) {
      if (tcg.name == "AcmeFaucet" || tcg.name.startsWith("Synthetic")) return;

      group(tcg.name, () {
        tcg.cases.asMap().forEach((index, tc) {
          test(index.toString(), () {
            var env = Envelope.fromJson(tc.json);
            var bytes = env.marshalBinary();
            expect(bytes, equals(tc.binary));
          });
        });
      });
    });
  });
}
