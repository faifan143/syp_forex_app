import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/forex_response_models.dart';
import 'package:syp_forex_app/services/market_behavior_profiles.dart';
import 'package:syp_forex_app/services/data_cache_handler.dart';
import 'package:syp_forex_app/services/market_analysis_engine.dart';
import 'package:syp_forex_app/services/volatility_service.dart';
import 'package:syp_forex_app/services/enhanced_forex_calculator.dart';

/// Forex Data Service - Handles data processing and caching
///
/// This service handles forex data from various sources and provides
/// formatted data for the Flutter application. It handles data transformation,
/// ML prediction processing, and intelligent caching.
///
/// The service works with data from multiple sources:
/// - Handles JSON responses from /forex/dashboard endpoint
/// - Handles ML prediction data from the server's LSTM models
/// - Manages local caching for performance optimization
/// - Formats data according to the app's data models
///
/// This service is used by ForexApiService to handle and format API responses.
class ForexDataService {
  // This URL is used when the Forex API server is unavailable
  // The primary data source is the Forex API server at localhost:5001
  static const String _baseUrl = 'https://open.er-api.com/v6/latest/USD';

  final DataCacheService _cacheManager;
  final int _rateLimitDelay;
  final int _dailyLimit;

  int _requestCount = 0;
  int? _dailyResetTime;
  int _lastRequestTime = 0;

  // MT5 Format currency pairs
  static const Map<String, String> _forexPairs = {
    'EUR': 'EURUSD', // EUR/USD
    'GBP': 'GBPUSD', // GBP/USD
    'AUD': 'AUDUSD', // AUD/USD
    'NZD': 'NZDUSD', // NZD/USD
    'JPY': 'USDJPY', // USD/JPY
    'CHF': 'USDCHF', // USD/CHF
    'CAD': 'USDCAD', // USD/CAD
    'SEK': 'USDSEK', // USD/SEK
    'TRY': 'USDTRY', // USD/TRY
    'CNH': 'USDCNY', // USD/CNY
  };

  ForexDataService({
    DataCacheService? cacheManager,
    int rateLimitDelay = 1,
    int dailyLimit = 1000,
  }) : _cacheManager = cacheManager ?? DataCacheService(),
       _rateLimitDelay = rateLimitDelay,
       _dailyLimit = dailyLimit;

  Future<void> _rateLimitCheck() async {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check daily limit reset
    if (_dailyResetTime != null && currentTime >= _dailyResetTime!) {
      _requestCount = 0;
      _dailyResetTime = null;
    }

    // Check daily limit
    if (_requestCount >= _dailyLimit) {
      if (_dailyResetTime == null) {
        _dailyResetTime = currentTime + (24 * 60 * 60);
      }
      throw Exception('Daily API limit reached ($_dailyLimit requests)');
    }

    // Check rate limit
    final timeSinceLast = currentTime - _lastRequestTime;
    if (timeSinceLast < _rateLimitDelay) {
      final sleepTime = _rateLimitDelay - timeSinceLast;
      await Future.delayed(Duration(seconds: sleepTime));
    }

    _lastRequestTime = currentTime;
    _requestCount++;
  }

