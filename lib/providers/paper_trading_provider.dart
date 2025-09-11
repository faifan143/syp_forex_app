import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paper_trading_models.dart';
import '../models/forex_models.dart';
import '../services/market_simulation_service.dart';

class PaperTradingProvider extends GetxController {
  VirtualWallet _wallet = VirtualWallet.initial();
  List<ForexRate> _forexRates = [];
  bool _isLoading = false;
  String? _error;

  // Market Simulation
  final MarketSimulationService _marketService = MarketSimulationService();
  bool _isSimulationRunning = false;
  Map<String, double> _currentPrices = {};
  Map<String, List<Map<String, double>>> _chartData = {};
  StreamSubscription<Map<String, double>>? _priceSubscription;
  StreamSubscription<Map<String, List<Map<String, double>>>>?
  _chartSubscription;

  // Getters
  VirtualWallet get wallet => _wallet;
  List<ForexRate> get forexRates => _forexRates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Simulation Getters
  bool get isSimulationRunning => _isSimulationRunning;
  Map<String, double> get currentPrices => _currentPrices;
  Map<String, List<Map<String, double>>> get chartData => _chartData;
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

      print('✅ [PAPER_TRADING] Loaded wallet data from SharedPreferences');
      print('💰 Balance: \$${balance.toStringAsFixed(2)}');
      print('📊 Open Positions: ${positions.length}');
      print('📈 Trade History: ${trades.length} trades');
    } catch (e) {
      print('❌ [PAPER_TRADING] Error loading wallet data: $e');
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

      print('💾 [PAPER_TRADING] Saved wallet data to SharedPreferences');
    } catch (e) {
      print('❌ [PAPER_TRADING] Error saving wallet data: $e');
    }
  }

  // Start market simulation (now primarily for chart data, prices come from dashboard)
  void startSimulation({String timeframe = '1m'}) {
    if (_isSimulationRunning) {
      print('⚠️ [PAPER_TRADING] Simulation already running, skipping start');
      return;
    }

    print('🚀 [PAPER_TRADING] Starting simulation with timeframe: $timeframe');
    _isSimulationRunning = true;
    _marketService.startSimulation(timeframe: timeframe);

    // Subscribe to price updates - allow simulation to continue updating all prices
    print('🔄 [PAPER_TRADING] Setting up price stream subscription...');
    _priceSubscription = _marketService.priceStream.listen((prices) {
      print(
        '🔄 [PAPER_TRADING] Received price update: ${prices.length} symbols',
      );
      // Update all prices from simulation (simulation continues running)
      for (String symbol in prices.keys) {
        _currentPrices[symbol] = prices[symbol]!;
      }
      _updatePositionPrices();
      update();
      print('🔄 [PAPER_TRADING] Updated UI with new prices');
    });
    print('🔄 [PAPER_TRADING] Price stream subscription set up successfully');

    // Subscribe to chart updates
    _chartSubscription = _marketService.chartStream.listen((chartData) {
      _chartData = chartData;
      update();
    });

    update();
  }

  // Stop market simulation
  void stopSimulation() {
    if (!_isSimulationRunning) return;

    _isSimulationRunning = false;
    _marketService.stopSimulation();
    _priceSubscription?.cancel();
    _chartSubscription?.cancel();
    update();
  }

  // Update simulation timeframe
  void updateTimeframe(String timeframe) {
    if (_isSimulationRunning) {
      _marketService.updateTimeframe(timeframe);
      update();
    }
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
    for (final position in positionsToClose) {
      _closePositionAutomatically(position);
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

    if (position.type == PositionType.buy) {
      // For buy positions
      if (position.stopLoss > 0 && currentPrice <= position.stopLoss) {
        return true; // Stop loss hit
      }
      if (position.takeProfit > 0 && currentPrice >= position.takeProfit) {
        return true; // Take profit hit
      }
    } else {
      // For sell positions
      if (position.stopLoss > 0 && currentPrice >= position.stopLoss) {
        return true; // Stop loss hit
      }
      if (position.takeProfit > 0 && currentPrice <= position.takeProfit) {
        return true; // Take profit hit
      }
    }

    return false;
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

    print(
      '🔄 [TRADE_HISTORY] Position closed automatically: ${position.symbol} - P&L: \$${finalPnL.toStringAsFixed(2)}',
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
    double? stopLossDollars,
    double? takeProfitDollars,
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

      // Convert dollar amounts to price levels if provided
      double? finalStopLoss = stopLoss;
      double? finalTakeProfit = takeProfit;

      if (stopLossDollars != null && stopLossDollars > 0) {
        // Calculate price level for stop loss based on dollar amount
        final pipValue = _calculatePipValue(symbol, currentPrice, volume);
        final stopLossPips = stopLossDollars / pipValue;
        final pipSize = _getPipSize(symbol);

        if (type == PositionType.buy) {
          finalStopLoss = currentPrice - (stopLossPips * pipSize);
        } else {
          finalStopLoss = currentPrice + (stopLossPips * pipSize);
        }
      }

      if (takeProfitDollars != null && takeProfitDollars > 0) {
        // Calculate price level for take profit based on dollar amount
        final pipValue = _calculatePipValue(symbol, currentPrice, volume);
        final takeProfitPips = takeProfitDollars / pipValue;
        final pipSize = _getPipSize(symbol);

        if (type == PositionType.buy) {
          finalTakeProfit = currentPrice + (takeProfitPips * pipSize);
        } else {
          finalTakeProfit = currentPrice - (takeProfitPips * pipSize);
        }
      }

      final newPosition = Position(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: symbol,
        type: type,
        volume: volume,
        openPrice: currentPrice,
        currentPrice: currentPrice,
        openTime: DateTime.now(),
        stopLoss: finalStopLoss ?? 0.0,
        takeProfit: finalTakeProfit ?? 0.0,
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

      print(
        '🔄 [TRADE_HISTORY] Position closed manually: ${position.symbol} - P&L: \$${finalPnL.toStringAsFixed(2)}',
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
    _priceSubscription?.cancel();
    _chartSubscription?.cancel();
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

      print(
        '🗑️ [PAPER_TRADING] Cleared all saved data from SharedPreferences',
      );
    } catch (e) {
      print('❌ [PAPER_TRADING] Error clearing saved data: $e');
    }
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
    print('=== Paper Trading Debug State ===');
    print('Balance: \$${_wallet.balance.toStringAsFixed(2)}');
    print('Equity: \$${_wallet.currentEquity.toStringAsFixed(2)}');
    print('Margin: \$${_wallet.margin.toStringAsFixed(2)}');
    print('Free Margin: \$${_wallet.freeMargin.toStringAsFixed(2)}');
    print('Open Positions: ${_wallet.openPositions.length}');
    print('Trade History: ${_wallet.tradeHistory.length}');
    print('================================');
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

  // Calculate pip value for a given symbol, price, and volume
  double _calculatePipValue(String symbol, double price, double volume) {
    final pipSize = _getPipSize(symbol);
    final contractSize = 100000.0; // Standard lot size
    final pipValue = (pipSize / price) * contractSize * volume;
    return pipValue;
  }

  // Get pip size for different currency pairs
  double _getPipSize(String symbol) {
    if (symbol.contains('JPY')) {
      return 0.01; // 0.01 for JPY pairs
    }
    return 0.0001; // 0.0001 for most pairs
  }
}
