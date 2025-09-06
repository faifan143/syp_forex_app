import 'dart:async';
import 'dart:math';

class MarketSimulationService {
  static final MarketSimulationService _instance = MarketSimulationService._internal();
  factory MarketSimulationService() => _instance;
  MarketSimulationService._internal();

  Timer? _simulationTimer;
  final Map<String, double> _currentPrices = {};
  final Map<String, List<Map<String, double>>> _chartData = {};
  final Random _random = Random();
  
  // Market data streams
  final StreamController<Map<String, double>> _priceController = StreamController<Map<String, double>>.broadcast();
  final StreamController<Map<String, List<Map<String, double>>>> _chartController = StreamController<Map<String, List<Map<String, double>>>>.broadcast();
  
  Stream<Map<String, double>> get priceStream => _priceController.stream;
  Stream<Map<String, List<Map<String, double>>>> get chartStream => _chartController.stream;

  // Currency pairs with realistic base prices
  final Map<String, double> _basePrices = {
    'EUR/USD': 1.0850,
    'GBP/USD': 1.2650,
    'USD/JPY': 150.25,
    'AUD/USD': 0.6550,
    'USD/CAD': 1.3650,
    'NZD/USD': 0.6050,
    'USD/CHF': 0.8850,
    'EUR/GBP': 0.8575,
    'EUR/JPY': 163.15,
    'GBP/JPY': 190.25,
  };

  // Volatility levels for each pair
  final Map<String, double> _volatility = {
    'EUR/USD': 0.0008,
    'GBP/USD': 0.0012,
    'USD/JPY': 0.15,
    'AUD/USD': 0.0010,
    'USD/CAD': 0.0009,
    'NZD/USD': 0.0015,
    'USD/CHF': 0.0007,
    'EUR/GBP': 0.0006,
    'EUR/JPY': 0.18,
    'GBP/JPY': 0.22,
  };

  bool _isRunning = false;

  void startSimulation() {
    if (_isRunning) return;
    
    _isRunning = true;
    _initializePrices();
    _initializeChartData();
    
    // Start price simulation timer (every 2 seconds)
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updatePrices();
      _updateChartData();
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isRunning = false;
  }

  void _initializePrices() {
    for (String symbol in _basePrices.keys) {
      _currentPrices[symbol] = _basePrices[symbol]!;
    }
    _priceController.add(Map.from(_currentPrices));
  }

  void _initializeChartData() {
    for (String symbol in _basePrices.keys) {
      _chartData[symbol] = _generateInitialChartData(symbol);
    }
    _chartController.add(Map.from(_chartData));
  }

  List<Map<String, double>> _generateInitialChartData(String symbol) {
    final basePrice = _basePrices[symbol]!;
    final volatility = _volatility[symbol]!;
    final List<Map<String, double>> candles = [];
    
    double currentPrice = basePrice;
    
    // Generate reasonable amount of initial data for good chart display
    for (int i = 0; i < 200; i++) {
      // Generate realistic price movement
      final change = _generatePriceChange(volatility);
      final open = currentPrice;
      final close = currentPrice + change;
      final high = [open, close].reduce((a, b) => a > b ? a : b) + (volatility * _random.nextDouble());
      final low = [open, close].reduce((a, b) => a < b ? a : b) - (volatility * _random.nextDouble());
      
      candles.add({
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'time': DateTime.now().subtract(Duration(hours: 200 - i)).millisecondsSinceEpoch.toDouble(),
      });
      
      currentPrice = close;
    }
    
    return candles;
  }

  double _generatePriceChange(double volatility) {
    // Use Box-Muller transformation for normal distribution
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final z0 = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    
    // Apply volatility and some trend
    final trend = (_random.nextDouble() - 0.5) * 0.0001; // Small trend component
    return (z0 * volatility) + trend;
  }

  void _updatePrices() {
    for (String symbol in _currentPrices.keys) {
      final volatility = _volatility[symbol]!;
      final change = _generatePriceChange(volatility);
      _currentPrices[symbol] = (_currentPrices[symbol]! + change).clamp(0.0001, 999.9999);
    }
    _priceController.add(Map.from(_currentPrices));
  }

