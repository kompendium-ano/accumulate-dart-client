import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../utils.dart';

import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";

class WriteDataToParam {
  late List<Uint8List> data;
  bool? scratch;
  bool? writeToState;
}

class WriteDataTo extends BasePayload {
  late List<Uint8List> _data;
  late bool _scratch;
  late bool _writeToState;
  Uint8List? _dataHash;
  Uint8List? _customHash;

  WriteDataTo(WriteDataToParam writeDataToParam) : super() {
    _data = writeDataToParam.data;
    _scratch = writeDataToParam.scratch ?? false;
    _writeToState = writeDataToParam.writeToState ?? false;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = _marshalBinary();
/*
    forConcat.addAll(uvarintMarshalBinary(TransactionType.writeData, 1));

    forConcat.addAll(fieldMarshalBinary(2, marshalDataEntry(_data)));
    forConcat.addAll(booleanMarshalBinary(_scratch, 3));*/

    return forConcat.asUint8List();
  }

  Uint8List _marshalBinary({bool withoutEntry = false}) {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.writeData, 1));

    if (!withoutEntry) {
      forConcat.addAll(fieldMarshalBinary(2, marshalDataEntry(this._data)));
    }

    if (this._scratch) {
      forConcat.addAll(booleanMarshalBinary(this._scratch, 3));
    }
    if (this._writeToState) {
      forConcat.addAll(booleanMarshalBinary(this._writeToState, 4));
    }


    return forConcat.asUint8List();
  }

  @override
  Uint8List hash() {

    /*if (_dataHash != null) {
      return _dataHash!;
    }
    _dataHash = hashTree(_data);
    return _dataHash!;*/

    if (_customHash != null) {
      return _customHash!;
    }
    List<int> forConcat = [];
    Uint8List bodyHash = sha256Update(_marshalBinary(withoutEntry:true));
    Uint8List dataHash = hashTree(_data);
    forConcat.addAll(bodyHash);
    forConcat.addAll(dataHash);
    _customHash = sha256Update(forConcat.asUint8List());

    return _customHash!;


  }

  Uint8List marshalDataEntry(List<Uint8List> data) {
    List<int> forConcat = [];

    // AccumulateDataEntry DataEntryType 2
    forConcat.addAll(uvarintMarshalBinary(2, 1));
    // Data
    for (Uint8List val in data) {
      forConcat.addAll(bytesMarshalBinary(val, 2));
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
