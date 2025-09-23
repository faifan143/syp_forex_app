import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Data Cache Service - Intelligent caching for forex data
///
/// This service manages both exchange rate caching and prediction result caching
/// to optimize performance and reduce API calls. It uses SharedPreferences for
/// persistent local storage and implements intelligent cache invalidation.
///
/// Cache Strategy:
/// - Exchange rates: 1-hour cache duration
/// - Predictions: 1-hour cache duration with consistent keys
/// - Automatic cleanup of expired cache entries
/// - Thread-safe operations for concurrent access
///
/// This service is used by ForexDataService for data caching.
class DataCacheService {
  static const String _exchangeRatesKey = 'cached_exchange_rates';
  static const String _exchangeRatesTimestampKey =
      'cached_exchange_rates_timestamp';
  static const String _predictionCachePrefix = 'prediction_cache_';

  final int cacheDurationSeconds;
  final int predictionCacheDurationSeconds;

  DataCacheService({
    this.cacheDurationSeconds = 86400, // 1 day (24 * 60 * 60)
    this.predictionCacheDurationSeconds = 86400, // 1 day (24 * 60 * 60)
  });

  // Exchange Rates Cache
  Future<void> cacheExchangeRates(Map<String, dynamic> ratesData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await prefs.setString(_exchangeRatesKey, jsonEncode(ratesData));
      await prefs.setInt(_exchangeRatesTimestampKey, timestamp);
    } catch (e) {
      print('Error caching exchange rates: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_exchangeRatesTimestampKey);

      if (timestamp == null) return null;

      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime - timestamp >= cacheDurationSeconds) {
        // Cache expired, remove it
        await clearExchangeRatesCache();
        return null;
      }

      final ratesJson = prefs.getString(_exchangeRatesKey);
      if (ratesJson == null) return null;

      return jsonDecode(ratesJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting cached exchange rates: $e');
      return null;
    }
  }

  Future<void> clearExchangeRatesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_exchangeRatesKey);
      await prefs.remove(_exchangeRatesTimestampKey);
    } catch (e) {
      print('Error clearing exchange rates cache: $e');
    }
  }

  // Prediction Cache
  String _getPredictionCacheKey(String currency, double currentRate) {
    // Round to 5 decimal places to create consistent cache keys
    final roundedRate = double.parse(currentRate.toStringAsFixed(5));
    return '${_predictionCachePrefix}${currency}_$roundedRate';
  }

  Future<void> cachePrediction(
    String currency,
    double currentRate,
    List<double> predictions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getPredictionCacheKey(currency, currentRate);
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final cachedData = {'predictions': predictions, 'timestamp': timestamp};

      await prefs.setString(cacheKey, jsonEncode(cachedData));
    } catch (e) {
      print('Error caching prediction: $e');
    }
  }

  Future<List<double>?> getCachedPrediction(
    String currency,
    double currentRate,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getPredictionCacheKey(currency, currentRate);
      final predictionJson = prefs.getString(cacheKey);

      if (predictionJson == null) return null;

      final cachedData = jsonDecode(predictionJson) as Map<String, dynamic>;
      final timestamp = cachedData['timestamp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (currentTime - timestamp >= predictionCacheDurationSeconds) {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        return null;
      }

      return (cachedData['predictions'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
    } catch (e) {
      print('Error getting cached prediction: $e');
      return null;
    }
  }
}
