import 'dart:convert';
import 'package:accumulate_api/src/utils/marshaller.dart';
import 'package:crypto/crypto.dart';

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
  final SignatureInfo signatureInfo;  // SigInfo            - Information that is included with the Transaction
  List<int> transaction;              // Transaction []byte - The transaction that follows

  ApiRequestTxGen(this.hash, this.signatureInfo);

  ApiRequestTxGen.fromJson(Map<String, dynamic> json)
      : hash = json['hash'],
        signatureInfo = json['signatureInfo'];

  Map<String, dynamic> toJson() => {
    'hash': hash,
    'sigInfo': signatureInfo,
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
    List<int> data  = signatureInfo.marshal();
    List<int> sHash = sha256.convert(data).bytes;
    List<int> tHash = sha256.convert(transaction).bytes;
    List<int> txhRaw = [];
    txhRaw.addAll(sHash);
    txhRaw.addAll(tHash);
    var txh = sha256.convert(txhRaw);
    return txh.bytes;
  }

  List<int> generateTransactionHashWithRemoteNonce(List<int> nonce){
    List<int> data  = signatureInfo.marshalWithRemoteNonce(nonce);
    List<int> sHash = sha256.convert(data).bytes;
    List<int> tHash = sha256.convert(transaction).bytes;
    List<int> txhRaw = [];
    txhRaw.addAll(sHash);
    txhRaw.addAll(tHash);
    var txh = sha256.convert(txhRaw);
    return txh.bytes;
  }

}


// SignatureInfo
// The struct holds the URL, the nonce, and the signature indexes that are
// used to validate the signatures of a transaction.
//
// The transaction hash is what is signed.  This must be unique, or
// transactions could be replayed (breaking the security of the protocol)
//
// The following defines the roles each field plays to ensure transactions
// cannot be replayed.
//
// The URL forces the transaction onto the chain identified by the URL.
//
// The ChainID derived from the URL allows the chain to provide the
// SigSpecGroup (signature specification group) that applies to this chain.
//
// The SigSpecHt specifies the number of elements in the SigSpecGroup when
// the signature was generated.  Any change to the keys of the SigSpecGroup
// will increment the height, and if the transaction has not been promoted,
// the transaction will be invalided.
//
// The Priority will specify exactly which signature specification submitted
// the transaction
//
// The PriorityIdx will specify which of possibly multiple signatures signed
// the transaction submission.
//
// The nonce of the transaction submission must be equal to the nonce of
// the signature that submitted the transaction.
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// type SignatureInfo struct {
// // The following elements are all part of the Transaction that goes onto
// // the main chain.  But the only thing that varies from one transaction
// // to another is the transaction itself.
// URL         string // URL for the transaction
// MSHeight    uint64 // Height of the multi sig spec
// PriorityIdx uint64 // Index within the Priority of the signature used
// Unused1     uint64 // This field is not used
// Unused2     uint64 // This field is not used
// }
class SignatureInfo {
  String url;      // in our case sender url like acc://
  int msHeight;    // Height of the multi sig spec
  int priorityIdx;
  int unused1;     // as priority
  int unused2;     // as nonce, timestamp

  SignatureInfo({String url, int msHeight, int priorityIdx,  int unused1, int unused2}){
    this.url = url;
    this.msHeight = msHeight;
    this.priorityIdx = priorityIdx;
    this.unused1 = unused1;
    this.unused2 = unused2;
  }


  // Marshal
  // UnMarshal
  // Create the binary representation of the GenTransaction
  //   func (t *SignatureInfo) Marshal() (data []byte, err error) { //            Serialize the Signature Info
  //       defer func() { //                                                      If any problems are encountered, then
  //       if err := recover(); err != nil { //                               Complain
  //       err = fmt.Errorf("error marshaling GenTransaction %v", err) //
  //       } //
  //       }()
  //
  //       data = common.SliceBytes([]byte(t.URL))                   //           URL =>
  //       data = append(data, common.Uint64Bytes(t.Unused2)...)     //           Nonce =>
  //       data = append(data, common.Uint64Bytes(t.MSHeight)...)    //           SigSpecHt =>
  //       data = append(data, common.Uint64Bytes(t.Unused1)...)     //           Priority =>
  //       data = append(data, common.Uint64Bytes(t.PriorityIdx)...) //           PriorityIdx =>
  //       return data, nil                                          //           All good, return data and nil error
  //   }
  List<int> marshal() {
    List<int> data = [];

    List<int> encAddr = utf8.encode(url);
    //print(encAddr.length);

    data.addAll(uint64ToBytes(encAddr.length));  // to emulate SliceBytes
    data.addAll(encAddr);                        // to emulate SliceBytes
    data.addAll(uint64ToBytes(unused2));         // append nonce
    data.addAll(uint64ToBytes(msHeight));
    data.addAll(uint64ToBytes(unused1));
    data.addAll(uint64ToBytes(priorityIdx));

    return data;
  }

  List<int> marshalWithRemoteNonce(List<int> nonce) {
    List<int> data = [];

    List<int> encAddr = utf8.encode(url);
    //Uint8List nonceAsBytes = intAsBytes32_8(nonce);

    data.add(encAddr.length);
    data.addAll(encAddr);
    print(encAddr.length);
    data.addAll(nonce);
    data.add(msHeight);
    data.add(unused1);
    data.add(priorityIdx);

    return data;
  }
}




