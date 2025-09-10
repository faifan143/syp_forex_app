class ForexRate {
  final String fromCurrency;
  final String toCurrency;
  final String symbol;
  final double rate;
  final DateTime timestamp;
  final double? change;
  final double? changePercent;

  ForexRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.symbol,
    required this.rate,
    required this.timestamp,
    this.change,
    this.changePercent,
  });

  factory ForexRate.fromJson(Map<String, dynamic> json) {
    final exchangeRate = json['Realtime Currency Exchange Rate'];
    if (exchangeRate == null) {
      throw Exception('Invalid forex rate data');
    }

    return ForexRate(
      fromCurrency: exchangeRate['1. From_Currency Code'] ?? '',
      toCurrency: exchangeRate['3. To_Currency Code'] ?? '',
      symbol: '${exchangeRate['1. From_Currency Code']}/${exchangeRate['3. To_Currency Code']}',
      rate: double.tryParse(exchangeRate['5. Exchange Rate'] ?? '0') ?? 0.0,
      timestamp: DateTime.parse(exchangeRate['6. Last Refreshed'] ?? DateTime.now().toIso8601String()),
      change: double.tryParse(exchangeRate['8. Bid Price'] ?? '0'),
      changePercent: double.tryParse(exchangeRate['9. Ask Price'] ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'symbol': symbol,
      'rate': rate,
      'timestamp': timestamp.toIso8601String(),
      'change': change,
      'changePercent': changePercent,
    };
  }
}

// Dashboard Models for 7-day predictions
class ForexDashboardResponse {
  final List<Currency> currencies;
  final String status;
  final String timestamp;
  final int totalCurrencies;

  ForexDashboardResponse({
    required this.currencies,
    required this.status,
    required this.timestamp,
    required this.totalCurrencies,
  });

  factory ForexDashboardResponse.fromJson(Map<String, dynamic> json) {
    return ForexDashboardResponse(
      currencies: (json['currencies'] as List)
          .map((currency) => Currency.fromJson(currency))
          .toList(),
      status: json['status'] ?? '',
      timestamp: json['timestamp'] ?? '',
      totalCurrencies: json['total_currencies'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencies': currencies.map((currency) => currency.toJson()).toList(),
      'status': status,
      'timestamp': timestamp,
      'total_currencies': totalCurrencies,
    };
  }
}

class Currency {
  final String currency;
  final double currentValue;
  final String dataSource;
  final List<double> forecast7Days;
  final String lastRefreshed;
  final String pair;
  final String timeZone;
  final double tomorrowChange;
  final double tomorrowChangePercent;
  final double tomorrowPrediction;
  final String tomorrowTrend;
  final double weekChange;
  final double weekChangePercent;
  final double weekPrediction;
  final String weekTrend;

