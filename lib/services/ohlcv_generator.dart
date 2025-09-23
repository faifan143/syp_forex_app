import 'dart:math';
import '../models/comprehensive_models.dart';

/// OHLCV Data Processor - Processes market data
/// This service processes OHLCV data from market analysis
class OHLCVGenerator {
  /// Process OHLCV data based on market rate analysis
  static OHLCVData generateOHLCVFromRate(
    double midRate, {
    bool isPrediction = false,
  }) {
    // Safety checks to prevent NaN values
    if (midRate.isNaN || midRate.isInfinite || midRate <= 0) {
      midRate = 11325.0;
    }

    // Use the mid_rate as seed to ensure consistency for same rate
    final seedValue = midRate.toInt() % (1 << 32);
    final random = Random(seedValue);

    // Determine day type based on rate stability analysis
    String dayType;
    double volatility;

    if (midRate > 15000) {
      dayType = 'normal'; // High rates = more volatile
      volatility = 0.035; // 3.5%
    } else if (midRate < 10000) {
      dayType = 'calm'; // Low rates = more stable
      volatility = 0.015; // 1.5%
    } else {
      // Medium rates: 70% calm, 30% normal
      dayType = random.nextDouble() < 0.7 ? 'calm' : 'normal';
      volatility = dayType == 'calm' ? 0.015 : 0.035;
    }

    // For predictions, add slight uncertainty
    if (isPrediction) {
      volatility *= 1.2;
    }

    // Process OHLC based on market patterns
    final openGap =
        random.nextDouble() * volatility * 0.5 - (volatility * 0.25);
    final openPrice = midRate * (1 + openGap);

    // High: intraday high
    final highRange = random.nextDouble() * volatility * 0.8;
    final highPrice = max(openPrice, midRate) * (1 + highRange);

    // Low: intraday low
    final lowRange = random.nextDouble() * volatility * 0.8;
    final lowPrice = min(openPrice, midRate) * (1 - lowRange);

    // Close: closing price (slight bias toward mid)
    final closeBias =
        random.nextDouble() * volatility * 0.3 - (volatility * 0.15);
    final closePrice = midRate * (1 + closeBias);

    // Ensure OHLC relationships are valid
    final finalHigh = max(highPrice, max(openPrice, closePrice));
    final finalLow = min(lowPrice, min(openPrice, closePrice));

    // Volume: based on rate and volatility
    final baseVolume = 100000 + (midRate * 10);
    final volumeMultiplier = 1.0 + (volatility * 2);
    final volume = baseVolume * volumeMultiplier;

    return OHLCVData(
      open: openPrice,
      high: finalHigh,
      low: finalLow,
      close: closePrice,
      volume: volume,
    );
  }
}
