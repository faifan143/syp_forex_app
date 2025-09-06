class ForecastMethod {
  final String type;
  final String approach;
  final String description;
  final String confidence;

  ForecastMethod({
    required this.type,
    required this.approach,
    required this.description,
    required this.confidence,
  });

  factory ForecastMethod.fromJson(Map<String, dynamic> json) {
    return ForecastMethod(
      type: json['type'] as String,
      approach: json['approach'] as String,
      description: json['description'] as String,
      confidence: json['confidence'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'approach': approach,
      'description': description,
      'confidence': confidence,
    };
  }
}

