
class ApiRequestCredits {
  final String? url;
  final int? amount;

  ApiRequestCredits(this.url, this.amount);

  ApiRequestCredits.fromJson(Map<String, dynamic> json)
      : url  = json['recipient'],
        amount = json['amount'];

  Map<String, dynamic> toJson() => {
    'recipient': url,
    'amount': amount,
  };

}