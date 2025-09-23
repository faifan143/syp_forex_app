class DamascusPrediction {
  final double ask;
  final double bid;

  const DamascusPrediction({
    required this.ask,
    required this.bid,
  });

  // Computed properties
  double get mid => (ask + bid) / 2;
  double get spread => ask - bid;
  String get formattedAsk => ask.toStringAsFixed(2);
  String get formattedBid => bid.toStringAsFixed(2);
  String get formattedMid => mid.toStringAsFixed(2);

  factory DamascusPrediction.fromJson(Map<String, dynamic> json) {
    return DamascusPrediction(
      ask: (json['ask'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
    };
  }
}

class CurrencyData {
  final String name;
  final double ask;
  final double bid;
  final double mid;
  final double change;
  final double changePercentage;
  final PreviousRates? previousRates;
  final String dataSource;

  const CurrencyData({
    required this.name,
    required this.ask,
    required this.bid,
    required this.mid,
    required this.change,
    required this.changePercentage,
    this.previousRates,
    required this.dataSource,
  });

  // Computed properties
  double get spread => ask - bid;
  bool get isPositiveChange => change >= 0;
  String get formattedAsk => ask.toStringAsFixed(2);
  String get formattedBid => bid.toStringAsFixed(2);
  String get formattedMid => mid.toStringAsFixed(2);
  String get formattedChange => '${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}';
  String get formattedChangePercentage => '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(2)}%';

  factory CurrencyData.fromJson(Map<String, dynamic> json) {
    return CurrencyData(
      name: json['name'] as String,
      ask: (json['ask'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
      mid: (json['mid'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercentage: (json['change_percentage'] as num).toDouble(),
      previousRates: json['previous_rates'] != null
          ? PreviousRates.fromJson(json['previous_rates'] as Map<String, dynamic>)
          : null,
      dataSource: json['data_source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ask': ask,
      'bid': bid,
      'mid': mid,
      'change': change,
      'change_percentage': changePercentage,
      'previous_rates': previousRates?.toJson(),
      'data_source': dataSource,
    };
  }
}

class PreviousRates {
  final double ask;
  final double bid;
  final double mid;
  final String timestamp;
  final String source;

  const PreviousRates({
    required this.ask,
    required this.bid,
    required this.mid,
    required this.timestamp,
    required this.source,
  });

  factory PreviousRates.fromJson(Map<String, dynamic> json) {
    return PreviousRates(
      ask: (json['ask'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
      mid: (json['mid'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
      'mid': mid,
      'timestamp': timestamp,
      'source': source,
    };
  }
}

class CityRates {
  final double ask;
  final double bid;

  const CityRates({
    required this.ask,
    required this.bid,
  });

  // Computed properties
  double get mid => (ask + bid) / 2;
  double get spread => ask - bid;
  String get formattedAsk => ask.toStringAsFixed(2);
  String get formattedBid => bid.toStringAsFixed(2);
  String get formattedMid => mid.toStringAsFixed(2);

  factory CityRates.fromJson(Map<String, dynamic> json) {
    return CityRates(
      ask: (json['ask'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
    };
  }
}

class OHLCVData {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const OHLCVData({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  // Computed properties
  String get formattedVolume => volume.toStringAsFixed(0);

  factory OHLCVData.fromJson(Map<String, dynamic> json) {
    return OHLCVData(
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}

class ComprehensiveResponse {
  final DamascusPrediction damascusPrediction;
  final List<CurrencyData> currencies;
  final Map<String, CityRates> cityRates;
  final OHLCVData ohlcv;

  const ComprehensiveResponse({
    required this.damascusPrediction,
    required this.currencies,
    required this.cityRates,
    required this.ohlcv,
  });

  factory ComprehensiveResponse.fromJson(Map<String, dynamic> json) {
    return ComprehensiveResponse(
      damascusPrediction: DamascusPrediction.fromJson(
        json['damascus_prediction'] as Map<String, dynamic>,
      ),
      currencies: (json['currencies'] as List<dynamic>)
          .map((e) => CurrencyData.fromJson(e as Map<String, dynamic>))
          .toList(),
      cityRates: (json['city_rates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          CityRates.fromJson(value as Map<String, dynamic>),
        ),
      ),
      ohlcv: OHLCVData.fromJson(json['ohlcv'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'damascus_prediction': damascusPrediction.toJson(),
      'currencies': currencies.map((e) => e.toJson()).toList(),
      'city_rates': cityRates.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'ohlcv': ohlcv.toJson(),
    };
  }
}