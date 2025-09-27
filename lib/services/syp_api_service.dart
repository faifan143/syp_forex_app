import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
// Debug config removed - using simple logging
import '../models/api_responses.dart';
import '../models/metadata.dart';
import 'api_config_service.dart';

class SypApiService {
  static const String _logTag = '🇸🇾 SYP_API';

  // Helper method for debug logging
  static void _log(
    String message, {
    String? method,
    dynamic data,
    String level = 'info',
  }) {
    // Always log for now

    final timestamp = DateTime.now().toIso8601String();
    final logMessage =
        '[$_logTag] [$timestamp] ${method != null ? '[$method] ' : ''}$message';

    developer.log(logMessage, name: 'SYP_Forex_App');
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    const method = 'healthCheck';

    try {
      _log('🚀 Checking SYP API health', method: method, level: 'info');

      final response = await http
          .get(
            Uri.parse(ApiConfigService.getSypApiUrl('/health')),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log(
          '✅ SYP API health check successful',
          method: method,
          level: 'info',
        );
        return jsonData;
      } else {
        throw Exception('SYP API health check failed: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ SYP API health check failed: $e', method: method, level: 'error');
      throw Exception('SYP API health check error: $e');
    }
  }

  // Get current rates
  static Future<Map<String, dynamic>> getCurrentRates({String? city}) async {
    const method = 'getCurrentRates';
    final endpoint = city != null ? '/api/current/$city' : '/api/current';

    try {
      _log(
        '🚀 Getting current SYP rates${city != null ? ' for $city' : ''}',
        method: method,
        level: 'info',
      );

      final response = await http
          .get(
            Uri.parse(ApiConfigService.getSypApiUrl(endpoint)),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log(
          '✅ Current rates retrieved successfully',
          method: method,
          level: 'info',
        );
        return jsonData;
      } else {
        throw Exception('Failed to get current rates: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Failed to get current rates: $e', method: method, level: 'error');
      throw Exception('Current rates error: $e');
    }
  }

  // Get forecast
  static Future<Map<String, dynamic>> getForecast({
    int? days,
    String? city,
  }) async {
    const method = 'getForecast';
    String endpoint = '/api/forecast';
    if (days != null) endpoint += '/$days';
    if (city != null) endpoint += '/$city';

    try {
      _log(
        '🚀 Getting SYP forecast${days != null ? ' for $days days' : ''}${city != null ? ' for $city' : ''}',
        method: method,
        level: 'info',
      );

      final response = await http
          .get(
            Uri.parse(ApiConfigService.getSypApiUrl(endpoint)),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log(
          '✅ Forecast retrieved successfully',
          method: method,
          level: 'info',
        );
        return jsonData;
      } else {
        throw Exception('Failed to get forecast: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Failed to get forecast: $e', method: method, level: 'error');
      throw Exception('Forecast error: $e');
    }
  }

  // Get ask/bid forecast
  static Future<Map<String, dynamic>> getAskBidForecast({
    int? days,
    String? city,
  }) async {
    const method = 'getAskBidForecast';
    String endpoint = '/api/ask-bid-forecast';
    if (days != null) endpoint += '/$days';
    if (city != null) endpoint += '/$city';

    try {
      _log(
        '🚀 Getting ask/bid forecast${days != null ? ' for $days days' : ''}${city != null ? ' for $city' : ''}',
        method: method,
        level: 'info',
      );

      final response = await http
          .get(
            Uri.parse(ApiConfigService.getSypApiUrl(endpoint)),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log(
          '✅ Ask/bid forecast retrieved successfully',
          method: method,
          level: 'info',
        );
        return jsonData;
      } else {
        throw Exception(
          'Failed to get ask/bid forecast: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log(
        '❌ Failed to get ask/bid forecast: $e',
        method: method,
        level: 'error',
      );
      throw Exception('Ask/bid forecast error: $e');
    }
  }

  // Get OHLCV data
  static Future<Map<String, dynamic>> getOhlcvData({String? city}) async {
    const method = 'getOhlcvData';
    final endpoint = city != null ? '/api/ohlcv/$city' : '/api/ohlcv';

    try {
      _log(
        '🚀 Getting OHLCV data${city != null ? ' for $city' : ''}',
        method: method,
        level: 'info',
      );

      final response = await http
          .get(
            Uri.parse(ApiConfigService.getSypApiUrl(endpoint)),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log(
          '✅ OHLCV data retrieved successfully',
          method: method,
          level: 'info',
        );
        return jsonData;
      } else {
        throw Exception('Failed to get OHLCV data: ${response.statusCode}');
      }
    } catch (e) {
      _log('❌ Failed to get OHLCV data: $e', method: method, level: 'error');
      throw Exception('OHLCV data error: $e');
    }
  }

  // Get city comparison
  static Future<Map<String, dynamic>> getCityComparison() async {
    const method = 'getCityComparison';

    try {
      _log('🚀 Getting city comparison', method: method, level: 'info');

      final response = await http
          .get(
            Uri.parse(ApiConfigService.getSypApiUrl('/api/comparison')),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log(
          '✅ City comparison retrieved successfully',
          method: method,
          level: 'info',
        );
        return jsonData;
      } else {
        throw Exception(
          'Failed to get city comparison: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log(
        '❌ Failed to get city comparison: $e',
        method: method,
        level: 'error',
      );
      throw Exception('City comparison error: $e');
    }
  }

  // Get batch forecast
  static Future<Map<String, dynamic>> getBatchForecast(int days) async {
    const method = 'getBatchForecast';

    try {
      _log(
        '🚀 Getting batch forecast for $days days',
        method: method,
        level: 'info',
      );

      final response = await http
          .get(
            Uri.parse(
              ApiConfigService.getSypApiUrl('/api/batch-forecast/$days'),
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log(
          '✅ Batch forecast retrieved successfully',
          method: method,
          level: 'info',
        );
        return jsonData;
      } else {
        throw Exception('Failed to get batch forecast: ${response.statusCode}');
      }
    } catch (e) {
      _log(
        '❌ Failed to get batch forecast: $e',
        method: method,
        level: 'error',
      );
      throw Exception('Batch forecast error: $e');
    }
  }

  // Convert API response to CurrentRatesResponse
  static CurrentRatesResponse parseCurrentRates(Map<String, dynamic> data) {
    try {
      final currentRates = data['current_rates'] ?? {};
      final ohlcv = data['ohlcv'] ?? {};

      return CurrentRatesResponse(
        success: data['success'] ?? false,
        timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        date: data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
        time:
            data['time'] ??
            DateTime.now().toIso8601String().split('T')[1].split('.')[0],
        pair: data['pair'] ?? 'USD/SYP',
        market: data['market'] ?? 'black_market',
        city: data['city'] ?? 'aleppo',
        currentRates: CurrentRates(
          ask: (currentRates['ask'] ?? 0.0).toDouble(),
          bid: (currentRates['bid'] ?? 0.0).toDouble(),
          mid: (currentRates['mid'] ?? 0.0).toDouble(),
          spread: (currentRates['spread'] ?? 0.0).toDouble(),
          change: (currentRates['change'] ?? 0.0).toDouble(),
          changePercentage: (currentRates['change_percentage'] ?? 0.0)
              .toDouble(),
        ),
        ohlcv: OHLCV(
          open: (ohlcv['open'] ?? 0.0).toDouble(),
          high: (ohlcv['high'] ?? 0.0).toDouble(),
          low: (ohlcv['low'] ?? 0.0).toDouble(),
          close: (ohlcv['close'] ?? 0.0).toDouble(),
          volume: (ohlcv['volume'] ?? 0.0).toDouble(),
          dayType: ohlcv['day_type'] ?? 'calm',
        ),
        metadata: Metadata(
          source: data['metadata']?['source'] ?? 'sp-today',
          approach: data['metadata']?['approach'] ?? '70% calm / 30% normal',
          lastUpdated:
              data['metadata']?['last_updated'] ??
              DateTime.now().toIso8601String(),
        ),
      );
    } catch (e) {
      _log('❌ Failed to parse current rates: $e', level: 'error');
      throw Exception('Failed to parse current rates: $e');
    }
  }

  // Convert API response to ForecastResponse
  static ForecastResponse parseForecast(Map<String, dynamic> data) {
    try {
      final prediction = data['prediction'] ?? {};
      // final spreadAnalysis = data['spread_analysis'] ?? {};
      final predictedOhlcv = data['predicted_ohlcv'] ?? {};
      final forecastMethod = data['forecast_method'] ?? {};
      final basedOn = data['based_on'] ?? {};

      return ForecastResponse(
        success: data['success'] ?? false,
        timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        forecastDate:
            data['forecast_date'] ??
            DateTime.now()
                .add(const Duration(days: 1))
                .toIso8601String()
                .split('T')[0],
        daysAhead: data['days_ahead'] ?? 1,
        pair: data['pair'] ?? 'USD/SYP',
        market: data['market'] ?? 'black_market_forecast',
        city: data['city'] ?? 'aleppo',
        prediction: Prediction(
          rate: (prediction['rate'] ?? 0.0).toDouble(),
          ask: (prediction['ask'] ?? 0.0).toDouble(),
          bid: (prediction['bid'] ?? 0.0).toDouble(),
          spread: (prediction['spread'] ?? 0.0).toDouble(),
          confidenceInterval: ConfidenceInterval(
            lower: (prediction['confidence_interval']?['lower'] ?? 0.0)
                .toDouble(),
            upper: (prediction['confidence_interval']?['upper'] ?? 0.0)
                .toDouble(),
            rangePct: (prediction['confidence_interval']?['range_pct'] ?? 0.0)
                .toDouble(),
          ),
          expectedChange: (prediction['expected_change'] ?? 0.0).toDouble(),
          dayType: prediction['day_type'] ?? 'calm',
        ),

        predictedOhlcv: OHLCV(
          open: (predictedOhlcv['open'] ?? 0.0).toDouble(),
          high: (predictedOhlcv['high'] ?? 0.0).toDouble(),
          low: (predictedOhlcv['low'] ?? 0.0).toDouble(),
          close: (predictedOhlcv['close'] ?? 0.0).toDouble(),
          volume: (predictedOhlcv['volume'] ?? 0.0).toDouble(),
          dayType: predictedOhlcv['day_type'] ?? 'calm',
        ),
        forecastMethod: ForecastMethod(
          type: forecastMethod['type'] ?? 'enhanced_forecast_with_ask_bid',
          approach: forecastMethod['approach'] ?? '70% calm / 30% normal',
          description:
              forecastMethod['description'] ??
              'Enhanced forecast with ask/bid predictions',
          confidence: forecastMethod['confidence'] ?? 'low',
          spreadPrediction:
              forecastMethod['spread_prediction'] ??
              'Based on current spread and day-type volatility',
        ),
        basedOn: basedOn,
      );
    } catch (e) {
      _log('❌ Failed to parse forecast: $e', level: 'error');
      throw Exception('Failed to parse forecast: $e');
    }
  }

  // Get available cities
  static List<String> getAvailableCities() {
    return ['aleppo', 'damascus', 'idlib'];
  }
}
