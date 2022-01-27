
class ApiRequestMetrics {
  final String metricName;
  final String timeframe;

  ApiRequestMetrics(this.metricName, this.timeframe);

  ApiRequestMetrics.fromJson(Map<String, dynamic> json)
      : metricName  = json['metric'],
        timeframe = json['duration'];

  Map<String, dynamic> toJson() => {
    'metric': metricName,
    'duration': timeframe
  };

}