import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'dart:async';
import '../models/forex_models.dart';
import '../services/market_simulation_service.dart';

class ForexProvider extends GetxController {
  String _selectedPair = 'EUR/USD';
  String _selectedTimeframe = 'daily';
  ForexChartData? _chartData;
  Map<String, ForexRate> _forexRates = {};
  bool _isLoadingChart = false;
  bool _isLoadingRates = false;
  String? _chartError;
  String? _ratesError;
  Timer? _refreshTimer;
  
  // Market simulation service
  final MarketSimulationService _marketService = MarketSimulationService();

  // Getters
  String get selectedPair => _selectedPair;
  String get selectedTimeframe => _selectedTimeframe;
  ForexChartData? get chartData => _chartData;
  Map<String, ForexRate> get forexRates => _forexRates;
  bool get isLoadingChart => _isLoadingChart;
  bool get isLoadingRates => _isLoadingRates;
  String? get chartError => _chartError;
  String? get ratesError => _ratesError;

  // Available pairs and timeframes (hardcoded for simulation)
  List<Map<String, String>> get availablePairs => [
    {'from': 'EUR', 'to': 'USD', 'symbol': 'EUR/USD'},
    {'from': 'GBP', 'to': 'USD', 'symbol': 'GBP/USD'},
    {'from': 'JPY', 'to': 'USD', 'symbol': 'USD/JPY'},
    {'from': 'CAD', 'to': 'USD', 'symbol': 'USD/CAD'},
    {'from': 'AUD', 'to': 'USD', 'symbol': 'AUD/USD'},
    {'from': 'NZD', 'to': 'USD', 'symbol': 'NZD/USD'},
    {'from': 'CHF', 'to': 'USD', 'symbol': 'USD/CHF'},
    {'from': 'TRY', 'to': 'USD', 'symbol': 'USD/TRY'},
    {'from': 'CNH', 'to': 'USD', 'symbol': 'CNH/USD'},
    {'from': 'SEK', 'to': 'USD', 'symbol': 'USD/SEK'},
  ];

  List<Map<String, String>> get availableTimeframes => [
    {'value': 'M1', 'label': '1 Minute'},
    {'value': 'M5', 'label': '5 Minutes'},
    {'value': 'M15', 'label': '15 Minutes'},
    {'value': 'H1', 'label': '1 Hour'},
    {'value': 'H4', 'label': '4 Hours'},
    {'value': 'D1', 'label': 'Daily'},
  ];

  void setSelectedPair(String pair) {
    if (_selectedPair != pair) {
      _selectedPair = pair;
      update();
      loadChartData();
    }
  }

  void setSelectedTimeframe(String timeframe) {
    if (_selectedTimeframe != timeframe) {
      _selectedTimeframe = timeframe;
      update();
      loadChartData();
    }
  }

  // Load simulated forex rates
  Future<void> loadForexRates() async {
    _isLoadingRates = true;
    _ratesError = null;
    update();

    try {
      // Get current prices from market simulation
      final currentPrices = _marketService.getCurrentPrices();
      final rates = <String, ForexRate>{};
      
      for (final pair in availablePairs) {
        final symbol = pair['symbol']!;
        final fromCurrency = pair['from']!;
        final toCurrency = pair['to']!;
        final currentPrice = currentPrices[symbol] ?? 1.0;
        
        // Create simulated ForexRate
        final rate = ForexRate(
          fromCurrency: fromCurrency,
          toCurrency: toCurrency,
          symbol: symbol,
          rate: currentPrice,
          timestamp: DateTime.now(),
          change: (currentPrice * 0.001) * (DateTime.now().millisecond % 2 == 0 ? 1 : -1), // Simulated change
          changePercent: (DateTime.now().millisecond % 2 == 0 ? 0.1 : -0.1), // Simulated change %
        );
        rates[symbol] = rate;
      }
      
      _forexRates = rates;
      _isLoadingRates = false;
      update();
    } catch (e) {
      _ratesError = 'Failed to load simulated forex rates: $e';
      _isLoadingRates = false;
      update();
    }
  }

  // Load simulated chart data
  Future<void> loadChartData() async {
    _isLoadingChart = true;
    _chartError = null;
    update();

    try {
      // Get chart data from market simulation
      final chartData = _marketService.getChartDataForSymbol(_selectedPair);
      
      if (chartData.isNotEmpty) {
        // Convert to ForexChartData format
        final candles = chartData.map((candle) => Candlestick(
          open: candle['open']!,
          high: candle['high']!,
          low: candle['low']!,
          close: candle['close']!,
          timestamp: DateTime.fromMillisecondsSinceEpoch(candle['time']!.toInt()),
          volume: 1000, // Default volume for simulated data
        )).toList();

        _chartData = ForexChartData(
          symbol: _selectedPair,
          timeframe: _selectedTimeframe,
          candles: candles,
          lastUpdate: DateTime.now(),
        );
      }
      
      _isLoadingChart = false;
      update();
    } catch (e) {
      _chartError = 'Failed to load simulated chart data: $e';
      _isLoadingChart = false;
      update();
    }
  }

  // Start auto-refresh
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadForexRates();
      loadChartData();
    });
  }

  // Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}