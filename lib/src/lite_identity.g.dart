// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lite_identity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LiteIdentityAdapter extends TypeAdapter<LiteIdentity> {
  @override
  final int typeId = 102;

  @override
  LiteIdentity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LiteIdentity();
  }

  @override
  void write(BinaryWriter writer, LiteIdentity obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiteIdentityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
