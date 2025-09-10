class ComprehensiveResponse {
  final Map<String, CityRate> cityRates;
  final List<Currency> currencies;
  final DamascusPrediction damascusPrediction;
  final OHLCV ohlcv;

  ComprehensiveResponse({
    required this.cityRates,
    required this.currencies,
    required this.damascusPrediction,
    required this.ohlcv,
  });

  factory ComprehensiveResponse.fromJson(Map<String, dynamic> json) {
    Map<String, CityRate> parsedCityRates = {};
    if (json['city_rates'] != null) {
      (json['city_rates'] as Map<String, dynamic>).forEach((key, value) {
        parsedCityRates[key] = CityRate.fromJson(value);
      });
    }

    return ComprehensiveResponse(
      cityRates: parsedCityRates,
      currencies: (json['currencies'] as List? ?? [])
          .map((currency) => Currency.fromJson(currency))
          .toList(),
      damascusPrediction: json['damascus_prediction'] != null
          ? DamascusPrediction.fromJson(json['damascus_prediction'])
          : DamascusPrediction(ask: 0, bid: 0),
      ohlcv: json['ohlcv'] != null
          ? OHLCV.fromJson(json['ohlcv'])
          : OHLCV(close: 0, high: 0, low: 0, open: 0, volume: 0),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> cityRatesJson = {};
    cityRates.forEach((key, value) {
      cityRatesJson[key] = value.toJson();
    });

    return {
      'city_rates': cityRatesJson,
      'currencies': currencies.map((currency) => currency.toJson()).toList(),
      'damascus_prediction': damascusPrediction.toJson(),
      'ohlcv': ohlcv.toJson(),
    };
  }

  // Convenience getters
  List<String> get availableCities => cityRates.keys.toList();
  Currency? getCurrencyByName(String name) {
    try {
      return currencies.firstWhere((currency) => currency.name == name);
    } catch (e) {
      return null;
    }
  }
}

class CityRate {
  final int ask;
  final int bid;

  CityRate({
    required this.ask,
    required this.bid,
  });

  factory CityRate.fromJson(Map<String, dynamic> json) {
    return CityRate(
      ask: json['ask'] ?? 0,
      bid: json['bid'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
    };
  }

  // Convenience getters
  double get mid => (ask + bid) / 2;
  int get spread => bid - ask;
  String get formattedAsk => ask.toString();
  String get formattedBid => bid.toString();
  String get formattedMid => mid.toStringAsFixed(1);
}

class Currency {
  final int ask;
  final int bid;
  final int change;
  final double changePercentage;
  final double mid;
  final String name;
  final PreviousRates? previousRates;

  Currency({
    required this.ask,
    required this.bid,
    required this.change,
    required this.changePercentage,
    required this.mid,
    required this.name,
    this.previousRates,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      ask: json['ask'] ?? 0,
      bid: json['bid'] ?? 0,
      change: json['change'] ?? 0,
      changePercentage: (json['change_percentage'] ?? 0.0).toDouble(),
      mid: (json['mid'] ?? 0.0).toDouble(),
      name: json['name'] ?? '',
      previousRates: json['previous_rates'] != null 
          ? PreviousRates.fromJson(json['previous_rates'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
      'change': change,
      'change_percentage': changePercentage,
      'mid': mid,
      'name': name,
      'previous_rates': previousRates?.toJson(),
    };
  }

  // Convenience getters
  bool get isPositiveChange => change > 0;
  bool get isNegativeChange => change < 0;
  int get spread => bid - ask;
  String get formattedAsk => ask.toString();
  String get formattedBid => bid.toString();
  String get formattedMid => mid.toStringAsFixed(1);
  String get formattedChange => change > 0 ? '+$change' : change.toString();
  String get formattedChangePercentage => changePercentage > 0 
      ? '+${changePercentage.toStringAsFixed(2)}%' 
      : '${changePercentage.toStringAsFixed(2)}%';
}

class DamascusPrediction {
  final int ask;
  final int bid;

  DamascusPrediction({
    required this.ask,
    required this.bid,
  });

  factory DamascusPrediction.fromJson(Map<String, dynamic> json) {
    return DamascusPrediction(
      ask: json['ask'] ?? 0,
      bid: json['bid'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
    };
  }

  // Convenience getters
  double get mid => (ask + bid) / 2;
  int get spread => bid - ask;
  String get formattedAsk => ask.toString();
  String get formattedBid => bid.toString();
  String get formattedMid => mid.toStringAsFixed(1);
}

class OHLCV {
  final double close;
  final double high;
  final double low;
  final double open;
  final int volume;

  OHLCV({
    required this.close,
    required this.high,
    required this.low,
    required this.open,
    required this.volume,
  });

  factory OHLCV.fromJson(Map<String, dynamic> json) {
    return OHLCV(
      close: (json['close'] ?? 0.0).toDouble(),
      high: (json['high'] ?? 0.0).toDouble(),
      low: (json['low'] ?? 0.0).toDouble(),
      open: (json['open'] ?? 0.0).toDouble(),
      volume: json['volume'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'close': close,
      'high': high,
      'low': low,
      'open': open,
      'volume': volume,
    };
  }

  // Convenience getters
  double get range => high - low;
  double get changeFromOpen => close - open;
  double get changePercentageFromOpen => open != 0 ? ((close - open) / open) * 100 : 0.0;
  bool get isGreenCandle => close > open;
  bool get isRedCandle => close < open;
  bool get isDoji => close == open;
  
  String get formattedOpen => open.toStringAsFixed(1);
  String get formattedHigh => high.toStringAsFixed(1);
  String get formattedLow => low.toStringAsFixed(1);
  String get formattedClose => close.toStringAsFixed(1);
  String get formattedVolume => volume.toString();
  String get formattedRange => range.toStringAsFixed(1);
  String get formattedChangeFromOpen => changeFromOpen > 0 
      ? '+${changeFromOpen.toStringAsFixed(1)}' 
      : changeFromOpen.toStringAsFixed(1);
  String get formattedChangePercentageFromOpen => changePercentageFromOpen > 0 
      ? '+${changePercentageFromOpen.toStringAsFixed(2)}%' 
      : '${changePercentageFromOpen.toStringAsFixed(2)}%';
}

class PreviousRates {
  final int ask;
  final int bid;
  final double mid;
  final String source;
  final String timestamp;

  PreviousRates({
    required this.ask,
    required this.bid,
    required this.mid,
    required this.source,
    required this.timestamp,
  });

  factory PreviousRates.fromJson(Map<String, dynamic> json) {
    return PreviousRates(
      ask: json['ask'] ?? 0,
      bid: json['bid'] ?? 0,
      mid: (json['mid'] ?? 0.0).toDouble(),
      source: json['source'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
      'mid': mid,
      'source': source,
      'timestamp': timestamp,
    };
  }

  // Convenience getters
  int get spread => bid - ask;
  DateTime? get parsedTimestamp {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
  
  String get formattedAsk => ask.toString();
  String get formattedBid => bid.toString();
  String get formattedMid => mid.toStringAsFixed(1);
  String get formattedSource => source.replaceAll('-', ' ').replaceAll('.com', '').toUpperCase();
  String get formattedTimestamp {
    final date = parsedTimestamp;
    if (date == null) return timestamp;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
