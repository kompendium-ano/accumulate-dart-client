// lib\src\client\tx_types.dart
class TransactionType {
  // CreateIdentity creates an ADI,
  // which produces a synthetic chain.
  static const createIdentity = 0x01;

  // CreateTokenAccount creates an ADI token account,
  // which produces a synthetic chain create transaction.
  static const createTokenAccount = 0x02;

  // SendTokens transfers tokens between token accounts,
  // which produces a synthetic deposit tokens transaction.
  static const sendTokens = 0x03;

  // CreateDataAccount creates an ADI Data Account,
  // which produces a synthetic chain create transaction.
  static const createDataAccount = 0x04;

  // WriteData writes data to an ADI Data Account,
  // which *does not* produce a synthetic transaction.
  static const writeData = 0x05;

  // WriteDataTo writes data to a Lite Data Account,
  // which produces a synthetic write data transaction.
  static const writeDataTo = 0x06;

  // AcmeFaucet produces a synthetic deposit tokens transaction,
  // that deposits ACME tokens into a lite token account.
  static const acmeFaucet = 0x07;

  // CreateToken creates a token issuer,
  // which produces a synthetic chain create transaction.
  static const createToken = 0x08;

  // IssueTokens issues tokens to a token account,
  // which produces a synthetic token deposit transaction.
  static const issueTokens = 0x09;

  // BurnTokens burns tokens from a token account,
  // which produces a synthetic burn tokens transaction.
  static const burnTokens = 0x0a;

  // Creates a lite token account
  static const CreateLiteTokenAccount = 0x0b;

  // CreateKeyPage creates a key page,
  // which produces a synthetic chain create transaction.
  static const createKeyPage = 0x0c;

  // CreateKeyBook creates a key book,
  // which produces a synthetic chain create transaction.
  static const createKeyBook = 0x0d;

  // AddCredits converts ACME tokens to credits,
  // which produces a synthetic deposit credits transaction.
  static const addCredits = 0x0e;

  // UpdateKeyPage adds, removes, or updates keys in a key page,
  // which *does not* produce a synthetic transaction.
  static const updateKeyPage = 0x0f;

  // AddValidator add a validator.
  static const addValidator = 0x12;

  //RemoveValidator remove a validator.
  static const removeValidator = 0x13;

  //UpdateValidatorKey update a validator key.
  static const updateValidatorKey = 0x14;

  //UpdateAccountAuth updates authorization for an account.
  static const updateAccountAuth = 0x15;

  //UpdateKey update key for existing keys.
  static const updateKey = 0x16;
}
