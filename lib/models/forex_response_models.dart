class CurrencyData {
  final String currency;
  final String pair;
  final double currentValue;
  final double tomorrowPrediction;
  final double weekPrediction;
  final double tomorrowChange;
  final double tomorrowChangePercent;
  final double weekChange;
  final double weekChangePercent;
  final String tomorrowTrend;
  final String weekTrend;
  final List<double> forecast7Days;
  final String lastRefreshed;
  final String timeZone;
  final String dataSource;

  const CurrencyData({
    required this.currency,
    required this.pair,
    required this.currentValue,
    required this.tomorrowPrediction,
    required this.weekPrediction,
    required this.tomorrowChange,
    required this.tomorrowChangePercent,
    required this.weekChange,
    required this.weekChangePercent,
    required this.tomorrowTrend,
    required this.weekTrend,
    required this.forecast7Days,
    required this.lastRefreshed,
    required this.timeZone,
    required this.dataSource,
  });

  factory CurrencyData.fromJson(Map<String, dynamic> json) {
    return CurrencyData(
      currency: json['currency'] as String,
      pair: json['pair'] as String,
      currentValue: (json['current_value'] as num).toDouble(),
      tomorrowPrediction: (json['tomorrow_prediction'] as num).toDouble(),
      weekPrediction: (json['week_prediction'] as num).toDouble(),
      tomorrowChange: (json['tomorrow_change'] as num).toDouble(),
      tomorrowChangePercent: (json['tomorrow_change_percent'] as num)
          .toDouble(),
      weekChange: (json['week_change'] as num).toDouble(),
      weekChangePercent: (json['week_change_percent'] as num).toDouble(),
      tomorrowTrend: json['tomorrow_trend'] as String,
      weekTrend: json['week_trend'] as String,
      forecast7Days: (json['forecast_7_days'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      lastRefreshed: json['last_refreshed'] as String,
      timeZone: json['time_zone'] as String,
      dataSource: json['data_source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'pair': pair,
      'current_value': currentValue,
      'tomorrow_prediction': tomorrowPrediction,
      'week_prediction': weekPrediction,
      'tomorrow_change': tomorrowChange,
      'tomorrow_change_percent': tomorrowChangePercent,
      'week_change': weekChange,
      'week_change_percent': weekChangePercent,
      'tomorrow_trend': tomorrowTrend,
      'week_trend': weekTrend,
      'forecast_7_days': forecast7Days,
      'last_refreshed': lastRefreshed,
      'time_zone': timeZone,
      'data_source': dataSource,
    };
  }
}

class ForexApiResponse {
  final String status;
  final String timestamp;
  final List<CurrencyData> currencies;
  final int totalCurrencies;
  final String predictionMethod;
  final String forecastPeriod;
  final String dataSource;
  final int apiRequestsToday;
  final int rateLimitRemaining;
  final Map<String, dynamic> features;

  const ForexApiResponse({
    required this.status,
    required this.timestamp,
    required this.currencies,
    required this.totalCurrencies,
    required this.predictionMethod,
    required this.forecastPeriod,
    required this.dataSource,
    required this.apiRequestsToday,
    required this.rateLimitRemaining,
    required this.features,
  });

  factory ForexApiResponse.fromJson(Map<String, dynamic> json) {
    return ForexApiResponse(
      status: json['status'] as String,
      timestamp: json['timestamp'] as String,
      currencies: (json['currencies'] as List<dynamic>)
          .map((e) => CurrencyData.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCurrencies: json['total_currencies'] as int,
      predictionMethod: json['prediction_method'] as String,
      forecastPeriod: json['forecast_period'] as String,
      dataSource: json['data_source'] as String,
      apiRequestsToday: json['api_requests_today'] as int,
      rateLimitRemaining: json['rate_limit_remaining'] as int,
      features: json['features'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp,
      'currencies': currencies.map((e) => e.toJson()).toList(),
      'total_currencies': totalCurrencies,
      'prediction_method': predictionMethod,
      'forecast_period': forecastPeriod,
      'data_source': dataSource,
      'api_requests_today': apiRequestsToday,
      'rate_limit_remaining': rateLimitRemaining,
      'features': features,
    };
  }
}
