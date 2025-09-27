import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../models/api_responses.dart';
import '../services/syp_api_service.dart';

class SypProvider extends GetxController {
  CurrentRatesResponse? _currentRates;
  ForecastResponse? _forecast;

  bool _isLoading = false;
  String? _error;

  // Caching
  DateTime? _lastRatesFetch;
  DateTime? _lastForecastFetch;
  static const Duration _cacheDuration = Duration(days: 1); // Cache for 1 day

  // Debug logging configuration
  static const String _logTag = '🔄 SYP_PROVIDER';

  // Helper method for debug logging
  void _log(
    String message, {
    String? method,
    dynamic data,
    String level = 'info',
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage =
        '[$_logTag] [$timestamp] ${method != null ? '[$method] ' : ''}$message';

    developer.log(logMessage, name: 'SYP_Forex_App');
  }

  // Getters
  CurrentRatesResponse? get currentRates => _currentRates;
  ForecastResponse? get forecast => _forecast;
  String get selectedCity => 'damascus';
  int get selectedForecastDays => 1;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cache checking methods
  bool get isRatesCacheValid =>
      _lastRatesFetch != null &&
      DateTime.now().difference(_lastRatesFetch!) < _cacheDuration;
  bool get isForecastCacheValid =>
      _lastForecastFetch != null &&
      DateTime.now().difference(_lastForecastFetch!) < _cacheDuration;

  // Load current rates
  Future<void> loadCurrentRates({bool forceRefresh = false}) async {
    const method = 'loadCurrentRates';

    // Check cache first
    if (!forceRefresh && isRatesCacheValid && _currentRates != null) {
      _log('Using cached current rates', method: method, level: 'info');
      return;
    }

    _log(
      '🚀 Loading current rates for city: damascus',
      method: method,
      level: 'info',
    );

    try {
      _setLoading(true);
      _clearError();

      _log(
        '⏳ Making API call to get current rates...',
        method: method,
        level: 'debug',
      );
      final apiData = await SypApiService.getCurrentRates(city: 'damascus');
      _currentRates = SypApiService.parseCurrentRates(apiData);
      _lastRatesFetch = DateTime.now(); // Update cache timestamp

      _log(
        '✅ Current rates loaded successfully',
        method: method,
        level: 'info',
      );

      // Log data models
      if (_currentRates != null) {
        _log(
          '💱 Rate: ${_currentRates!.currentRates.mid}',
          method: method,
          level: 'debug',
        );
        _log(
          '🏙️ City: ${_currentRates!.city}',
          method: method,
          level: 'debug',
        );
        _log(
          '📊 Day type: ${_currentRates!.ohlcv.dayType}',
          method: method,
          level: 'debug',
        );
      }

      update();
      _log(
        '✅ Listeners notified of current rates update',
        method: method,
        level: 'debug',
      );
    } catch (e) {
      _log('❌ Failed to load current rates', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      _setError(e.toString());
    } finally {
      _setLoading(false);
      _log('⏹️ Loading finished', method: method, level: 'debug');
    }
  }

  // Load forecast
  Future<void> loadForecast({bool forceRefresh = false}) async {
    const method = 'loadForecast';

    // Check cache first
    if (!forceRefresh && isForecastCacheValid && _forecast != null) {
      _log('Using cached forecast data', method: method, level: 'info');
      return;
    }

    _log(
      '🚀 Loading forecast for city: damascus',
      method: method,
      level: 'info',
    );

    try {
      _setLoading(true);
      _clearError();

      _log(
        '⏳ Making API call to get forecast...',
        method: method,
        level: 'debug',
      );
      final apiData = await SypApiService.getForecast(
        days: 1,
        city: 'damascus',
      );
      _forecast = SypApiService.parseForecast(apiData);
      _lastForecastFetch = DateTime.now(); // Update cache timestamp

      _log('✅ Forecast loaded successfully', method: method, level: 'info');

      // Log data models
      if (_forecast != null) {
        _log(
          '🔮 Predicted rate: ${_forecast!.prediction.rate}',
          method: method,
          level: 'debug',
        );
        _log(
          '📅 Forecast date: ${_forecast!.forecastDate}',
          method: method,
          level: 'debug',
        );
        _log(
          '📊 Day type: ${_forecast!.prediction.dayType}',
          method: method,
          level: 'debug',
        );
      }

      update();
      _log(
        '✅ Listeners notified of forecast update',
        method: method,
        level: 'debug',
      );
    } catch (e) {
      _log('❌ Failed to load forecast', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      _setError(e.toString());
    } finally {
      _setLoading(false);
      _log('⏹️ Loading finished', method: method, level: 'debug');
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    const method = 'refreshData';
    _log('🔄 Starting full data refresh', method: method, level: 'info');
    _log('🏙️ City: damascus', method: method, level: 'debug');

    final stopwatch = Stopwatch()..start();

    try {
      await Future.wait([loadCurrentRates(), loadForecast()]);

      stopwatch.stop();
      final duration = stopwatch.elapsed;

      _log(
        '✅ Full data refresh completed successfully',
        method: method,
        level: 'info',
      );
      _log(
        '⏱️ Total refresh time: ${duration.inMilliseconds}ms',
        method: method,
        level: 'debug',
      );
    } catch (e) {
      _log('❌ Full data refresh failed', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
    }
  }

  // Initialize data
  Future<void> initializeData() async {
    const method = 'initializeData';
    _log('🚀 Initializing provider data', method: method, level: 'info');
    _log('🏙️ City: damascus', method: method, level: 'debug');

    await refreshData();

    _log('✅ Provider initialization completed', method: method, level: 'info');
  }

  // Helper methods
  void _setLoading(bool loading) {
    _log(
      '⏳ Setting loading state: $loading (was: $_isLoading)',
      level: 'debug',
    );
    _isLoading = loading;
    update();
    _log('✅ Loading state updated, listeners notified', level: 'debug');
  }

  void _setError(String error) {
    _log('🚨 Setting error: $error', level: 'error');
    _error = error;
    update();
    _log('✅ Error set, listeners notified', level: 'debug');
  }

  void _clearError() {
    if (_error != null) {
      _log('🧹 Clearing previous error: $_error', level: 'debug');
      _error = null;
      update();
      _log('✅ Error cleared, listeners notified', level: 'debug');
    }
  }

  void clearError() {
    _log('🧹 Manually clearing error', level: 'debug');
    _clearError();
  }

  // Utility methods
  String formatRate(double rate) {
    final formatted = rate.toStringAsFixed(2);
    _log('💱 Formatting rate: $rate -> $formatted', level: 'debug');
    return formatted;
  }

  String formatChange(double change) {
    final formatted = change.toStringAsFixed(2);
    _log('📈 Formatting change: $change -> $formatted', level: 'debug');
    return formatted;
  }

  bool isPositiveChange(double change) {
    final isPositive = change >= 0;
    _log(
      '🎨 Change color check: $change -> ${isPositive ? "positive" : "negative"}',
      level: 'debug',
    );
    return isPositive;
  }

  bool isCalmDay(String dayType) {
    final isCalm = dayType.toLowerCase() == 'calm';
    _log(
      '🌤️ Day type check: $dayType -> ${isCalm ? "calm" : "normal"}',
      level: 'debug',
    );
    return isCalm;
  }

  // Test server connection
  Future<bool> testServerConnection() async {
    const method = 'testServerConnection';
    _log('🧪 Testing server connection', method: method, level: 'info');

    try {
      // Try to load current rates as a connection test
      await loadCurrentRates();
      _log(
        '✅ Server connection test successful',
        method: method,
        level: 'info',
      );
      return true;
    } catch (e) {
      _log('❌ Server connection test failed', method: method, level: 'error');
      _log('🚨 Error: $e', method: method, level: 'error');
      return false;
    }
  }

  // Debug current state
  void debugCurrentState() {
    const method = 'debugCurrentState';
    _log('🔍 Debugging current provider state', method: method, level: 'info');
    _log('🏙️ City: damascus', method: method, level: 'debug');
    _log('⏳ Loading: $_isLoading', method: method, level: 'debug');
    _log('🚨 Error: $_error', method: method, level: 'debug');
    _log(
      '💱 Current rates: ${_currentRates != null ? "loaded" : "null"}',
      method: method,
      level: 'debug',
    );
    _log(
      '🔮 Forecast: ${_forecast != null ? "loaded" : "null"}',
      method: method,
      level: 'debug',
    );
  }
}
