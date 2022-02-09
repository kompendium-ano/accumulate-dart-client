
class ApiRequestTx {
  final String txid;
  //final String from;

  ApiRequestTx(this.txid);

  ApiRequestTx.fromJson(Map<String, dynamic> json)
      : txid = json['txid'];
        //from = json['from'];

  Map<String, dynamic> toJson() => {
    'txid': txid,
    //'from': from,
  };

}