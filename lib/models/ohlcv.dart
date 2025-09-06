class OHLCV {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String dayType;

  OHLCV({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.dayType,
  });

  factory OHLCV.fromJson(Map<String, dynamic> json) {
    return OHLCV(
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      dayType: json['day_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'day_type': dayType,
    };
  }
}

