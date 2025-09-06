

// Virtual wallet for paper trading
class VirtualWallet {
  final double balance;
  final double equity;
  final double margin;
  final double freeMargin;
  final double marginLevel;
  final List<Position> openPositions;
  final List<ClosedTrade> tradeHistory;
  final DateTime lastUpdate;

  VirtualWallet({
    required this.balance,
    required this.equity,
    required this.margin,
    required this.freeMargin,
    required this.marginLevel,
    required this.openPositions,
    required this.tradeHistory,
    required this.lastUpdate,
  });

  // Calculate current equity based on open positions
  double get currentEquity {
    double unrealizedPnL = 0.0;
    for (final position in openPositions) {
      unrealizedPnL += position.unrealizedPnL;
    }
    return balance + unrealizedPnL;
  }

  // Calculate margin level percentage
  double get marginLevelPercent => (equity / margin) * 100;

  // Check if margin call is needed
  bool get isMarginCall => marginLevel < 100.0;

  // Get total open positions count
  int get totalPositions => openPositions.length;

  // Get total volume of open positions
  double get totalVolume {
    double volume = 0.0;
    for (final position in openPositions) {
      volume += position.volume;
    }
    return volume;
  }

  // Create initial wallet
  factory VirtualWallet.initial() {
    return VirtualWallet(
      balance: 100000.0, // $100,000 starting balance
      equity: 100000.0,
      margin: 0.0,
      freeMargin: 100000.0,
      marginLevel: 0.0,
      openPositions: [],
      tradeHistory: [],
      lastUpdate: DateTime.now(),
    );
  }

