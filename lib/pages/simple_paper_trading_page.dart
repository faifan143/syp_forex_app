import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/paper_trading_provider.dart';
import '../providers/forex_provider.dart';
import '../models/paper_trading_models.dart';

class SimplePaperTradingPage extends StatefulWidget {
  const SimplePaperTradingPage({super.key});

  @override
  State<SimplePaperTradingPage> createState() => _SimplePaperTradingPageState();
}

class _SimplePaperTradingPageState extends State<SimplePaperTradingPage> {
  String _selectedSymbol = 'EUR/USD';
  PositionType _selectedType = PositionType.buy;
  double _volume = 0.1;
  double? _stopLoss;
  double? _takeProfit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forexProvider = context.read<ForexProvider>();
      final paperProvider = context.read<PaperTradingProvider>();
      
      // Load dashboard data first, then fallback to rates
      forexProvider.loadForexDashboard(forceRefresh: true);
      forexProvider.loadForexRates();
      
      // Update paper trading with dashboard data
      if (forexProvider.dashboardData != null) {
        final rates = <ForexRate>[];
        for (final currency in forexProvider.dashboardData!.currencies) {
          final rate = ForexRate(
            fromCurrency: currency.pair.split('/')[0],
            toCurrency: currency.pair.split('/')[1],
            symbol: currency.pair,
            rate: currency.currentValue,
            timestamp: DateTime.now(),
            change: currency.tomorrowChange,
            changePercent: currency.tomorrowChangePercent,
          );
          rates.add(rate);
        }
        paperProvider.updateForexRates(rates);
        
        // Update simulation base prices with dashboard data
        final Map<String, double> dashboardPrices = {};
        for (final currency in forexProvider.dashboardData!.currencies) {
          dashboardPrices[currency.pair] = currency.currentValue;
        }
        paperProvider.updateSimulationBasePrices(dashboardPrices);
      } else {
        // Fallback to regular forex rates
        paperProvider.updateForexRates(forexProvider.forexRates.values.toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Simple Trading'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final forexProvider = context.read<ForexProvider>();
              final paperProvider = context.read<PaperTradingProvider>();
              
              // Refresh both dashboard data and rates
              forexProvider.loadForexDashboard(forceRefresh: true);
              forexProvider.loadForexRates();
              
              // Update paper trading with fresh data
              Future.delayed(const Duration(milliseconds: 500), () {
                if (forexProvider.dashboardData != null) {
                  final rates = <ForexRate>[];
                  for (final currency in forexProvider.dashboardData!.currencies) {
                    final rate = ForexRate(
                      fromCurrency: currency.pair.split('/')[0],
                      toCurrency: currency.pair.split('/')[1],
                      symbol: currency.pair,
                      rate: currency.currentValue,
                      timestamp: DateTime.now(),
                      change: currency.tomorrowChange,
                      changePercent: currency.tomorrowChangePercent,
                    );
                    rates.add(rate);
                  }
                  paperProvider.updateForexRates(rates);
                  
                  // Update simulation base prices with dashboard data
                  final Map<String, double> dashboardPrices = {};
                  for (final currency in forexProvider.dashboardData!.currencies) {
                    dashboardPrices[currency.pair] = currency.currentValue;
                  }
                  paperProvider.updateSimulationBasePrices(dashboardPrices);
                } else {
                  paperProvider.updateForexRates(forexProvider.forexRates.values.toList());
                }
              });
            },
          ),
        ],
      ),
      body: Consumer2<PaperTradingProvider, ForexProvider>(
        builder: (context, paperProvider, forexProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Balance Card
                _buildBalanceCard(paperProvider),
                
                const SizedBox(height: 20),
                
                // Quick Trade Card
                _buildQuickTradeCard(paperProvider, forexProvider),
                
                const SizedBox(height: 20),
                
                // Open Positions
                _buildOpenPositions(paperProvider),
                
                const SizedBox(height: 20),
                
                // Recent Trades
                _buildRecentTrades(paperProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(PaperTradingProvider paperProvider) {
    final wallet = paperProvider.wallet;
    final profit = wallet.equity - wallet.balance;
    final isProfit = profit >= 0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account Balance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MT5 Demo',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${wallet.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTradeCard(PaperTradingProvider paperProvider, ForexProvider forexProvider) {
    final currentRate = forexProvider.forexRates[_selectedSymbol];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Trade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Symbol Selection
            Row(
              children: [
                const Text('Pair: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedSymbol,
                  items: forexProvider.availablePairs.map((pair) {
                    return DropdownMenuItem(
                      value: pair['symbol'],
                      child: Text(pair['symbol']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSymbol = value!;
                    });
                  },
                ),
                const Spacer(),
                if (currentRate != null)
                  Text(
                    currentRate.rate.toStringAsFixed(5),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Buy/Sell Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openPosition(paperProvider, PositionType.buy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openPosition(paperProvider, PositionType.sell),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('SELL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Volume Slider
            Row(
              children: [
                const Text('Volume: '),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0.01,
                    max: 1.0,
                    divisions: 99,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                      });
                    },
                  ),
                ),
                Text(
                  _volume.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenPositions(PaperTradingProvider paperProvider) {
    final positions = paperProvider.wallet.openPositions;
    
    if (positions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No Open Positions',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open Positions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...positions.map((position) => _buildPositionCard(position, paperProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionCard(Position position, PaperTradingProvider paperProvider) {
    final profit = (position.currentPrice - position.openPrice) * position.volume * 
                   (position.type == PositionType.buy ? 1 : -1);
    final isProfit = profit >= 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isProfit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Position Type Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: position.type == PositionType.buy ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                position.type == PositionType.buy ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Position Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position.symbol,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${position.type.name.toUpperCase()} ${position.volume} @ ${position.openPrice.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            // Profit/Loss
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${position.currentPrice.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            
            // Close Button
            IconButton(
              onPressed: () => _closePosition(position, paperProvider),
              icon: const Icon(Icons.close, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTrades(PaperTradingProvider paperProvider) {
    final trades = paperProvider.wallet.tradeHistory.take(5).toList();
    
    if (trades.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No Recent Trades',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Trades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...trades.map((trade) => _buildTradeCard(trade)),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeCard(ClosedTrade trade) {
    final isProfit = trade.realizedPnL >= 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: trade.type == PositionType.buy ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trade.symbol} ${trade.type.name.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${trade.volume} @ ${trade.openPrice.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '\$${trade.realizedPnL.toStringAsFixed(2)}',
            style: TextStyle(
              color: isProfit ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _openPosition(PaperTradingProvider paperProvider, PositionType type) async {
    final forexProvider = context.read<ForexProvider>();
    final currentRate = forexProvider.forexRates[_selectedSymbol];
    
    if (currentRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for market data to load'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    await paperProvider.openPosition(
      symbol: _selectedSymbol,
      type: type,
      volume: _volume,
      price: currentRate.rate,
      stopLoss: _stopLoss,
      takeProfit: _takeProfit,
      comment: 'Quick Trade',
    );
    
    if (paperProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.name.toUpperCase()} position opened for $_selectedSymbol'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${paperProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _closePosition(Position position, PaperTradingProvider paperProvider) async {
    final currentRate = context.read<ForexProvider>().forexRates[position.symbol];
    
    if (currentRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    await paperProvider.closePosition(position.id, currentRate.rate);
    
    if (paperProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position closed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${paperProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
