class CurrentRates {
  final double ask;
  final double bid;
  final double mid;
  final double spread;
  final double change;
  final double changePercentage;

  CurrentRates({
    required this.ask,
    required this.bid,
    required this.mid,
    required this.spread,
    required this.change,
    required this.changePercentage,
  });

  factory CurrentRates.fromJson(Map<String, dynamic> json) {
    return CurrentRates(
      ask: (json['ask'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
      mid: (json['mid'] as num).toDouble(),
      spread: (json['spread'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercentage: (json['change_percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ask': ask,
      'bid': bid,
      'mid': mid,
      'spread': spread,
      'change': change,
      'change_percentage': changePercentage,
    };
  }
}

