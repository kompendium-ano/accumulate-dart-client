import 'dart:convert';
import 'package:accumulate/src/utils/format.dart';
import 'package:crypto/crypto.dart';

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

// this is a special type we follow
// to reproduce hash created inside Accumulate node
// we don't need to have everything only things that are marshalled
// type GenTransaction struct {
//   Routing uint64 //            first 8 bytes of hash of identity [NOT marshaled]
//   ChainID []byte //            hash of chain URL [NOT marshaled]
//
//   Signature   []*ED25519Sig  // Signature(s) of the transaction
//   TxHash      []byte         // Hash of the Transaction
//   SigInfo     *SignatureInfo // Information that is included with the Transaction
//   Transaction []byte         // The transaction that follows
// }
class ApiRequestTxGen {
  List<int> hash;                     // TxHash []byte      - Hash of the Transaction
  final TransactionHeader header;     // SigInfo            - Information that is included with the Transaction
  List<int> transaction;              // Transaction []byte - The transaction that follows

  ApiRequestTxGen(this.hash, this.transaction, this.header);

  ApiRequestTxGen.fromJson(Map<String, dynamic> json)
      : hash = json['hash'],
        header = json['header'];

  Map<String, dynamic> toJson() => {
    'hash': hash,
    'header': header,
  };

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
    List<int> tHash = sha256.convert(transaction).bytes;
    List<int> txhRaw = [];
    txhRaw.addAll(sHash);
    txhRaw.addAll(tHash);
    var txh = sha256.convert(txhRaw);
    return txh.bytes;
  }
}