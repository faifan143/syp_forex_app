import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
// Debug config removed - using simple logging

class ForexApiService {
  static const String _apiKey = 'BA5NW8DI2HWTODRB';
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  static const String _logTag = '🌐 FOREX_API';

  // Helper method for debug logging
  static void _log(String message, {String? method, dynamic data, String level = 'info'}) {
    // Always log
    
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$_logTag] [$timestamp] ${method != null ? '[$method] ' : ''}$message';
    
    developer.log(logMessage, name: 'SYP_Forex_App');
    print(logMessage);
    
    if (data != null && true) {
      print('[$_logTag] Data: ${json.encode(data)}');
    }
  }

  // Get real-time forex data for a currency pair
  static Future<Map<String, dynamic>> getForexData(String fromCurrency, String toCurrency) async {
    const method = 'getForexData';
    final endpoint = '?function=CURRENCY_EXCHANGE_RATE&from_currency=$fromCurrency&to_currency=$toCurrency&apikey=$_apiKey';
    
    try {
      _log('🚀 Getting forex data for $fromCurrency/$toCurrency', method: method, level: 'info');
      _log('🌐 Full URL: $_baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) {
        _log('✅ Forex data received', method: method, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) {
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 Forex JSON parsed successfully', method: method, level: 'info');
          
          if (true) {
            _log('📋 Response keys: ${jsonData.keys.toList()}', method: method, level: 'debug');
          }
          
          return jsonData;
        } catch (parseError) {
          _log('❌ Forex JSON parsing failed', method: method, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          throw Exception('Failed to parse forex response: $parseError');
        }
      } else {
        _log('❌ Forex HTTP error', method: method, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        throw Exception('Failed to load forex data: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 Forex request failed', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      throw Exception('Network error: $e');
    }
  }

  // Get intraday forex data for candlestick charts
  static Future<Map<String, dynamic>> getIntradayData(String fromCurrency, String toCurrency, String interval) async {
    const method = 'getIntradayData';
    final endpoint = '?function=FX_INTRADAY&from_symbol=$fromCurrency&to_symbol=$toCurrency&interval=$interval&apikey=$_apiKey';
    
    try {
      _log('🚀 Getting intraday data for $fromCurrency/$toCurrency ($interval)', method: method, level: 'info');
      _log('🌐 Full URL: $_baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) {
        _log('✅ Intraday data received', method: method, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) {
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 Intraday JSON parsed successfully', method: method, level: 'info');
          
          if (true) {
            _log('📋 Response keys: ${jsonData.keys.toList()}', method: method, level: 'debug');
          }
          
          return jsonData;
        } catch (parseError) {
          _log('❌ Intraday JSON parsing failed', method: method, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          throw Exception('Failed to parse intraday response: $parseError');
        }
      } else {
        _log('❌ Intraday HTTP error', method: method, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        throw Exception('Failed to load intraday data: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 Intraday request failed', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      throw Exception('Network error: $e');
    }
  }

  // Get daily forex data
  static Future<Map<String, dynamic>> getDailyData(String fromCurrency, String toCurrency) async {
    const method = 'getDailyData';
    final endpoint = '?function=FX_DAILY&from_symbol=$fromCurrency&to_symbol=$toCurrency&apikey=$_apiKey';
    
    try {
      _log('🚀 Getting daily data for $fromCurrency/$toCurrency', method: method, level: 'info');
      _log('🌐 Full URL: $_baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) {
        _log('✅ Daily data received', method: method, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) {
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 Daily JSON parsed successfully', method: method, level: 'info');
          
          if (true) {
            _log('📋 Response keys: ${jsonData.keys.toList()}', method: method, level: 'debug');
          }
          
          return jsonData;
        } catch (parseError) {
          _log('❌ Daily JSON parsing failed', method: method, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          throw Exception('Failed to parse daily response: $parseError');
        }
      } else {
        _log('❌ Daily HTTP error', method: method, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        throw Exception('Failed to load daily data: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 Daily request failed', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      throw Exception('Network error: $e');
    }
  }

  // Get available currency pairs
  static List<Map<String, String>> getAvailablePairs() {
    return [
      {'from': 'USD', 'to': 'EUR', 'symbol': 'USD/EUR'},
      {'from': 'EUR', 'to': 'USD', 'symbol': 'EUR/USD'},
      {'from': 'GBP', 'to': 'USD', 'symbol': 'GBP/USD'},
      {'from': 'USD', 'to': 'JPY', 'symbol': 'USD/JPY'},
      {'from': 'USD', 'to': 'CHF', 'symbol': 'USD/CHF'},
      {'from': 'AUD', 'to': 'USD', 'symbol': 'AUD/USD'},
      {'from': 'USD', 'to': 'CAD', 'symbol': 'USD/CAD'},
    ];
  }

  // Get available timeframes
  static List<Map<String, String>> getAvailableTimeframes() {
    return [
      {'value': '1min', 'label': '1 Minute'},
      {'value': '5min', 'label': '5 Minutes'},
      {'value': '15min', 'label': '15 Minutes'},
      {'value': '30min', 'label': '30 Minutes'},
      {'value': '60min', 'label': '1 Hour'},
      {'value': 'daily', 'label': 'Daily'},
    ];
  }
}



