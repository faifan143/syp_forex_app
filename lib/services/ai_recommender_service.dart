import 'dart:math';
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

    // Combine technical and fundamental analysis
    double buyScore = 0.0;
    double sellScore = 0.0;

    // Technical analysis scoring
    if (technicalTrend == 'bullish') {
      buyScore += technicalStrength * 0.4;
    } else if (technicalTrend == 'bearish') {
      sellScore += technicalStrength * 0.4;
    }

    // Fundamental analysis scoring
    if (fundamentalSentiment == 'bullish') {
      buyScore += fundamentalStrength * 0.3;
    } else if (fundamentalSentiment == 'bearish') {
      sellScore += fundamentalStrength * 0.3;
    }

    // Add some randomness to make it more realistic
    final random = Random();
    buyScore += (random.nextDouble() - 0.5) * 0.2;
    sellScore += (random.nextDouble() - 0.5) * 0.2;

    // Determine recommendation type
    RecommendationType type;
    if (buyScore > sellScore + 0.1) {
      type = RecommendationType.buy;
    } else if (sellScore > buyScore + 0.1) {
      type = RecommendationType.sell;
    } else {
      type = RecommendationType.hold;
    }

    // Calculate confidence
    final maxScore = max(buyScore, sellScore);
    ConfidenceLevel confidence;
    if (maxScore > 0.7) {
      confidence = ConfidenceLevel.veryHigh;
    } else if (maxScore > 0.5) {
      confidence = ConfidenceLevel.high;
    } else if (maxScore > 0.3) {
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

    // Generate reasoning
    final reasoning = _generateReasoning(
      type: type,
      technicalAnalysis: technicalAnalysis,
      fundamentalAnalysis: fundamentalAnalysis,
      confidence: confidence,
    );

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
      marketSentiment: fundamentalSentiment,
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
      indicators.add('RSI Overbought');
    } else if (rsi < 30) {
      indicators.add('RSI Oversold');
    }
    
    if (macd > 0) {
      indicators.add('MACD Bullish');
    } else if (macd < 0) {
      indicators.add('MACD Bearish');
    }
    
    if (bollinger == 'overbought') {
      indicators.add('Bollinger Overbought');
    } else if (bollinger == 'oversold') {
      indicators.add('Bollinger Oversold');
    }
    
    return indicators;
  }

  List<String> _getFundamentalFactors(Currency currencyData) {
    final factors = <String>[];
    
    if (currencyData.tomorrowChangePercent.abs() > 1.0) {
      factors.add('Strong ${currencyData.tomorrowTrend} momentum');
    }
    
    if (currencyData.weekChangePercent.abs() > 2.0) {
      factors.add('Weekly ${currencyData.weekTrend} trend');
    }
    
    if (currencyData.forecast7Days.isNotEmpty) {
      final avgForecast = currencyData.forecast7Days.reduce((a, b) => a + b) / currencyData.forecast7Days.length;
      if (avgForecast > currencyData.currentValue * 1.01) {
        factors.add('Positive 7-day forecast');
      } else if (avgForecast < currencyData.currentValue * 0.99) {
        factors.add('Negative 7-day forecast');
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
        return '1-2 hours';
      case ConfidenceLevel.medium:
        return '2-4 hours';
      case ConfidenceLevel.high:
        return '4-8 hours';
      case ConfidenceLevel.veryHigh:
        return '8-24 hours';
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
      reasons.add('Technical analysis shows ${technicalTrend} momentum');
      if (fundamentalSentiment == 'bullish') {
        reasons.add('Fundamental factors support upward movement');
      }
    } else if (type == RecommendationType.sell) {
      reasons.add('Technical analysis indicates ${technicalTrend} pressure');
      if (fundamentalSentiment == 'bearish') {
        reasons.add('Fundamental factors suggest downward movement');
      }
    } else {
      reasons.add('Mixed signals from technical and fundamental analysis');
      reasons.add('Market conditions are uncertain');
    }
    
    reasons.add('Confidence level: ${confidence.toString().split('.').last}');
    
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
}
