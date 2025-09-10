import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum RecommendationType {
  buy,
  sell,
  hold,
}

enum ConfidenceLevel {
  low,
  medium,
  high,
  veryHigh,
}

class AIRecommendation {
  final RecommendationType type;
  final ConfidenceLevel confidence;
  final double confidenceScore; // 0.0 to 1.0
  final String reasoning;
  final List<String> keyFactors;
  final double expectedPriceChange;
  final double expectedPriceChangePercent;
  final String timeHorizon; // e.g., "1 hour", "4 hours", "1 day"
  final DateTime timestamp;
  final String symbol;
  final double currentPrice;
  final double targetPrice;
  final double stopLossPrice;
  final double riskRewardRatio;
  final String marketSentiment; // "bullish", "bearish", "neutral"
  final List<String> technicalIndicators;
  final List<String> fundamentalFactors;

  AIRecommendation({
    required this.type,
    required this.confidence,
    required this.confidenceScore,
    required this.reasoning,
    required this.keyFactors,
    required this.expectedPriceChange,
    required this.expectedPriceChangePercent,
    required this.timeHorizon,
    required this.timestamp,
    required this.symbol,
    required this.currentPrice,
    required this.targetPrice,
    required this.stopLossPrice,
    required this.riskRewardRatio,
    required this.marketSentiment,
    required this.technicalIndicators,
    required this.fundamentalFactors,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      type: RecommendationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => RecommendationType.hold,
      ),
      confidence: ConfidenceLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['confidence'],
        orElse: () => ConfidenceLevel.medium,
      ),
      confidenceScore: (json['confidenceScore'] ?? 0.5).toDouble(),
      reasoning: json['reasoning'] ?? '',
      keyFactors: List<String>.from(json['keyFactors'] ?? []),
      expectedPriceChange: (json['expectedPriceChange'] ?? 0.0).toDouble(),
      expectedPriceChangePercent: (json['expectedPriceChangePercent'] ?? 0.0).toDouble(),
      timeHorizon: json['timeHorizon'] ?? '1 hour',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      symbol: json['symbol'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      targetPrice: (json['targetPrice'] ?? 0.0).toDouble(),
      stopLossPrice: (json['stopLossPrice'] ?? 0.0).toDouble(),
      riskRewardRatio: (json['riskRewardRatio'] ?? 1.0).toDouble(),
      marketSentiment: json['marketSentiment'] ?? 'neutral',
      technicalIndicators: List<String>.from(json['technicalIndicators'] ?? []),
      fundamentalFactors: List<String>.from(json['fundamentalFactors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'confidence': confidence.toString().split('.').last,
      'confidenceScore': confidenceScore,
      'reasoning': reasoning,
      'keyFactors': keyFactors,
      'expectedPriceChange': expectedPriceChange,
      'expectedPriceChangePercent': expectedPriceChangePercent,
      'timeHorizon': timeHorizon,
      'timestamp': timestamp.toIso8601String(),
      'symbol': symbol,
      'currentPrice': currentPrice,
      'targetPrice': targetPrice,
      'stopLossPrice': stopLossPrice,
      'riskRewardRatio': riskRewardRatio,
      'marketSentiment': marketSentiment,
      'technicalIndicators': technicalIndicators,
      'fundamentalFactors': fundamentalFactors,
    };
  }

  // Helper getters
  bool get isBuy => type == RecommendationType.buy;
  bool get isSell => type == RecommendationType.sell;
  bool get isHold => type == RecommendationType.hold;
  
  String get typeDisplayName {
    switch (type) {
      case RecommendationType.buy:
        return 'buyRecommendation'.tr;
      case RecommendationType.sell:
        return 'sellRecommendation'.tr;
      case RecommendationType.hold:
        return 'holdRecommendation'.tr;
    }
  }

  String get confidenceDisplayName {
    switch (confidence) {
      case ConfidenceLevel.low:
        return 'low'.tr;
      case ConfidenceLevel.medium:
        return 'medium'.tr;
      case ConfidenceLevel.high:
        return 'high'.tr;
      case ConfidenceLevel.veryHigh:
        return 'veryHigh'.tr;
    }
  }

  Color get typeColor {
    switch (type) {
      case RecommendationType.buy:
        return Colors.green;
      case RecommendationType.sell:
        return Colors.red;
      case RecommendationType.hold:
        return Colors.orange;
    }
  }

  Color get confidenceColor {
    switch (confidence) {
      case ConfidenceLevel.low:
        return Colors.red[300]!;
      case ConfidenceLevel.medium:
        return Colors.orange[300]!;
      case ConfidenceLevel.high:
        return Colors.blue[300]!;
      case ConfidenceLevel.veryHigh:
        return Colors.green[300]!;
    }
  }

  String get formattedExpectedChange => 
      '${expectedPriceChangePercent >= 0 ? '+' : ''}${expectedPriceChangePercent.toStringAsFixed(2)}%';

  String get formattedTargetPrice => targetPrice.toStringAsFixed(4);
  String get formattedStopLossPrice => stopLossPrice.toStringAsFixed(4);
  String get formattedRiskRewardRatio => riskRewardRatio.toStringAsFixed(2);
}
