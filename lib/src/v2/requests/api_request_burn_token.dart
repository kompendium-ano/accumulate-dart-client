class ApiRequestBurnToken {
  final String? amount;

  ApiRequestBurnToken(this.amount);

  ApiRequestBurnToken.fromJson(Map<String, dynamic> json) : amount = json['amount'];

  Map<String, dynamic> toJson() => {
        'amount': amount,
      };
}