  void _updateChartData() {
    for (String symbol in _chartData.keys) {
      final candles = _chartData[symbol]!;
      final currentPrice = _currentPrices[symbol]!;
      
      // Update the last candle or create a new one
      if (candles.isNotEmpty) {
        final lastCandle = candles.last;
        final now = DateTime.now();
        final lastTime = DateTime.fromMillisecondsSinceEpoch(lastCandle['time']!.toInt());
        
        // If more than 1 minute has passed, create new candle
        if (now.difference(lastTime).inMinutes >= 1) {
          candles.add({
            'open': lastCandle['close']!,
            'high': currentPrice,
            'low': currentPrice,
            'close': currentPrice,
            'time': now.millisecondsSinceEpoch.toDouble(),
          });
          
          // Keep only last 200 candles for good chart display
          if (candles.length > 200) {
            candles.removeAt(0);
          }
        } else {
          // Update current candle
          lastCandle['high'] = [lastCandle['high']!, currentPrice].reduce((a, b) => a > b ? a : b);
          lastCandle['low'] = [lastCandle['low']!, currentPrice].reduce((a, b) => a < b ? a : b);
          lastCandle['close'] = currentPrice;
        }
      }
    }
    _chartController.add(Map.from(_chartData));
  }

  Map<String, double> getCurrentPrices() {
    return Map.from(_currentPrices);
  }

  Map<String, List<Map<String, double>>> getChartData() {
    return Map.from(_chartData);
  }

  List<Map<String, double>> getChartDataForSymbol(String symbol) {
    return _chartData[symbol] ?? [];
  }

  double getCurrentPrice(String symbol) {
    return _currentPrices[symbol] ?? 0.0;
  }

  double getBidPrice(String symbol) {
    final price = getCurrentPrice(symbol);
    return price - _getSpread(symbol);
  }

  double getAskPrice(String symbol) {
    final price = getCurrentPrice(symbol);
    return price + _getSpread(symbol);
  }

  // Get bid price with realistic spread
  double getBidPriceRealistic(String symbol) {
    final midPrice = _currentPrices[symbol] ?? _basePrices[symbol] ?? 1.0;
    final spread = getDynamicSpread(symbol);
    return midPrice - (spread / 2);
  }

  // Get ask price with realistic spread
  double getAskPriceRealistic(String symbol) {
    final midPrice = _currentPrices[symbol] ?? _basePrices[symbol] ?? 1.0;
    final spread = getDynamicSpread(symbol);
    return midPrice + (spread / 2);
  }

  // Get dynamic spread based on time and volatility
  double getDynamicSpread(String symbol) {
    final baseSpread = _getBaseSpread(symbol);
    final timeMultiplier = _getTimeMultiplier();
    final volatilityMultiplier = _volatility[symbol] ?? 0.001;
    
    return baseSpread * timeMultiplier * (1 + volatilityMultiplier * 10);
  }

  // Get base spread for a symbol
  double _getBaseSpread(String symbol) {
    // Different spreads for different pairs
    switch (symbol) {
      case 'EUR/USD':
        return 0.0001; // 1 pip
      case 'GBP/USD':
        return 0.0002; // 2 pips
      case 'USD/JPY':
        return 0.02; // 2 pips
      case 'AUD/USD':
        return 0.0003; // 3 pips
      case 'USD/CAD':
        return 0.0002; // 2 pips
      case 'NZD/USD':
        return 0.0004; // 4 pips
      case 'USD/CHF':
        return 0.0002; // 2 pips
      case 'EUR/GBP':
        return 0.0002; // 2 pips
      case 'EUR/JPY':
        return 0.03; // 3 pips
      case 'GBP/JPY':
        return 0.04; // 4 pips
      default:
        return 0.0002; // Default 2 pips
    }
  }

  // Get time-based multiplier for spread
  double _getTimeMultiplier() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Higher spreads during off-market hours
    if (hour >= 22 || hour <= 6) {
      return 1.5; // 50% higher spread
    } else if (hour >= 7 && hour <= 9) {
      return 1.2; // 20% higher spread during Asian session
    } else if (hour >= 13 && hour <= 17) {
      return 0.8; // 20% lower spread during London session
    } else {
      return 1.0; // Normal spread
    }
  }

  double _getSpread(String symbol) {
    // Realistic spreads based on symbol
    final spreads = {
      'EUR/USD': 0.0001,
      'GBP/USD': 0.0002,
      'USD/JPY': 0.02,
      'AUD/USD': 0.0002,
      'USD/CAD': 0.0002,
      'NZD/USD': 0.0003,
      'USD/CHF': 0.0002,
      'EUR/GBP': 0.0002,
      'EUR/JPY': 0.03,
      'GBP/JPY': 0.04,
    };
    return spreads[symbol] ?? 0.0001;
  }

  void dispose() {
    stopSimulation();
    _priceController.close();
    _chartController.close();
  }
}

