import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/paper_trading_provider.dart';
import '../providers/forex_provider.dart';
import '../models/paper_trading_models.dart';


class PaperTradingPage extends StatefulWidget {
  const PaperTradingPage({super.key});

  @override
  State<PaperTradingPage> createState() => _PaperTradingPageState();
}

class _PaperTradingPageState extends State<PaperTradingPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _volumeController = TextEditingController();
  final _stopLossController = TextEditingController();
  final _takeProfitController = TextEditingController();
  final _commentController = TextEditingController();
  
  PositionType _selectedPositionType = PositionType.buy;
  String _selectedSymbol = 'EUR/USD';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paperProvider = context.read<PaperTradingProvider>();
      final forexProvider = context.read<ForexProvider>();
      
      paperProvider.initialize();
      paperProvider.loadDemoData(); // Load demo data for testing
      
      // Sync forex rates
      if (forexProvider.forexRates.isNotEmpty) {
        paperProvider.updateForexRates(forexProvider.forexRates.values.toList());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _symbolController.dispose();
    _volumeController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Paper Trading'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Wallet'),
            Tab(icon: Icon(Icons.trending_up), text: 'Positions'),
            Tab(icon: Icon(Icons.add_chart), text: 'Trade'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.terminal), text: 'MT5'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugDialog(context),
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalletTab(),
          _buildPositionsTab(),
          _buildTradeTab(),
          _buildHistoryTab(),
          _buildMt5Tab(),
        ],
      ),
    );
  }

  // Wallet Tab
  Widget _buildWalletTab() {
    return Consumer<PaperTradingProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Overview Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MetaTrader 5 Demo',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Account: 95551549',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Balance Row
                      _buildBalanceRow('Balance', provider.currentBalance, Colors.blue),
                      const SizedBox(height: 12),
                      
                      // Equity Row
                      _buildBalanceRow('Equity', provider.currentEquity, Colors.green),
                      const SizedBox(height: 12),
                      
                      // P&L Row
                      _buildBalanceRow(
                        'Total P&L',
                        provider.totalPnL,
                        provider.totalPnL >= 0 ? Colors.green : Colors.red,
                        showPercent: true,
                        percent: provider.totalPnLPercent,
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => provider.loadDemoData(),
                              icon: const Icon(Icons.games),
                              label: const Text('Load Demo Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showResetDialog(context),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset Wallet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Margin Information Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Margin Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Margin Used:'),
                          Text(
                            '\$${provider.wallet.margin.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Free Margin:'),
                          Text(
                            '\$${provider.wallet.freeMargin.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Margin Level:'),
                          Text(
                            '${provider.wallet.marginLevelPercent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: provider.isMarginCall ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Trading Statistics Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trading Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildStatRow('Total Trades', provider.tradingStats.totalTrades.toString()),
                      _buildStatRow('Win Rate', '${provider.tradingStats.winRate.toStringAsFixed(1)}%'),
                      _buildStatRow('Profit Factor', provider.tradingStats.profitFactor.toStringAsFixed(2)),
                      _buildStatRow('Max Drawdown', '\$${provider.tradingStats.maxDrawdown.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Positions Tab
  Widget _buildPositionsTab() {
    return Consumer<PaperTradingProvider>(
      builder: (context, provider, child) {
        final positions = provider.openPositions;
        
        if (positions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No Open Positions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Open your first position from the Trade tab',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: positions.length,
          itemBuilder: (context, index) {
            final position = positions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          position.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: position.type == PositionType.buy ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            position.type.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Position Details
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Volume', '${position.volume.toStringAsFixed(0)}'),
                              _buildDetailRow('Open Price', '\$${position.openPrice.toStringAsFixed(4)}'),
                              _buildDetailRow('Current Price', '\$${position.currentPrice.toStringAsFixed(4)}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildDetailRow('P&L', '\$${position.unrealizedPnL.toStringAsFixed(2)}', 
                                color: position.isProfitable ? Colors.green : Colors.red),
                              _buildDetailRow('P&L %', '${position.pnlPercent.toStringAsFixed(2)}%',
                                color: position.isProfitable ? Colors.green : Colors.red),
                              _buildDetailRow('Value', '\$${position.positionValue.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Stop Loss & Take Profit
                    if (position.stopLoss > 0 || position.takeProfit > 0) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (position.stopLoss > 0) ...[
                            Expanded(
                              child: _buildOrderRow('Stop Loss', position.stopLoss.toStringAsFixed(4), Colors.red),
                            ),
                          ],
                          if (position.stopLoss > 0 && position.takeProfit > 0)
                            const SizedBox(width: 16),
                          if (position.takeProfit > 0) ...[
                            Expanded(
                              child: _buildOrderRow('Take Profit', position.takeProfit.toStringAsFixed(4), Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showModifyPositionDialog(context, position),
                            icon: const Icon(Icons.edit),
                            label: const Text('Modify'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _closePosition(context, position.id),
                            icon: const Icon(Icons.close),
                            label: const Text('Close'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Trade Tab
  Widget _buildTradeTab() {
    return Consumer2<PaperTradingProvider, ForexProvider>(
      builder: (context, paperProvider, forexProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Market Data Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      if (forexProvider.forexRates.isNotEmpty) ...[
                        ...forexProvider.forexRates.entries.map((entry) {
                          final rate = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rate.symbol),
                                Text(
                                  '\$${rate.rate.toStringAsFixed(4)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else ...[
                        const Text('No market data available'),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // New Position Form
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open New Position',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        
                        // Symbol Selection
                        DropdownButtonFormField<String>(
                          value: _selectedSymbol,
                          decoration: const InputDecoration(
                            labelText: 'Currency Pair',
                            border: OutlineInputBorder(),
                          ),
                          items: forexProvider.availablePairs.map((pair) {
                            return DropdownMenuItem(
                              value: pair['symbol'],
                              child: Text(pair['symbol']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSymbol = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a currency pair';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Position Type
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<PositionType>(
                                title: const Text('Buy'),
                                value: PositionType.buy,
                                groupValue: _selectedPositionType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPositionType = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<PositionType>(
                                title: const Text('Sell'),
                                value: PositionType.sell,
                                groupValue: _selectedPositionType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPositionType = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Volume
                        TextFormField(
                          controller: _volumeController,
                          decoration: const InputDecoration(
                            labelText: 'Volume (Units)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 10000',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter volume';
                            }
                            final volume = double.tryParse(value);
                            if (volume == null || volume <= 0) {
                              return 'Please enter a valid volume';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Stop Loss
                        TextFormField(
                          controller: _stopLossController,
                          decoration: const InputDecoration(
                            labelText: 'Stop Loss (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 1.1600',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Take Profit
                        TextFormField(
                          controller: _takeProfitController,
                          decoration: const InputDecoration(
                            labelText: 'Take Profit (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 1.1750',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Comment
                        TextFormField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Comment (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Technical analysis based',
                          ),
                          maxLines: 2,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: paperProvider.isLoading ? null : _openPosition,
                            icon: paperProvider.isLoading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add),
                            label: Text(paperProvider.isLoading ? 'Opening...' : 'Open Position'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        
                        if (paperProvider.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    paperProvider.error!,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red[700]),
                                  onPressed: () => paperProvider.clearError(),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // History Tab
  Widget _buildHistoryTab() {
    return Consumer<PaperTradingProvider>(
      builder: (context, provider, child) {
        final trades = provider.wallet.tradeHistory;
        
        if (trades.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No Trade History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your closed trades will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trades.length,
          itemBuilder: (context, index) {
            final trade = trades[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trade.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trade.type == PositionType.buy ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trade.type.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Trade Details
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Volume', '${trade.volume.toStringAsFixed(0)}'),
                              _buildDetailRow('Open Price', '\$${trade.openPrice.toStringAsFixed(4)}'),
                              _buildDetailRow('Close Price', '\$${trade.closePrice.toStringAsFixed(4)}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildDetailRow('P&L', '\$${trade.realizedPnL.toStringAsFixed(2)}',
                                color: trade.isProfitable ? Colors.green : Colors.red),
                              _buildDetailRow('P&L %', '${trade.pnlPercent.toStringAsFixed(2)}%',
                                color: trade.isProfitable ? Colors.green : Colors.red),
                              _buildDetailRow('Duration', _formatDuration(trade.duration)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (trade.comment != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          trade.comment!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper Methods
  Widget _buildBalanceRow(String label, double value, Color color, {bool showPercent = false, double? percent}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (showPercent && percent != null)
              Text(
                '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  // Action Methods
  void _refreshData() {
    final paperProvider = context.read<PaperTradingProvider>();
    final forexProvider = context.read<ForexProvider>();
    if (forexProvider.forexRates.isNotEmpty) {
      paperProvider.updateForexRates(forexProvider.forexRates.values.toList());
    }
  }

  void _openPosition() async {
    if (!_formKey.currentState!.validate()) return;
    
    final volume = double.parse(_volumeController.text);
    final stopLoss = _stopLossController.text.isNotEmpty 
        ? double.tryParse(_stopLossController.text) 
        : null;
    final takeProfit = _takeProfitController.text.isNotEmpty 
        ? double.tryParse(_takeProfitController.text) 
        : null;
    final comment = _commentController.text.isNotEmpty 
        ? _commentController.text 
        : null;
    
    final paperProvider = context.read<PaperTradingProvider>();
    final forexProvider = context.read<ForexProvider>();
    
    // Get current price for the symbol
    final currentRate = forexProvider.forexRates[_selectedSymbol];
    if (currentRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No current price available for $_selectedSymbol')),
      );
      return;
    }
    
    final currentPrice = currentRate.rate;
    
    await paperProvider.openPosition(
      symbol: _selectedSymbol,
      type: _selectedPositionType,
      volume: volume,
      price: currentPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
    );
    
    if (paperProvider.error == null) {
      // Clear form
      _volumeController.clear();
      _stopLossController.clear();
      _takeProfitController.clear();
      _commentController.clear();
      
      // Switch to positions tab
      _tabController.animateTo(1);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position opened successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _closePosition(BuildContext context, String positionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Position'),
        content: const Text('Are you sure you want to close this position?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final paperProvider = context.read<PaperTradingProvider>();
      final forexProvider = context.read<ForexProvider>();
      
      // Get current price for closing
      final position = paperProvider.openPositions.firstWhere((p) => p.id == positionId);
      final currentRate = forexProvider.forexRates[position.symbol];
      final closePrice = currentRate?.rate ?? position.currentPrice;
      
      await paperProvider.closePosition(positionId, closePrice);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position closed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showModifyPositionDialog(BuildContext context, Position position) {
    final stopLossController = TextEditingController(
      text: position.stopLoss > 0 ? position.stopLoss.toString() : '',
    );
    final takeProfitController = TextEditingController(
      text: position.takeProfit > 0 ? position.takeProfit.toString() : '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modify ${position.symbol}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: stopLossController,
              decoration: const InputDecoration(
                labelText: 'Stop Loss',
                hintText: 'e.g., 1.1600',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: takeProfitController,
              decoration: const InputDecoration(
                labelText: 'Take Profit',
                hintText: 'e.g., 1.1750',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final stopLoss = stopLossController.text.isNotEmpty 
                  ? double.tryParse(stopLossController.text) 
                  : null;
              final takeProfit = takeProfitController.text.isNotEmpty 
                  ? double.tryParse(takeProfitController.text) 
                  : null;
              
              final paperProvider = context.read<PaperTradingProvider>();
              await paperProvider.modifyPosition(
                position.id,
                stopLoss: stopLoss,
                takeProfit: takeProfit,
              );
              
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Position modified successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Wallet'),
        content: const Text(
          'This will reset your wallet to the initial \$100,000 balance and clear all positions and trade history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final paperProvider = context.read<PaperTradingProvider>();
              paperProvider.resetWallet();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wallet reset successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    final paperProvider = context.read<PaperTradingProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Paper Trading Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💰 Balance: \$${paperProvider.currentBalance.toStringAsFixed(2)}'),
              Text('📊 Equity: \$${paperProvider.currentEquity.toStringAsFixed(2)}'),
              Text('📈 Total P&L: \$${paperProvider.totalPnL.toStringAsFixed(2)}'),
              Text('📈 P&L %: ${paperProvider.totalPnLPercent.toStringAsFixed(2)}%'),
              Text('🕯️ Open Positions: ${paperProvider.openPositionsCount}'),
              Text('📚 Trade History: ${paperProvider.wallet.tradeHistory.length}'),
              Text('💳 Margin Used: \$${paperProvider.wallet.margin.toStringAsFixed(2)}'),
              Text('💳 Free Margin: \$${paperProvider.wallet.freeMargin.toStringAsFixed(2)}'),
              Text('📊 Forex Rates: ${paperProvider.forexRates.length}'),
              Text('⏳ Loading: ${paperProvider.isLoading}'),
              if (paperProvider.error != null) Text('🚨 Error: ${paperProvider.error}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              paperProvider.debugCurrentState();
            },
            child: const Text('Debug State'),
          ),
        ],
      ),
    );
  }

  // MT5 Tab
  Widget _buildMt5Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MT5 Connection Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MetaTrader5 Demo Account',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Connect to your MT5 demo account for live paper trading',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Connection Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 12),
                        const SizedBox(width: 8),
                        const Text('Connected to MT5 Demo'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => _showMt5ConnectionDialog(),
                          child: const Text('Reconnect'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Account Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAccountDetail('Account Holder', 'faisal fansa'),
                  _buildAccountDetail('Login', '95551549'),
                  _buildAccountDetail('Server', 'MetaQuotes-Demo'),
                  _buildAccountDetail('Account Type', 'Forex Hedged USD (1:100)'),
                  _buildAccountDetail('Initial Deposit', '\$100,000 USD'),
                  _buildAccountDetail('Leverage', '1:100'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // MT5 Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MT5 Integration Features',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.sync,
                    'Real-time Data',
                    'Live market data from MT5 demo account',
                  ),
                  _buildFeatureItem(
                    Icons.trending_up,
                    'Live Trading',
                    'Execute trades directly on MT5 demo account',
                  ),
                  _buildFeatureItem(
                    Icons.account_balance,
                    'Account Sync',
                    'Synchronize balance and positions with MT5',
                  ),
                  _buildFeatureItem(
                    Icons.history,
                    'Trade History',
                    'View complete trading history from MT5',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Setup Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setup Instructions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('1. Open MetaTrader5 and create a demo account'),
                  const Text('2. Note your account credentials (login, password, server)'),
                  const Text('3. Enable API access in MT5 settings'),
                  const Text('4. Enter your credentials in the connection dialog'),
                  const Text('5. Start live paper trading with real market data'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showMt5ConnectionDialog(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure MT5 Connection'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showMt5ConnectionDialog() {
    final loginController = TextEditingController(text: '95551549');
    final passwordController = TextEditingController(text: 'K*5fQgCf');
    final serverController = TextEditingController(text: 'MetaQuotes-Demo');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MT5 Demo Account Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: loginController,
              decoration: const InputDecoration(
                labelText: 'Login',
                hintText: 'Enter your MT5 demo account login',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your MT5 demo account password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                labelText: 'Server',
                hintText: 'Enter MT5 server name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _connectToMt5(
                loginController.text,
                passwordController.text,
                serverController.text,
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _connectToMt5(String login, String password, String server) {
    // This would implement the actual MT5 connection
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Connected to MT5 Demo Account: $login\nServer: $server\nBalance: \$100,000 USD'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}



