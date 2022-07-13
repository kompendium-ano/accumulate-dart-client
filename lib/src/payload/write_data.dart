import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../utils.dart';

import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class WriteDataParam {
  late List<Uint8List> data;
  bool? scratch;
}

class WriteData extends BasePayload {
  late List<Uint8List> _data;
  late bool _scratch;
  Uint8List? _dataHash;

  WriteData(WriteDataParam writeDataParam) : super() {
    _data = writeDataParam.data;
    _scratch = writeDataParam.scratch ?? false;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.writeData, 1));

    forConcat.addAll(fieldMarshalBinary(2, marshalDataEntry(_data)));
    forConcat.addAll(booleanMarshalBinary(_scratch, 3));

    return forConcat.asUint8List();
  }

  @override
  Uint8List hash() {
    if (_dataHash != null) {
      return _dataHash!;
    }
    _dataHash = hashTree(_data);
    return _dataHash!;
  }

  Uint8List marshalDataEntry(List<Uint8List> data) {
    List<int> forConcat = [];

    // AccumulateDataEntry DataEntryType 2
    forConcat.addAll(uvarintMarshalBinary(2, 1));
    // Data
    for (Uint8List val in data) {
      forConcat.addAll(bytesMarshalBinary(val, 3));
    }

    return bytesMarshalBinary(forConcat.asUint8List());
  }

  Uint8List sha256Update(Uint8List data) {
    return sha256.convert(data).bytes.asUint8List();
  }

  Uint8List hashTree(List<Uint8List> items) {
    final hashes = items.map((i) => sha256Update(i)).toList();

    while (hashes.length > 1) {
      var i = 0; // hashes index
      var p = 0; // pointer
      while (i < hashes.length) {
        if (i == hashes.length - 1) {
          // Move the last "alone" leaf to the pointer
          hashes[p] = hashes[i];
          i += 1;
        } else {
          List<int> forConcat = [];
          forConcat.addAll(hashes[i]);
          forConcat.addAll(hashes[i + 1]);
          hashes[p] = sha256Update(forConcat.asUint8List());
          i += 2;
        }
        p += 1;
      }
      hashes.length = p;
    }

    return hashes[0];
  }
}
