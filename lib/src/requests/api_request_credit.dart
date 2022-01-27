
class ApiRequestCredits {
  final String url;
  final int amount;
  final bool wait;

  ApiRequestCredits(this.url, this.amount, this.wait);

  ApiRequestCredits.fromJson(Map<String, dynamic> json)
      : url  = json['recipient'],
        amount = json['amount'],
        wait = json['wait'];

  Map<String, dynamic> toJson() => {
    'recipient': url,
    'amount': amount,
    'wait': wait
  };

}