import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paper_trading_models.dart';
import '../models/forex_models.dart';
import '../services/market_simulation_service.dart';
import '../services/simulation_api_service.dart';
import '../services/timeframe_converter.dart';

class PaperTradingProvider extends GetxController {
  VirtualWallet _wallet = VirtualWallet.initial();
  List<ForexRate> _forexRates = [];
  bool _isLoading = false;
  String? _error;

  // Real M1 Simulation Data (from Flask API)
  final SimulationApiService _simulationService = SimulationApiService();
  Map<String, List<Map<String, dynamic>>> _simulationData = {};
  Map<String, int> _currentDataIndex = {}; // Track current position in M1 data
  Map<String, double> _currentPrices = {};
  Map<String, List<Map<String, double>>> _chartData = {};
  Map<String, Map<String, List<Map<String, double>>>> _timeframeData = {}; // Store data for all timeframes
  bool _isSimulationRunning = false;
  Timer? _simulationTimer;
  String _currentTimeframe = '1m';

  // Legacy Market Simulation (for fallback)
  final MarketSimulationService _marketService = MarketSimulationService();

  // Getters
  VirtualWallet get wallet => _wallet;
  List<ForexRate> get forexRates => _forexRates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Simulation Getters
  bool get isSimulationRunning => _isSimulationRunning;
  Map<String, double> get currentPrices => _currentPrices;
  Map<String, List<Map<String, double>>> get chartData => _chartData;
  Map<String, Map<String, List<Map<String, double>>>> get timeframeData => _timeframeData;
  
  // Get chart data for specific timeframe
  List<Map<String, double>> getChartDataForTimeframe(String symbol, String timeframe) {
    if (_timeframeData.containsKey(symbol) && 
        _timeframeData[symbol]!.containsKey(timeframe)) {
      return _timeframeData[symbol]![timeframe]!;
    }
    return [];
  }
  Map<String, int> get currentDataIndex => _currentDataIndex;
  Map<String, List<Map<String, dynamic>>> get simulationData => _simulationData;
  Stream<Map<String, List<Map<String, double>>>>? get chartDataStream =>
      _marketService.chartStream;

  // Computed properties
  double get currentBalance => _wallet.balance;
  double get currentEquity => _wallet.currentEquity;
  double get totalPnL => _wallet.currentEquity - _wallet.balance;
  double get totalPnLPercent =>
      _wallet.balance > 0 ? (totalPnL / _wallet.balance) * 100 : 0.0;
  List<Position> get openPositions => _wallet.openPositions;
  TradingStats get tradingStats =>
      TradingStats.fromTrades(_wallet.tradeHistory);
  bool get isMarginCall => _wallet.isMarginCall;
  bool get realisticMode => true; // Always realistic mode for paper trading

  // Initialize the provider
  void initialize() {
    _wallet = VirtualWallet.initial();
    _loadWalletData(); // Load saved data on initialization
    update();
  }

