import 'metadata.dart';

class CurrentRatesResponse {
  final bool success;
  final int timestamp;
  final String date;
  final String time;
  final String pair;
  final String market;
  final String city;
  final CurrentRates currentRates;
  final OHLCV ohlcv;
  final Metadata metadata;

  CurrentRatesResponse({
    required this.success,
    required this.timestamp,
    required this.date,
    required this.time,
    required this.pair,
    required this.market,
    required this.city,
    required this.currentRates,
    required this.ohlcv,
    required this.metadata,
  });

  factory CurrentRatesResponse.fromJson(Map<String, dynamic> json) {
    return CurrentRatesResponse(
      success: json['success'] as bool,
      timestamp: json['timestamp'] as int,
      date: json['date'] as String,
      time: json['time'] as String,
      pair: json['pair'] as String,
      market: json['market'] as String,
      city: json['city'] as String,
      currentRates: CurrentRates.fromJson(json['current_rates']),
      ohlcv: OHLCV.fromJson(json['ohlcv']),
      metadata: Metadata.fromJson(json['metadata']),
    );
  }
}

class ForecastResponse {
  final bool success;
  final int timestamp;
  final String forecastDate;
  final int daysAhead;
  final String pair;
  final String market;
  final String city;
  final Prediction prediction;
  final OHLCV predictedOhlcv;
  final ForecastMethod forecastMethod;
  final Map<String, dynamic> basedOn;

  ForecastResponse({
    required this.success,
    required this.timestamp,
    required this.forecastDate,
    required this.daysAhead,
    required this.pair,
    required this.market,
    required this.city,
    required this.prediction,
    required this.predictedOhlcv,
    required this.forecastMethod,
    required this.basedOn,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    return ForecastResponse(
      success: json['success'] as bool,
      timestamp: json['timestamp'] as int,
      forecastDate: json['forecast_date'] as String,
      daysAhead: json['days_ahead'] as int,
      pair: json['pair'] as String,
      market: json['market'] as String,
      city: json['city'] as String,
      prediction: Prediction.fromJson(json['prediction']),
      predictedOhlcv: OHLCV.fromJson(json['predicted_ohlcv']),
      forecastMethod: ForecastMethod.fromJson(json['forecast_method']),
      basedOn: json['based_on'] as Map<String, dynamic>,
    );
  }
}

class BatchForecastResponse {
  final bool success;
  final double currentRate;
  final List<DailyForecast> forecasts;
  final String approach;
  final String timestamp;

  BatchForecastResponse({
    required this.success,
    required this.currentRate,
    required this.forecasts,
    required this.approach,
    required this.timestamp,
  });

