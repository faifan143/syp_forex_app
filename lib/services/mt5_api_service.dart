import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/mt5_models.dart';
import 'api_config_service.dart';

class Mt5ApiService {
  static const String _logTag = '📈 MT5_API';
  
  // MT5 Demo Account Credentials (Real Account)
  static const String _mt5Login = '95550103';
  static const String _mt5Password = '*¡We0e7o';
  static const String _mt5Server = 'MetaQuotes-Demo';
  
  // MT5 Web API endpoints (configurable via ApiConfigService)
  static String get _baseUrl => ApiConfigService.mt5ApiBaseUrl;
  
  // Connection status
  static bool _isConnected = false;
  static String? _connectionError;
  
  // Getters
  static bool get isConnected => _isConnected;
  static String? get connectionError => _connectionError;
  static String get mt5Login => _mt5Login;
  static String get mt5Server => _mt5Server;
  
  /// Connect to MT5 demo account
  static Future<bool> connect() async {
    const method = 'connect';
    try {
      _log('🚀 Connecting to MT5 Demo Account...', method: method, level: 'info');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': _mt5Login,
          'password': _mt5Password,
          'server': _mt5Server,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isConnected = data['connected'] == true;
        _connectionError = _isConnected ? null : data['error'];
        
        if (_isConnected) {
          _log('✅ Connected to MT5 Demo Account successfully', method: method, level: 'success');
        } else {
          _log('❌ Failed to connect to MT5: $_connectionError', method: method, level: 'error');
        }
      } else {
        _isConnected = false;
        _connectionError = 'HTTP ${response.statusCode}: ${response.body}';
        _log('❌ Connection failed: $_connectionError', method: method, level: 'error');
      }
    } catch (e) {
      _isConnected = false;
      _connectionError = 'Connection error: $e';
      _log('❌ Connection error: $e', method: method, level: 'error');
    }
    
