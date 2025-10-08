import 'dart:math';
import 'package:syp_forex_app/services/market_behavior_profiles.dart';

/// VolatilityService - offline, independent volatility derivation using
/// empirical ADR% baselines per pair with deterministic variation.
class VolatilityService {
  // Baseline ADR% (as fraction) for common FX pairs
  static const Map<String, double> _adrPct = {
    'EUR': 0.0060, // 0.60%
    'GBP': 0.0090, // 0.90%
    'JPY': 0.0070, // 0.70%
    'AUD': 0.0080, // 0.80%
    'NZD': 0.0090, // 0.90%
    'CAD': 0.0070, // 0.70%
    'CHF': 0.0060, // 0.60%
    'SEK': 0.0100, // 1.00%
    'TRY': 0.0280, // 2.80% - More realistic for Turkish Lira volatility
    'CNH': 0.0045, // 0.45% - Updated to reflect current CNY volatility
  };

  /// Build currency characteristics from baseline ADR%.
  /// Independent of any external data provider.
  static Future<CurrencyCharacteristics> buildCharacteristicsFromBaseline(
    String currency,
    double currentRate,
    CurrencyCharacteristics fallback,
  ) async {
    final double baseAdr = _adrPct[currency] ?? 0.0060;

    // Deterministic variation factor per rate to avoid static feel (±15%)
    final int seed = _hash('${currency}_${currentRate.toStringAsFixed(5)}');
    final Random rng = Random(seed);
    final double variation = 0.85 + (rng.nextDouble() * 0.30); // 0.85–1.15x

    final double adrAdj = (baseAdr * variation).clamp(0.0015, 0.0300);

    final double dailyVolatility = adrAdj * 0.7; // conservative drift
    final double minRange = adrAdj * 0.8; // typical small day
    final double maxRange = adrAdj * 1.6; // larger day but realistic

    return CurrencyCharacteristics(
      dailyVolatility: dailyVolatility,
      trendPersistence: fallback.trendPersistence,
      meanReversion: max(fallback.meanReversion, 0.0005),
      jumpProbability: fallback.jumpProbability,
      typicalRange: Range(min: minRange, max: maxRange),
    );
  }

  static int _hash(String s) {
    int h = 0;
    for (int i = 0; i < s.length; i++) {
      h = ((h << 5) - h + s.codeUnitAt(i)) & 0x7fffffff;
    }
    return h;
  }
}


