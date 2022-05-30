import 'dart:convert';
import 'dart:typed_data';

/// Converts a `List<int>` to a [Uint8List].
///
/// Attempts to cast to a [Uint8List] first to avoid creating an unnecessary
/// copy.
extension AsUint8List on List<int> {
  Uint8List asUint8List() {
    final self = this; // Local variable to allow automatic type promotion.
    return (self is Uint8List) ? self : Uint8List.fromList(this);
  }
}


extension MapToJSON on Map<String,dynamic> {
  String toJson() {
    return jsonEncode(this);
  }
}

extension DynamicToJSON on dynamic {
  String toJson() {
    return jsonEncode(this);
  }
}

extension ObjectToJSON on Object {
  String toJson() {
    return jsonEncode(this);
  }
}