import 'dart:convert';
import 'package:accumulate/src/utils/format.dart';
import 'package:crypto/crypto.dart';

class TransactionType {
  // TxTypeCreateIdentity creates an ADI, which produces a synthetic chain
  // create transaction.
  static const CreateIdentity = 0x01;

  // TxTypeCreateTokenAccount creates an ADI token account, which produces a
  // synthetic chain create transaction.
  static const CreateTokenAccount = 0x02;

  // TxTypeSendTokens transfers tokens between token accounts, which produces
  // a synthetic deposit tokens transaction.
  static const SendTokens = 0x03;

  // TxTypeCreateDataAccount creates an ADI Data Account, which produces a
  // synthetic chain create transaction.
  static const CreateDataAccount = 0x04;

  // TxTypeWriteData writes data to an ADI Data Account, which *does not*
  // produce a synthetic transaction.
  static const WriteData = 0x05;

  // TxTypeWriteDataTo writes data to a Lite Data Account, which produces a
  // synthetic write data transaction.
  static const WriteDataTo = 0x06;

  // TxTypeAcmeFaucet produces a synthetic deposit tokens transaction that
  // deposits ACME tokens into a lite account.
  static const AcmeFaucet = 0x07;

  // TxTypeCreateToken creates a token issuer, which produces a synthetic
  // chain create transaction.
  static const CreateToken = 0x08;

  // TxTypeIssueTokens issues tokens to a token account, which produces a
  // synthetic token deposit transaction.
  static const IssueTokens = 0x09;

  // TxTypeBurnTokens burns tokens from a token account, which produces a
  // synthetic burn tokens transaction.
  static const BurnTokens = 0x0a;

  // TxTypeCreateKeyPage creates a key page, which produces a synthetic chain
  // create transaction.
  static const CreateKeyPage = 0x0c;

  // TxTypeCreateKeyBook creates a key book, which produces a synthetic chain
  // create transaction.
  static const CreateKeyBook = 0x0d;

  // TxTypeAddCredits converts ACME tokens to credits, which produces a
  // synthetic deposit credits transaction.
  static const AddCredits = 0x0e;

  // TxTypeUpdateKeyPage adds, removes, or updates keys in a key page, which
  // *does not* produce a synthetic transaction.
  static const UpdateKeyPage = 0x0f;
}

class TransactionHeader {
  String origin;
  int nonce;
  int keyPageHeight;
  int keyPageIndex;

  TransactionHeader({String origin, int nonce, int keyPageHeight, int keyPageIndex}) {
    this.origin = origin;
    this.nonce = nonce;
    this.keyPageHeight = keyPageHeight;
    this.keyPageIndex = keyPageIndex;
  }

  // Execute binary conversion according to protocol definition
  List<int> marshal() {
    List<int> data = [];

    List<int> encodedOrigin = utf8.encode(origin);
    data.addAll(uint64ToBytes(encodedOrigin.length));
    data.addAll(encodedOrigin);

    data.addAll(uint64ToBytes(keyPageHeight));
    data.addAll(uint64ToBytes(keyPageIndex));
    data.addAll(uint64ToBytes(nonce));

    return data;
  }
}

class ApiRequestTxGen {
  final TransactionHeader header; // Information that is included with the Transaction
  List<int> body;                 // The transaction that follows
  List<int> hash;                 // Hash of the Transaction

  ApiRequestTxGen(this.hash, this.header, this.body);

  // TransactionHash
  // compute the transaction hash from the elements of the GenTransaction.
  // This is used to populate the TxHash field.
  // func (t *GenTransaction) TransactionHash() []byte {
  //   if t.TxHash != nil {                               // Check if I have the hash already
  //     return t.TxHash                                  // Return it if I do
  //   }
  //   data, err := t.SigInfo.Marshal()                   //  Get the SigInfo (all the indexes to signatures)
  //   if err != nil {                                    //  On an error, return a nil
  //     return nil
  //   }
  //   sHash := sha256.Sum256(data)                        // Compute the SigHash
  //   tHash := sha256.Sum256(t.Transaction)               // Compute the transaction Hash
  //   txh := sha256.Sum256(append(sHash[:], tHash[:]...)) // Take hash of SigHash on left and hash of sub tx on right
  //   t.TxHash = txh[:]                                   // cache it
  //   return txh[:]                                       // And return it
  // }+
  List<int> generateTransactionHash(){
    List<int> encodedHeader = header.marshal();
    List<int> sHash = sha256.convert(encodedHeader).bytes;
    List<int> tHash = sha256.convert(body).bytes;
    List<int> txhRaw = [];
    txhRaw.addAll(sHash);
    txhRaw.addAll(tHash);
    var txhb = sha256.convert(txhRaw).bytes;
    return txhb;
  }
}