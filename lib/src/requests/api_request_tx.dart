
class ApiRequestTx {
  final String hash;
  final String from;

  ApiRequestTx(this.hash, this.from);

  ApiRequestTx.fromJson(Map<String, dynamic> json)
      : hash = json['hash'],
        from = json['from'];

  Map<String, dynamic> toJson() => {
    'hash': hash,
    'from': from,
  };

}