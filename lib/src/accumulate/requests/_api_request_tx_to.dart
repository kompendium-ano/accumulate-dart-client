// Notes: sig is the ed25519 signature of txhash
class ApiRequestTxTo {
  final ApiRequestTxToData data;
  final ApiRequestTxToSigner signer;
  final int timestamp;

  ApiRequestTxTo(this.data, this.signer, this.timestamp);

  ApiRequestTxTo.fromJson(Map<String, dynamic> json)
      : data = json['data'],
        signer = json['signer'],
        timestamp = json['timestamp'];

  Map<String, dynamic> toJson() => {
        'data': data,
        'signer': signer,
        'timestamp': timestamp,
      };
}

class ApiRequestTxToData {
  final String from;
  final List<ApiRequestTxToDataTo> to;
  final String meta;

  ApiRequestTxToData(this.from, this.to, this.meta);

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'meta': meta,
      };
}

class ApiRequestTxToDataTo {
  final String url;
  final String amount;

  ApiRequestTxToDataTo(this.url, this.amount);

  Map<String, dynamic> toJson() => {
    'url': url,
    'amount': amount,
  };
}

class ApiRequestTxToSigner {
  final String url;
  final String publicKey;

  ApiRequestTxToSigner(this.url, this.publicKey);

  Map<String, dynamic> toJson() => {
        'from': url,
        'to': publicKey,
      };
}
