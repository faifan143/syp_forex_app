class CurrencyCharacteristics {
  final double dailyVolatility;
  final double trendPersistence;
  final double meanReversion;
  final double jumpProbability;
  final Range typicalRange;

  const CurrencyCharacteristics({
    required this.dailyVolatility,
    required this.trendPersistence,
    required this.meanReversion,
    required this.jumpProbability,
    required this.typicalRange,
  });

  factory CurrencyCharacteristics.fromJson(Map<String, dynamic> json) {
    return CurrencyCharacteristics(
      dailyVolatility: (json['daily_volatility'] as num).toDouble(),
      trendPersistence: (json['trend_persistence'] as num).toDouble(),
      meanReversion: (json['mean_reversion'] as num).toDouble(),
      jumpProbability: (json['jump_probability'] as num).toDouble(),
      typicalRange: Range.fromJson(json['typical_range']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_volatility': dailyVolatility,
      'trend_persistence': trendPersistence,
      'mean_reversion': meanReversion,
      'jump_probability': jumpProbability,
      'typical_range': typicalRange.toJson(),
    };
  }
}

class Range {
  final double min;
  final double max;

  const Range({required this.min, required this.max});

  factory Range.fromJson(List<dynamic> json) {
    return Range(
      min: (json[0] as num).toDouble(),
      max: (json[1] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max};
  }
}

class CurrencyCharacteristicsService {
  static const Map<String, CurrencyCharacteristics> characteristics = {
    'EUR': CurrencyCharacteristics(
      dailyVolatility: 0.0006,
      trendPersistence: 0.05,
      meanReversion: 0.0001,
      jumpProbability: 0.02,
      typicalRange: Range(min: 0.0002, max: 0.0015),
    ),
    'GBP': CurrencyCharacteristics(
      dailyVolatility: 0.0008,
      trendPersistence: 0.08,
      meanReversion: 0.0002,
      jumpProbability: 0.03,
      typicalRange: Range(min: 0.0003, max: 0.0020),
    ),
    'JPY': CurrencyCharacteristics(
      dailyVolatility: 0.0007,
      trendPersistence: 0.06,
      meanReversion: 0.0001,
      jumpProbability: 0.025,
      typicalRange: Range(min: 0.0002, max: 0.0018),
    ),
    'CAD': CurrencyCharacteristics(
      dailyVolatility: 0.0005,
      trendPersistence: 0.04,
      meanReversion: 0.0001,
      jumpProbability: 0.015,
      typicalRange: Range(min: 0.0001, max: 0.0012),
    ),
    'AUD': CurrencyCharacteristics(
      dailyVolatility: 0.0009,
      trendPersistence: 0.12,
      meanReversion: 0.0003,
      jumpProbability: 0.04,
      typicalRange: Range(min: 0.0003, max: 0.0022),
    ),
    'NZD': CurrencyCharacteristics(
      dailyVolatility: 0.0010,
      trendPersistence: 0.15,
      meanReversion: 0.0004,
      jumpProbability: 0.05,
      typicalRange: Range(min: 0.0004, max: 0.0025),
    ),
    'CHF': CurrencyCharacteristics(
      dailyVolatility: 0.0004,
      trendPersistence: 0.03,
      meanReversion: 0.00005,
      jumpProbability: 0.01,
      typicalRange: Range(min: 0.0001, max: 0.0010),
    ),
    'SEK': CurrencyCharacteristics(
      dailyVolatility: 0.0008,
      trendPersistence: 0.07,
      meanReversion: 0.0002,
      jumpProbability: 0.025,
      typicalRange: Range(min: 0.0002, max: 0.0018),
    ),
    'TRY': CurrencyCharacteristics(
      dailyVolatility: 0.0020,
      trendPersistence: 0.20,
      meanReversion: 0.0008,
      jumpProbability: 0.08,
      typicalRange: Range(min: 0.0005, max: 0.0050),
    ),
    'CNH': CurrencyCharacteristics(
      dailyVolatility: 0.0003,
      trendPersistence: 0.02,
      meanReversion: 0.00005,
      jumpProbability: 0.005,
      typicalRange: Range(min: 0.0001, max: 0.0008),
    ),
  };

  static CurrencyCharacteristics getDefault() {
    return const CurrencyCharacteristics(
      dailyVolatility: 0.0006,
      trendPersistence: 0.05,
      meanReversion: 0.0001,
      jumpProbability: 0.02,
      typicalRange: Range(min: 0.0002, max: 0.0015),
    );
  }
}
