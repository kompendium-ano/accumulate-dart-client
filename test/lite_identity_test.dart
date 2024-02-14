import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:mockito/mockito.dart';

// Manual mocking
class MockSigner extends Mock implements Signer {
  @override
  int get type => 0;

  @override
  Uint8List publicKey() => Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22]);

  @override
  Uint8List publicKeyHash() => Uint8List.fromList(List.generate(20, (index) => index + 1));

  @override
  Uint8List signRaw(Uint8List data) => Uint8List.fromList([7, 8, 9]);

  @override
  Uint8List secretKey() => Uint8List.fromList([10, 11, 12]);

  @override
  String mnemonic() => "mock mnemonic";
}

void main() {
  group('LiteIdentity', () {
    late LiteIdentity liteIdentity;
    late MockSigner mockSigner;

    setUp(() {
      // Initialize your mockSigner before each test
      mockSigner = MockSigner();
      // Pass the mockSigner to your LiteIdentity constructor
      liteIdentity = LiteIdentity(mockSigner);
    });

    test('LiteIdentity initialization', () {
      // Verifying the liteIdentity instance is correctly initialized with a URL
      expect(liteIdentity.url, isNotNull);
      // Here, you could add more specific checks to validate the URL
    });

    test('Get ACME Token Account URL', () {
      // Testing the ACME Token Account URL functionality
      final acmeTokenAccount = liteIdentity.acmeTokenAccount;
      expect(acmeTokenAccount, isNotNull);
      // You can add more specific validations for the ACME Token Account URL
    });

    test('Compute URL', () {
      final publicKeyHash = Uint8List.fromList(List.generate(20, (index) => index + 1));
      final url = LiteIdentity.computeUrl(publicKeyHash);
      
      expect(url, isNotNull);
    });
  });
}