  Future<Map<String, dynamic>?> getAllRates() async {
    try {
      // Check cache first
      final cachedRates = await _cacheManager.getCachedExchangeRates();
      if (cachedRates != null) {
        return cachedRates;
      }

      await _rateLimitCheck();

      final response = await http
          .get(Uri.parse(_baseUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['result'] == 'success') {
          // Cache the response
          await _cacheManager.cacheExchangeRates(data);
          return data;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<double?> getRealTimeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      // Use enhanced calculator for high-volatility pairs
      if ((fromCurrency == 'USD' && (toCurrency == 'TRY' || toCurrency == 'CNY' || toCurrency == 'CNH')) ||
          (toCurrency == 'USD' && (fromCurrency == 'TRY' || fromCurrency == 'CNY' || fromCurrency == 'CNH'))) {
        final enhancedRate = await EnhancedForexCalculator.getEnhancedRealTimeRate(fromCurrency, toCurrency);
        if (enhancedRate != null) {
          return enhancedRate;
        }
        // Fallback to standard method if enhanced fails
      }

      final allRatesData = await getAllRates();
      if (allRatesData == null) return null;

      final rates = allRatesData['rates'] as Map<String, dynamic>;

      // Calculate the exchange rate
      double rate;
      if (fromCurrency == 'USD') {
        // Direct rate from USD to target currency
        if (rates.containsKey(toCurrency)) {
          rate = (rates[toCurrency] as num).toDouble();
        } else {
          return null;
        }
      } else {
        // Convert from source currency to USD, then to target currency
        if (rates.containsKey(fromCurrency) && rates.containsKey(toCurrency)) {
          // Convert from_currency to USD, then USD to to_currency
          final usdFromSource =
              1 / (rates[fromCurrency] as num).toDouble(); // Convert to USD
          rate =
              usdFromSource *
              (rates[toCurrency] as num)
                  .toDouble(); // Convert from USD to target
        } else {
          return null;
        }
      }

      return rate;
    } catch (e) {
      return null;
    }
  }

  Future<List<double>> calculatePredictions(
    double currentRate,
    String currency,
    int days,
  ) async {
    // Check cache first
    final cachedPredictions = await _cacheManager.getCachedPrediction(
      currency,
      currentRate,
    );
    if (cachedPredictions != null) {
      return cachedPredictions.take(days).toList();
    }

    List<double> predictions;

    // Use enhanced calculator for high-volatility pairs
    if (currency == 'TRY' || currency == 'CNH' || currency == 'CNY') {
      // Try to get historical data for technical analysis
      List<double>? historicalRates;
      try {
        historicalRates = await _getHistoricalRates(currency);
      } catch (e) {
        // Continue without historical data
      }

      predictions = EnhancedForexCalculator.calculateEnhancedPredictions(
        currentRate,
        currency,
        days,
        historicalRates: historicalRates,
      );
    } else {
      // Use standard calculation for other currencies
      // Start from static characteristics, then refine by ATR% if possible
      CurrencyCharacteristics? characteristics =
          CurrencyCharacteristicsService.characteristics[currency];

      // Refine characteristics using offline ADR%-based service (independent)
      if (characteristics != null) {
        characteristics = await VolatilityService.buildCharacteristicsFromBaseline(
          currency,
          currentRate,
          characteristics,
        );
      }

      predictions = MarketAnalysisService.calculatePredictions(
        currentRate,
        currency,
        days,
        characteristics: characteristics,
      );
    }

    // Cache the predictions
    await _cacheManager.cachePrediction(currency, currentRate, predictions);

    return predictions;
  }

  Future<CurrencyData?> getCurrencyDataWithPredictions(String currency) async {
    if (!_forexPairs.containsKey(currency)) {
      return null;
    }

    final pair = _forexPairs[currency]!;

    // Determine from/to currencies
    String fromCurr, toCurr;
    if (pair.endsWith('USD')) {
      fromCurr = pair.substring(0, 3);
      toCurr = 'USD';
    } else {
      fromCurr = 'USD';
      toCurr = pair.substring(3);
    }

    // Get real-time rate
    final rate = await getRealTimeRate(fromCurr, toCurr);
    if (rate == null) return null;

    // Calculate predictions
    final predictions = await calculatePredictions(rate, currency, 7);

    // Calculate tomorrow and week predictions
    final tomorrowPrediction = predictions[0];
    final weekPrediction = predictions[6];

    // Calculate changes
    final tomorrowChange = tomorrowPrediction - rate;
    final tomorrowChangePercent = (tomorrowChange / rate) * 100;

    final weekChange = weekPrediction - rate;
    final weekChangePercent = (weekChange / rate) * 100;

    // Determine trends
    final tomorrowTrend = tomorrowChange > 0
        ? 'up'
        : tomorrowChange < 0
        ? 'down'
        : 'stable';
    final weekTrend = weekChange > 0
        ? 'up'
        : weekChange < 0
        ? 'down'
        : 'stable';

    return CurrencyData(
      currency: currency,
      pair: pair,
      currentValue: double.parse(rate.toStringAsFixed(5)),
      tomorrowPrediction: double.parse(tomorrowPrediction.toStringAsFixed(5)),
      weekPrediction: double.parse(weekPrediction.toStringAsFixed(5)),
      tomorrowChange: double.parse(tomorrowChange.toStringAsFixed(5)),
      tomorrowChangePercent: double.parse(
        tomorrowChangePercent.toStringAsFixed(3),
      ),
      weekChange: double.parse(weekChange.toStringAsFixed(5)),
      weekChangePercent: double.parse(weekChangePercent.toStringAsFixed(3)),
      tomorrowTrend: tomorrowTrend,
      weekTrend: weekTrend,
      forecast7Days: predictions
          .map((p) => double.parse(p.toStringAsFixed(5)))
          .toList(),
      lastRefreshed: DateTime.now().toIso8601String(),
      timeZone: 'UTC',
      dataSource: 'ExchangeRate-API Real-Time + Predictions',
    );
  }

  Future<ForexApiResponse> getDashboard() async {
    final currenciesData = <CurrencyData>[];

    for (final currency in _forexPairs.keys) {
      try {
        final currencyData = await getCurrencyDataWithPredictions(currency);
        if (currencyData != null) {
          currenciesData.add(currencyData);
        } else {}
      } catch (e) {}
    }

    return ForexApiResponse(
      status: 'success',
      timestamp: DateTime.now().toIso8601String(),
      currencies: currenciesData,
      totalCurrencies: currenciesData.length,
      predictionMethod: 'Ensemble (Trend + Mean Reversion) - Consistent',
      forecastPeriod: '7 days',
      dataSource: 'ExchangeRate-API Real-Time + Predictive Models',
      apiRequestsToday: _requestCount,
      rateLimitRemaining: _dailyLimit - _requestCount,
      features: {
        'consistent_predictions': true,
        'prediction_caching': true,
        'same_forex_value_same_predictions': true,
      },
    );
  }

  // Getters for external access
  Map<String, String> get forexPairs => _forexPairs;
  int get requestCount => _requestCount;
  int get dailyLimit => _dailyLimit;
  int get rateLimitRemaining => _dailyLimit - _requestCount;

  /// Get historical rates for technical analysis (simulated for now)
  Future<List<double>?> _getHistoricalRates(String currency) async {
    try {
      // For now, generate simulated historical data based on current market conditions
      // In a real implementation, this would fetch actual historical data
      final currentRate = await getRealTimeRate('USD', currency);
      if (currentRate == null) return null;

      final historicalRates = <double>[];
      double rate = currentRate;
      
      // Generate 30 days of historical data (working backwards)
      for (int i = 30; i > 0; i--) {
        final dailyChange = _generateHistoricalChange(currency, i);
        rate *= (1 + dailyChange);
        historicalRates.insert(0, rate);
      }
      
      return historicalRates;
    } catch (e) {
      return null;
    }
  }

  /// Generate realistic historical daily changes for simulation
  double _generateHistoricalChange(String currency, int daysAgo) {
    final random = Random(currency.hashCode + daysAgo);
    
    double baseVolatility;
    switch (currency) {
      case 'TRY':
        baseVolatility = 0.025; // 2.5% daily volatility
        break;
      case 'CNH':
      case 'CNY':
        baseVolatility = 0.008; // 0.8% daily volatility
        break;
      default:
        baseVolatility = 0.01; // 1% default
    }
    
    // Generate realistic daily change with some trend
    final trendComponent = sin(daysAgo * 0.1) * baseVolatility * 0.3;
    final randomComponent = (random.nextDouble() - 0.5) * baseVolatility * 2;
    
    return trendComponent + randomComponent;
  }

  // No external conversions needed in offline mode
}
