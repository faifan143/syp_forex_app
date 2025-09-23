/// Forex API Integration Service
///
/// This service handles the integration with the Forex API server.
/// The server provides real-time forex data and ML predictions.
///
/// API Endpoints:
/// - GET /forex/dashboard - Get comprehensive dashboard data
/// - GET /health - Health check endpoint
/// - GET /forex/currencies - Get available currencies
/// - GET /forex/predictions/{currency} - Get specific currency predictions
/// - POST /forex/refresh - Force refresh of data
///
/// The server uses advanced ML models including LSTM neural networks,
/// Transformer models, and ensemble methods for accurate predictions.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';

class ForexApiIntegration {
  static const String _logTag = '🌐 FOREX_API';

  /// Test connection to the Forex API server
  /// This method verifies that the Forex API server is running and accessible
  static Future<bool> testServerConnection() async {
    try {
      final url = ServerConfig.getForexApiUrl(ServerConfig.forexHealthEndpoint);
      print('$_logTag Testing connection to Forex API server: $url');

      final response = await http
          .get(Uri.parse(url), headers: ServerConfig.defaultHeaders)
          .timeout(Duration(seconds: ServerConfig.healthCheckTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('$_logTag ✅ Forex API server is running');
        print('$_logTag Server version: ${data['version'] ?? 'unknown'}');
        print('$_logTag Server uptime: ${data['uptime'] ?? 'unknown'}');
        return true;
      } else {
        print(
          '$_logTag ❌ Forex API server returned error: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('$_logTag ❌ Failed to connect to Forex API server: $e');
      return false;
    }
  }

  /// Get server health status
  /// This method retrieves detailed health information from the Forex API server
  static Future<Map<String, dynamic>?> getServerHealth() async {
    try {
      final url = ServerConfig.getForexApiUrl(ServerConfig.forexHealthEndpoint);
      print('$_logTag Getting server health from: $url');

      final response = await http
          .get(Uri.parse(url), headers: ServerConfig.defaultHeaders)
          .timeout(Duration(seconds: ServerConfig.healthCheckTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('$_logTag ✅ Server health retrieved successfully');
        return data;
      } else {
        print('$_logTag ❌ Failed to get server health: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('$_logTag ❌ Error getting server health: $e');
      return null;
    }
  }

  /// Get available currencies from the Forex API server
  /// This method retrieves the list of supported currencies
  static Future<List<String>?> getAvailableCurrencies() async {
    try {
      final url = ServerConfig.getForexApiUrl('/forex/currencies');
      print('$_logTag Getting available currencies from: $url');

      final response = await http
          .get(Uri.parse(url), headers: ServerConfig.defaultHeaders)
          .timeout(Duration(seconds: ServerConfig.defaultTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final currencies = (data['currencies'] as List<dynamic>)
            .map((c) => c.toString())
            .toList();
        print('$_logTag ✅ Retrieved ${currencies.length} currencies');
        return currencies;
      } else {
        print('$_logTag ❌ Failed to get currencies: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('$_logTag ❌ Error getting currencies: $e');
      return null;
    }
  }

  /// Force refresh of data on the Forex API server
  /// This method triggers a data refresh on the server side
  static Future<bool> forceDataRefresh() async {
    try {
      final url = ServerConfig.getForexApiUrl('/forex/refresh');
      print('$_logTag Forcing data refresh on Forex API server: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ServerConfig.defaultHeaders,
            body: jsonEncode({'force': true}),
          )
          .timeout(Duration(seconds: ServerConfig.defaultTimeout));

      if (response.statusCode == 200) {
        print('$_logTag ✅ Data refresh triggered successfully');
        return true;
      } else {
        print('$_logTag ❌ Failed to refresh data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('$_logTag ❌ Error refreshing data: $e');
      return false;
    }
  }

  /// Get server statistics
  /// This method retrieves performance and usage statistics from the Forex API server
  static Future<Map<String, dynamic>?> getServerStats() async {
    try {
      final url = ServerConfig.getForexApiUrl('/forex/stats');
      print('$_logTag Getting server statistics from: $url');

      final response = await http
          .get(Uri.parse(url), headers: ServerConfig.defaultHeaders)
          .timeout(Duration(seconds: ServerConfig.defaultTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('$_logTag ✅ Server statistics retrieved successfully');
        return data;
      } else {
        print('$_logTag ❌ Failed to get server stats: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('$_logTag ❌ Error getting server stats: $e');
      return null;
    }
  }

  /// Check if the Forex API server is running
  /// This method performs a quick health check
  static Future<bool> isServerRunning() async {
    try {
      final url = ServerConfig.getForexApiUrl(ServerConfig.forexHealthEndpoint);
      final response = await http
          .get(Uri.parse(url), headers: ServerConfig.defaultHeaders)
          .timeout(Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get server configuration
  /// This method retrieves the current server configuration
  static Map<String, dynamic> getServerConfig() {
    return {
      'host': ServerConfig.forexApiHost,
      'port': ServerConfig.forexApiPort,
      'timeout': ServerConfig.defaultTimeout,
      'retries': ServerConfig.maxRetries,
      'rate_limit_per_minute': ServerConfig.rateLimitPerMinute,
      'rate_limit_per_day': ServerConfig.rateLimitPerDay,
      'model_version': ServerConfig.modelVersion,
      'prediction_days': ServerConfig.predictionDays,
      'environment': ServerConfig.environment,
      'is_production': ServerConfig.isProduction,
    };
  }
}
