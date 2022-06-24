// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tx_signer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TxSignerAdapter extends TypeAdapter<TxSigner> {
  @override
  final int typeId = 101;

  @override
  TxSigner read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TxSigner()
      .._url = fields[0] as AccURL
      .._signer = fields[1] as Signer
      .._version = fields[2] as int;
  }

  @override
  void write(BinaryWriter writer, TxSigner obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj._url)
      ..writeByte(1)
      ..write(obj._signer)
      ..writeByte(2)
      ..write(obj._version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxSignerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
