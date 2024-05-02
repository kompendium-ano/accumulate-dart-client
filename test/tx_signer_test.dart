import 'package:test/test.dart';
import 'package:mockito/mockito.dart'; // Ensure Mockito is imported
import 'mocks.mocks.dart'; // Ensure generated mocks are imported

import 'package:accumulate_api/src/client/acc_url.dart';
import 'package:accumulate_api/src/client/tx_signer.dart';
import 'package:accumulate_api/src/payload.dart';
import 'package:accumulate_api/src/transaction.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  group('TxSigner', () {
    late MockSigner mockSigner;
    late TxSigner txSigner;

    setUp(() {
      mockSigner = MockSigner();
      txSigner = TxSigner(AccURL.parse('acc://example.acme'), mockSigner);

      // Stubbing methods for MockSigner
      when(mockSigner.publicKey()).thenReturn(Uint8List.fromList([1, 2, 3, 4]));
      // Ensure the returned signature is realistic for your application's needs
      when(mockSigner.signRaw(any))
          .thenReturn(Uint8List.fromList([5, 6, 7, 8])); // Example signature
      when(mockSigner.secretKey())
          .thenReturn(Uint8List.fromList([9, 10, 11, 12]));
      when(mockSigner.publicKeyHash())
          .thenReturn(Uint8List.fromList([13, 14, 15, 16]));
      when(mockSigner.mnemonic()).thenReturn("dummy mnemonic");
      when(mockSigner.type).thenReturn(0);
    });

    test('TxSigner should sign a transaction correctly', () {
      final payload = DummyPayload();
      final headerOptions = HeaderOptions(
          timestamp: DateTime.now().microsecondsSinceEpoch, memo: "Test Memo");
      final header = Header(AccURL.parse('acc://example.com'), headerOptions);
      final transaction = Transaction(payload, header);

      // Perform the signing
      transaction
          .sign(txSigner); // This line is crucial - it performs the signing

      // Verification that signRaw was called
      verify(mockSigner.signRaw(any)).called(
          1); // Ensure this matches how your TxSigner and Signer interact

      // Assertions to confirm the signature is applied
      expect(transaction.signature, isNotNull,
          reason: "Signature should not be null after signing.");
      expect(transaction.signature!.signature, isNotNull,
          reason: "Signature content should not be null.");
    });
  });
}

class DummyPayload extends Payload {
  @override
  Uint8List marshalBinary() {
    return utf8.encode("Dummy data");
  }

  @override
  Uint8List hash() {
    return sha256.convert(marshalBinary()).bytes as Uint8List;
  }
}
