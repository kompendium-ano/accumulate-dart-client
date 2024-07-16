
class SignatureType {
  static const signatureTypeMultiHash =
      1; //  main signature type after v1.02 for MHz wallets
  static const signatureTypeED25519 = 2; //  type used before v1.0.2
  static const signatureTypeRCD1 =
      3; //  external signature type for FCT wallets, pre v1.0.2
  static const signatureTypeBTC =
      4; //  external signature type introduced in protocol v1.0.2
  static const signatureTypeETH =
      5; //  external signature type introduced in protocol v1.0.2

  marshalJSON(int sigType) {
    switch (sigType) {
      case signatureTypeED25519:
        return "ed25519";
      case signatureTypeRCD1:
        return "rcd1";
      default:
        throw Exception("Cannot marshal JSON SignatureType: $sigType");
    }
  }
}