  // Copy with updates
  VirtualWallet copyWith({
    double? balance,
    double? equity,
    double? margin,
    double? freeMargin,
    double? marginLevel,
    List<Position>? openPositions,
    List<ClosedTrade>? tradeHistory,
    DateTime? lastUpdate,
  }) {
    return VirtualWallet(
      balance: balance ?? this.balance,
      equity: equity ?? this.equity,
      margin: margin ?? this.margin,
      freeMargin: freeMargin ?? this.freeMargin,
      marginLevel: marginLevel ?? this.marginLevel,
      openPositions: openPositions ?? this.openPositions,
      tradeHistory: tradeHistory ?? this.tradeHistory,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'equity': equity,
      'margin': margin,
      'freeMargin': freeMargin,
      'marginLevel': marginLevel,
      'openPositions': openPositions.map((p) => p.toJson()).toList(),
      'tradeHistory': tradeHistory.map((t) => t.toJson()).toList(),
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  factory VirtualWallet.fromJson(Map<String, dynamic> json) {
    return VirtualWallet(
      balance: json['balance']?.toDouble() ?? 0.0,
      equity: json['equity']?.toDouble() ?? 0.0,
      margin: json['margin']?.toDouble() ?? 0.0,
      freeMargin: json['freeMargin']?.toDouble() ?? 0.0,
      marginLevel: json['marginLevel']?.toDouble() ?? 0.0,
      openPositions: (json['openPositions'] as List?)
          ?.map((p) => Position.fromJson(p))
          .toList() ?? [],
      tradeHistory: (json['tradeHistory'] as List?)
          ?.map((t) => ClosedTrade.fromJson(t))
          .toList() ?? [],
      lastUpdate: DateTime.parse(json['lastUpdate'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Open trading position
class Position {
  final String id;
  final String symbol;
  final PositionType type;
  final double volume;
  final double openPrice;
  final double currentPrice;
  final DateTime openTime;
  final double stopLoss;
  final double takeProfit;
  final String? comment;

  Position({
    required this.id,
    required this.symbol,
    required this.type,
    required this.volume,
    required this.openPrice,
    required this.currentPrice,
    required this.openTime,
    this.stopLoss = 0.0,
    this.takeProfit = 0.0,
    this.comment,
  });

  // Calculate unrealized P&L
  double get unrealizedPnL {
    // For forex, 1 pip = 0.0001, and pip value is $10 per lot for major pairs
    const double pipValue = 10.0; // $10 per pip per lot
    const double pipSize = 0.0001; // 1 pip = 0.0001 for major pairs
    
    double pips;
    if (type == PositionType.buy) {
      pips = (currentPrice - openPrice) / pipSize;
    } else {
      pips = (openPrice - currentPrice) / pipSize;
    }
    
    return pips * pipValue * volume;
  }

  // Calculate P&L percentage
  double get pnlPercent {
    if (type == PositionType.buy) {
      return ((currentPrice - openPrice) / openPrice) * 100;
    } else {
      return ((openPrice - currentPrice) / openPrice) * 100;
    }
  }

  // Check if position is profitable
  bool get isProfitable => unrealizedPnL > 0;

  // Check if position is at stop loss
  bool get isAtStopLoss {
    if (stopLoss == 0.0) return false;
    if (type == PositionType.buy) {
      return currentPrice <= stopLoss;
    } else {
      return currentPrice >= stopLoss;
    }
  }

  // Check if position is at take profit
  bool get isAtTakeProfit {
    if (takeProfit == 0.0) return false;
    if (type == PositionType.buy) {
      return currentPrice >= takeProfit;
    } else {
      return currentPrice <= takeProfit;
    }
  }

  // Get position value
  double get positionValue => currentPrice * volume;

  // Get margin required (simplified calculation)
  double get marginRequired => positionValue * 0.02; // 2% margin requirement

  // Update current price
  Position copyWithPrice(double newPrice) {
    return Position(
      id: id,
      symbol: symbol,
      type: type,
      volume: volume,
      openPrice: openPrice,
      currentPrice: newPrice,
      openTime: openTime,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      comment: comment,
    );
  }

  // Copy with updates
  Position copyWith({
    String? id,
    String? symbol,
    PositionType? type,
    double? volume,
    double? openPrice,
    double? currentPrice,
    DateTime? openTime,
    double? stopLoss,
    double? takeProfit,
    String? comment,
  }) {
    return Position(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      volume: volume ?? this.volume,
      openPrice: openPrice ?? this.openPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      openTime: openTime ?? this.openTime,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      comment: comment ?? this.comment,
    );
  }

  // Update stop loss or take profit
  Position copyWithOrders({
    double? stopLoss,
    double? takeProfit,
  }) {
    return Position(
      id: id,
      symbol: symbol,
      type: type,
      volume: volume,
      openPrice: openPrice,
      currentPrice: currentPrice,
      openTime: openTime,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      comment: comment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.name,
      'volume': volume,
      'openPrice': openPrice,
      'currentPrice': currentPrice,
      'openTime': openTime.toIso8601String(),
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'comment': comment,
    };
  }

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      type: PositionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PositionType.buy,
      ),
      volume: json['volume']?.toDouble() ?? 0.0,
      openPrice: json['openPrice']?.toDouble() ?? 0.0,
      currentPrice: json['currentPrice']?.toDouble() ?? 0.0,
      openTime: DateTime.parse(json['openTime'] ?? DateTime.now().toIso8601String()),
      stopLoss: json['stopLoss']?.toDouble() ?? 0.0,
      takeProfit: json['takeProfit']?.toDouble() ?? 0.0,
      comment: json['comment'],
    );
  }
}

// Closed trade record
class ClosedTrade {
  final String id;
  final String symbol;
  final PositionType type;
  final double volume;
  final double openPrice;
  final double closePrice;
  final DateTime openTime;
  final DateTime closeTime;
  final double realizedPnL;
  final double commission;
  final String? comment;

  ClosedTrade({
    required this.id,
    required this.symbol,
    required this.type,
    required this.volume,
    required this.openPrice,
    required this.closePrice,
    required this.openTime,
    required this.closeTime,
    required this.realizedPnL,
    this.commission = 0.0,
    this.comment,
  });

  // Calculate trade duration
  Duration get duration => closeTime.difference(openTime);

  // Calculate P&L percentage
  double get pnlPercent {
    if (type == PositionType.buy) {
      return ((closePrice - openPrice) / openPrice) * 100;
    } else {
      return ((openPrice - closePrice) / openPrice) * 100;
    }
  }

  // Check if trade was profitable
  bool get isProfitable => realizedPnL > 0;

  // Get trade value
  double get tradeValue => closePrice * volume;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.name,
      'volume': volume,
      'openPrice': openPrice,
      'closePrice': closePrice,
      'openTime': openTime.toIso8601String(),
      'closeTime': closeTime.toIso8601String(),
      'realizedPnL': realizedPnL,
      'commission': commission,
      'comment': comment,
    };
  }

  factory ClosedTrade.fromJson(Map<String, dynamic> json) {
    return ClosedTrade(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      type: PositionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PositionType.buy,
      ),
      volume: json['volume']?.toDouble() ?? 0.0,
      openPrice: json['openPrice']?.toDouble() ?? 0.0,
      closePrice: json['closePrice']?.toDouble() ?? 0.0,
      openTime: DateTime.parse(json['openTime'] ?? DateTime.now().toIso8601String()),
      closeTime: DateTime.parse(json['closeTime'] ?? DateTime.now().toIso8601String()),
      realizedPnL: json['realizedPnL']?.toDouble() ?? 0.0,
      commission: json['commission']?.toDouble() ?? 0.0,
      comment: json['comment'],
    );
  }
}

// Position type (Buy/Sell)
enum PositionType {
  buy,
  sell,
}

// Order types
enum OrderType {
  market,
  limit,
  stop,
  stopLimit,
}

// Order status
enum OrderStatus {
  pending,
  filled,
  cancelled,
  rejected,
}

// Trading order
class Order {
  final String id;
  final String symbol;
  final OrderType type;
  final PositionType positionType;
  final double volume;
  final double price;
  final double? stopLoss;
  final double? takeProfit;
  final OrderStatus status;
  final DateTime createTime;
  final DateTime? fillTime;
  final String? comment;

