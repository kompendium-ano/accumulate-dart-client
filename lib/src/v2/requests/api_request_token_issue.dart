class ApiRequestTokenIssue {
  final String url;
  final int amount;

  ApiRequestTokenIssue(this.url, this.amount);

  ApiRequestTokenIssue.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        amount = json['amount'];

  Map<String, dynamic> toJson() => {'url': url,  'amount': amount};
}
