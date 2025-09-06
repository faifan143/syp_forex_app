class Prediction {
  final double rate;
  final ConfidenceInterval confidenceInterval;
  final double expectedChange;
  final String dayType;

  Prediction({
    required this.rate,
    required this.confidenceInterval,
    required this.expectedChange,
    required this.dayType,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      rate: (json['rate'] as num).toDouble(),
      confidenceInterval: ConfidenceInterval.fromJson(json['confidence_interval']),
      expectedChange: (json['expected_change'] as num).toDouble(),
      dayType: json['day_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'confidence_interval': confidenceInterval.toJson(),
      'expected_change': expectedChange,
      'day_type': dayType,
    };
  }
}

class ConfidenceInterval {
  final double lower;
  final double upper;
  final double rangePct;

  ConfidenceInterval({
    required this.lower,
    required this.upper,
    required this.rangePct,
  });

  factory ConfidenceInterval.fromJson(Map<String, dynamic> json) {
    return ConfidenceInterval(
      lower: (json['lower'] as num).toDouble(),
      upper: (json['upper'] as num).toDouble(),
      rangePct: (json['range_pct'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lower': lower,
      'upper': upper,
      'range_pct': rangePct,
    };
  }
}