  Order({
    required this.id,
    required this.symbol,
    required this.type,
    required this.positionType,
    required this.volume,
    required this.price,
    this.stopLoss,
    this.takeProfit,
    this.status = OrderStatus.pending,
    required this.createTime,
    this.fillTime,
    this.comment,
  });

  // Check if order is pending
  bool get isPending => status == OrderStatus.pending;

  // Check if order is filled
  bool get isFilled => status == OrderStatus.filled;

  // Get order value
  double get orderValue => price * volume;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.name,
      'positionType': positionType.name,
      'volume': volume,
      'price': price,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'status': status.name,
      'createTime': createTime.toIso8601String(),
      'fillTime': fillTime?.toIso8601String(),
      'comment': comment,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      type: OrderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OrderType.market,
      ),
      positionType: PositionType.values.firstWhere(
        (e) => e.name == json['positionType'],
        orElse: () => PositionType.buy,
      ),
      volume: json['volume']?.toDouble() ?? 0.0,
      price: json['price']?.toDouble() ?? 0.0,
      stopLoss: json['stopLoss']?.toDouble(),
      takeProfit: json['takeProfit']?.toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createTime: DateTime.parse(json['createTime'] ?? DateTime.now().toIso8601String()),
      fillTime: json['fillTime'] != null 
          ? DateTime.parse(json['fillTime'])
          : null,
      comment: json['comment'],
    );
  }
}

// Trading statistics
class TradingStats {
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double totalPnL;
  final double winningPnL;
  final double losingPnL;
  final double winRate;
  final double averageWin;
  final double averageLoss;
  final double profitFactor;
  final double maxDrawdown;
  final DateTime startDate;

