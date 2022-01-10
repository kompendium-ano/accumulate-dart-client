import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:fixnum/fixnum.dart';

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
  String generateTransactionHash(){
    var data  = signatureInfo.marshal();
    var sHash = sha256.convert(data);
    //var tHash = sha256.convert();

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
// SigSpecHt   uint64 // Height of the SigSpec Chain
// Priority    uint64 // Priority for the signature in the SigSpec
// PriorityIdx uint64 // Index within the Priority of the signature used
// Nonce       uint64 // Nonce for the signature to prevent replays
// }
class SignatureInfo {
  String url;              // in our case sender url like acme-xxx
  int sigSpecHt;
  int priority;
  int priorityIdx;
  int nonce;


  SignatureInfo(this.url, this.sigSpecHt, this.priority, this.priorityIdx, this.nonce);

  // Marshal
  // Create the binary representation of the GenTransaction
  //   func (t *SignatureInfo) Marshal() (data []byte, err error) { //            Serialize the Signature Info
  //   defer func() { //                                                      If any problems are encountered, then
  //   if err := recover(); err != nil { //                               Complain
  //   err = fmt.Errorf("error marshaling GenTransaction %v", err) //
  //   } //
  //   }()
  //
  //   data = common.SliceBytes([]byte(t.URL))                   //           URL =>
  //   data = append(data, common.Uint64Bytes(t.Nonce)...)       //           Nonce =>
  //   data = append(data, common.Uint64Bytes(t.SigSpecHt)...)   //           SigSpecHt =>
  //   data = append(data, common.Uint64Bytes(t.Priority)...)    //           Priority =>
  //   data = append(data, common.Uint64Bytes(t.PriorityIdx)...) //           PriorityIdx =>
  //   return data, nil                                          //           All good, return data and nil error
  //   }
  //
  //
  //  // Uint64Bytes
  //  // Marshal a uint64 (big endian)
  //  // Uint64Bytes gets the big-endian 8-byte representation of a uint64.
  //  func Uint64Bytes(i uint64) (data []byte) {
  // 	  var buf [16]byte
  // 	  count := binary.PutUvarint(buf[:], i)
  // 	  return buf[:count]
  //  }
  //
  //
  List<int> marshal() {
    List<int> data = [];

    List<int> encAddr = utf8.encode(url);
    Uint8List nonceAsBytes = intAsBytes32_8(nonce);

    data.add(encAddr.length);
    data.addAll(encAddr);
    print(encAddr.length);
    data.addAll(nonceAsBytes.toList());
    data.add(sigSpecHt);
    data.add(priority);
    data.add(priorityIdx);

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
    data.add(sigSpecHt);
    data.add(priority);
    data.add(priorityIdx);

    return data;
  }

//  // Uint64Bytes
  //  // Marshal a uint64 (big endian)
  //  // Uint64Bytes gets the big-endian 8-byte representation of a uint64.
  //  func Uint64Bytes(i uint64) (data []byte) {
  // 	  var buf [16]byte                                  // SB: creates byte array of size 16
  // 	  count := binary.PutUvarint(buf[:], i)             // SB: use binary library to put number into byte array
                                                          // SB: PutUvarint encodes a uint64 into buf and returns the
                                                          //     number of bytes written. If the buffer is too small, PutUvarint will panic.
  // 	  return buf[:count]
  //  }
  //
  //
//   func PutUvarint(buf []byte, x uint64) int {
//     i := 0
//     for x >= 0x80 {
//       buf[i] = byte(x) | 0x80
//       x >>= 7
//       i++
//     }
//     buf[i] = byte(x)
//     return i + 1
// }
  void marshal2() {

    //В Dart по int умолчанию используется 64-битное значение
    int nonce = 1633767686115;

    Int64 nonce64 = Int64(nonce);
    List<int> nonce64bytes = nonce64.toBytes();
    BigInt nonceBig = BigInt.from(nonce);
    Uint8List nonceBigBytes = bigIntToUint8List(nonceBig);
    Uint16List nonceBigBytes16 = bigIntToUint16List(nonceBig);

    /////////////
    Uint8List buff11 = int32Bytes(nonce);
    Uint8List buff11_64 = int32Bytes(nonce);
    Uint8List buff12 = int32BigEndianBytes(nonce);
    Uint16List buff13 = int64BigEndianBytes(nonce);
    Uint16List buff14 = int64BigEndianBytes(nonce);
    Uint32List buff15 = intasBytes64_32_big(nonce);
    Uint8List buff21 = int64Bytes(nonce);
    Uint8List buff22 = intAsBytes32_8(nonce); //
    Uint8List buff23 = intAsBytes32_8_big(nonce);
    Uint8List buff24 = intAsBytes64_8(nonce);
    Uint8List buff25 = intAsBytes64_8_big(nonce);


    Uint16List bytes = Uint16List.fromList([227,255,145,161,198,47]);
    // ByteBuffer byteBuffer = bytes.buffer;
    // int res = bytes.buffer.asByteData().getUint64(0);

    //int res = bytesToInteger([227,255,145,161,198,47]);
    int res = fromBytesToInt32(227,255,145,161,198,47);


    print("==========");
    print("Converting: $nonce");
    print("Test: $res");

    print("int32Bytes: $buff11");
    print("int32BigEndianBytes: $buff12");
    print("int64BigEndianBytes: $buff13");
    print("intasBytes64_32_big: $buff15");

    print("==========");
    print("intasBytes: $buff14");
    print("int64Bytes: $buff21");
    print("lil-32-as-8: $buff22");
    print("big-32-as-8: $buff23");
    print("lil-64-as-8: $buff24");
    print("big-64-as-8: $buff25");
    print("==========");
    print("fixnum: $nonce64bytes");
    print("bigint: $nonceBigBytes");
    print("bigint16: $nonceBigBytes16");

    List<int> data = [];
    List<int> encAddr = utf8.encode("acme-118dc7974a8527edd98ae92a3d9f10197a489e");
    data.add(encAddr.length);
    data.addAll(encAddr);
    print(encAddr.length);
    data.addAll(buff22.toList()); //  [227 255 145 161 198 47]
    data.add(0);
    data.add(0);
    data.add(0);
    print(data);
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'sigSpecHt': sigSpecHt,
    'priority':priority,
    'priorityIdx':priorityIdx,
    'nonce': nonce,
  };

}
Uint8List int32Bytes(int value) =>
    Uint8List(4)..buffer.asInt32List()[0] = value;


Uint8List int32BigEndianBytes(int value) =>
    Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

Uint8List int64Bytes(int value) =>
    Uint8List(8)..buffer.asInt64List()[0] = value;

////
Uint16List int64BigEndianBytes(int value) =>
    Uint16List(4)..buffer.asByteData().setInt64(0, value, Endian.big);

Uint8List int64BigEndianBytes_(int value) =>
    Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);

