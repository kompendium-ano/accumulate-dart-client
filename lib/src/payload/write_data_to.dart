import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../utils/utils.dart';
import '../encoding.dart';
import '../client/tx_types.dart';
import "base_payload.dart";

class WriteDataToParam {
  String? recipient;
  List<Uint8List> data;
  String? memo;
  Uint8List? metadata;

  // Adding a constructor that properly initializes all fields
  WriteDataToParam(
      {this.recipient, required this.data, this.memo, this.metadata});
}

class WriteDataTo extends BasePayload {
  late List<Uint8List> _data;
  late String _recipient;
  Uint8List? _dataHash;
  Uint8List? _customHash;

  WriteDataTo(WriteDataToParam writeDataToParam) : super() {
    _data = writeDataToParam.data;
    _recipient = writeDataToParam.recipient!;
    super.memo = writeDataToParam.memo;
    super.metadata = writeDataToParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = _marshalBinary();

    return forConcat.asUint8List();
  }

  Uint8List _marshalBinary({bool withoutEntry = false}) {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.writeDataTo, 1));
    forConcat.addAll(stringMarshalBinary(this._recipient, 2));

    if (!withoutEntry) {
      forConcat.addAll(withFieldNumber(marshalDataEntry(this._data), 3));
    }

    return forConcat.asUint8List();
  }

  @override
  Uint8List hash() {
    if (_customHash != null) {
      return _customHash!;
    }
    List<int> forConcat = [];
    Uint8List bodyHash = sha256Update(_marshalBinary(withoutEntry: true));
    Uint8List dataHash = sha256Update(hashTree(_data));
    forConcat.addAll(bodyHash);
    forConcat.addAll(dataHash);
    _customHash = sha256Update(forConcat.asUint8List());

    return _customHash!;
  }

  Uint8List marshalDataEntry(List<Uint8List> data) {
    List<int> forConcat = [];

    // DoubleHashDataEntry DataEntryType 3
    forConcat.addAll(uvarintMarshalBinary(3, 1));

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