  Currency({
    required this.currency,
    required this.currentValue,
    required this.dataSource,
    required this.forecast7Days,
    required this.lastRefreshed,
    required this.pair,
    required this.timeZone,
    required this.tomorrowChange,
    required this.tomorrowChangePercent,
    required this.tomorrowPrediction,
    required this.tomorrowTrend,
    required this.weekChange,
    required this.weekChangePercent,
    required this.weekPrediction,
    required this.weekTrend,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      currency: json['currency'] ?? '',
      currentValue: (json['current_value'] ?? 0.0).toDouble(),
      dataSource: json['data_source'] ?? '',
      forecast7Days: (json['forecast_7_days'] as List? ?? [])
          .map((e) => (e ?? 0.0).toDouble())
          .toList()
          .cast<double>(),
      lastRefreshed: json['last_refreshed'] ?? '',
      pair: json['pair'] ?? '',
      timeZone: json['time_zone'] ?? '',
      tomorrowChange: (json['tomorrow_change'] ?? 0.0).toDouble(),
      tomorrowChangePercent: (json['tomorrow_change_percent'] ?? 0.0).toDouble(),
      tomorrowPrediction: (json['tomorrow_prediction'] ?? 0.0).toDouble(),
      tomorrowTrend: json['tomorrow_trend'] ?? '',
      weekChange: (json['week_change'] ?? 0.0).toDouble(),
      weekChangePercent: (json['week_change_percent'] ?? 0.0).toDouble(),
      weekPrediction: (json['week_prediction'] ?? 0.0).toDouble(),
      weekTrend: json['week_trend'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'current_value': currentValue,
      'data_source': dataSource,
      'forecast_7_days': forecast7Days,
      'last_refreshed': lastRefreshed,
      'pair': pair,
      'time_zone': timeZone,
      'tomorrow_change': tomorrowChange,
      'tomorrow_change_percent': tomorrowChangePercent,
      'tomorrow_prediction': tomorrowPrediction,
      'tomorrow_trend': tomorrowTrend,
      'week_change': weekChange,
      'week_change_percent': weekChangePercent,
      'week_prediction': weekPrediction,
      'week_trend': weekTrend,
    };
  }

  // Convenience getters for easier use in UI
  bool get isTomorrowTrendUp => tomorrowTrend.toLowerCase() == 'up';
  bool get isWeekTrendUp => weekTrend.toLowerCase() == 'up';
  
  String get formattedCurrentValue => currentValue.toStringAsFixed(4);
  String get formattedTomorrowChangePercent => '${tomorrowChangePercent.toStringAsFixed(2)}%';
  String get formattedWeekChangePercent => '${weekChangePercent.toStringAsFixed(2)}%';
}

class Candlestick {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  Candlestick({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candlestick.fromJson(Map<String, dynamic> json, String dateKey, String timeKey) {
    final date = json[dateKey] ?? '';
    final time = json[timeKey] ?? '';
    final dateTime = DateTime.parse('$date $time');

    return Candlestick(
      timestamp: dateTime,
      open: double.tryParse(json['1. open'] ?? '0') ?? 0.0,
      high: double.tryParse(json['2. high'] ?? '0') ?? 0.0,
      low: double.tryParse(json['3. low'] ?? '0') ?? 0.0,
      close: double.tryParse(json['4. close'] ?? '0') ?? 0.0,
      volume: int.tryParse(json['5. volume'] ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  bool get isGreen => close > open;
  bool get isRed => close < open;
  double get bodySize => (close - open).abs();
  double get upperShadow => high - (close > open ? close : open);
  double get lowerShadow => (close > open ? open : close) - low;
}

class ForexChartData {
  final String symbol;
  final String timeframe;
  final List<Candlestick> candles;
  final DateTime lastUpdate;
  final String? metadata;

  ForexChartData({
    required this.symbol,
    required this.timeframe,
    required this.candles,
    required this.lastUpdate,
    this.metadata,
  });

  factory ForexChartData.fromIntradayJson(Map<String, dynamic> json, String symbol, String timeframe) {
    final timeSeriesKey = 'Time Series FX ($timeframe)';
    final timeSeries = json[timeSeriesKey];
    
    if (timeSeries == null) {
      throw Exception('Invalid intraday data');
    }

    final candles = <Candlestick>[];
    final entries = timeSeries.entries.toList();
    
    // Sort by timestamp (newest first for Alpha Vantage)
    entries.sort((a, b) => b.key.compareTo(a.key));
    
    // Take last 30 candles for chart (1 month of daily data)
    final recentEntries = entries.take(30).toList();
    
    for (final entry in recentEntries) {
      try {
        final candle = Candlestick.fromJson(entry.value, 'date', 'time');
        candles.add(candle);
      } catch (e) {
        // Skip invalid candles
        continue;
      }
    }

    return ForexChartData(
      symbol: symbol,
      timeframe: timeframe,
      candles: candles,
      lastUpdate: DateTime.now(),
      metadata: json['Meta Data']?['1. Information'],
    );
  }

  factory ForexChartData.fromDailyJson(Map<String, dynamic> json, String symbol) {
    final timeSeriesKey = 'Time Series FX (Daily)';
    final timeSeries = json[timeSeriesKey];
    
    if (timeSeries == null) {
      throw Exception('Invalid daily data');
    }

    final candles = <Candlestick>[];
    final entries = timeSeries.entries.toList();
    
    // Sort by timestamp (newest first for Alpha Vantage)
    entries.sort((a, b) => b.key.compareTo(a.key));
    
    // Take last 30 candles for chart (1 month of daily data)
    final recentEntries = entries.take(30).toList();
    
    for (final entry in recentEntries) {
      try {
        final candle = Candlestick.fromJson(entry.value, 'date', 'time');
        candles.add(candle);
      } catch (e) {
        // Skip invalid candles
        continue;
      }
    }

    return ForexChartData(
      symbol: symbol,
      timeframe: 'Daily',
      candles: candles,
      lastUpdate: DateTime.now(),
      metadata: json['Meta Data']?['1. Information'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'timeframe': timeframe,
      'candles': candles.map((c) => c.toJson()).toList(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Get current price (latest close)
  double get currentPrice => candles.isNotEmpty ? candles.first.close : 0.0;
  
  // Get price change
  double get priceChange {
    if (candles.length < 2) return 0.0;
    return candles.first.close - candles[1].close;
  }
  
  // Get price change percentage
  double get priceChangePercent {
    if (candles.length < 2) return 0.0;
    final previousClose = candles[1].close;
    if (previousClose == 0) return 0.0;
    return (priceChange / previousClose) * 100;
  }
  
  // Check if price is up
  bool get isPriceUp => priceChange > 0;
  
  // Check if price is down
  bool get isPriceDown => priceChange < 0;
}



