import 'package:get/get.dart';
import 'dart:async';
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
  StreamSubscription<Map<String, List<Map<String, double>>>>? _chartSubscription;

  // Getters
  VirtualWallet get wallet => _wallet;
  List<ForexRate> get forexRates => _forexRates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Simulation Getters
  bool get isSimulationRunning => _isSimulationRunning;
  Map<String, double> get currentPrices => _currentPrices;
  Map<String, List<Map<String, double>>> get chartData => _chartData;

  // Computed properties
  double get currentBalance => _wallet.balance;
  double get currentEquity => _wallet.currentEquity;
  double get totalPnL => _wallet.currentEquity - _wallet.balance;
  double get totalPnLPercent => _wallet.balance > 0 ? (totalPnL / _wallet.balance) * 100 : 0.0;
  List<Position> get openPositions => _wallet.openPositions;
  TradingStats get tradingStats => TradingStats.fromTrades(_wallet.tradeHistory);
  bool get isMarginCall => _wallet.isMarginCall;
  bool get realisticMode => true; // Always realistic mode for paper trading

  // Initialize the provider
  void initialize() {
    _wallet = VirtualWallet.initial();
    update();
  }
  
  // Start market simulation
  void startSimulation() {
    if (_isSimulationRunning) return;
    
    _isSimulationRunning = true;
    _marketService.startSimulation();
    
    // Subscribe to price updates
    _priceSubscription = _marketService.priceStream.listen((prices) {
      _currentPrices = prices;
      _updatePositionPrices();
      update();
    });
    
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
  
  // Update position prices with current market prices
  void _updatePositionPrices() {
    final updatedPositions = _wallet.openPositions.map((position) {
      final currentPrice = _currentPrices[position.symbol] ?? position.currentPrice;
      return position.copyWith(currentPrice: currentPrice);
    }).toList();
    
    _wallet = _wallet.copyWith(
      openPositions: updatedPositions,
      lastUpdate: DateTime.now(),
    );
  }
  
  // Reset account to initial state
  void resetAccount() {
    stopSimulation();
    _wallet = VirtualWallet.initial();
    _currentPrices.clear();
    _chartData.clear();
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

  // Open a new position
  Future<void> openPosition({
    required String symbol,
    required PositionType type,
    required double volume,
    required double price,
    double? stopLoss,
    double? takeProfit,
    String? comment,
  }) async {
    _setLoading(true);
    
    try {
      // Get current market price if simulation is running
      final currentPrice = _isSimulationRunning 
          ? (type == PositionType.buy ? _marketService.getAskPrice(symbol) : _marketService.getBidPrice(symbol))
          : price;
      
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
        comment: comment ?? '',
      );

      // Calculate required margin (simplified calculation)
      final requiredMargin = volume * currentPrice * 0.01; // 1% margin requirement
      
      if (_wallet.freeMargin < requiredMargin) {
        throw Exception('Insufficient margin. Required: \$${requiredMargin.toStringAsFixed(2)}');
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

      // Get current market price if simulation is running
      final currentClosePrice = _isSimulationRunning 
          ? (position.type == PositionType.buy ? _marketService.getBidPrice(position.symbol) : _marketService.getAskPrice(position.symbol))
          : closePrice;

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
        realizedPnL: realizedPnL,
        commission: -1.0, // Fixed commission
        comment: position.comment,
      );

      // Update wallet
      final updatedPositions = _wallet.openPositions.where((p) => p.id != positionId).toList();
      final updatedTrades = [..._wallet.tradeHistory, closedTrade];
      final newBalance = _wallet.balance + realizedPnL;
      final newMargin = _wallet.margin - (position.volume * position.openPrice * 0.01);
      final newFreeMargin = _wallet.freeMargin + (position.volume * position.openPrice * 0.01);

      _wallet = _wallet.copyWith(
        openPositions: updatedPositions,
        tradeHistory: updatedTrades,
        balance: newBalance,
        margin: newMargin,
        freeMargin: newFreeMargin,
        lastUpdate: DateTime.now(),
      );

      _clearError();
    } catch (e) {
      _setError('Failed to close position: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset wallet to initial state
  void resetWallet() {
    _wallet = VirtualWallet.initial();
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

  // Modify position (for stop loss/take profit updates)
  Future<void> modifyPosition(String positionId, {double? stopLoss, double? takeProfit}) async {
    _setLoading(true);
    
    try {
      final positionIndex = _wallet.openPositions.indexWhere((p) => p.id == positionId);
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

  // Get current bid price for a symbol
  double getCurrentBid(String symbol) {
    return _marketService.getBidPriceRealistic(symbol);
  }

  // Get current ask price for a symbol
  double getCurrentAsk(String symbol) {
    return _marketService.getAskPriceRealistic(symbol);
  }
}
