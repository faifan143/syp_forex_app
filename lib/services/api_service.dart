import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_responses.dart';
// Debug config removed - using simple logging

class ApiService {
  static const String baseUrl = 'http://192.168.74.20:5000';
  
  // For production, replace with actual server URL
  // static const String baseUrl = 'https://your-server.com';

  // Debug logging configuration
  static const String _logTag = '🔗 API_SERVICE';

  // Helper method for debug logging
  static void _log(String message, {String? method, String? endpoint, dynamic data, String level = 'info'}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$_logTag] [$timestamp] ${method != null ? '[$method] ' : ''}${endpoint != null ? '[$endpoint] ' : ''}$message';
    
    developer.log(logMessage, name: 'SYP_Forex_App');
    print(logMessage);
    

  }

  // Get current rates for a specific city
  static Future<CurrentRatesResponse> getCurrentRates(String city) async {
    final method = 'getCurrentRates';
    final endpoint = '/api/current/$city';
    
    try {
      _log('🚀 Starting request', method: method, endpoint: endpoint, level: 'info');
      _log('📍 Target city: $city', method: method, level: 'debug');
      _log('🌐 Full URL: $baseUrl$endpoint', method: method, level: 'debug');
      
      if (true) { // Always log network requests
        _log('📡 Making HTTP GET request', method: method, level: 'debug');
      }
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) { // Always log network responses
        _log('✅ Response received', method: method, endpoint: endpoint, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) { // Always log response time
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }
      
      if (true) { // Always log response size
        _log('📏 Response Size: ${response.body.length} characters', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          if (true) { // Always log JSON parsing
            _log('🔍 Parsing JSON response...', method: method, level: 'debug');
          }
          
          final jsonData = json.decode(response.body);
          _log('🔍 JSON parsed successfully', method: method, endpoint: endpoint, level: 'info');
          
          if (true) { // Always log data validation
            _log('📋 Response keys: ${jsonData.keys.toList()}', method: method, level: 'debug');
          }
          
          if (true) { // Always log data models
            _log('🎯 Creating CurrentRatesResponse model...', method: method, level: 'debug');
          }
          
          final result = CurrentRatesResponse.fromJson(jsonData);
          _log('🎯 Data model created successfully', method: method, endpoint: endpoint, level: 'info');
          _log('🏙️ City: ${result.city}', method: method, level: 'debug');
          _log('💱 Rate: ${result.currentRates.mid}', method: method, level: 'debug');
          
          return result;
        } catch (parseError) {
          _log('❌ JSON parsing failed', method: method, endpoint: endpoint, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          
          if (true) { // Always log network errors
            _log('📄 Raw response: ${response.body}', method: method, level: 'error');
          }
          
          throw Exception('Failed to parse response: $parseError');
        }
      } else {
        _log('❌ HTTP error', method: method, endpoint: endpoint, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        
        if (true) { // Always log network errors
          _log('📄 Error body: ${response.body}', method: method, level: 'error');
        }
        
        throw Exception('Failed to load current rates: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 Request failed', method: method, endpoint: endpoint, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      
      if (true) { // Always log network errors
        if (e is http.ClientException) {
          _log('🌐 Network error - check server connectivity', method: method, level: 'warning');
        } else if (e is SocketException) {
          _log('🔌 Socket error - server may be unreachable', method: method, level: 'warning');
        } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
          _log('⏰ Request timeout - server may be slow', method: method, level: 'warning');
        }
      }
      
      throw Exception('Network error: $e');
    }
  }

  // Get forecast for specific number of days ahead
  static Future<ForecastResponse> getForecast(int days, String city) async {
    final method = 'getForecast';
    final endpoint = '/api/forecast/$days/$city';
    
    try {
      _log('🚀 Starting forecast request', method: method, endpoint: endpoint, level: 'info');
      _log('📅 Days ahead: $days', method: method, level: 'debug');
      _log('📍 Target city: $city', method: method, level: 'debug');
      _log('🌐 Full URL: $baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) { // Always log network responses
        _log('✅ Forecast response received', method: method, endpoint: endpoint, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) { // Always log response time
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 Forecast JSON parsed successfully', method: method, endpoint: endpoint, level: 'info');
          
          final result = ForecastResponse.fromJson(jsonData);
          _log('🎯 Forecast model created successfully', method: method, endpoint: endpoint, level: 'info');
          _log('📅 Forecast date: ${result.forecastDate}', method: method, level: 'debug');
          _log('🔮 Predicted rate: ${result.prediction.rate}', method: method, level: 'debug');
          
          return result;
        } catch (parseError) {
          _log('❌ Forecast JSON parsing failed', method: method, endpoint: endpoint, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          throw Exception('Failed to parse forecast response: $parseError');
        }
      } else {
        _log('❌ Forecast HTTP error', method: method, endpoint: endpoint, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        throw Exception('Failed to load forecast: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 Forecast request failed', method: method, endpoint: endpoint, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      throw Exception('Network error: $e');
    }
  }

  // Get batch forecast for multiple days
  static Future<BatchForecastResponse> getBatchForecast(int days) async {
    final method = 'getBatchForecast';
    final endpoint = '/api/batch-forecast/$days';
    
    try {
      _log('🚀 Starting batch forecast request', method: method, endpoint: endpoint, level: 'info');
      _log('📅 Days: $days', method: method, level: 'debug');
      _log('🌐 Full URL: $baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) { // Always log network responses
        _log('✅ Batch forecast response received', method: method, endpoint: endpoint, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) { // Always log response time
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 Batch forecast JSON parsed successfully', method: method, endpoint: endpoint, level: 'info');
          
          final result = BatchForecastResponse.fromJson(jsonData);
          _log('🎯 Batch forecast model created successfully', method: method, endpoint: endpoint, level: 'info');
          _log('📊 Number of forecasts: ${result.forecasts.length}', method: method, level: 'debug');
          _log('💱 Current rate: ${result.currentRate}', method: method, level: 'debug');
          
          return result;
        } catch (parseError) {
          _log('❌ Batch forecast JSON parsing failed', method: method, endpoint: endpoint, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          throw Exception('Failed to parse batch forecast response: $parseError');
        }
      } else {
        _log('❌ Batch forecast HTTP error', method: method, endpoint: endpoint, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        throw Exception('Failed to load batch forecast: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 Batch forecast request failed', method: method, endpoint: endpoint, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      throw Exception('Network error: $e');
    }
  }

  // Get city comparison data
  static Future<ComparisonResponse> getCityComparison() async {
    final method = 'getCityComparison';
    const endpoint = '/api/comparison';
    
    try {
      _log('🚀 Starting city comparison request', method: method, endpoint: endpoint, level: 'info');
      _log('🌐 Full URL: $baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) { // Always log network responses
        _log('✅ City comparison response received', method: method, endpoint: endpoint, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) { // Always log response time
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 City comparison JSON parsed successfully', method: method, endpoint: endpoint, level: 'info');
          
          final result = ComparisonResponse.fromJson(jsonData);
          _log('🎯 City comparison model created successfully', method: method, endpoint: endpoint, level: 'info');
          _log('🏙️ Cities reporting: ${result.cities.length}', method: method, level: 'debug');
          _log('📊 Average rate: ${result.statistics.averageRate}', method: method, level: 'debug');
          
          return result;
        } catch (parseError) {
          _log('❌ City comparison JSON parsing failed', method: method, endpoint: endpoint, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          throw Exception('Failed to parse city comparison response: $parseError');
        }
      } else {
        _log('❌ City comparison HTTP error', method: method, endpoint: endpoint, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        throw Exception('Failed to load city comparison: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 City comparison request failed', method: method, endpoint: endpoint, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      throw Exception('Network error: $e');
    }
  }

  // Get OHLCV data for a specific city
  static Future<Map<String, dynamic>> getOHLCV(String city) async {
    final method = 'getOHLCV';
    final endpoint = '/api/ohlcv/$city';
    
    try {
      _log('🚀 Starting OHLCV request', method: method, endpoint: endpoint, level: 'info');
      _log('📍 Target city: $city', method: method, level: 'debug');
      _log('🌐 Full URL: $baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) { // Always log network responses
        _log('✅ OHLCV response received', method: method, endpoint: endpoint, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) { // Always log response time
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 OHLCV JSON parsed successfully', method: method, endpoint: endpoint, level: 'info');
          
          if (true) { // Always log data validation
            _log('📊 OHLCV data keys: ${jsonData.keys.toList()}', method: method, level: 'debug');
          }
          
          return jsonData;
        } catch (parseError) {
          _log('❌ OHLCV JSON parsing failed', method: method, endpoint: endpoint, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          throw Exception('Failed to parse OHLCV response: $parseError');
        }
      } else {
        _log('❌ OHLCV HTTP error', method: method, endpoint: endpoint, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        throw Exception('Failed to load OHLCV data: ${response.statusCode}');
      }
    } catch (e) {
      _log('💥 OHLCV request failed', method: method, endpoint: endpoint, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      throw Exception('Network error: $e');
    }

  }

  // Get available cities
  static List<String> getAvailableCities() {
    _log('🏙️ Getting available cities: [damascus]', level: 'debug');
    return ['damascus'];
  }

  // Get default city
  static String getDefaultCity() {
    _log('📍 Getting default city: damascus', level: 'debug');
    return 'damascus';
  }

  // Test basic connection to the server
  static Future<bool> testBasicConnection() async {
    const method = 'testBasicConnection';
    _log('🧪 Testing basic connection to server', method: method, level: 'info');
    
    try {
      final startTime = DateTime.now();
      
      // Try a simple GET request to the root endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _log('⏰ Basic connection test timed out', method: method, level: 'warning');
          throw Exception('Basic connection test timed out');
        },
      );
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      _log('📥 Basic connection response: ${response.statusCode}', method: method, level: 'info');
      _log('⏱️ Connection time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      
      return response.statusCode == 200;
    } catch (e) {
      _log('❌ Basic connection test failed', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      return false;
    }
  }

  // Test connection to server
  static Future<bool> testConnection() async {
    const method = 'testConnection';
    const endpoint = '/health';
    
    try {
      _log('🧪 Testing server connection', method: method, endpoint: endpoint, level: 'info');
      _log('🌐 Full URL: $baseUrl$endpoint', method: method, level: 'debug');
      
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (true) { // Always log network responses
        _log('✅ Health check response received', method: method, endpoint: endpoint, level: 'info');
        _log('📊 Status Code: ${response.statusCode}', method: method, level: 'debug');
      }
      
      if (true) { // Always log response time
        _log('⏱️ Response Time: ${duration.inMilliseconds}ms', method: method, level: 'debug');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 Health check JSON parsed successfully', method: method, endpoint: endpoint, level: 'info');
          _log('💚 Server status: ${jsonData['status']}', method: method, level: 'debug');
          _log('📝 Server message: ${jsonData['message']}', method: method, level: 'debug');
          
          return true;
        } catch (parseError) {
          _log('❌ Health check JSON parsing failed', method: method, endpoint: endpoint, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          return false;
        }
      } else {
        _log('❌ Health check HTTP error', method: method, endpoint: endpoint, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        return false;
      }
    } catch (e) {
      _log('💥 Health check failed', method: method, endpoint: endpoint, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      return false;
    }
  }

  // Get server info
  static Future<Map<String, dynamic>?> getServerInfo() async {
    const method = 'getServerInfo';
    const endpoint = '/';
    
    try {
      _log('ℹ️ Getting server info', method: method, endpoint: endpoint, level: 'info');
      _log('🌐 Full URL: $baseUrl$endpoint', method: method, level: 'debug');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          _log('🔍 Server info JSON parsed successfully', method: method, endpoint: endpoint, level: 'info');
          
          if (true) { // Always log data validation
            _log('📋 Server info keys: ${jsonData.keys.toList()}', method: method, level: 'debug');
          }
          
          _log('🏷️ Server name: ${jsonData['name']}', method: method, level: 'debug');
          _log('📦 Version: ${jsonData['version']}', method: method, level: 'debug');
          
          return jsonData;
        } catch (parseError) {
          _log('❌ Server info JSON parsing failed', method: method, endpoint: endpoint, level: 'error');
          _log('🚨 Parse error: $parseError', method: method, level: 'error');
          return null;
        }
      } else {
        _log('❌ Server info HTTP error', method: method, endpoint: endpoint, level: 'error');
        _log('🚨 Status: ${response.statusCode}', method: method, level: 'error');
        return null;
      }
    } catch (e) {
      _log('💥 Server info request failed', method: method, endpoint: endpoint, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      return null;
    }
  }
}