  // Load simulation data from Flask API
  Future<void> loadSimulationData(String symbol) async {
    try {
      _setLoading(true);

      // Handle both currency codes (EUR) and currency pairs (EUR/USD)
      String currency;
      if (symbol.contains('/')) {
        // It's a currency pair, convert to currency code
        currency = _getCurrencyFromSymbol(symbol) ?? symbol;
      } else {
        // It's already a currency code
        currency = symbol;
      }
      
      
      // Validate currency code
      final validCurrencies = ['EUR', 'GBP', 'AUD', 'NZD', 'JPY', 'CHF', 'CAD', 'SEK', 'TRY', 'CNH'];
      if (!validCurrencies.contains(currency)) {
        return;
      }

      // Get simulation data from Flask API
      final simulationData = await SimulationApiService.getSimulationData(
        currency,
      );
      
      if (simulationData != null && simulationData.data.isNotEmpty) {
        
        _simulationData[symbol] = simulationData.data;
        
        // Find the last day's beginning to start simulation from
        final lastDayStartIndex = _findLastDayStartIndex(simulationData.data);
        _currentDataIndex[symbol] = lastDayStartIndex;

        // Initialize current price with last day's first data point
        final currencyPair = _getCurrencyPairFromCode(symbol);
        if (currencyPair != null) {
          if (_simulationData[symbol]!.isNotEmpty && lastDayStartIndex >= 0) {
            final startData = _simulationData[symbol]![lastDayStartIndex];
            _currentPrices[currencyPair] = _parsePrice(startData);
          } else if (_simulationData[symbol]!.isNotEmpty) {
            // Fallback to first data point if not enough data
            final firstData = _simulationData[symbol]!.first;
            _currentPrices[currencyPair] = _parsePrice(firstData);
            _currentDataIndex[symbol] = 0; // Reset to start if not enough data
          }
        }

        // Generate initial chart data from simulation data (progressive from start)
        _generateChartDataFromSimulation(symbol);
        if (currencyPair != null) {
        }

        // Log the starting data point and some context
        if (_simulationData[symbol]!.isNotEmpty) {
          final startData = _simulationData[symbol]![lastDayStartIndex];
          final firstData = _simulationData[symbol]!.first;
          final lastData = _simulationData[symbol]!.last;
        }
      } else {
      }
    } catch (e) {
      _setError('Failed to load simulation data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Convert symbol format (EUR/USD -> EUR)
  String? _getCurrencyFromSymbol(String symbol) {
    final currencyMap = {
      'EUR/USD': 'EUR',
      'GBP/USD': 'GBP',
      'AUD/USD': 'AUD',
      'NZD/USD': 'NZD',
      'USD/JPY': 'JPY',
      'USD/CHF': 'CHF',
      'USD/CAD': 'CAD',
      'USD/SEK': 'SEK',
      'USD/TRY': 'TRY',
      'USD/CNY': 'CNH',
    };
    return currencyMap[symbol];
  }

  // Convert currency code to currency pair for chart data storage
  String? _getCurrencyPairFromCode(String currencyCode) {
    final pairMap = {
      'EUR': 'EUR/USD',
      'GBP': 'GBP/USD',
      'AUD': 'AUD/USD',
      'NZD': 'NZD/USD',
      'JPY': 'USD/JPY',
      'CHF': 'USD/CHF',
      'CAD': 'USD/CAD',
      'SEK': 'USD/SEK',
      'TRY': 'USD/TRY',
      'CNH': 'USD/CNY',
    };
    return pairMap[currencyCode];
  }

  // Parse price from simulation data
  double _parsePrice(Map<String, dynamic> data) {
    // Try different possible price field names
    if (data.containsKey('Close')) return data['Close'].toDouble();
    if (data.containsKey('close')) return data['close'].toDouble();
    if (data.containsKey('price')) return data['price'].toDouble();
    if (data.containsKey('rate')) return data['rate'].toDouble();
    return 1.0; // Fallback
  }

  // Generate chart data from simulation data (progressive - only up to current position)
  void _generateChartDataFromSimulation(String symbol) {
    if (!_simulationData.containsKey(symbol)) return;
    if (!_currentDataIndex.containsKey(symbol)) return;
    
    // Check if we have any listeners before updating
    if (!hasListeners) {
      return;
    }

    final data = _simulationData[symbol]!;
    final currentIndex = _currentDataIndex[symbol]!;
    final candles = <Map<String, double>>[];

    // Only use data up to current position (progressive chart)
    final dataToUse = data.take(currentIndex + 1).toList();

    if (dataToUse.isEmpty) {
      return;
    }

    // Generate data for all timeframes using TimeframeConverter
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];
    
    if (!_timeframeData.containsKey(symbol)) {
      _timeframeData[symbol] = {};
    }

    for (final timeframe in timeframes) {
      final timeframeCandles = TimeframeConverter.convertToTimeframe(dataToUse, timeframe);
      _timeframeData[symbol]![timeframe] = timeframeCandles;
    }

    // Store chart data for the current timeframe
    final currencyPair = _getCurrencyPairFromCode(symbol);
    if (currencyPair != null) {
      final currentTimeframeCandles = _timeframeData[symbol]![_currentTimeframe] ?? [];
      
      // Limit to reasonable number of candles for performance (e.g., last 155 candles)
      final maxCandles = 155;
      final finalCandles = currentTimeframeCandles.length > maxCandles
          ? currentTimeframeCandles.sublist(currentTimeframeCandles.length - maxCandles)
          : currentTimeframeCandles;
      
      _chartData[currencyPair] = finalCandles;
    }
    update();
  }

  // Parse timestamp from simulation data
  DateTime _parseTimestamp(Map<String, dynamic> data) {
    if (data.containsKey('Datetime')) {
      return DateTime.parse(data['Datetime']);
    }
    if (data.containsKey('timestamp')) {
      return DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
    }
    if (data.containsKey('time')) {
      return DateTime.parse(data['time']);
    }
    return DateTime.now(); // Fallback
  }


  // Start simulation using real M1 data
  void startSimulation({String timeframe = '1m'}) {
    
    if (_isSimulationRunning) {
      return;
    }

    _isSimulationRunning = true;
    _currentTimeframe = timeframe;

    // Reset all symbols to start from last day's beginning
    for (final symbol in _simulationData.keys) {
      final lastDayStartIndex = _findLastDayStartIndex(_simulationData[symbol]!);
      _currentDataIndex[symbol] = lastDayStartIndex;
      
      if (_simulationData[symbol]!.isNotEmpty && lastDayStartIndex >= 0) {
        final startData = _simulationData[symbol]![lastDayStartIndex];
        _currentPrices[symbol] = _parsePrice(startData);
      } else {
        _currentDataIndex[symbol] = 0; // Fallback to start if not enough data
        final firstData = _simulationData[symbol]!.first;
        _currentPrices[symbol] = _parsePrice(firstData);
      }
    }

    // Start timer to advance through M1 data (5 seconds for balanced simulation)
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _advanceSimulationData();
    });
  }

