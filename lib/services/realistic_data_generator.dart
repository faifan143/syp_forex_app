import 'dart:math';

class RealisticDataGenerator {
  static final Random _random = Random();

  // Generate realistic forex candlestick data
  static List<Map<String, double>> generateCandlestickData({
    required int count,
    double basePrice = 1.1000,
    double volatility = 0.001,
    String symbol = 'EUR/USD',
    bool addTimeFields = false,
  }) {
    final List<Map<String, double>> candles = [];
    double currentPrice = basePrice;

    // Different volatility patterns for different symbols
    double actualVolatility = volatility;
    if (symbol.contains('JPY')) {
      actualVolatility =
          volatility * 0.8; // JPY pairs are typically less volatile
    } else if (symbol.contains('GBP')) {
      actualVolatility = volatility * 1.2; // GBP pairs are more volatile
    } else if (symbol.contains('AUD') || symbol.contains('NZD')) {
      actualVolatility = volatility * 1.1; // Commodity currencies
    }

    // Add some realistic market sessions (London, New York, Tokyo)
    final List<double> sessionMultipliers = [
      0.8,
      1.2,
      0.6,
      1.0,
    ]; // Different volatility per session

    // Calculate time interval based on count (for realistic time progression)
    final now = DateTime.now();
    final Duration timeInterval = Duration(
      minutes: count > 1000 ? 1 : (count > 500 ? 5 : (count > 200 ? 15 : 60)),
    );

    for (int i = 0; i < count; i++) {
      // Determine market session (simplified)
      final int sessionIndex = (i ~/ (count ~/ 4)) % 4;
      final double sessionVolatility =
          actualVolatility * sessionMultipliers[sessionIndex];

      // Generate more realistic price movement with momentum
      final double trend = _generateTrend(i, count);
      final double noise = _generateNoise(sessionVolatility);
      final double momentum = _generateMomentum(i, candles);
      final double movement = trend + noise + momentum;

      // Calculate OHLC with more realistic patterns
      final double open = currentPrice;
      final double close = open + movement;

      // Generate realistic body and wick sizes
      final double bodySize = (close - open).abs();
      final double maxWickSize = bodySize * 3.0; // Max 3x body size for wicks
      final double minWickSize = bodySize * 0.1; // Min 0.1x body size

      // Upper wick (from high to max(open, close))
      final double upperWickSize =
          minWickSize + (maxWickSize - minWickSize) * _random.nextDouble();
      final double lowerWickSize =
          minWickSize + (maxWickSize - minWickSize) * _random.nextDouble();

      final double maxPrice = [open, close].reduce((a, b) => a > b ? a : b);
      final double minPrice = [open, close].reduce((a, b) => a < b ? a : b);

      final double high = maxPrice + upperWickSize;
      final double low = minPrice - lowerWickSize;

      // Add some doji candles (open == close) occasionally
      final bool isDoji = _random.nextDouble() < 0.05; // 5% chance
      final double finalClose = isDoji ? open : close;

      // Create candle data
      final Map<String, double> candle = {
        'open': open,
        'high': high,
        'low': low,
        'close': finalClose,
      };

      // Add time field if requested
      if (addTimeFields) {
        final DateTime candleTime = now.subtract(
          Duration(milliseconds: (count - i - 1) * timeInterval.inMilliseconds),
        );
        candle['time'] = candleTime.millisecondsSinceEpoch.toDouble();
      }

      candles.add(candle);
      currentPrice = finalClose;
    }

    return candles;
  }

  // Generate trend component (longer-term price movement)
  static double _generateTrend(int index, int total) {
    // Create some realistic trend patterns
    final double progress = index / total;

    // Multiple trend cycles
    final double cycle1 = sin(progress * 2 * pi * 3) * 0.0005; // 3 cycles
    final double cycle2 = sin(progress * 2 * pi * 7) * 0.0002; // 7 cycles
    final double cycle3 = sin(progress * 2 * pi * 13) * 0.0001; // 13 cycles

    // Overall trend
    final double overallTrend = (progress - 0.5) * 0.001; // Slight upward trend

    return cycle1 + cycle2 + cycle3 + overallTrend;
  }

