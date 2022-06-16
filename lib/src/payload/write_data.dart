import 'dart:typed_data';
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

  WriteData(WriteDataParam writeDataParam) : super() {
    _data = writeDataParam.data;
    _scratch = writeDataParam.scratch ?? false;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat.addAll(uvarintMarshalBinary(TransactionType.writeData, 1));

    //forConcat.addAll(fieldMarshalBinary(2, marshalDataEntry(_data)));
    forConcat.addAll(booleanMarshalBinary(_scratch, 3));

    return forConcat.asUint8List();
  }
}