  // Advance through simulation data
  void _advanceSimulationData() {
    // Check if we have any listeners before updating
    if (!hasListeners) {
      return;
    }
    
    for (final symbol in _simulationData.keys) {
      if (!_currentDataIndex.containsKey(symbol)) continue;

      final data = _simulationData[symbol]!;
      final currentIndex = _currentDataIndex[symbol]!;

      // Check if we have more data
      if (currentIndex < data.length - 1) {
        final nextIndex = currentIndex + 1;
        _currentDataIndex[symbol] = nextIndex;
        final newData = data[nextIndex];
        // Store current price with currency pair as key
        final currencyPair = _getCurrencyPairFromCode(symbol);
        if (currencyPair != null) {
          _currentPrices[currencyPair] = _parsePrice(newData);
        }

        // Log progress every 100 data points and first few data points
        if (nextIndex < 5 || nextIndex % 100 == 0) {
          final timestamp = newData['Datetime'] ?? 'Unknown';
          final price = _parsePrice(newData).toStringAsFixed(4);
        }

        // Update chart data on every advance for real-time progressive chart
        _generateChartDataFromSimulation(symbol);

        _updatePositionPrices();
        update();
      } else {
        // Reached end of data, restart from beginning of last day
        final lastDayStartIndex = _findLastDayStartIndex(data);
        _currentDataIndex[symbol] = lastDayStartIndex;
        final startData = data[lastDayStartIndex];
        
        // Store current price with currency pair as key
        final currencyPair = _getCurrencyPairFromCode(symbol);
        if (currencyPair != null) {
          _currentPrices[currencyPair] = _parsePrice(startData);
        }
        
        _generateChartDataFromSimulation(symbol);
        _updatePositionPrices();
        update();
      }
    }
  }

