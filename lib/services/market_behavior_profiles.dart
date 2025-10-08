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
    // Majors typically 0.3%–1.0% daily moves; GBP can exceed 1%
    'EUR': CurrencyCharacteristics(
      dailyVolatility: 0.0035, // ~0.35% baseline
      trendPersistence: 0.05,
      meanReversion: 0.0008,
      jumpProbability: 0.02,
      typicalRange: Range(min: 0.0030, max: 0.0090), // 0.3%–0.9%
    ),
    'GBP': CurrencyCharacteristics(
      dailyVolatility: 0.0050,
      trendPersistence: 0.08,
      meanReversion: 0.0010,
      jumpProbability: 0.03,
      typicalRange: Range(min: 0.0040, max: 0.0120), // 0.4%–1.2%
    ),
    'JPY': CurrencyCharacteristics(
      dailyVolatility: 0.0030,
      trendPersistence: 0.06,
      meanReversion: 0.0007,
      jumpProbability: 0.025,
      typicalRange: Range(min: 0.0030, max: 0.0080),
    ),
    'CAD': CurrencyCharacteristics(
      dailyVolatility: 0.0030,
      trendPersistence: 0.04,
      meanReversion: 0.0007,
      jumpProbability: 0.015,
      typicalRange: Range(min: 0.0025, max: 0.0080),
    ),
    'AUD': CurrencyCharacteristics(
      dailyVolatility: 0.0040,
      trendPersistence: 0.12,
      meanReversion: 0.0009,
      jumpProbability: 0.04,
      typicalRange: Range(min: 0.0030, max: 0.0100),
    ),
    'NZD': CurrencyCharacteristics(
      dailyVolatility: 0.0045,
      trendPersistence: 0.15,
      meanReversion: 0.0010,
      jumpProbability: 0.05,
      typicalRange: Range(min: 0.0035, max: 0.0110),
    ),
    'CHF': CurrencyCharacteristics(
      dailyVolatility: 0.0025,
      trendPersistence: 0.03,
      meanReversion: 0.0006,
      jumpProbability: 0.01,
      typicalRange: Range(min: 0.0020, max: 0.0070),
    ),
    'SEK': CurrencyCharacteristics(
      dailyVolatility: 0.0040,
      trendPersistence: 0.07,
      meanReversion: 0.0009,
      jumpProbability: 0.025,
      typicalRange: Range(min: 0.0030, max: 0.0100),
    ),
    'TRY': CurrencyCharacteristics(
      dailyVolatility: 0.0180, // Increased volatility for Turkish Lira
      trendPersistence: 0.35, // Higher trend persistence due to economic factors
      meanReversion: 0.0025, // Lower mean reversion due to structural issues
      jumpProbability: 0.12, // Higher jump probability due to political/economic events
      typicalRange: Range(min: 0.0120, max: 0.0450), // 1.2%–4.5% realistic range
    ),
    'CNH': CurrencyCharacteristics(
      dailyVolatility: 0.0035, // Increased from 0.002 to reflect recent volatility
      trendPersistence: 0.08, // Higher due to policy-driven moves
      meanReversion: 0.0012, // Stronger mean reversion due to PBOC intervention
      jumpProbability: 0.015, // Higher due to policy announcements
      typicalRange: Range(min: 0.0025, max: 0.0120), // 0.25%–1.2% more realistic
    ),
  };

  static CurrencyCharacteristics getDefault() {
    return const CurrencyCharacteristics(
      dailyVolatility: 0.0035,
      trendPersistence: 0.05,
      meanReversion: 0.0008,
      jumpProbability: 0.02,
      typicalRange: Range(min: 0.0030, max: 0.0090),
    );
  }
}
