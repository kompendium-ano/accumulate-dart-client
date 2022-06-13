import 'dart:typed_data';
import '../utils.dart';

import "../encoding.dart";
import "../tx_types.dart" show TransactionType;
import "base_payload.dart" show BasePayload;

class WriteDataArg{
late List<Uint8List> data;
bool? scratch;
}

class WriteData extends BasePayload {
  late List<Uint8List> _data;
  late bool _scratch;
  WriteData(WriteDataArg arg) : super() {

    _data = arg.data;
    _scratch = arg.scratch ?? false;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];
    forConcat.addAll(uvarintMarshalBinary(TransactionType.writeData));

    for(Uint8List item in _data){
      forConcat.addAll(hashMarshalBinary(item));
    }

    forConcat.addAll(booleanMarshalBinary(_scratch));

    return forConcat.asUint8List();
  }
}

