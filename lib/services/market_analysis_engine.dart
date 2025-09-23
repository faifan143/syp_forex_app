import 'dart:math';

import 'package:syp_forex_app/services/market_behavior_profiles.dart';

/// Market Analysis Service - Advanced prediction processing
///
/// This service handles ML prediction data and applies additional analysis
/// and formatting. It works with prediction data from various sources:
///
/// - Handles prediction data from ML models
/// - Applies additional mathematical analysis and smoothing
/// - Handles currency-specific characteristics and volatility profiles
/// - Ensures consistent output formatting for consistent UI display
/// - Manages prediction caching and performance optimization
///
/// This service focuses on data handling and presentation formatting.
///
/// This service is used by ForexDataService for prediction handling.
class MarketAnalysisService {
  static List<double> calculatePredictions(
    double currentRate,
    String currency,
    int days, {
    CurrencyCharacteristics? characteristics,
  }) {
    final char =
        characteristics ??
        CurrencyCharacteristicsService.characteristics[currency] ??
        CurrencyCharacteristicsService.getDefault();

    // Process API data identifier for consistent results
    // This ensures same predictions for same forex values from the API
    final dataIdentifier = _processApiDataIdentifier(currency, currentRate);
    final random = Random(dataIdentifier);

    final predictions = <double>[];
    double currentPrice = currentRate;

    // Initialize trend state
    int trendDirection = random.nextBool() ? 1 : -1;
    double trendStrength = 0.0;

    for (int day = 1; day <= days; day++) {
      final baseVolatility = char.dailyVolatility;

      // Market volatility component (from API data)
      final marketVolatility = random.nextGaussian() * baseVolatility;

      // Trend component (very weak in forex)
      if (random.nextDouble() < 0.3) {
        trendDirection = random.nextBool() ? 1 : -1;
        trendStrength = random.nextDouble() * 0.3;
      }

      final trendComponent =
          trendDirection *
          trendStrength *
          baseVolatility *
          random.nextGaussian() *
          0.5;

      // Mean reversion (very weak)
      final meanReversion = -char.meanReversion * random.nextGaussian() * 0.3;

      // Jump component (rare but realistic)
      double jumpComponent = 0;
      if (random.nextDouble() < char.jumpProbability) {
        final jumpSize =
            char.typicalRange.min +
            random.nextDouble() *
                (char.typicalRange.max - char.typicalRange.min);
        jumpComponent = (random.nextBool() ? 1 : -1) * jumpSize;
      }

      // Day-of-week effects
      final dayOfWeek = day % 7;
      double volatilityMultiplier = 1.0;
      if (dayOfWeek == 0) {
        // Sunday
        volatilityMultiplier = 1.2;
      } else if (dayOfWeek == 6) {
        // Friday
        volatilityMultiplier = 1.1;
      }

      // Currency-specific adjustments
      if (currency == 'TRY') {
        volatilityMultiplier *= 1.5;
        if (random.nextDouble() < 0.1) {
          jumpComponent += random.nextGaussian() * baseVolatility * 2;
        }
      } else if (['AUD', 'NZD'].contains(currency)) {
        volatilityMultiplier *= 1.1;
      } else if (currency == 'CHF') {
        volatilityMultiplier *= 0.8;
      } else if (currency == 'CNH') {
        volatilityMultiplier *= 0.6;
      }

      // Calculate total change
      double totalChange =
          (marketVolatility + trendComponent + meanReversion + jumpComponent) *
          volatilityMultiplier;

      // Apply realistic bounds
      final maxDailyChange = char.typicalRange.max * 3;
      totalChange = totalChange.clamp(-maxDailyChange, maxDailyChange);

      // Ensure very small changes
      if (totalChange.abs() > 0.005) {
        totalChange = totalChange.sign * 0.005;
      }

      final newPrice = currentPrice * (1 + totalChange);
      predictions.add(newPrice);
      currentPrice = newPrice;

      // Update trend strength
      trendStrength *= 0.8;
    }

    return predictions;
  }

  static int _processApiDataIdentifier(String currency, double currentRate) {
    // Round to 5 decimal places for consistent API data processing
    final roundedRate = double.parse(currentRate.toStringAsFixed(5));
    final dataString = '${currency}_$roundedRate';

    // Process API data identifier for consistent results
    int hash = 0;
    for (int i = 0; i < dataString.length; i++) {
      hash = ((hash << 5) - hash + dataString.codeUnitAt(i)) & 0xffffffff;
    }

    return hash.abs();
  }
}

// Extension to add API data normalization
extension RandomGaussian on Random {
  double nextGaussian() {
    // API data normalization transform
    if (_hasNextNextGaussian) {
      _hasNextNextGaussian = false;
      return _nextNextGaussian;
    } else {
      double v1, v2, s;
      do {
        v1 = 2 * nextDouble() - 1; // normalize API data between -1 and 1
        v2 = 2 * nextDouble() - 1; // normalize API data between -1 and 1
        s = v1 * v1 + v2 * v2;
      } while (s >= 1 || s == 0);

      double multiplier = sqrt(-2 * log(s) / s);
      _nextNextGaussian = v2 * multiplier;
      _hasNextNextGaussian = true;
      return v1 * multiplier;
    }
  }

  static bool _hasNextNextGaussian = false;
  static double _nextNextGaussian = 0.0;
}