  // Generate noise component (random price movement)
  static double _generateNoise(double volatility) {
    // Use Box-Muller transformation for normal distribution
    final double u1 = _random.nextDouble();
    final double u2 = _random.nextDouble();
    final double z0 = sqrt(-2 * log(u1)) * cos(2 * pi * u2);

    return z0 * volatility;
  }

  // Generate momentum component (price continuation)
  static double _generateMomentum(
    int index,
    List<Map<String, double>> previousCandles,
  ) {
    if (index < 3) return 0.0;

    // Look at last 3 candles to determine momentum
    final recentCandles = previousCandles.take(3).toList();
    double totalMovement = 0.0;

    for (final candle in recentCandles) {
      totalMovement += candle['close']! - candle['open']!;
    }

    // If recent movement is strong, continue in same direction with decreasing strength
    final double momentumStrength =
        (totalMovement / 3).abs() * 0.3; // 30% of recent movement
    final double momentumDirection = totalMovement > 0 ? 1.0 : -1.0;

    return momentumStrength *
        momentumDirection *
        (1.0 - (index % 10) / 10.0); // Fade over time
  }

  // Generate different timeframes of data for the last month (30 days)
  static List<Map<String, double>> generateTimeframeData({
    required String timeframe,
    required String symbol,
    int days = 30, // Changed to 30 days (1 month)
    double? basePrice, // Optional base price from dashboard data
  }) {
    int count;
    double actualBasePrice;
    double volatility;

    // Set parameters based on timeframe and symbol - OPTIMIZED FOR CHART DISPLAY
    switch (timeframe) {
      case 'M1':
        count = 500; // 500 candles for 1-minute (about 8 hours of data)
        actualBasePrice = basePrice ?? _getBasePrice(symbol);
        volatility = 0.0001;
        break;
      case 'M5':
        count = 400; // 400 candles for 5-minute (about 33 hours of data)
        actualBasePrice = basePrice ?? _getBasePrice(symbol);
        volatility = 0.0002;
        break;
      case 'M15':
        count = 300; // 300 candles for 15-minute (about 75 hours of data)
        actualBasePrice = basePrice ?? _getBasePrice(symbol);
        volatility = 0.0003;
        break;
      case 'H1':
        count = 200; // 200 candles for 1-hour (about 8 days of data)
        actualBasePrice = basePrice ?? _getBasePrice(symbol);
        volatility = 0.0005;
        break;
      case 'H4':
        count = 150; // 150 candles for 4-hour (about 25 days of data)
        actualBasePrice = basePrice ?? _getBasePrice(symbol);
        volatility = 0.001;
        break;
      case 'D1':
        count = 30; // 30 candles for daily (1 month of data)
        actualBasePrice = basePrice ?? _getBasePrice(symbol);
        volatility = 0.002;
        break;
      default:
        count = 200; // Default to 200 candles for good display
        actualBasePrice = basePrice ?? 1.1000;
        volatility = 0.001;
    }

    return generateCandlestickData(
      count: count,
      basePrice: actualBasePrice,
      volatility: volatility,
      symbol: symbol,
      addTimeFields: true, // Add time fields for chart display
    );
  }

  // Get realistic base prices for different currency pairs
  static double _getBasePrice(String symbol) {
    switch (symbol) {
      case 'EUR/USD':
        return 1.1000;
      case 'GBP/USD':
        return 1.2500;
      case 'USD/JPY':
        return 150.00;
      case 'AUD/USD':
        return 0.6500;
      case 'USD/CAD':
        return 1.3500;
      case 'NZD/USD':
        return 0.6000;
      case 'USD/CHF':
        return 0.9000;
      case 'EUR/GBP':
        return 0.8800;
      case 'EUR/JPY':
        return 165.00;
      case 'GBP/JPY':
        return 187.50;
      default:
        return 1.1000;
    }
  }
}
