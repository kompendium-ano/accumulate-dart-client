class DataResp {
  List<int> signInfoMarshaled;
  List<int> dataPayload;
  List<int> txHash;
  List<int> nHash;

  DataResp(List<int> valuesInt, List<int> valuesIntSigInfo, List<int> valuesIntSig, List<int> msgTosign) {
    dataPayload = valuesInt;
    signInfoMarshaled = valuesIntSigInfo;
    txHash = valuesIntSig;
    nHash = msgTosign;
  }
}