import 'dart:math';

class TimeframeConverter {
  /// Convert M1 data to different timeframes
  static List<Map<String, double>> convertToTimeframe(
    List<Map<String, dynamic>> m1Data,
    String targetTimeframe,
  ) {
    if (m1Data.isEmpty) return [];

    switch (targetTimeframe) {
      case '1m':
      case 'M1':
        return _convertM1ToM1(m1Data);
      case '5m':
      case 'M5':
        return _convertM1ToM5(m1Data);
      case '15m':
      case 'M15':
        return _convertM1ToM15(m1Data);
      case '1h':
      case 'H1':
        return _convertM1ToH1(m1Data);
      case '4h':
      case 'H4':
        return _convertM1ToH4(m1Data);
      case '1d':
      case 'D1':
        return _convertM1ToD1(m1Data);
      default:
        return _convertM1ToM1(m1Data);
    }
  }

  /// Convert M1 to M1 (no conversion needed, just format)
  static List<Map<String, double>> _convertM1ToM1(List<Map<String, dynamic>> m1Data) {
    return m1Data.map((record) => {
      'open': (record['open'] as num).toDouble(),
      'high': (record['high'] as num).toDouble(),
      'low': (record['low'] as num).toDouble(),
      'close': (record['close'] as num).toDouble(),
      'volume': (record['volume'] as num).toDouble(),
    }).toList();
  }

  /// Convert M1 to M5 (aggregate 5 M1 candles)
  static List<Map<String, double>> _convertM1ToM5(List<Map<String, dynamic>> m1Data) {
    final List<Map<String, double>> m5Candles = [];
    
    for (int i = 0; i < m1Data.length; i += 5) {
      if (i + 5 <= m1Data.length) {
        final group = m1Data.sublist(i, i + 5);
        m5Candles.add(_aggregateCandles(group));
      }
    }
    
    return m5Candles;
  }

  /// Convert M1 to M15 (aggregate 15 M1 candles)
  static List<Map<String, double>> _convertM1ToM15(List<Map<String, dynamic>> m1Data) {
    final List<Map<String, double>> m15Candles = [];
    
    for (int i = 0; i < m1Data.length; i += 15) {
      if (i + 15 <= m1Data.length) {
        final group = m1Data.sublist(i, i + 15);
        m15Candles.add(_aggregateCandles(group));
      }
    }
    
    return m15Candles;
  }

  /// Convert M1 to H1 (aggregate 60 M1 candles)
  static List<Map<String, double>> _convertM1ToH1(List<Map<String, dynamic>> m1Data) {
    final List<Map<String, double>> h1Candles = [];
    
    for (int i = 0; i < m1Data.length; i += 60) {
      if (i + 60 <= m1Data.length) {
        final group = m1Data.sublist(i, i + 60);
        h1Candles.add(_aggregateCandles(group));
      }
    }
    
    return h1Candles;
  }

  /// Convert M1 to H4 (aggregate 240 M1 candles)
  static List<Map<String, double>> _convertM1ToH4(List<Map<String, dynamic>> m1Data) {
    final List<Map<String, double>> h4Candles = [];
    
    for (int i = 0; i < m1Data.length; i += 240) {
      if (i + 240 <= m1Data.length) {
        final group = m1Data.sublist(i, i + 240);
        h4Candles.add(_aggregateCandles(group));
      }
    }
    
    return h4Candles;
  }

  /// Convert M1 to D1 (aggregate all M1 candles from same day)
  static List<Map<String, double>> _convertM1ToD1(List<Map<String, dynamic>> m1Data) {
    final List<Map<String, double>> d1Candles = [];
    final Map<String, List<Map<String, dynamic>>> dailyGroups = {};
    
    // Group M1 data by date
    for (final record in m1Data) {
      final datetime = DateTime.parse(record['Datetime'] as String);
      final dateKey = '${datetime.year}-${datetime.month.toString().padLeft(2, '0')}-${datetime.day.toString().padLeft(2, '0')}';
      
      if (!dailyGroups.containsKey(dateKey)) {
        dailyGroups[dateKey] = [];
      }
      dailyGroups[dateKey]!.add(record);
    }
    
    // Convert each day's data to D1 candle
    final sortedDates = dailyGroups.keys.toList()..sort();
    for (final date in sortedDates) {
      final dayData = dailyGroups[date]!;
      if (dayData.isNotEmpty) {
        d1Candles.add(_aggregateCandles(dayData));
      }
    }
    
    return d1Candles;
  }

  /// Aggregate a group of M1 candles into a single candle
  static Map<String, double> _aggregateCandles(List<Map<String, dynamic>> candles) {
    if (candles.isEmpty) {
      return {
        'open': 0.0,
        'high': 0.0,
        'low': 0.0,
        'close': 0.0,
        'volume': 0.0,
      };
    }

    final open = (candles.first['open'] as num).toDouble();
    final close = (candles.last['close'] as num).toDouble();
    
    double high = double.negativeInfinity;
    double low = double.infinity;
    double volume = 0.0;
    
    for (final candle in candles) {
      final candleHigh = (candle['high'] as num).toDouble();
      final candleLow = (candle['low'] as num).toDouble();
      final candleVolume = (candle['volume'] as num).toDouble();
      
      high = max(high, candleHigh);
      low = min(low, candleLow);
      volume += candleVolume;
    }
    
    return {
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  /// Get the number of M1 candles needed for a specific timeframe
  static int getM1CandlesPerTimeframe(String timeframe) {
    switch (timeframe) {
      case '1m':
      case 'M1':
        return 1;
      case '5m':
      case 'M5':
        return 5;
      case '15m':
      case 'M15':
        return 15;
      case '1h':
      case 'H1':
        return 60;
      case '4h':
      case 'H4':
        return 240;
      case '1d':
      case 'D1':
        return 1440; // 24 hours * 60 minutes
      default:
        return 1;
    }
  }

  /// Check if a timeframe is valid
  static bool isValidTimeframe(String timeframe) {
    const validTimeframes = ['1m', 'M1', '5m', 'M5', '15m', 'M15', '1h', 'H1', '4h', 'H4', '1d', 'D1'];
    return validTimeframes.contains(timeframe);
  }

  /// Convert timeframe string to standard format
  static String normalizeTimeframe(String timeframe) {
    switch (timeframe) {
      case '1m':
        return 'M1';
      case '5m':
        return 'M5';
      case '15m':
        return 'M15';
      case '1h':
        return 'H1';
      case '4h':
        return 'H4';
      case '1d':
        return 'D1';
      default:
        return timeframe;
    }
  }
}