  factory BatchForecastResponse.fromJson(Map<String, dynamic> json) {
    return BatchForecastResponse(
      success: json['success'] as bool,
      currentRate: (json['current_rate'] as num).toDouble(),
      forecasts: (json['forecasts'] as List)
          .map((f) => DailyForecast.fromJson(f))
          .toList(),
      approach: json['approach'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}

class DailyForecast {
  final int day;
  final String date;
  final double rate;
  final double change;
  final String dayType;
  final Map<String, double> confidenceRange;

  DailyForecast({
    required this.day,
    required this.date,
    required this.rate,
    required this.change,
    required this.dayType,
    required this.confidenceRange,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      day: json['day'] as int,
      date: json['date'] as String,
      rate: (json['rate'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      dayType: json['day_type'] as String,
      confidenceRange: Map<String, double>.from(json['confidence_range']),
    );
  }
}

class ComparisonResponse {
  final bool success;
  final String timestamp;
  final List<CityRate> cities;
  final MarketStatistics statistics;
  final String approach;

  ComparisonResponse({
    required this.success,
    required this.timestamp,
    required this.cities,
    required this.statistics,
    required this.approach,
  });

  factory ComparisonResponse.fromJson(Map<String, dynamic> json) {
    return ComparisonResponse(
      success: json['success'] as bool,
      timestamp: json['timestamp'] as String,
      cities: (json['cities'] as List)
          .map((c) => CityRate.fromJson(c))
          .toList(),
      statistics: MarketStatistics.fromJson(json['statistics']),
      approach: json['approach'] as String,
    );
  }
}

class CityRate {
  final String city;
  final double rate;
  final double bid;
  final double ask;
  final double spread;
  final double change;
  final double changePercent;
  final String dayType;

  CityRate({
    required this.city,
    required this.rate,
    required this.bid,
    required this.ask,
    required this.spread,
    required this.change,
    required this.changePercent,
    required this.dayType,
  });

  factory CityRate.fromJson(Map<String, dynamic> json) {
    return CityRate(
      city: json['city'] as String,
      rate: (json['rate'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
      ask: (json['ask'] as num).toDouble(),
      spread: (json['spread'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['change_percent'] as num).toDouble(),
      dayType: json['day_type'] as String,
    );
  }
}

class MarketStatistics {
  final double averageRate;
  final double minRate;
  final double maxRate;
  final double rateSpread;
  final int citiesReporting;

  MarketStatistics({
    required this.averageRate,
    required this.minRate,
    required this.maxRate,
    required this.rateSpread,
    required this.citiesReporting,
  });

  factory MarketStatistics.fromJson(Map<String, dynamic> json) {
    return MarketStatistics(
      averageRate: (json['average_rate'] as num).toDouble(),
      minRate: (json['min_rate'] as num).toDouble(),
      maxRate: (json['max_rate'] as num).toDouble(),
      rateSpread: (json['rate_spread'] as num).toDouble(),
      citiesReporting: json['cities_reporting'] as int,
    );
  }
}

// Missing classes for the API responses
class CurrentRates {
  final double ask;
  final double bid;
  final double mid;
  final double spread;
  final double change;
  final double changePercentage;

  CurrentRates({
    required this.ask,
    required this.bid,
    required this.mid,
    required this.spread,
    required this.change,
    required this.changePercentage,
  });

  factory CurrentRates.fromJson(Map<String, dynamic> json) {
    return CurrentRates(
      ask: (json['ask'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
      mid: (json['mid'] as num).toDouble(),
      spread: (json['spread'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercentage: (json['change_percentage'] as num).toDouble(),
    );
  }
}

class Prediction {
  final double rate;
  final double ask;
  final double bid;
  final double spread;
  final ConfidenceInterval confidenceInterval;
  final double expectedChange;
  final String dayType;

  Prediction({
    required this.rate,
    required this.ask,
    required this.bid,
    required this.spread,
    required this.confidenceInterval,
    required this.expectedChange,
    required this.dayType,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      rate: (json['rate'] as num).toDouble(),
      ask: (json['ask'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
      spread: (json['spread'] as num).toDouble(),
      confidenceInterval: ConfidenceInterval.fromJson(json['confidence_interval']),
      expectedChange: (json['expected_change'] as num).toDouble(),
      dayType: json['day_type'] as String,
    );
  }
}

class ConfidenceInterval {
  final double lower;
  final double upper;
  final double rangePct;

  ConfidenceInterval({
    required this.lower,
    required this.upper,
    required this.rangePct,
  });

  factory ConfidenceInterval.fromJson(Map<String, dynamic> json) {
    return ConfidenceInterval(
      lower: (json['lower'] as num).toDouble(),
      upper: (json['upper'] as num).toDouble(),
      rangePct: (json['range_pct'] as num).toDouble(),
    );
  }
}

class OHLCV {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String dayType;

  OHLCV({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.dayType,
  });

  factory OHLCV.fromJson(Map<String, dynamic> json) {
    return OHLCV(
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      dayType: json['day_type'] as String,
    );
  }
}

class ForecastMethod {
  final String type;
  final String approach;
  final String description;
  final String confidence;
  final String spreadPrediction;

  ForecastMethod({
    required this.type,
    required this.approach,
    required this.description,
    required this.confidence,
    required this.spreadPrediction,
  });

  factory ForecastMethod.fromJson(Map<String, dynamic> json) {
    return ForecastMethod(
      type: json['type'] as String,
      approach: json['approach'] as String,
      description: json['description'] as String,
      confidence: json['confidence'] as String,
      spreadPrediction: json['spread_prediction'] as String,
    );
  }
}

class SpreadAnalysis {
  final double currentSpread;
  final double currentSpreadPct;
  final double predictedSpread;
  final double spreadChange;
  final double spreadChangePct;
  final double spreadVolatilityUsed;

  SpreadAnalysis({
    required this.currentSpread,
    required this.currentSpreadPct,
    required this.predictedSpread,
    required this.spreadChange,
    required this.spreadChangePct,
    required this.spreadVolatilityUsed,
  });

  factory SpreadAnalysis.fromJson(Map<String, dynamic> json) {
    return SpreadAnalysis(
      currentSpread: (json['current_spread'] as num).toDouble(),
      currentSpreadPct: (json['current_spread_pct'] as num).toDouble(),
      predictedSpread: (json['predicted_spread'] as num).toDouble(),
      spreadChange: (json['spread_change'] as num).toDouble(),
      spreadChangePct: (json['spread_change_pct'] as num).toDouble(),
      spreadVolatilityUsed: (json['spread_volatility_used'] as num).toDouble(),
    );
  }
}

class BasedOn {
  final double currentRate;
  final double currentAsk;
  final double currentBid;
  final double currentSpread;
  final CurrentRates sourceData;

  BasedOn({
    required this.currentRate,
    required this.currentAsk,
    required this.currentBid,
    required this.currentSpread,
    required this.sourceData,
  });

  factory BasedOn.fromJson(Map<String, dynamic> json) {
    return BasedOn(
      currentRate: (json['current_rate'] as num).toDouble(),
      currentAsk: (json['current_ask'] as num).toDouble(),
      currentBid: (json['current_bid'] as num).toDouble(),
      currentSpread: (json['current_spread'] as num).toDouble(),
      sourceData: CurrentRates.fromJson(json['source_data']),
    );
  }
}