  // Find the index of the first record of the last day in the dataset
  int _findLastDayStartIndex(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0;
    
    // Get the last record's date
    final lastRecord = data.last;
    final lastDateTime = DateTime.parse(lastRecord['Datetime'] as String);
    final lastDate = DateTime(lastDateTime.year, lastDateTime.month, lastDateTime.day);
    
    // Find the first record of the last day
    for (int i = data.length - 1; i >= 0; i--) {
      final recordDateTime = DateTime.parse(data[i]['Datetime'] as String);
      final recordDate = DateTime(recordDateTime.year, recordDateTime.month, recordDateTime.day);
      
      if (recordDate.isBefore(lastDate)) {
        // Found the first record of the last day (next index)
        return i + 1;
      }
    }
    
    // If we reach here, all records are from the same day
    return 0;
  }

  // Stop simulation
  void stopSimulation() {
    _isSimulationRunning = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  // Reset simulation to beginning
  void resetSimulation() {
    for (final symbol in _simulationData.keys) {
      _currentDataIndex[symbol] = -1;
      if (_simulationData[symbol]!.isNotEmpty) {
        final firstData = _simulationData[symbol]!.first;
        _currentPrices[symbol] = _parsePrice(firstData);
        _generateChartDataFromSimulation(symbol);
      }
    }
    _updatePositionPrices();
    update();
  }

  // Update simulation with new timeframe
  void updateTimeframe(String timeframe) {
    _currentTimeframe = timeframe;

    // Update chart data for all symbols using stored timeframe data
    for (final symbol in _simulationData.keys) {
      final currencyPair = _getCurrencyPairFromCode(symbol);
      if (currencyPair != null && 
          _timeframeData.containsKey(symbol) && 
          _timeframeData[symbol]!.containsKey(timeframe)) {
        
        final timeframeCandles = _timeframeData[symbol]![timeframe]!;
        
        // Limit to reasonable number of candles for performance
        final maxCandles = 155;
        final finalCandles = timeframeCandles.length > maxCandles
            ? timeframeCandles.sublist(timeframeCandles.length - maxCandles)
            : timeframeCandles;
        
        _chartData[currencyPair] = finalCandles;
      }
    }

    update();
  }

  // Load wallet data from SharedPreferences
  Future<void> _loadWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load wallet data
      final balance = prefs.getDouble('wallet_balance') ?? 100000.0;
      final margin = prefs.getDouble('wallet_margin') ?? 0.0;
      final freeMargin = prefs.getDouble('wallet_free_margin') ?? 100000.0;
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('wallet_last_update') ??
            DateTime.now().millisecondsSinceEpoch,
      );

      // Load open positions
      final positionsJson = prefs.getString('wallet_open_positions') ?? '[]';
      final List<dynamic> positionsData = json.decode(positionsJson);
      final List<Position> positions = positionsData
          .map((data) => Position.fromJson(data))
          .toList();

      // Load trade history
      final tradesJson = prefs.getString('wallet_trade_history') ?? '[]';
      final List<dynamic> tradesData = json.decode(tradesJson);
      final List<ClosedTrade> trades = tradesData
          .map((data) => ClosedTrade.fromJson(data))
          .toList();

