class Mt5AccountInfo {
  final int login;
  final String name;
  final String server;
  final double balance;
  final double equity;
  final double margin;
  final double freeMargin;
  final double marginLevel;
  final String currency;
  final double leverage;
  final String accountType;
  final DateTime lastUpdate;

  Mt5AccountInfo({
    required this.login,
    required this.name,
    required this.server,
    required this.balance,
    required this.equity,
    required this.margin,
    required this.freeMargin,
    required this.marginLevel,
    required this.currency,
    required this.leverage,
    required this.accountType,
    required this.lastUpdate,
  });

  factory Mt5AccountInfo.fromJson(Map<String, dynamic> json) {
    return Mt5AccountInfo(
      login: json['login'] ?? 0,
      name: json['name'] ?? '',
      server: json['server'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      equity: (json['equity'] ?? 0.0).toDouble(),
      margin: (json['margin'] ?? 0.0).toDouble(),
      freeMargin: (json['freeMargin'] ?? 0.0).toDouble(),
      marginLevel: (json['marginLevel'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      leverage: (json['leverage'] ?? 100.0).toDouble(),
      accountType: json['accountType'] ?? 'DEMO',
      lastUpdate: DateTime.tryParse(json['lastUpdate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'name': name,
      'server': server,
      'balance': balance,
      'equity': equity,
      'margin': margin,
      'freeMargin': freeMargin,
      'marginLevel': marginLevel,
      'currency': currency,
      'leverage': leverage,
      'accountType': accountType,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  double get profit => equity - balance;
  double get profitPercent => balance > 0 ? (profit / balance) * 100 : 0.0;
}

class Mt5Position {
  final int ticket;
  final String symbol;
  final String type; // 'buy' or 'sell'
  final double volume;
  final double openPrice;
  final double currentPrice;
  final double stopLoss;
  final double takeProfit;
  final double profit;
  final double swap;
  final double commission;
  final DateTime openTime;
  final String comment;

  Mt5Position({
    required this.ticket,
    required this.symbol,
    required this.type,
    required this.volume,
    required this.openPrice,
    required this.currentPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.profit,
    required this.swap,
    required this.commission,
    required this.openTime,
    required this.comment,
  });

  factory Mt5Position.fromJson(Map<String, dynamic> json) {
    return Mt5Position(
      ticket: json['ticket'] ?? 0,
      symbol: json['symbol'] ?? '',
      type: json['type'] ?? '',
      volume: (json['volume'] ?? 0.0).toDouble(),
      openPrice: (json['openPrice'] ?? 0.0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      stopLoss: (json['stopLoss'] ?? 0.0).toDouble(),
      takeProfit: (json['takeProfit'] ?? 0.0).toDouble(),
      profit: (json['profit'] ?? 0.0).toDouble(),
      swap: (json['swap'] ?? 0.0).toDouble(),
      commission: (json['commission'] ?? 0.0).toDouble(),
      openTime: DateTime.tryParse(json['openTime'] ?? '') ?? DateTime.now(),
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket': ticket,
      'symbol': symbol,
      'type': type,
      'volume': volume,
      'openPrice': openPrice,
      'currentPrice': currentPrice,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'profit': profit,
      'swap': swap,
      'commission': commission,
      'openTime': openTime.toIso8601String(),
      'comment': comment,
    };
  }

  double get totalPnL => profit + swap + commission;
  bool get isBuy => type.toLowerCase() == 'buy';
  bool get isSell => type.toLowerCase() == 'sell';
}

class Mt5Trade {
  final int ticket;
  final String symbol;
  final String type; // 'buy' or 'sell'
  final double volume;
  final double openPrice;
  final double closePrice;
  final double profit;
  final double swap;
  final double commission;
  final DateTime openTime;
  final DateTime closeTime;
  final String comment;

  Mt5Trade({
    required this.ticket,
    required this.symbol,
    required this.type,
    required this.volume,
    required this.openPrice,
    required this.closePrice,
    required this.profit,
    required this.swap,
    required this.commission,
    required this.openTime,
    required this.closeTime,
    required this.comment,
  });

  factory Mt5Trade.fromJson(Map<String, dynamic> json) {
    return Mt5Trade(
      ticket: json['ticket'] ?? 0,
      symbol: json['symbol'] ?? '',
      type: json['type'] ?? '',
      volume: (json['volume'] ?? 0.0).toDouble(),
      openPrice: (json['openPrice'] ?? 0.0).toDouble(),
      closePrice: (json['closePrice'] ?? 0.0).toDouble(),
      profit: (json['profit'] ?? 0.0).toDouble(),
      swap: (json['swap'] ?? 0.0).toDouble(),
      commission: (json['commission'] ?? 0.0).toDouble(),
      openTime: DateTime.tryParse(json['openTime'] ?? '') ?? DateTime.now(),
      closeTime: DateTime.tryParse(json['closeTime'] ?? '') ?? DateTime.now(),
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket': ticket,
      'symbol': symbol,
      'type': type,
      'volume': volume,
      'openPrice': openPrice,
      'closePrice': closePrice,
      'profit': profit,
      'swap': swap,
      'commission': commission,
      'openTime': openTime.toIso8601String(),
      'closeTime': closeTime.toIso8601String(),
      'comment': comment,
    };
  }

  double get totalPnL => profit + swap + commission;
  bool get isBuy => type.toLowerCase() == 'buy';
  bool get isSell => type.toLowerCase() == 'sell';
}

class Mt5Candlestick {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Mt5Candlestick({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Mt5Candlestick.fromJson(Map<String, dynamic> json) {
    return Mt5Candlestick(
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
      open: (json['open'] ?? 0.0).toDouble(),
      high: (json['high'] ?? 0.0).toDouble(),
      low: (json['low'] ?? 0.0).toDouble(),
      close: (json['close'] ?? 0.0).toDouble(),
      volume: (json['volume'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  // Convert to format expected by CandlestickPainter
  Map<String, double> toChartFormat() {
    return {
      'open': open,
      'high': high,
      'low': low,
      'close': close,
    };
  }
}

class Mt5OrderResult {
  final int orderId;
  final bool success;
  final String message;
  final double? price;
  final DateTime timestamp;

  Mt5OrderResult({
    required this.orderId,
    required this.success,
    required this.message,
    this.price,
    required this.timestamp,
  });

  factory Mt5OrderResult.fromJson(Map<String, dynamic> json) {
    return Mt5OrderResult(
      orderId: json['orderId'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      price: json['price']?.toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'success': success,
      'message': message,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}




