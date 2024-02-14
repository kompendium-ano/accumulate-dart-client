import 'package:test/test.dart';
import 'package:accumulate_api/src/client/signature_type.dart';

void main() {
  group('SignatureType', () {
    test('marshalJSON with ED25519', () {
      final signatureType = SignatureType.signatureTypeED25519;
      final result = SignatureType().marshalJSON(signatureType);
      expect(result, 'ed25519');
    });

    test('marshalJSON with RCD1', () {
      final signatureType = SignatureType.signatureTypeRCD1;
      final result = SignatureType().marshalJSON(signatureType);
      expect(result, 'rcd1');
    });

    test('marshalJSON with unknown signature type', () {
      final signatureType = 99; // An unknown signature type
      try {
        SignatureType().marshalJSON(signatureType);
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), 'Exception: Cannot marshal JSON SignatureType: $signatureType');
      }
    });
  });
}