    return _isConnected;
  }
  
  /// Get account information
  static Future<Mt5AccountInfo?> getAccountInfo() async {
    const method = 'getAccountInfo';
    if (!_isConnected) {
      _log('⚠️ Not connected to MT5', method: method, level: 'warning');
      return null;
    }
    
    try {
      _log('📊 Fetching account info...', method: method, level: 'info');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/account'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accountInfo = Mt5AccountInfo.fromJson(data);
        _log('✅ Account info retrieved successfully', method: method, level: 'success');
        return accountInfo;
      } else {
        _log('❌ Failed to get account info: ${response.statusCode}', method: method, level: 'error');
        return null;
      }
    } catch (e) {
      _log('❌ Error getting account info: $e', method: method, level: 'error');
      return null;
    }
  }
  
  /// Get current positions
  static Future<List<Mt5Position>> getPositions() async {
    const method = 'getPositions';
    if (!_isConnected) {
      _log('⚠️ Not connected to MT5', method: method, level: 'warning');
      return [];
    }
    
    try {
      _log('📈 Fetching current positions...', method: method, level: 'info');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/positions'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final positions = (data['positions'] as List)
            .map((pos) => Mt5Position.fromJson(pos))
            .toList();
        _log('✅ Retrieved ${positions.length} positions', method: method, level: 'success');
        return positions;
      } else {
        _log('❌ Failed to get positions: ${response.statusCode}', method: method, level: 'error');
        return [];
      }
    } catch (e) {
      _log('❌ Error getting positions: $e', method: method, level: 'error');
      return [];
    }
  }
  
  /// Get trade history
  static Future<List<Mt5Trade>> getTradeHistory({int limit = 100}) async {
    const method = 'getTradeHistory';
    if (!_isConnected) {
      _log('⚠️ Not connected to MT5', method: method, level: 'warning');
      return [];
    }
    
    try {
      _log('📋 Fetching trade history...', method: method, level: 'info');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/trades?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trades = (data['trades'] as List)
            .map((trade) => Mt5Trade.fromJson(trade))
            .toList();
        _log('✅ Retrieved ${trades.length} trades', method: method, level: 'success');
        return trades;
      } else {
        _log('❌ Failed to get trade history: ${response.statusCode}', method: method, level: 'error');
        return [];
      }
    } catch (e) {
      _log('❌ Error getting trade history: $e', method: method, level: 'error');
      return [];
    }
  }
  
  /// Get chart data (OHLCV)
  static Future<List<Mt5Candlestick>> getChartData(String symbol, String timeframe, int bars) async {
    const method = 'getChartData';
    if (!_isConnected) {
      _log('⚠️ Not connected to MT5', method: method, level: 'warning');
      return [];
    }
    
    try {
      _log('📊 Fetching chart data for $symbol ($timeframe)...', method: method, level: 'info');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/chart?symbol=$symbol&timeframe=$timeframe&bars=$bars'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candles = (data['candles'] as List)
            .map((candle) => Mt5Candlestick.fromJson(candle))
            .toList();
        _log('✅ Retrieved ${candles.length} candles for $symbol', method: method, level: 'success');
        return candles;
      } else {
        _log('❌ Failed to get chart data: ${response.statusCode}', method: method, level: 'error');
        return [];
      }
    } catch (e) {
      _log('❌ Error getting chart data: $e', method: method, level: 'error');
      return [];
    }
  }
  
  /// Get current market prices
  static Future<Map<String, double>> getCurrentPrices(List<String> symbols) async {
    const method = 'getCurrentPrices';
    if (!_isConnected) {
      _log('⚠️ Not connected to MT5', method: method, level: 'warning');
      return {};
    }
    
    try {
      _log('💰 Fetching current prices for ${symbols.length} symbols...', method: method, level: 'info');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/prices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'symbols': symbols}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prices = Map<String, double>.from(data['prices']);
        _log('✅ Retrieved prices for ${prices.length} symbols', method: method, level: 'success');
        return prices;
      } else {
        _log('❌ Failed to get current prices: ${response.statusCode}', method: method, level: 'error');
        return {};
      }
    } catch (e) {
      _log('❌ Error getting current prices: $e', method: method, level: 'error');
      return {};
    }
  }
  
  /// Place a market order
  static Future<Mt5OrderResult?> placeOrder({
    required String symbol,
    required String orderType, // 'buy' or 'sell'
    required double volume,
    double? stopLoss,
    double? takeProfit,
    String? comment,
  }) async {
    const method = 'placeOrder';
    if (!_isConnected) {
      _log('⚠️ Not connected to MT5', method: method, level: 'warning');
      return null;
    }
    
    try {
      _log('📝 Placing $orderType order for $symbol...', method: method, level: 'info');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symbol': symbol,
          'type': orderType,
          'volume': volume,
          'stopLoss': stopLoss,
          'takeProfit': takeProfit,
          'comment': comment,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = Mt5OrderResult.fromJson(data);
        _log('✅ Order placed successfully: ${result.orderId}', method: method, level: 'success');
        return result;
      } else {
        _log('❌ Failed to place order: ${response.statusCode}', method: method, level: 'error');
        return null;
      }
    } catch (e) {
      _log('❌ Error placing order: $e', method: method, level: 'error');
      return null;
    }
  }
  
  /// Close a position
  static Future<bool> closePosition(int positionId) async {
    const method = 'closePosition';
    if (!_isConnected) {
      _log('⚠️ Not connected to MT5', method: method, level: 'warning');
      return false;
    }
    
    try {
      _log('🔒 Closing position $positionId...', method: method, level: 'info');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/close'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'positionId': positionId}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _log('✅ Position $positionId closed successfully', method: method, level: 'success');
        return true;
      } else {
        _log('❌ Failed to close position: ${response.statusCode}', method: method, level: 'error');
        return false;
      }
    } catch (e) {
      _log('❌ Error closing position: $e', method: method, level: 'error');
      return false;
    }
  }
  
  /// Disconnect from MT5
  static Future<void> disconnect() async {
    const method = 'disconnect';
    try {
      _log('🔌 Disconnecting from MT5...', method: method, level: 'info');
      
      await http.post(
        Uri.parse('$_baseUrl/disconnect'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      _isConnected = false;
      _connectionError = null;
      _log('✅ Disconnected from MT5', method: method, level: 'success');
    } catch (e) {
      _log('❌ Error disconnecting: $e', method: method, level: 'error');
    }
  }
  
  static void _log(String message, {String method = '', String level = 'info'}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$_logTag] [$timestamp] [$method] $message';
    developer.log(logMessage, name: 'SYP_Forex_App');
  }
}