      // Create wallet with loaded data
      _wallet = VirtualWallet(
        balance: balance,
        equity: balance, // Will be recalculated by currentEquity getter
        margin: margin,
        freeMargin: freeMargin,
        marginLevel: margin > 0 ? (balance / margin) * 100 : 0.0,
        openPositions: positions,
        tradeHistory: trades,
        lastUpdate: lastUpdate,
      );
    } catch (e) {
      // Keep default wallet if loading fails
    }
  }

  // Save wallet data to SharedPreferences
  Future<void> _saveWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save basic wallet data
      await prefs.setDouble('wallet_balance', _wallet.balance);
      await prefs.setDouble('wallet_margin', _wallet.margin);
      await prefs.setDouble('wallet_free_margin', _wallet.freeMargin);
      await prefs.setInt(
        'wallet_last_update',
        _wallet.lastUpdate.millisecondsSinceEpoch,
      );

      // Save open positions
      final positionsJson = json.encode(
        _wallet.openPositions.map((position) => position.toJson()).toList(),
      );
      await prefs.setString('wallet_open_positions', positionsJson);

      // Save trade history
      final tradesJson = json.encode(
        _wallet.tradeHistory.map((trade) => trade.toJson()).toList(),
      );
      await prefs.setString('wallet_trade_history', tradesJson);
    } catch (e) {}
  }

  // Toggle simulation
  void toggleSimulation() {
    if (_isSimulationRunning) {
      stopSimulation();
    } else {
      startSimulation();
    }
  }

  // Load chart data for specific symbol
  void loadChartData(String symbol, String timeframe) {
    _chartData[symbol] = _marketService.getChartDataForSymbol(symbol);
    update();
  }

  // Update position prices with current market prices and check for stop loss/take profit
  void _updatePositionPrices() {
    if (_wallet.openPositions.isEmpty) return;

    final updatedPositions = <Position>[];
    final positionsToClose = <Position>[];

    for (final position in _wallet.openPositions) {
      final currentPrice =
          _currentPrices[position.symbol] ?? position.currentPrice;
      final updatedPosition = position.copyWith(currentPrice: currentPrice);

      // Check for stop loss or take profit
      if (_shouldClosePosition(updatedPosition)) {
        positionsToClose.add(updatedPosition);
      } else {
        updatedPositions.add(updatedPosition);
      }
    }

    // Close positions that hit stop loss or take profit
    if (positionsToClose.isNotEmpty) {
      for (final position in positionsToClose) {
        _closePositionAutomatically(position);
      }
    }

    _wallet = _wallet.copyWith(
      openPositions: updatedPositions,
      lastUpdate: DateTime.now(),
    );
  }

  // Check if position should be closed due to stop loss or take profit
  bool _shouldClosePosition(Position position) {
    final currentPrice = position.currentPrice;

    // If no stop loss or take profit is set, don't close
    if (position.stopLoss <= 0 && position.takeProfit <= 0) {
      return false;
    }

    // Prevent positions from being closed immediately after creation (within 10 seconds)
    final timeSinceOpen = DateTime.now().difference(position.openTime);
    if (timeSinceOpen.inSeconds < 10) {
      return false;
    }

    bool shouldClose = false;
    String reason = '';

    if (position.type == PositionType.buy) {
      // For buy positions
      if (position.stopLoss > 0 && currentPrice <= position.stopLoss) {
        shouldClose = true;
        reason = 'Stop Loss Hit';
      } else if (position.takeProfit > 0 && currentPrice >= position.takeProfit) {
        shouldClose = true;
        reason = 'Take Profit Hit';
      }
    } else {
      // For sell positions
      if (position.stopLoss > 0 && currentPrice >= position.stopLoss) {
        shouldClose = true;
        reason = 'Stop Loss Hit';
      } else if (position.takeProfit > 0 && currentPrice <= position.takeProfit) {
        shouldClose = true;
        reason = 'Take Profit Hit';
      }
    }

    return shouldClose;
  }

  // Calculate commission for a position
  double _calculateCommission(Position position) {
    // Simple commission calculation: $7 per lot
    return position.volume * 7.0;
  }

  // Automatically close position when stop loss or take profit is hit
  void _closePositionAutomatically(Position position) {
    final currentPrice = position.currentPrice;


    // Use consistent P&L calculation with manual closing
    const double pipValue = 10.0; // $10 per pip per lot
    const double pipSize = 0.0001; // 1 pip = 0.0001 for major pairs

    double pips;
    if (position.type == PositionType.buy) {
      pips = (currentPrice - position.openPrice) / pipSize;
    } else {
      pips = (position.openPrice - currentPrice) / pipSize;
    }

    final realizedPnL = pips * pipValue * position.volume;
    final commission = _calculateCommission(position);
    final finalPnL = realizedPnL - commission;


    // Create trade record
    final trade = ClosedTrade(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: position.symbol,
      type: position.type,
      volume: position.volume,
      openPrice: position.openPrice,
      closePrice: currentPrice,
      openTime: position.openTime,
      closeTime: DateTime.now(),
      realizedPnL: finalPnL, // Use the final P&L after commission
      commission: commission,
      comment: '',
    );

    // Update wallet
    _wallet = _wallet.copyWith(
      balance: _wallet.balance + finalPnL, // Use final P&L for balance update
      tradeHistory: [..._wallet.tradeHistory, trade],
      lastUpdate: DateTime.now(),
    );

    _saveWalletData(); // Save to SharedPreferences
    update(); // Notify UI of changes
  }

  // Reset account to initial state
  void resetAccount() {
    stopSimulation();
    _wallet = VirtualWallet.initial();
    _currentPrices.clear();
    _chartData.clear();
    _saveWalletData(); // Save reset state to SharedPreferences
    _clearError();
    update();
  }

  // Load demo data for testing
  void loadDemoData() {
    _setLoading(true);

    try {
      // Create some demo positions and trades
      final demoPositions = [
        Position(
          id: '1',
          symbol: 'EUR/USD',
          type: PositionType.buy,
          volume: 0.1,
          openPrice: 1.0850,
          currentPrice: 1.0875,
          openTime: DateTime.now().subtract(const Duration(hours: 2)),
          stopLoss: 1.0800,
          takeProfit: 1.0900,
          comment: 'Demo Buy Position',
        ),
        Position(
          id: '2',
          symbol: 'GBP/USD',
          type: PositionType.sell,
          volume: 0.05,
          openPrice: 1.2650,
          currentPrice: 1.2625,
          openTime: DateTime.now().subtract(const Duration(hours: 1)),
          stopLoss: 1.2700,
          takeProfit: 1.2600,
          comment: 'Demo Sell Position',
        ),
      ];

      final demoTrades = [
        ClosedTrade(
          id: '1',
          symbol: 'USD/JPY',
          type: PositionType.buy,
          volume: 0.1,
          openPrice: 150.00,
          closePrice: 150.50,
          openTime: DateTime.now().subtract(const Duration(days: 1)),
          closeTime: DateTime.now().subtract(const Duration(hours: 6)),
          realizedPnL: 50.0,
          commission: -1.0,
          comment: 'Demo Closed Trade',
        ),
        ClosedTrade(
          id: '2',
          symbol: 'AUD/USD',
          type: PositionType.sell,
          volume: 0.05,
          openPrice: 0.6550,
          closePrice: 0.6525,
          openTime: DateTime.now().subtract(const Duration(days: 2)),
          closeTime: DateTime.now().subtract(const Duration(days: 1)),
          realizedPnL: 12.5,
          commission: -0.5,
          comment: 'Demo Closed Trade 2',
        ),
      ];

      // Update wallet with demo data
      _wallet = _wallet.copyWith(
        openPositions: demoPositions,
        tradeHistory: demoTrades,
        balance: 100250.0, // Updated balance with demo trades
        lastUpdate: DateTime.now(),
      );

      _clearError();
    } catch (e) {
      _setError('Failed to load demo data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update forex rates
  void updateForexRates(List<ForexRate> rates) {
    _forexRates = rates;

    // Update current prices for open positions
    final updatedPositions = _wallet.openPositions.map((position) {
      final rate = _forexRates.firstWhere(
        (r) => r.symbol == position.symbol,
        orElse: () => ForexRate(
          fromCurrency: position.symbol.split('/')[0],
          toCurrency: position.symbol.split('/')[1],
          symbol: position.symbol,
          rate: position.currentPrice,
          timestamp: DateTime.now(),
        ),
      );

      return position.copyWith(currentPrice: rate.rate);
    }).toList();

    _wallet = _wallet.copyWith(
      openPositions: updatedPositions,
      lastUpdate: DateTime.now(),
    );

    update();
  }

  // Update simulation base prices with real market data
  void updateSimulationBasePrices(Map<String, double> basePrices) {
    // Update the market simulation service with real market data as base prices
    _marketService.updateBasePrices(basePrices);

    // Update current prices with dashboard data but allow simulation to continue
    for (String symbol in basePrices.keys) {
      _currentPrices[symbol] = basePrices[symbol]!;
    }
    _updatePositionPrices();
    update();
  }

  // Open a new position
  Future<void> openPosition({
    required String symbol,
    required PositionType type,
    required double volume,
    required double price,
    double? stopLoss,
    double? takeProfit,
  }) async {
    _setLoading(true);

    try {
      // Get current market price from dashboard data first, then simulation
      double currentPrice;
      if (_currentPrices.containsKey(symbol)) {
        // Use dashboard data prices
        currentPrice = type == PositionType.buy
            ? getCurrentAsk(symbol)
            : getCurrentBid(symbol);
      } else if (_isSimulationRunning) {
        // Fallback to simulation
        currentPrice = type == PositionType.buy
            ? _marketService.getAskPrice(symbol)
            : _marketService.getBidPrice(symbol);
      } else {
        currentPrice = price;
      }

      final newPosition = Position(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: symbol,
        type: type,
        volume: volume,
        openPrice: currentPrice,
        currentPrice: currentPrice,
        openTime: DateTime.now(),
        stopLoss: stopLoss ?? 0.0,
        takeProfit: takeProfit ?? 0.0,
        comment: '',
      );

      // Calculate required margin (simplified calculation)
      final requiredMargin =
          volume * currentPrice * 0.01; // 1% margin requirement

      if (_wallet.freeMargin < requiredMargin) {
        throw Exception(
          'Insufficient margin. Required: \$${requiredMargin.toStringAsFixed(2)}',
        );
      }

      final updatedPositions = [..._wallet.openPositions, newPosition];
      final newMargin = _wallet.margin + requiredMargin;
      final newFreeMargin = _wallet.freeMargin - requiredMargin;

      _wallet = _wallet.copyWith(
        openPositions: updatedPositions,
        margin: newMargin,
        freeMargin: newFreeMargin,
        lastUpdate: DateTime.now(),
      );

      _saveWalletData(); // Save to SharedPreferences
      _clearError();
    } catch (e) {
      _setError('Failed to open position: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Close a position
  Future<void> closePosition(String positionId, double closePrice) async {
    _setLoading(true);

    try {
      final position = _wallet.openPositions.firstWhere(
        (p) => p.id == positionId,
        orElse: () => throw Exception('Position not found'),
      );

      // Get current market price from dashboard data first, then simulation
      double currentClosePrice;
      if (_currentPrices.containsKey(position.symbol)) {
        // Use dashboard data prices
        currentClosePrice = position.type == PositionType.buy
            ? getCurrentBid(position.symbol)
            : getCurrentAsk(position.symbol);
      } else if (_isSimulationRunning) {
        // Fallback to simulation
        currentClosePrice = position.type == PositionType.buy
            ? _marketService.getBidPrice(position.symbol)
            : _marketService.getAskPrice(position.symbol);
      } else {
        currentClosePrice = closePrice;
      }

      // Calculate realized P&L (using same calculation as unrealizedPnL)
      const double pipValue = 10.0; // $10 per pip per lot
      const double pipSize = 0.0001; // 1 pip = 0.0001 for major pairs

      double pips;
      if (position.type == PositionType.buy) {
        pips = (currentClosePrice - position.openPrice) / pipSize;
      } else {
        pips = (position.openPrice - currentClosePrice) / pipSize;
      }

      final realizedPnL = pips * pipValue * position.volume;
      final commission = _calculateCommission(position);
      final finalPnL = realizedPnL - commission;

      // Create closed trade
      final closedTrade = ClosedTrade(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: position.symbol,
        type: position.type,
        volume: position.volume,
        openPrice: position.openPrice,
        closePrice: currentClosePrice,
        openTime: position.openTime,
        closeTime: DateTime.now(),
        realizedPnL: finalPnL, // Use final P&L after commission
        commission: commission, // Use calculated commission
        comment: position.comment,
      );

      // Update wallet
      final updatedPositions = _wallet.openPositions
          .where((p) => p.id != positionId)
          .toList();
      final updatedTrades = [..._wallet.tradeHistory, closedTrade];
      final newBalance =
          _wallet.balance + finalPnL; // Use final P&L for balance
      final newMargin =
          _wallet.margin - (position.volume * position.openPrice * 0.01);
      final newFreeMargin =
          _wallet.freeMargin + (position.volume * position.openPrice * 0.01);

      _wallet = _wallet.copyWith(
        openPositions: updatedPositions,
        tradeHistory: updatedTrades,
        balance: newBalance,
        margin: newMargin,
        freeMargin: newFreeMargin,
        lastUpdate: DateTime.now(),
      );

      _saveWalletData(); // Save to SharedPreferences
      _clearError();
      update(); // Notify UI of changes
    } catch (e) {
      _setError('Failed to close position: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset wallet to initial state
  void resetWallet() {
    _wallet = VirtualWallet.initial();
    _saveWalletData(); // Save reset state to SharedPreferences
    _clearError();
    update();
  }

  // Dispose resources
  @override
  void dispose() {
    _simulationTimer?.cancel();
    _marketService.dispose();
    super.dispose();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Clear all saved data from SharedPreferences
  Future<void> clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_balance');
      await prefs.remove('wallet_margin');
      await prefs.remove('wallet_free_margin');
      await prefs.remove('wallet_last_update');
      await prefs.remove('wallet_open_positions');
      await prefs.remove('wallet_trade_history');
    } catch (e) {}
  }

  // Manually save current wallet data (useful for debugging)
  Future<void> saveCurrentData() async {
    await _saveWalletData();
  }

  // Modify position (for stop loss/take profit updates)
  Future<void> modifyPosition(
    String positionId, {
    double? stopLoss,
    double? takeProfit,
  }) async {
    _setLoading(true);

    try {
      final positionIndex = _wallet.openPositions.indexWhere(
        (p) => p.id == positionId,
      );
      if (positionIndex == -1) {
        throw Exception('Position not found');
      }

      final position = _wallet.openPositions[positionIndex];
      final updatedPosition = position.copyWith(
        stopLoss: stopLoss ?? position.stopLoss,
        takeProfit: takeProfit ?? position.takeProfit,
      );

      final updatedPositions = List<Position>.from(_wallet.openPositions);
      updatedPositions[positionIndex] = updatedPosition;

      _wallet = _wallet.copyWith(
        openPositions: updatedPositions,
        lastUpdate: DateTime.now(),
      );

      _saveWalletData(); // Save to SharedPreferences
      _clearError();
    } catch (e) {
      _setError('Failed to modify position: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get open positions count
  int get openPositionsCount => _wallet.openPositions.length;

  // Debug current state
  void debugCurrentState() {
    // Debug method - no output needed
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    update();
  }

  void _setError(String error) {
    _error = error;
    update();
  }

  void _clearError() {
    _error = null;
    update();
  }

  // Toggle realistic mode (always true for paper trading)
  void toggleRealisticMode() {
    // Always realistic mode for paper trading
  }

  // Get current bid price for a symbol (based on dashboard data)
  double getCurrentBid(String symbol) {
    // First try to get from current prices (updated from dashboard)
    if (_currentPrices.containsKey(symbol)) {
      final midPrice = _currentPrices[symbol]!;
      final spread = _marketService.getDynamicSpread(symbol);
      return midPrice - (spread / 2);
    }

    // Fallback to simulation service
    return _marketService.getBidPriceRealistic(symbol);
  }

  // Get current ask price for a symbol (based on dashboard data)
  double getCurrentAsk(String symbol) {
    // First try to get from current prices (updated from dashboard)
    if (_currentPrices.containsKey(symbol)) {
      final midPrice = _currentPrices[symbol]!;
      final spread = _marketService.getDynamicSpread(symbol);
      return midPrice + (spread / 2);
    }

    // Fallback to simulation service
    return _marketService.getAskPriceRealistic(symbol);
  }
}
