
class ApiRequestMask {
  final int? val;

  ApiRequestMask(this.val);

  ApiRequestMask.fromJson(Map<String, dynamic> json)
      : val = json['val'];

  Map<String, dynamic> toJson() => {
    'val': val,
  };

}