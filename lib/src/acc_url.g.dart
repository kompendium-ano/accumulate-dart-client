// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acc_url.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccURLAdapter extends TypeAdapter<AccURL> {
  @override
  final int typeId = 100;

  @override
  AccURL read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < 1; i++) reader.readByte(): reader.read(),
    };
    return AccURL(fields[0])
      ..authority = Uri.parse(fields[0]).host
      ..path = Uri.parse(fields[0]).path
      ..query = Uri.parse(fields[0]).query
      ..fragment = Uri.parse(fields[0]).fragment;
  }

  @override
  void write(BinaryWriter writer, AccURL obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.authority)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.query)
      ..writeByte(3)
      ..write(obj.fragment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccURLAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