  TradingStats({
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.totalPnL,
    required this.winningPnL,
    required this.losingPnL,
    required this.winRate,
    required this.averageWin,
    required this.averageLoss,
    required this.profitFactor,
    required this.maxDrawdown,
    required this.startDate,
  });

  // Calculate from trade history
  factory TradingStats.fromTrades(List<ClosedTrade> trades) {
    if (trades.isEmpty) {
      return TradingStats.empty();
    }

    final winningTrades = trades.where((t) => t.isProfitable).toList();
    final losingTrades = trades.where((t) => !t.isProfitable).toList();

    final totalPnL = trades.fold(0.0, (sum, t) => sum + t.realizedPnL);
    final winningPnL = winningTrades.fold(0.0, (sum, t) => sum + t.realizedPnL);
    final losingPnL = losingTrades.fold(0.0, (sum, t) => sum + t.realizedPnL);

    final winRate = trades.length > 0 ? (winningTrades.length / trades.length) * 100 : 0.0;
    final averageWin = winningTrades.isNotEmpty ? winningPnL / winningTrades.length : 0.0;
    final averageLoss = losingTrades.isNotEmpty ? losingPnL / losingTrades.length : 0.0;
    final profitFactor = averageLoss != 0 ? averageWin / averageLoss.abs() : 0.0;

    // Calculate max drawdown (simplified)
    double maxDrawdown = 0.0;
    double peak = 0.0;
    double runningTotal = 0.0;
    
    for (final trade in trades) {
      runningTotal += trade.realizedPnL;
      if (runningTotal > peak) {
        peak = runningTotal;
      }
      final drawdown = peak - runningTotal;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }

    return TradingStats(
      totalTrades: trades.length,
      winningTrades: winningTrades.length,
      losingTrades: losingTrades.length,
      totalPnL: totalPnL,
      winningPnL: winningPnL,
      losingPnL: losingPnL,
      winRate: winRate,
      averageWin: averageWin,
      averageLoss: averageLoss,
      profitFactor: profitFactor,
      maxDrawdown: maxDrawdown,
      startDate: trades.map((t) => t.openTime).reduce((a, b) => a.isBefore(b) ? a : b),
    );
  }

  // Empty stats
  factory TradingStats.empty() {
    return TradingStats(
      totalTrades: 0,
      winningTrades: 0,
      losingTrades: 0,
      totalPnL: 0.0,
      winningPnL: 0.0,
      losingPnL: 0.0,
      winRate: 0.0,
      averageWin: 0.0,
      averageLoss: 0.0,
      profitFactor: 0.0,
      maxDrawdown: 0.0,
      startDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTrades': totalTrades,
      'winningTrades': winningTrades,
      'losingTrades': losingTrades,
      'totalPnL': totalPnL,
      'winningPnL': winningPnL,
      'losingPnL': losingPnL,
      'winRate': winRate,
      'averageWin': averageWin,
      'averageLoss': averageLoss,
      'profitFactor': profitFactor,
      'maxDrawdown': maxDrawdown,
      'startDate': startDate.toIso8601String(),
    };
  }

  factory TradingStats.fromJson(Map<String, dynamic> json) {
    return TradingStats(
      totalTrades: json['totalTrades'] ?? 0,
      winningTrades: json['winningTrades'] ?? 0,
      losingTrades: json['losingTrades'] ?? 0,
      totalPnL: json['totalPnL']?.toDouble() ?? 0.0,
      winningPnL: json['winningPnL']?.toDouble() ?? 0.0,
      losingPnL: json['losingPnL']?.toDouble() ?? 0.0,
      winRate: json['winRate']?.toDouble() ?? 0.0,
      averageWin: json['averageWin']?.toDouble() ?? 0.0,
      averageLoss: json['averageLoss']?.toDouble() ?? 0.0,
      profitFactor: json['profitFactor']?.toDouble() ?? 0.0,
      maxDrawdown: json['maxDrawdown']?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}



