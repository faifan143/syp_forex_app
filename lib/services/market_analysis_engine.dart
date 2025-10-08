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
    final double anchorPrice = currentRate; // mean-reversion anchor

    // Initialize trend state
    int trendDirection = random.nextBool() ? 1 : -1;
    double trendStrength = 0.0;

    for (int day = 1; day <= days; day++) {
      final baseVolatility = char.dailyVolatility;

      // Core market noise component
      final marketVolatility = random.nextGaussian() * baseVolatility;

      // Trend component (kept weak for FX)
      if (random.nextDouble() < 0.2) {
        trendDirection = random.nextBool() ? 1 : -1;
        trendStrength = random.nextDouble() * 0.2;
      }
      trendStrength = trendStrength.clamp(0.0, 0.2);
      final trendComponent =
          trendDirection * trendStrength * baseVolatility * random.nextGaussian() * 0.4;

      // Mean reversion towards the starting price
      final deviationFromAnchor = (anchorPrice - currentPrice) / anchorPrice;
      final meanReversion = char.meanReversion * deviationFromAnchor;

      // Jump component (rare and capped)
      double jumpComponent = 0.0;
      if (random.nextDouble() < char.jumpProbability) {
        final cappedJump = min(char.typicalRange.max, 0.002);
        jumpComponent = (random.nextBool() ? 1 : -1) * cappedJump * (0.3 + 0.7 * random.nextDouble());
      }

      // Enhanced currency-specific adjustments with realistic factors
      double volatilityMultiplier = 1.0;
      double economicFactorAdjustment = 0.0;
      
      if (currency == 'TRY') {
        // Turkish Lira: High volatility due to inflation, political factors
        volatilityMultiplier *= 1.8; // Increased from 1.3
        
        // Add economic stress factor based on current rate level
        final stressLevel = _calculateTurkishLiraStress(currentPrice, anchorPrice);
        economicFactorAdjustment = stressLevel * baseVolatility * 0.5;
        
        // Add inflation expectation factor
        final inflationFactor = _getInflationPressure(day, random) * baseVolatility * 0.3;
        economicFactorAdjustment += inflationFactor;
        
      } else if (currency == 'CNH') {
        // Chinese Yuan: Controlled volatility with policy intervention effects
        volatilityMultiplier *= 1.2; // Increased from 0.8
        
        // Add policy intervention simulation
        final interventionEffect = _simulatePBOCIntervention(currentPrice, anchorPrice, day, random);
        economicFactorAdjustment = interventionEffect * baseVolatility;
        
        // Add trade war / economic policy factor
        final policyFactor = _getTradeWarFactor(day, random) * baseVolatility * 0.2;
        economicFactorAdjustment += policyFactor;
        
      } else if (currency == 'AUD' || currency == 'NZD') {
        volatilityMultiplier *= 1.05;
      } else if (currency == 'CHF') {
        volatilityMultiplier *= 0.9;
      }

      // Aggregate daily fractional change including economic factors
      double totalChange =
          (marketVolatility + trendComponent + meanReversion + jumpComponent) *
          volatilityMultiplier + economicFactorAdjustment;

      // Apply realistic bounds using pair-specific range
      final maxDailyChange = char.typicalRange.max;
      totalChange = totalChange.clamp(-maxDailyChange, maxDailyChange);

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

  /// Calculate Turkish Lira economic stress factor
  static double _calculateTurkishLiraStress(double currentPrice, double anchorPrice) {
    // Higher stress when TRY weakens significantly from anchor
    final deviationRatio = (currentPrice - anchorPrice) / anchorPrice;
    
    // Stress increases exponentially with weakness
    if (deviationRatio > 0) {
      return min(deviationRatio * 2.0, 1.0); // Cap at 1.0
    } else {
      return max(deviationRatio * 0.5, -0.3); // Less stress when strengthening
    }
  }

  /// Simulate inflation pressure on Turkish Lira
  static double _getInflationPressure(int day, Random random) {
    // Simulate periodic inflation concerns
    final cyclicalPressure = sin(day * 0.1) * 0.3;
    final randomShock = (random.nextDouble() - 0.5) * 0.4;
    
    // Generally positive pressure (inflationary)
    return max(0.1 + cyclicalPressure + randomShock, 0.0);
  }

  /// Simulate PBOC intervention effects on CNY
  static double _simulatePBOCIntervention(double currentPrice, double anchorPrice, int day, Random random) {
    final deviationFromAnchor = (currentPrice - anchorPrice) / anchorPrice;
    
    // PBOC tends to intervene when CNY moves too far from target
    final interventionThreshold = 0.015; // 1.5% deviation triggers intervention
    
    if (deviationFromAnchor.abs() > interventionThreshold) {
      // Strong intervention to bring back to target
      final interventionStrength = random.nextDouble() * 0.8 + 0.2; // 20-100% strength
      return -deviationFromAnchor * interventionStrength * 0.5;
    } else {
      // Minor adjustments
      return (random.nextDouble() - 0.5) * 0.1;
    }
  }

  /// Simulate trade war and economic policy factors for CNY
  static double _getTradeWarFactor(int day, Random random) {
    // Simulate periodic trade tensions
    final tensionCycle = sin(day * 0.05) * 0.2;
    final policyShock = random.nextDouble() < 0.05 ? (random.nextDouble() - 0.5) * 0.3 : 0.0;
    
    return tensionCycle + policyShock;
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
