import 'dart:developer' as developer;

class ApiConfigService {
  static const String _logTag = '⚙️ API_CONFIG';
  
  // Default configurations
  static String _forexApiHost = 'localhost';
  static int _forexApiPort = 5001;
  static String _sypApiHost = 'localhost';
  static int _sypApiPort = 5002;
  static String _mt5ApiHost = 'localhost';
  static int _mt5ApiPort = 8080;
  
  // Getters for API URLs
  static String get forexApiBaseUrl => 'http://$_forexApiHost:$_forexApiPort';
  static String get sypApiBaseUrl => 'http://$_sypApiHost:$_sypApiPort';
  static String get mt5ApiBaseUrl => 'http://$_mt5ApiHost:$_mt5ApiPort/mt5';
  
  // Getters for individual components
  static String get forexApiHost => _forexApiHost;
  static int get forexApiPort => _forexApiPort;
  static String get sypApiHost => _sypApiHost;
  static int get sypApiPort => _sypApiPort;
  static String get mt5ApiHost => _mt5ApiHost;
  static int get mt5ApiPort => _mt5ApiPort;
  
  // Setters for dynamic configuration
  static void setForexApiConfig(String host, int port) {
    _forexApiHost = host;
    _forexApiPort = port;
    _log('Updated Forex API config: $host:$port', level: 'info');
  }
  
  static void setSypApiConfig(String host, int port) {
    _sypApiHost = host;
    _sypApiPort = port;
    _log('Updated SYP API config: $host:$port', level: 'info');
  }
  
  static void setMt5ApiConfig(String host, int port) {
    _mt5ApiHost = host;
    _mt5ApiPort = port;
    _log('Updated MT5 API config: $host:$port', level: 'info');
  }
  
  // Reset to defaults
  static void resetToDefaults() {
    _forexApiHost = 'localhost';
    _forexApiPort = 5001;
    _sypApiHost = 'localhost';
    _sypApiPort = 5002;
    _mt5ApiHost = 'localhost';
    _mt5ApiPort = 8080;
    _log('Reset API configs to defaults', level: 'info');
  }
  
  // Test connection methods
  static String getForexApiUrl(String endpoint) {
    final url = '$forexApiBaseUrl$endpoint';
    _log('Forex API URL: $url', level: 'debug');
    return url;
  }
  
  static String getSypApiUrl(String endpoint) {
    final url = '$sypApiBaseUrl$endpoint';
    _log('SYP API URL: $url', level: 'debug');
    return url;
  }
  
  static String getMt5ApiUrl(String endpoint) {
    final url = '$mt5ApiBaseUrl$endpoint';
    _log('MT5 API URL: $url', level: 'debug');
    return url;
  }
  
  // Configuration validation
  static bool isValidHost(String host) {
    return host.isNotEmpty && 
           (host == 'localhost' || 
            RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(host) ||
            RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(host));
  }
  
  static bool isValidPort(int port) {
    return port > 0 && port <= 65535;
  }
  
  // Get current configuration as map
  static Map<String, dynamic> getCurrentConfig() {
    return {
      'forexApi': {
        'host': _forexApiHost,
        'port': _forexApiPort,
        'baseUrl': forexApiBaseUrl,
      },
      'sypApi': {
        'host': _sypApiHost,
        'port': _sypApiPort,
        'baseUrl': sypApiBaseUrl,
      },
      'mt5Api': {
        'host': _mt5ApiHost,
        'port': _mt5ApiPort,
        'baseUrl': mt5ApiBaseUrl,
      },
    };
  }
  
  static void _log(String message, {String level = 'info'}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$_logTag] [$timestamp] $message';
    developer.log(logMessage, name: 'SYP_Forex_App');
    print(logMessage);
  }
}
