import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'dart:async';
import '../models/forex_models.dart';
import '../services/market_simulation_service.dart';
import '../services/forex_dashboard_api_service.dart';

class ForexProvider extends GetxController {
  String _selectedPair = 'EUR/USD';
  String _selectedTimeframe = 'daily';
  ForexChartData? _chartData;
  Map<String, ForexRate> _forexRates = {};
  ForexDashboardResponse? _dashboardData;
  bool _isLoadingChart = false;
  bool _isLoadingRates = false;
  bool _isLoadingDashboard = false;
  String? _chartError;
  String? _ratesError;
  String? _dashboardError;
  Timer? _refreshTimer;

  // Caching
  DateTime? _lastDashboardFetch;
  DateTime? _lastRatesFetch;
  static const Duration _cacheDuration = Duration(days: 1); // Cache for 1 day

  // Services
  final MarketSimulationService _marketService = MarketSimulationService();
  final ForexDashboardApiService _dashboardService = ForexDashboardApiService();

  // Getters
  String get selectedPair => _selectedPair;
  String get selectedTimeframe => _selectedTimeframe;
  ForexChartData? get chartData => _chartData;
  Map<String, ForexRate> get forexRates => _forexRates;
  ForexDashboardResponse? get dashboardData => _dashboardData;
  bool get isLoadingChart => _isLoadingChart;
  bool get isLoadingRates => _isLoadingRates;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get chartError => _chartError;
  String? get ratesError => _ratesError;
  String? get dashboardError => _dashboardError;

  // Cache checking methods
  bool get isDashboardCacheValid =>
      _lastDashboardFetch != null &&
      DateTime.now().difference(_lastDashboardFetch!) < _cacheDuration;
  bool get isRatesCacheValid =>
      _lastRatesFetch != null &&
      DateTime.now().difference(_lastRatesFetch!) < _cacheDuration;

  // Available pairs and timeframes (configured for simulation)
  List<Map<String, String>> get availablePairs => [
    {'from': 'EUR', 'to': 'USD', 'symbol': 'EUR/USD'},
    {'from': 'GBP', 'to': 'USD', 'symbol': 'GBP/USD'},
    {'from': 'JPY', 'to': 'USD', 'symbol': 'USD/JPY'},
    {'from': 'CAD', 'to': 'USD', 'symbol': 'USD/CAD'},
    {'from': 'AUD', 'to': 'USD', 'symbol': 'AUD/USD'},
    {'from': 'NZD', 'to': 'USD', 'symbol': 'NZD/USD'},
    {'from': 'CHF', 'to': 'USD', 'symbol': 'USD/CHF'},
    {'from': 'TRY', 'to': 'USD', 'symbol': 'USD/TRY'},
    {'from': 'CNH', 'to': 'USD', 'symbol': 'USD/CNY'},
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
  Future<void> loadForexRates({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && isRatesCacheValid && _forexRates.isNotEmpty) {
      developer.log('Using cached forex rates', name: 'ForexProvider');
      return;
    }

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
          change:
              (currentPrice * 0.001) *
              (DateTime.now().millisecond % 2 == 0
                  ? 1
                  : -1), // Simulated change
          changePercent: (DateTime.now().millisecond % 2 == 0
              ? 0.1
              : -0.1), // Simulated change %
        );
        rates[symbol] = rate;
      }

      _forexRates = rates;
      _lastRatesFetch = DateTime.now(); // Update cache timestamp
      _isLoadingRates = false;
      update();
    } catch (e) {
      _ratesError = 'Failed to load simulated forex rates: $e';
      _isLoadingRates = false;
      update();
    }
  }

  // Load forex dashboard with 7-day predictions
  Future<void> loadForexDashboard({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && isDashboardCacheValid && _dashboardData != null) {
      developer.log('Using cached dashboard data', name: 'ForexProvider');
      return;
    }

    _isLoadingDashboard = true;
    _dashboardError = null;
    update();

    try {
      developer.log('Loading forex dashboard...', name: 'ForexProvider');

      // Add timeout wrapper for the entire operation
      final dashboardResponse = await _dashboardService
          .getForexDashboard()
          .timeout(
            const Duration(seconds: 90), // 90 seconds total timeout
            onTimeout: () {
              throw TimeoutException(
                'Dashboard request timed out after 90 seconds',
                const Duration(seconds: 90),
              );
            },
          );

      _dashboardData = dashboardResponse;
      _lastDashboardFetch = DateTime.now(); // Update cache timestamp

      // Update simulation base prices with real dashboard data
      _updateSimulationWithDashboardData(dashboardResponse);

      developer.log(
        'Dashboard loaded: ${dashboardResponse.currencies.length} currencies',
        name: 'ForexProvider',
      );
      update();
    } catch (e) {
      _dashboardError = 'Failed to load dashboard: $e';
      developer.log('Error loading dashboard: $e', name: 'ForexProvider');
    } finally {
      _isLoadingDashboard = false;
      update();
    }
  }

  // Update simulation base prices with dashboard data
  void _updateSimulationWithDashboardData(
    ForexDashboardResponse dashboardData,
  ) {
    try {
      // Convert dashboard data to base prices map
      final Map<String, double> basePrices = {};

      for (final currency in dashboardData.currencies) {
        // Convert API format (EURUSD) to display format (EUR/USD)
        final pair = currency.pair;
        String displaySymbol;

        if (pair.startsWith('USD')) {
          // USD pairs: USDJPY -> USD/JPY
          displaySymbol = 'USD/${pair.substring(3)}';
        } else {
          // Other pairs: EURUSD -> EUR/USD
          displaySymbol = '${pair.substring(0, 3)}/${pair.substring(3)}';
        }

        basePrices[displaySymbol] = currency.currentValue;
      }

      // Update the market simulation service with real market data as base prices
      _marketService.updateBasePrices(basePrices);

      developer.log(
        'Updated simulation base prices with dashboard data: ${basePrices.length} symbols',
        name: 'ForexProvider',
      );
    } catch (e) {
      developer.log(
        'Error updating simulation with dashboard data: $e',
        name: 'ForexProvider',
      );
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
        final candles = chartData
            .map(
              (candle) => Candlestick(
                open: candle['open']!,
                high: candle['high']!,
                low: candle['low']!,
                close: candle['close']!,
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  candle['time']!.toInt(),
                ),
                volume: 1000, // Default volume for simulated data
              ),
            )
            .toList();

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