Uint8List intasBytes(int value) =>
    Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);

Uint8List intAsBytes32_8(int value) =>
    Uint8List(8)..buffer.asByteData().setUint32(0, value, Endian.little);

Uint8List intAsBytes32_8_big(int value) =>
    Uint8List(8)..buffer.asByteData().setUint32(0, value, Endian.big);

Uint8List intAsBytes64_8(int value) =>
    Uint8List(8)..buffer.asByteData().setUint64(0, value, Endian.little);

Uint8List intAsBytes64_8_big(int value) =>
    Uint8List(8)..buffer.asByteData().setUint64(0, value, Endian.big);

Uint16List intasBytes64_16(int value) =>
    Uint16List(8)..buffer.asByteData().setUint64(0, value, Endian.little);

Uint16List intasBytes64_16_big(int value) =>
    Uint16List(8)..buffer.asByteData().setUint64(0, value, Endian.big);

Uint32List intasBytes64_32_big(int value) =>
    Uint32List(16)..buffer.asByteData().setUint64(0, value, Endian.big);

/////////////////////////////////

Uint8List bigIntToUint8List(BigInt bigInt) =>
    bigIntToByteData(bigInt).buffer.asUint8List();

Uint16List bigIntToUint16List(BigInt bigInt) =>
    bigIntToByteData(bigInt).buffer.asUint16List();

ByteData bigIntToByteData(BigInt bigInt) {
  final data = ByteData((bigInt.bitLength / 8).ceil());
  var _bigInt = bigInt;

  for (var i = 1; i <= data.lengthInBytes; i++) {
    data.setUint8(data.lengthInBytes - i, _bigInt.toUnsigned(8).toInt());
    _bigInt = _bigInt >> 8;
  }

  return data;
}

////////////////
Uint8List int64Bytes_(int value) =>
    Uint8List(16)..buffer.asInt64List()[0] = value;

int bytesToInteger(List<int> bytes) {
  var value = 0;

  for (var i = 0, length = bytes.length; i < length; i++) {
    value += bytes[i] * pow(256, i);
  }

  return value;
}

int fromBytesToInt32(int b5, int b4, int b3, int b2, int b1, int b0) {
  final int8List = new Int8List(8)
    ..[5] = b5
    ..[4] = b4
    ..[3] = b3
    ..[2] = b2
    ..[1] = b1
    ..[0] = b0;

  return int8List.buffer.asByteData().getInt32(0);
}

