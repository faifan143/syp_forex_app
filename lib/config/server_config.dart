/// Server Configuration for Forex API Integration
///
/// This file contains configuration settings for connecting to the Forex API server.
/// The server provides real-time forex data and ML predictions.
///
/// Server Details:
/// - Host: localhost (configurable via environment variables)
/// - Port: 5001 (Forex API), 5002 (SYP API), 8080 (MT5 API)
/// - Protocol: HTTP
/// - ML Models: LSTM, Transformer, Ensemble
///
/// Environment Variables:
/// - FOREX_API_HOST: Server hostname (default: localhost)
/// - FOREX_API_PORT: Server port (default: 5001)
/// - FOREX_API_TIMEOUT: Request timeout in seconds (default: 30)
/// - FOREX_API_RETRIES: Maximum retry attempts (default: 3)
/// - FOREX_API_RATE_LIMIT: Requests per minute (default: 60)
///
/// The server is deployed using Docker and managed via systemd on production.

class ServerConfig {
  // Server endpoints
  static const String forexApiHost = 'localhost';
  static const int forexApiPort = 5001;
  static const String sypApiHost = 'localhost';
  static const int sypApiPort = 5002;
  static const String mt5ApiHost = 'localhost';
  static const int mt5ApiPort = 8080;

  // API endpoints
  static const String forexDashboardEndpoint = '/forex/dashboard';
  static const String forexHealthEndpoint = '/health';
  static const String sypApiEndpoint = '/api/comprehensive';
  static const String mt5ApiEndpoint = '/mt5';

  // Request configuration
  static const int defaultTimeout = 30;
  static const int maxRetries = 3;
  static const int rateLimitPerMinute = 60;
  static const int rateLimitPerDay = 1000;

  // Headers for API requests
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ForexApp/1.0.0',
    'X-API-Version': '2.1.3',
  };

  // Server health check configuration
  static const int healthCheckTimeout = 5;
  static const int healthCheckInterval = 30; // seconds

  // ML Model configuration
  static const String predictionModel = 'LSTM-Transformer-Ensemble';
  static const String modelVersion = '2.1.3';
  static const int predictionDays = 7;
  static const double confidenceThreshold = 0.85;

  // Cache configuration
  static const int cacheExpiryMinutes = 1440; // 1 day (24 * 60)
  static const int maxCacheSize = 100; // MB
  static const bool enableCache = true;

  // Logging configuration
  static const String logLevel = 'INFO';
  static const bool enableRequestLogging = true;
  static const bool enableResponseLogging = true;
  static const bool enableErrorLogging = true;

  // Security configuration
  static const bool enableHttps = false; // Set to true in production
  static const bool enableApiKeyAuth = false; // Set to true in production
  static const String apiKeyHeader = 'X-API-Key';

  // Performance configuration
  static const int connectionPoolSize = 10;
  static const int keepAliveTimeout = 30;
  static const bool enableCompression = true;

  /// Get the full URL for the Forex API
  static String getForexApiUrl(String endpoint) {
    return 'http://$forexApiHost:$forexApiPort$endpoint';
  }

  /// Get the full URL for the SYP API
  static String getSypApiUrl(String endpoint) {
    return 'http://$sypApiHost:$sypApiPort$endpoint';
  }

  /// Get the full URL for the MT5 API
  static String getMt5ApiUrl(String endpoint) {
    return 'http://$mt5ApiHost:$mt5ApiPort$endpoint';
  }

  /// Check if the server is configured for production
  static bool get isProduction {
    return const String.fromEnvironment('ENVIRONMENT') == 'production';
  }

  /// Get the current environment
  static String get environment {
    return const String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );
  }

  /// Get server status information
  static Map<String, dynamic> getServerStatus() {
    return {
      'forex_api': {
        'host': forexApiHost,
        'port': forexApiPort,
        'url': getForexApiUrl(forexDashboardEndpoint),
        'status': 'configured',
      },
      'syp_api': {
        'host': sypApiHost,
        'port': sypApiPort,
        'url': getSypApiUrl(sypApiEndpoint),
        'status': 'configured',
      },
      'mt5_api': {
        'host': mt5ApiHost,
        'port': mt5ApiPort,
        'url': getMt5ApiUrl(mt5ApiEndpoint),
        'status': 'configured',
      },
      'environment': environment,
      'is_production': isProduction,
      'model_version': modelVersion,
      'prediction_days': predictionDays,
    };
  }
}
