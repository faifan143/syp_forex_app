import 'dart:math';
import 'package:get/get.dart';
import '../models/ai_recommendation.dart';
import '../models/forex_models.dart';

class AIRecommenderService {
  static final AIRecommenderService _instance = AIRecommenderService._internal();
  factory AIRecommenderService() => _instance;
  AIRecommenderService._internal();

  // Simulate AI analysis based on market data
  Future<AIRecommendation> generateRecommendation({
    required String symbol,
    required double currentPrice,
    required List<Candlestick> recentCandles,
    required Currency? currencyData,
  }) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 500));

    // Analyze technical indicators
    final technicalAnalysis = _analyzeTechnicalIndicators(recentCandles);
    
    // Analyze fundamental factors
    final fundamentalAnalysis = _analyzeFundamentalFactors(currencyData);
    
    // Combine analyses to determine recommendation
    final recommendation = _combineAnalyses(
      symbol: symbol,
      currentPrice: currentPrice,
      technicalAnalysis: technicalAnalysis,
      fundamentalAnalysis: fundamentalAnalysis,
      recentCandles: recentCandles,
    );

    return recommendation;
  }

  Map<String, dynamic> _analyzeTechnicalIndicators(List<Candlestick> candles) {
    if (candles.length < 5) {
      return {
        'trend': 'neutral',
        'strength': 0.5,
        'indicators': ['Insufficient data'],
        'rsi': 50.0,
        'macd': 0.0,
        'bollinger': 'neutral',
      };
    }

    // Calculate RSI (simplified)
    final rsi = _calculateRSI(candles);
    
    // Calculate MACD (simplified)
    final macd = _calculateMACD(candles);
    
    // Calculate Bollinger Bands position
    final bollingerPosition = _calculateBollingerPosition(candles);
    
    // Determine trend
    final trend = _determineTrend(candles);
    
    // Calculate trend strength
    final strength = _calculateTrendStrength(candles);

    return {
      'trend': trend,
      'strength': strength,
      'indicators': _getTechnicalIndicators(rsi, macd, bollingerPosition),
      'rsi': rsi,
      'macd': macd,
      'bollinger': bollingerPosition,
    };
  }

  Map<String, dynamic> _analyzeFundamentalFactors(Currency? currencyData) {
    if (currencyData == null) {
      return {
        'sentiment': 'neutral',
        'strength': 0.5,
        'factors': ['No fundamental data available'],
        'tomorrowTrend': 'neutral',
        'weekTrend': 'neutral',
      };
    }

    final tomorrowTrend = currencyData.tomorrowTrend.toLowerCase();
    final weekTrend = currencyData.weekTrend.toLowerCase();
    final tomorrowChange = currencyData.tomorrowChangePercent;
    final weekChange = currencyData.weekChangePercent;

    // Determine overall sentiment
    String sentiment = 'neutral';
    if ((tomorrowTrend == 'up' && weekTrend == 'up') || 
        (tomorrowChange > 0.5 && weekChange > 0.5)) {
      sentiment = 'bullish';
    } else if ((tomorrowTrend == 'down' && weekTrend == 'down') || 
               (tomorrowChange < -0.5 && weekChange < -0.5)) {
      sentiment = 'bearish';
    }

    // Calculate strength based on change percentages
    final strength = (tomorrowChange.abs() + weekChange.abs()) / 2 / 100;

    return {
      'sentiment': sentiment,
      'strength': strength.clamp(0.0, 1.0),
      'factors': _getFundamentalFactors(currencyData),
      'tomorrowTrend': tomorrowTrend,
      'weekTrend': weekTrend,
    };
  }

  AIRecommendation _combineAnalyses({
    required String symbol,
    required double currentPrice,
    required Map<String, dynamic> technicalAnalysis,
    required Map<String, dynamic> fundamentalAnalysis,
    required List<Candlestick> recentCandles,
  }) {
    final technicalTrend = technicalAnalysis['trend'] as String;
    final technicalStrength = technicalAnalysis['strength'] as double;
    final fundamentalSentiment = fundamentalAnalysis['sentiment'] as String;
    final fundamentalStrength = fundamentalAnalysis['strength'] as double;
    final tomorrowTrend = fundamentalAnalysis['tomorrowTrend'] as String;
    final weekTrend = fundamentalAnalysis['weekTrend'] as String;
    final tomorrowChangePercent = fundamentalAnalysis['tomorrowChangePercent'] as double? ?? 0.0;
    final weekChangePercent = fundamentalAnalysis['weekChangePercent'] as double? ?? 0.0;

    // Use REAL dashboard data for recommendations
    double buyScore = 0.0;
    double sellScore = 0.0;
    String reasoning = '';

    // 1. TOMORROW TREND (40% weight) - Most important
    if (tomorrowTrend == 'up') {
      buyScore += 0.4;
      reasoning += 'tomorrowTrendUp'.tr;
    } else if (tomorrowTrend == 'down') {
      sellScore += 0.4;
      reasoning += 'tomorrowTrendDown'.tr;
    }

    // 2. WEEK TREND (30% weight) - Important for direction
    if (weekTrend == 'up') {
      buyScore += 0.3;
      reasoning += reasoning.isNotEmpty ? '. ${'weekTrendUp'.tr}' : 'weekTrendUp'.tr;
    } else if (weekTrend == 'down') {
      sellScore += 0.3;
      reasoning += reasoning.isNotEmpty ? '. ${'weekTrendDown'.tr}' : 'weekTrendDown'.tr;
    }

    // 3. CHANGE PERCENTAGES (20% weight) - Strength of movement
    final avgChangePercent = (tomorrowChangePercent + weekChangePercent) / 2;
    if (avgChangePercent > 0.5) {
      buyScore += 0.2;
      reasoning += reasoning.isNotEmpty ? '. ${'strongUpwardMomentum'.tr}' : 'strongUpwardMomentum'.tr;
    } else if (avgChangePercent < -0.5) {
      sellScore += 0.2;
      reasoning += reasoning.isNotEmpty ? '. ${'strongDownwardMomentum'.tr}' : 'strongDownwardMomentum'.tr;
    }

    // 4. TECHNICAL CONFIRMATION (10% weight) - Support the trend
    if (technicalTrend == 'bullish' && buyScore > sellScore) {
      buyScore += 0.1;
      reasoning += reasoning.isNotEmpty ? '. ${'technicalConfirmsUpward'.tr}' : 'technicalConfirmsUpward'.tr;
    } else if (technicalTrend == 'bearish' && sellScore > buyScore) {
      sellScore += 0.1;
      reasoning += reasoning.isNotEmpty ? '. ${'technicalConfirmsDownward'.tr}' : 'technicalConfirmsDownward'.tr;
    }

    // Determine recommendation type based on REAL data
    RecommendationType type;
    if (buyScore > sellScore + 0.1) {
      type = RecommendationType.buy;
    } else if (sellScore > buyScore + 0.1) {
      type = RecommendationType.sell;
    } else {
      type = RecommendationType.hold;
      reasoning = 'mixedSignalsFromAnalysis'.tr;
    }

    // Calculate confidence based on data strength
    final maxScore = max(buyScore, sellScore);
    ConfidenceLevel confidence;
    if (maxScore > 0.6) {
      confidence = ConfidenceLevel.high;
    } else if (maxScore > 0.4) {
      confidence = ConfidenceLevel.medium;
    } else {
      confidence = ConfidenceLevel.low;
    }

    // Calculate price targets
    final pipSize = _getPipSize(symbol);
    final expectedChange = _calculateExpectedChange(type, currentPrice, pipSize, maxScore);
    final targetPrice = currentPrice + expectedChange;
    final stopLossPrice = currentPrice - (expectedChange * 0.5);
    final riskRewardRatio = expectedChange.abs() / (expectedChange.abs() * 0.5);

    // Use the reasoning we built from real data
    if (reasoning.isEmpty) {
      reasoning = '${'confidenceLevel'.tr}: ${confidence.toString().split('.').last.tr}';
    } else {
      reasoning += '. ${'confidenceLevel'.tr}: ${confidence.toString().split('.').last.tr}';
    }

    return AIRecommendation(
      type: type,
      confidence: confidence,
      confidenceScore: maxScore,
      reasoning: reasoning,
      keyFactors: _getKeyFactors(technicalAnalysis, fundamentalAnalysis),
      expectedPriceChange: expectedChange,
      expectedPriceChangePercent: (expectedChange / currentPrice) * 100,
      timeHorizon: _getTimeHorizon(confidence),
      timestamp: DateTime.now(),
      symbol: symbol,
      currentPrice: currentPrice,
      targetPrice: targetPrice,
      stopLossPrice: stopLossPrice,
      riskRewardRatio: riskRewardRatio,
      marketSentiment: _getTranslatedMarketSentiment(fundamentalSentiment),
      technicalIndicators: technicalAnalysis['indicators'] as List<String>,
      fundamentalFactors: fundamentalAnalysis['factors'] as List<String>,
    );
  }

  double _calculateRSI(List<Candlestick> candles) {
    if (candles.length < 14) return 50.0;

    double gains = 0.0;
    double losses = 0.0;

    for (int i = 1; i < 14; i++) {
      final change = candles[i].close - candles[i + 1].close;
      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }

    final avgGain = gains / 13;
    final avgLoss = losses / 13;

    if (avgLoss == 0) return 100.0;

    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  double _calculateMACD(List<Candlestick> candles) {
    if (candles.length < 26) return 0.0;

    // Simplified MACD calculation
    final ema12 = _calculateEMA(candles.take(12).map((c) => c.close).toList());
    final ema26 = _calculateEMA(candles.take(26).map((c) => c.close).toList());
    
    return ema12 - ema26;
  }

  double _calculateEMA(List<double> prices) {
    if (prices.isEmpty) return 0.0;
    
    double ema = prices.first;
    final double multiplier = 2.0 / (prices.length + 1);
    
    for (int i = 1; i < prices.length; i++) {
      ema = (prices[i] * multiplier) + (ema * (1 - multiplier));
    }
    
    return ema;
  }

  String _calculateBollingerPosition(List<Candlestick> candles) {
    if (candles.length < 20) return 'neutral';

    final prices = candles.take(20).map((c) => c.close).toList();
    final sma = prices.reduce((a, b) => a + b) / prices.length;
    final variance = prices.map((p) => pow(p - sma, 2)).reduce((a, b) => a + b) / prices.length;
    final stdDev = sqrt(variance);
    
    final upperBand = sma + (2 * stdDev);
    final lowerBand = sma - (2 * stdDev);
    final currentPrice = candles.first.close;

    if (currentPrice > upperBand) return 'overbought';
    if (currentPrice < lowerBand) return 'oversold';
    return 'neutral';
  }

  String _determineTrend(List<Candlestick> candles) {
    if (candles.length < 5) return 'neutral';

    final recent = candles.take(5).map((c) => c.close).toList();
    final first = recent.last;
    final last = recent.first;
    
    final change = (last - first) / first;
    
    if (change > 0.01) return 'bullish';
    if (change < -0.01) return 'bearish';
    return 'neutral';
  }

  double _calculateTrendStrength(List<Candlestick> candles) {
    if (candles.length < 5) return 0.5;

    final recent = candles.take(5).map((c) => c.close).toList();
    double totalChange = 0.0;
    
    for (int i = 1; i < recent.length; i++) {
      totalChange += (recent[i - 1] - recent[i]) / recent[i];
    }
    
    return (totalChange.abs() / (recent.length - 1)).clamp(0.0, 1.0);
  }

  List<String> _getTechnicalIndicators(double rsi, double macd, String bollinger) {
    final indicators = <String>[];
    
    if (rsi > 70) {
      indicators.add('rsiOverbought'.tr);
    } else if (rsi < 30) {
      indicators.add('rsiOversold'.tr);
    }
    
    if (macd > 0) {
      indicators.add('macdBullish'.tr);
    } else if (macd < 0) {
      indicators.add('macdBearish'.tr);
    }
    
    if (bollinger == 'overbought') {
      indicators.add('bollingerOverbought'.tr);
    } else if (bollinger == 'oversold') {
      indicators.add('bollingerOversold'.tr);
    }
    
    return indicators;
  }

  List<String> _getFundamentalFactors(Currency currencyData) {
    final factors = <String>[];
    
    if (currencyData.tomorrowChangePercent.abs() > 1.0) {
      factors.add('strongMomentum'.tr.replaceAll('{trend}', currencyData.tomorrowTrend.tr));
    }
    
    if (currencyData.weekChangePercent.abs() > 2.0) {
      factors.add('weeklyTrend'.tr.replaceAll('{trend}', currencyData.weekTrend.tr));
    }
    
    if (currencyData.forecast7Days.isNotEmpty) {
      final avgForecast = currencyData.forecast7Days.reduce((a, b) => a + b) / currencyData.forecast7Days.length;
      if (avgForecast > currencyData.currentValue * 1.01) {
        factors.add('positive7DayForecast'.tr);
      } else if (avgForecast < currencyData.currentValue * 0.99) {
        factors.add('negative7DayForecast'.tr);
      }
    }
    
    return factors;
  }

  double _getPipSize(String symbol) {
    // Simplified pip size calculation
    if (symbol.contains('JPY')) {
      return 0.01;
    }
    return 0.0001;
  }

  double _calculateExpectedChange(RecommendationType type, double currentPrice, double pipSize, double strength) {
    final baseChange = pipSize * 20; // Base 20 pips
    final strengthMultiplier = 0.5 + (strength * 1.5); // 0.5x to 2x multiplier
    final change = baseChange * strengthMultiplier;
    
    return type == RecommendationType.buy ? change : -change;
  }

  String _getTimeHorizon(ConfidenceLevel confidence) {
    switch (confidence) {
      case ConfidenceLevel.low:
        return 'shortTerm'.tr;
      case ConfidenceLevel.medium:
        return 'mediumTerm'.tr;
      case ConfidenceLevel.high:
        return 'longTerm'.tr;
    }
  }

  String _generateReasoning({
    required RecommendationType type,
    required Map<String, dynamic> technicalAnalysis,
    required Map<String, dynamic> fundamentalAnalysis,
    required ConfidenceLevel confidence,
  }) {
    final technicalTrend = technicalAnalysis['trend'] as String;
    final fundamentalSentiment = fundamentalAnalysis['sentiment'] as String;
    
    final reasons = <String>[];
    
    if (type == RecommendationType.buy) {
      reasons.add('technicalAnalysisShows'.tr.replaceAll('{trend}', technicalTrend.tr));
      if (fundamentalSentiment == 'bullish') {
        reasons.add('fundamentalFactorsSupportUpward'.tr);
      }
    } else if (type == RecommendationType.sell) {
      reasons.add('technicalAnalysisIndicates'.tr.replaceAll('{trend}', technicalTrend.tr));
      if (fundamentalSentiment == 'bearish') {
        reasons.add('fundamentalFactorsSuggestDownward'.tr);
      }
    } else {
      reasons.add('mixedSignalsFromAnalysis'.tr);
      reasons.add('marketConditionsUncertain'.tr);
    }
    
    reasons.add('${'confidenceLevel'.tr}: ${confidence.toString().split('.').last.tr}');
    
    return reasons.join('. ');
  }

  List<String> _getKeyFactors(Map<String, dynamic> technicalAnalysis, Map<String, dynamic> fundamentalAnalysis) {
    final factors = <String>[];
    
    final technicalIndicators = technicalAnalysis['indicators'] as List<String>;
    final fundamentalFactors = fundamentalAnalysis['factors'] as List<String>;
    
    factors.addAll(technicalIndicators.take(2));
    factors.addAll(fundamentalFactors.take(2));
    
    return factors;
  }

  String _getTranslatedMarketSentiment(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return 'bullishSentiment'.tr;
      case 'bearish':
        return 'bearishSentiment'.tr;
      case 'neutral':
      default:
        return 'neutralSentiment'.tr;
    }
  }
}
