class SignatureType {
  static const signatureTypeED25519 = 2;
  static const  signatureTypeRCD1 = 3;


  marshalJSON(int sigType) {
    switch (sigType) {
      case signatureTypeED25519 :
        return "ed25519";
      case signatureTypeRCD1 :
        return "rcd1";
      default :
        throw Exception ("Cannot marshal JSON SignatureType: $sigType");
    }
  }
}