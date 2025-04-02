import 'package:test/test.dart';
import 'package:accumulate_api/src/client/tx_types.dart';

void main() {
  group('TransactionType', () {
    test('TransactionType constants should have correct values', () {
      expect(TransactionType.createIdentity, 0x01);
      expect(TransactionType.createTokenAccount, 0x02);
      expect(TransactionType.sendTokens, 0x03);
      expect(TransactionType.createDataAccount, 0x04);
      expect(TransactionType.writeData, 0x05);
      expect(TransactionType.writeDataTo, 0x06);
      expect(TransactionType.acmeFaucet, 0x07);
      expect(TransactionType.createToken, 0x08);
      expect(TransactionType.issueTokens, 0x09);
      expect(TransactionType.burnTokens, 0x0a);
      expect(TransactionType.CreateLiteTokenAccount, 0x0b);
      expect(TransactionType.createKeyPage, 0x0c);
      expect(TransactionType.createKeyBook, 0x0d);
      expect(TransactionType.addCredits, 0x0e);
      expect(TransactionType.updateKeyPage, 0x0f);
      expect(TransactionType.addValidator, 0x12);
      expect(TransactionType.removeValidator, 0x13);
      expect(TransactionType.updateValidatorKey, 0x14);
      expect(TransactionType.updateAccountAuth, 0x15);
      expect(TransactionType.updateKey, 0x16);
    });
  });
}
