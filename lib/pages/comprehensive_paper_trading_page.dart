import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';
import '../providers/paper_trading_provider.dart';
import '../providers/forex_provider.dart';
import '../models/paper_trading_models.dart';
import '../models/forex_models.dart';
import '../services/realistic_data_generator.dart';
import '../widgets/ai_recommender_widget.dart';
import 'fullscreen_chart_page.dart';

class ComprehensivePaperTradingPage extends StatefulWidget {
  const ComprehensivePaperTradingPage({super.key});

  @override
  State<ComprehensivePaperTradingPage> createState() =>
      _ComprehensivePaperTradingPageState();
}

class _ComprehensivePaperTradingPageState
    extends State<ComprehensivePaperTradingPage> {
  // Trading form controllers
  final _volumeController = TextEditingController(text: '0.1');
  final _stopLossController = TextEditingController();
  final _takeProfitController = TextEditingController();

  String _selectedSymbol = 'EUR/USD';
  String _selectedTimeframe = '1h'; // Default to 1 hour timeframe
  PositionType _selectedType = PositionType.buy;

  // Key for accessing the interactive chart
  final GlobalKey<_InteractiveCandlestickChartState> _chartKey =
      GlobalKey<_InteractiveCandlestickChartState>();
  final bool _showFastMA = true;
  final bool _showSlowMA = true;
  final int _fastMAPeriod = 20;
  final int _slowMAPeriod = 50;

  // Chart data caching
  final Map<String, Map<String, List<Map<String, double>>>> _cachedChartData =
      {};
  DateTime? _lastDataGeneration;

  // Timer for periodic dashboard data sync
  Timer? _dashboardSyncTimer;

  // Color helper
  // ignore: unused_element
  Color _darken(Color c, [double amount = .15]) {
    final hsl = HSLColor.fromColor(c);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  // Helper method to build statistic items
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Get pip size for different currency pairs
  double _getPipSize(String symbol) {
    // JPY pairs have 0.01 pip size, others have 0.0001
    if (symbol.contains('/JPY') || symbol.startsWith('JPY/')) {
      return 0.01;
    }
    return 0.0001;
  }

  // Calculate pip value in USD for a given currency pair, price, and volume
  double _calculatePipValue(String symbol, double currentPrice, double volume) {
    final pipSize = _getPipSize(symbol);

    // For major pairs, pip value is typically $10 per lot per pip
    // For JPY pairs, it's approximately $10 per lot per pip (simplified calculation)
    if (symbol.contains('/JPY') || symbol.startsWith('JPY/')) {
      // For JPY pairs: pip value = (pip size / current price) * volume * 100000
      return (pipSize / currentPrice) * volume * 100000;
    } else {
      // For major pairs: pip value = pip size * volume * 100000
      return pipSize * volume * 100000;
    }
  }

  // Calculate dollar amount for stop loss or take profit
  double _calculateDollarAmount(
    Position position, {
    bool isTakeProfit = false,
  }) {
    final targetPrice = isTakeProfit ? position.takeProfit : position.stopLoss;
    final priceDifference = (targetPrice - position.openPrice).abs();
    final pipSize = _getPipSize(position.symbol);
    final pips = priceDifference / pipSize;
    final pipValue = _calculatePipValue(
      position.symbol,
      position.openPrice,
      position.volume,
    );
    return pips * pipValue;
  }

  // Get current price for a position from dashboard data or simulation
  double _getCurrentPriceForPosition(Position position) {
    final forexProvider = Get.find<ForexProvider>();
    final paperProvider = Get.find<PaperTradingProvider>();

    // PRIORITIZE SIMULATION DATA for real-time updates in open positions
    if (paperProvider.isSimulationRunning &&
        paperProvider.currentPrices.containsKey(position.symbol)) {
      print(
        '🔄 [OPEN_POSITIONS] Using simulation data for ${position.symbol}: ${paperProvider.currentPrices[position.symbol]}',
      );
      return paperProvider.currentPrices[position.symbol]!;
    }

    // Fallback to dashboard data (static data)
    if (forexProvider.dashboardData != null) {
      // Convert symbol format to match API (EUR/USD -> EURUSD)
      final apiSymbol = position.symbol.replaceAll('/', '');
      final currency = forexProvider.dashboardData!.currencies
          .where((c) => c.pair == apiSymbol)
          .firstOrNull;

      if (currency != null) {
        print(
          '🔄 [OPEN_POSITIONS] Using dashboard data for ${position.symbol}: ${currency.currentValue}',
        );
        return currency.currentValue;
      }
    }

    // Last resort: use stored current price
    print(
      '🔄 [OPEN_POSITIONS] Using position current price for ${position.symbol}: ${position.currentPrice}',
    );
    return position.currentPrice;
  }

  // Calculate unrealized P&L using current price from dashboard data
  double _calculateUnrealizedPnL(Position position, double currentPrice) {
    // For forex, 1 pip = 0.0001, and pip value is $10 per lot for major pairs
    const double pipValue = 10.0; // $10 per pip per lot
    const double pipSize = 0.0001; // 1 pip = 0.0001 for major pairs

    double pips;
    if (position.type == PositionType.buy) {
      pips = (currentPrice - position.openPrice) / pipSize;
    } else {
      pips = (position.openPrice - currentPrice) / pipSize;
    }

    return pips * pipValue * position.volume;
  }

  // Helper method to update paper trading with forex data from dashboard or rates
  void _updatePaperTradingWithForexData(
    ForexProvider forexProvider,
    PaperTradingProvider paperProvider,
  ) {
    // Try to get data from dashboard first, then fallback to rates
    if (forexProvider.dashboardData != null) {
      // Convert dashboard data to ForexRate format for paper trading
      final rates = <ForexRate>[];
      for (final currency in forexProvider.dashboardData!.currencies) {
        // Convert from EURUSD format to EUR/USD format for ForexRate
        final pair = currency.pair;
        String fromCurrency, toCurrency, formattedSymbol;
        if (pair.startsWith('USD')) {
          // USD pairs: USDJPY -> USD, JPY, USD/JPY
          fromCurrency = 'USD';
          toCurrency = pair.substring(3);
          formattedSymbol = 'USD/$toCurrency';
        } else {
          // Other pairs: EURUSD -> EUR, USD, EUR/USD
          fromCurrency = pair.substring(0, 3);
          toCurrency = pair.substring(3);
          formattedSymbol = '$fromCurrency/$toCurrency';
        }

        final rate = ForexRate(
          fromCurrency: fromCurrency,
          toCurrency: toCurrency,
          symbol: formattedSymbol,
          rate: currency.currentValue,
          timestamp: DateTime.now(),
          change: currency.tomorrowChange,
          changePercent: currency.tomorrowChangePercent,
        );
        rates.add(rate);
      }
      paperProvider.updateForexRates(rates);

      // Feed dashboard data into the simulation as base prices (simulation continues running)
      _updateSimulationWithDashboardData(
        forexProvider.dashboardData!.currencies,
        paperProvider,
      );
    } else if (forexProvider.forexRates.isNotEmpty) {
      // Fallback to regular forex rates
      paperProvider.updateForexRates(forexProvider.forexRates.values.toList());

      // Feed forex rates into simulation as base prices (simulation continues running)
      _updateSimulationWithForexRates(
        forexProvider.forexRates.values.toList(),
        paperProvider,
      );
    }
  }

  // Update simulation with dashboard data as base prices
  void _updateSimulationWithDashboardData(
    List<dynamic> currencies,
    PaperTradingProvider paperProvider,
  ) {
    // Create a map of current prices from dashboard data
    final Map<String, double> dashboardPrices = {};
    for (final currency in currencies) {
      // Convert from EURUSD format to EUR/USD format for simulation
      final pair = currency.pair;
      String formattedPair;
      if (pair.startsWith('USD')) {
        // USD pairs: USDJPY -> USD/JPY
        formattedPair = 'USD/${pair.substring(3)}';
      } else {
        // Other pairs: EURUSD -> EUR/USD
        formattedPair = '${pair.substring(0, 3)}/${pair.substring(3)}';
      }
      dashboardPrices[formattedPair] = currency.currentValue;
    }

    // Update the simulation service with dashboard prices
    paperProvider.updateSimulationBasePrices(dashboardPrices);
  }

  // Update simulation with forex rates as base prices
  void _updateSimulationWithForexRates(
    List<ForexRate> rates,
    PaperTradingProvider paperProvider,
  ) {
    // Create a map of current prices from forex rates
    final Map<String, double> ratePrices = {};
    for (final rate in rates) {
      ratePrices[rate.symbol] = rate.rate;
    }

    // Update the simulation service with rate prices
    paperProvider.updateSimulationBasePrices(ratePrices);
  }

  // Get spread percentage based on currency pair
  // Formula: Bid ≈ Ask - (spread_percentage × Ask)
  double _getSpreadPercentage(String symbol) {
    if (symbol.contains('JPY')) {
      // JPY pairs typically have larger spreads (0.6-1.2%)
      return 0.008; // 0.8%
    } else if (symbol == 'EUR/USD' ||
        symbol == 'GBP/USD' ||
        symbol == 'AUD/USD') {
      // Major pairs have tighter spreads (0.02-0.05%)
      return 0.0004; // 0.04%
    } else if (symbol.contains('USD')) {
      // Other USD pairs have medium spreads (0.1-0.3%)
      return 0.002; // 0.2%
    } else {
      // Exotic pairs have wider spreads (0.3-0.8%)
      return 0.005; // 0.5%
    }
  }

  // Calculate realistic spread based on currency pair using percentage-based formula
  // Formula: Bid ≈ Ask - (spread_percentage × Ask) => Spread = spread_percentage × Ask

  // Change timeframe and update simulation
  void _changeTimeframe(String timeframe) {
    if (_selectedTimeframe != timeframe) {
      _selectedTimeframe = timeframe;

      // Update simulation with new timeframe
      final paperProvider = Get.find<PaperTradingProvider>();
      paperProvider.updateTimeframe(timeframe);

      // Clear chart cache to force refresh with new timeframe
      _cachedChartData.clear();
      _lastDataGeneration = null;

      // Chart will automatically refresh due to setState

      setState(() {}); // Refresh the UI
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forexProvider = Get.find<ForexProvider>();
      final paperProvider = Get.find<PaperTradingProvider>();

      // Load forex dashboard data (same as home page) with fallback to rates
      forexProvider.loadForexDashboard(forceRefresh: true);
      paperProvider.initialize();
      paperProvider.startSimulation(
        timeframe: _selectedTimeframe,
      ); // Start paper trading simulation with timeframe

      // Update paper trading with forex data after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _updatePaperTradingWithForexData(forexProvider, paperProvider);
      });

      // Set up periodic refresh to sync with dashboard data
      _dashboardSyncTimer = Timer.periodic(const Duration(seconds: 30), (
        timer,
      ) {
        if (forexProvider.dashboardData != null) {
          _updatePaperTradingWithForexData(forexProvider, paperProvider);
          // Clear chart cache to force refresh with new data
          _cachedChartData.clear();
          _lastDataGeneration = null;
          setState(() {}); // Refresh the UI
        }
      });
    });
  }

  @override
  void dispose() {
    _dashboardSyncTimer?.cancel();
    _volumeController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎮 ${'paperTrading'.tr}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final forexProvider = Get.find<ForexProvider>();
              final paperProvider = Get.find<PaperTradingProvider>();
              // Use same data source as home page
              forexProvider.loadForexDashboard(forceRefresh: true);
              // Update paper trading with new data
              Future.delayed(const Duration(milliseconds: 500), () {
                _updatePaperTradingWithForexData(forexProvider, paperProvider);
              });
            },
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: _buildComprehensiveTradingView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFullscreenChart();
        },
        backgroundColor: Colors.blue,
        tooltip: 'chartFullscreen'.tr,
        child: const Icon(Icons.fullscreen, color: Colors.white),
      ),
    );
  }

  Widget _buildComprehensiveTradingView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        final content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildAccountSummarySection(),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: _buildChartSection(),
            ),
            const SizedBox(height: 12),
          ],
        );

        if (!isWide) {
          return SingleChildScrollView(
            child: Column(
              children: [
                content,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTradingFormSection(),
                ),
                _buildPositionsSection(),
                _buildTradesHistorySection(),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: SingleChildScrollView(child: content)),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTradingFormSection(),
                    ),
                    _buildPositionsSection(),
                    _buildTradesHistorySection(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSummarySection() {
    return GetBuilder<PaperTradingProvider>(
      builder: (paperProvider) {
        final balance = paperProvider.currentBalance;
        final equity = paperProvider.currentEquity;
        final margin = paperProvider.wallet.margin;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 700;
              final tiles = [
                _kpiTile(
                  icon: Icons.account_balance_wallet,
                  label: 'balance'.tr,
                  value: balance,
                  color: Colors.blue,
                ),
                _kpiTile(
                  icon: Icons.assessment,
                  label: 'equity'.tr,
                  value: equity,
                  color: Colors.indigo,
                ),
                _kpiTile(
                  icon: Icons.shield,
                  label: 'margin'.tr,
                  value: margin,
                  color: Colors.orange,
                ),
                // _kpiTile(icon: Icons.wallet_giftcard, label: 'free'.tr, value: freeMargin, color: Colors.green),
                // _levelTile(marginLevel, isMarginCall),
              ];
              if (isCompact) {
                return Wrap(spacing: 12, runSpacing: 12, children: tiles);
              }
              return Row(
                children: tiles
                    .map(
                      (w) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: w,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _kpiTile({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                '\$${value.toStringAsFixed(2)}',
                style: TextStyle(
                  color: _darken(color),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return GetBuilder<ForexProvider>(
      builder: (forexProvider) {
        return GetBuilder<PaperTradingProvider>(
          builder: (paperProvider) {
            // Get current rate from dashboard data or forex rates (same as home page)
            ForexRate? currentRate;
            if (forexProvider.dashboardData != null) {
              // Find currency in dashboard data
              final currency = forexProvider.dashboardData!.currencies
                  .where((c) => c.pair == _selectedSymbol)
                  .firstOrNull;
              if (currency != null) {
                currentRate = ForexRate(
                  fromCurrency: currency.pair.split('/')[0],
                  toCurrency: currency.pair.split('/')[1],
                  symbol: currency.pair,
                  rate: currency.currentValue,
                  timestamp: DateTime.now(),
                  change: currency.tomorrowChange,
                  changePercent: currency.tomorrowChangePercent,
                );
              }
            } else {
              // Fallback to regular forex rates
              currentRate = forexProvider.forexRates[_selectedSymbol];
            }

            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Timeframe selector
                  _buildTimeframeSelector(),
                  // Chart area - Takes full available height with dual scrolling
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildScrollableChart(currentRate),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = [
      {'value': '1m', 'label': '1M', 'interval': '1s'},
      {'value': '5m', 'label': '5M', 'interval': '5s'},
      {'value': '15m', 'label': '15M', 'interval': '15s'},
      {'value': '1h', 'label': '1H', 'interval': '30s'},
      {'value': '4h', 'label': '4H', 'interval': '1m'},
      {'value': '1d', 'label': '1D', 'interval': '5m'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Timeframe:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: timeframes.map((tf) {
                  final isSelected = _selectedTimeframe == tf['value'];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _changeTimeframe(tf['value']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tf['label']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              tf['interval']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimary.withOpacity(0.8)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingFormSection() {
    return GetBuilder<ForexProvider>(
      builder: (forexProvider) {
        return GetBuilder<PaperTradingProvider>(
          builder: (paperProvider) {
            // Get current price from simulation or forex data (same as home page)
            double currentPrice = 0.0;
            double bidPrice = 0.0;
            double askPrice = 0.0;
            double spread = 0.0;

            // PRIORITIZE SIMULATION DATA for real-time updates in paper trading
            ForexRate? currentRate;

            // First try simulation data (for real-time updates in paper trading)
            if (paperProvider.isSimulationRunning &&
                paperProvider.currentPrices.containsKey(_selectedSymbol)) {
              // Use simulation data for real-time updates
              print(
                '🔄 [TRADING_FORM] Using simulation data for $_selectedSymbol',
              );
              final spreadPercentage = _getSpreadPercentage(_selectedSymbol);
              currentPrice = paperProvider.currentPrices[_selectedSymbol]!;
              askPrice = currentPrice;
              bidPrice = askPrice - (spreadPercentage * askPrice);
              spread = askPrice - bidPrice;
              print(
                '🔄 [TRADING_FORM] Simulation price: $currentPrice, Ask: $askPrice, Bid: $bidPrice',
              );
            }
            // Fallback to dashboard data (static data)
            if (currentPrice == 0.0 && forexProvider.dashboardData != null) {
              // Fallback to dashboard data
              print(
                '🔄 [TRADING_FORM] Using dashboard data for $_selectedSymbol',
              );
              final apiSymbol = _selectedSymbol.replaceAll('/', '');

              // Find currency in dashboard data using converted symbol
              final currency = forexProvider.dashboardData!.currencies
                  .where((c) => c.pair == apiSymbol)
                  .firstOrNull;
              if (currency != null) {
                // Extract currencies from pair (e.g., EURUSD -> EUR, USD)
                final pair = currency.pair;
                String fromCurrency, toCurrency;
                if (pair.startsWith('USD')) {
                  // USD pairs: USDJPY -> USD, JPY
                  fromCurrency = 'USD';
                  toCurrency = pair.substring(3);
                } else {
                  // Other pairs: EURUSD -> EUR, USD
                  fromCurrency = pair.substring(0, 3);
                  toCurrency = pair.substring(3);
                }

                currentRate = ForexRate(
                  fromCurrency: fromCurrency,
                  toCurrency: toCurrency,
                  symbol: _selectedSymbol, // Use original format for display
                  rate: currency.currentValue,
                  timestamp: DateTime.now(),
                  change: currency.tomorrowChange,
                  changePercent: currency.tomorrowChangePercent,
                );

                // Calculate realistic spread using percentage formula: Bid ≈ Ask - (spread_percentage × Ask)
                final spreadPercentage = _getSpreadPercentage(_selectedSymbol);
                currentPrice = currentRate.rate;
                askPrice = currentRate.rate; // Use current rate as ask price
                bidPrice =
                    askPrice -
                    (spreadPercentage *
                        askPrice); // Calculate bid using the formula
                spread = askPrice - bidPrice; // Calculate actual spread
                print(
                  '🔄 [TRADING_FORM] Dashboard price: $currentPrice, Ask: $askPrice, Bid: $bidPrice',
                );
              }
            }
            // Fallback to regular forex rates
            if (currentPrice == 0.0 &&
                forexProvider.forexRates.containsKey(_selectedSymbol)) {
              currentRate = forexProvider.forexRates[_selectedSymbol];
              if (currentRate != null) {
                final spreadPercentage = _getSpreadPercentage(_selectedSymbol);
                currentPrice = currentRate.rate;
                askPrice = currentRate.rate;
                bidPrice = askPrice - (spreadPercentage * askPrice);
                spread = askPrice - bidPrice;
              }
            }

            // Update the current price for the AI recommender

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'openNewPosition'.tr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Enhanced price display
                    if (currentPrice > 0) ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedSymbol,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'live'.tr,
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPriceCard(
                                    'bid'.tr,
                                    bidPrice,
                                    Colors.red[600]!,
                                  ),
                                  _buildPriceCard(
                                    'ask'.tr,
                                    askPrice,
                                    Colors.green[600]!,
                                  ),
                                  _buildPriceCard(
                                    'spread'.tr,
                                    spread * 10000,
                                    Colors.orange[600]!,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Trading form - Responsive layout
                    Column(
                      children: [
                        // Trading pair and position type in separate rows for better responsiveness
                        _buildEnhancedDropdown(
                          'tradingPair'.tr,
                          _selectedSymbol,
                          forexProvider.availablePairs
                              .map((pair) => pair['symbol']!)
                              .toList(),
                          (value) {
                            setState(() {
                              _selectedSymbol = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Position type selector
                        _buildPositionTypeSelector(),
                        const SizedBox(height: 20),

                        // AI Recommender Widget
                        _buildAIRecommenderSection(),
                        const SizedBox(height: 20),

                        // Volume input
                        _buildVolumeInput(),
                        const SizedBox(height: 20),

                        // Risk management section
                        _buildRiskManagementSection(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButtons(paperProvider, currentPrice),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPositionsSection() {
    return GetBuilder<PaperTradingProvider>(
      builder: (paperProvider) {
        final positions = paperProvider.wallet.openPositions;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'openPositions'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${positions.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),

              if (positions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'noOpenPositions'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'openPositionUsingForm'.tr,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final position = positions[index];
                    return _buildPositionCard(position, paperProvider);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradesHistorySection() {
    return GetBuilder<PaperTradingProvider>(
      builder: (paperProvider) {
        final trades = paperProvider.wallet.tradeHistory.reversed.toList();

        // Calculate trade statistics
        final totalTrades = trades.length;
        final profitableTrades = trades.where((t) => t.realizedPnL > 0).length;
        final totalPnL = trades.fold(0.0, (sum, t) => sum + t.realizedPnL);
        final totalCommission = trades.fold(
          0.0,
          (sum, t) => sum + t.commission,
        );
        final winRate = totalTrades > 0
            ? (profitableTrades / totalTrades * 100)
            : 0.0;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              'tradeHistory'.tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (totalTrades > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    'Total Trades',
                                    totalTrades.toString(),
                                    Icons.analytics,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    'Win Rate',
                                    '${winRate.toStringAsFixed(1)}%',
                                    Icons.trending_up,
                                    valueColor: winRate >= 50
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    'Total P&L',
                                    '\$${totalPnL.toStringAsFixed(2)}',
                                    Icons.account_balance_wallet,
                                    valueColor: totalPnL >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    'Commission',
                                    '\$${totalCommission.toStringAsFixed(2)}',
                                    Icons.receipt,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (trades.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'noTradeHistory'.tr,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: trades.length,
                      itemBuilder: (context, index) {
                        final t = trades[index];
                        final isProfit = t.realizedPnL >= 0;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          leading: Icon(
                            t.type == PositionType.buy
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: t.type == PositionType.buy
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Row(
                            children: [
                              Text(
                                t.symbol,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: t.type == PositionType.buy
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.type == PositionType.buy ? 'BUY' : 'SELL',
                                  style: TextStyle(
                                    color: t.type == PositionType.buy
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${t.volume.toStringAsFixed(2)} lots',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Open: ${t.openPrice.toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 12),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Close: ${t.closePrice.toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${t.openTime.toLocal().toString().substring(0, 16)} → ${t.closeTime.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isProfit
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (isProfit ? '+' : '') +
                                      '\$${t.realizedPnL.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isProfit ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (t.commission > 0)
                                Text(
                                  'Fee: \$${t.commission.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                '${((t.closePrice - t.openPrice) / t.openPrice * 100).toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isProfit ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Add spacing below the trade history card to prevent FAB overlap
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildScrollableChart(rate) {
    return GetBuilder<PaperTradingProvider>(
      builder: (paperProvider) {
        // Get cached data or generate new data only when needed
        final candles = _getChartData();

        return LayoutBuilder(
          builder: (context, constraints) {
            const double leftPadding = 40.0;
            const double rightAxisWidth = 56.0;
            const double pixelsPerCandle = 8.0; // base width per candle
            final double dynamicWidth =
                (leftPadding + rightAxisWidth) +
                (pixelsPerCandle * candles.length);
            final double canvasWidth = dynamicWidth < constraints.maxWidth
                ? constraints.maxWidth
                : dynamicWidth;
            return Stack(
              children: [
                // Horizontal scrollable chart
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: canvasWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        InteractiveCandlestickChart(
                          key: _chartKey,
                          candles: candles,
                          size: Size(canvasWidth, constraints.maxHeight),
                          showFastMA: _showFastMA,
                          showSlowMA: _showSlowMA,
                          fastMAPeriod: _fastMAPeriod,
                          slowMAPeriod: _slowMAPeriod,
                          externalScroll: true,
                        ),
                        // Invisible tap area for full-screen
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              // Open full-screen chart on tap
                              _showFullscreenChart();
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Get chart data based on dashboard data with proper caching and timeframe handling
  List<Map<String, double>> _getChartData() {
    final now = DateTime.now();

    // Check if we have cached data for this symbol and timeframe
    if (_cachedChartData.containsKey(_selectedSymbol) &&
        _cachedChartData[_selectedSymbol]!.containsKey(_selectedTimeframe)) {
      final cachedData =
          _cachedChartData[_selectedSymbol]![_selectedTimeframe]!;
      final lastGeneration = _lastDataGeneration;

      // Check if we need to update based on timeframe
      if (lastGeneration != null) {
        final timeSinceLastUpdate = now.difference(lastGeneration);
        final shouldUpdate = _shouldUpdateForTimeframe(timeSinceLastUpdate);

        if (!shouldUpdate) {
          return cachedData;
        }
      }
    }

    // Get base price from dashboard data if available
    final forexProvider = Get.find<ForexProvider>();
    double basePrice = 1.1000; // Default fallback

    if (forexProvider.dashboardData != null) {
      // Find the current price from dashboard data
      try {
        final currency = forexProvider.dashboardData!.currencies.firstWhere(
          (c) => c.pair == _selectedSymbol,
        );
        basePrice = currency.currentValue;
      } catch (e) {
        // Symbol not found in dashboard data, use default
        basePrice = 1.1000;
      }
    } else if (forexProvider.forexRates.containsKey(_selectedSymbol)) {
      // Fallback to forex rates
      basePrice = forexProvider.forexRates[_selectedSymbol]!.rate;
    }

    // Generate new data based on dashboard price
    final newData = RealisticDataGenerator.generateTimeframeData(
      timeframe: _selectedTimeframe,
      symbol: _selectedSymbol,
      days: 7,
      basePrice: basePrice, // Use dashboard price as base
    );

    // Cache the data
    _cachedChartData[_selectedSymbol] ??= {};
    _cachedChartData[_selectedSymbol]![_selectedTimeframe] = newData;
    _lastDataGeneration = now;

    return newData;
  }

  // Determine if data should be updated based on timeframe
  bool _shouldUpdateForTimeframe(Duration timeSinceLastUpdate) {
    switch (_selectedTimeframe) {
      case 'M1':
        return timeSinceLastUpdate.inMinutes >= 1;
      case 'M5':
        return timeSinceLastUpdate.inMinutes >= 5;
      case 'M15':
        return timeSinceLastUpdate.inMinutes >= 15;
      case 'H1':
        return timeSinceLastUpdate.inHours >= 1;
      case 'H4':
        return timeSinceLastUpdate.inHours >= 4;
      case 'D1':
        return timeSinceLastUpdate.inDays >= 1;
      default:
        return timeSinceLastUpdate.inMinutes >= 15; // Default to M15
    }
  }

  // Generate recent candles for AI recommender technical analysis
  List<Candlestick> _generateRecentCandles(double currentPrice) {
    final candles = <Candlestick>[];
    final now = DateTime.now();

    // Generate 50 recent candles for technical analysis
    for (int i = 0; i < 50; i++) {
      final time = now.subtract(Duration(hours: i));

      // Generate realistic price movement around current price
      final volatility = 0.001; // 0.1% volatility
      final random = Random();
      final change = (random.nextDouble() - 0.5) * volatility * currentPrice;

      final open = currentPrice + change;
      final close =
          open + ((random.nextDouble() - 0.5) * volatility * currentPrice);
      final high =
          [open, close].reduce((a, b) => a > b ? a : b) +
          (volatility * currentPrice * random.nextDouble());
      final low =
          [open, close].reduce((a, b) => a < b ? a : b) -
          (volatility * currentPrice * random.nextDouble());

      candles.add(
        Candlestick(
          timestamp: time,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: 1000, // Default volume for generated data
        ),
      );

      // Update current price for next candle (slight trend)
      currentPrice = close;
    }

    return candles.reversed.toList(); // Most recent first
  }

  // Old tab methods removed - now using comprehensive single view

  void _showFullscreenChart() {
    final candles = _getChartData();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenChartPage(
          symbol: _selectedSymbol,
          timeframe: _selectedTimeframe,
          initialCandles: candles,
        ),
      ),
    );
  }

  Widget _buildPriceCard(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(5),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 16)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'positionType'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        // Use IntrinsicHeight to ensure buttons have equal height
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildPositionTypeButton(
                  'buy'.tr,
                  PositionType.buy,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPositionTypeButton(
                  'sell'.tr,
                  PositionType.sell,
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionTypeButton(
    String label,
    PositionType type,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : color,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'volumeLots'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _volumeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'enterVolumeHint'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            suffixIcon: Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield, color: Colors.orange[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'riskManagement'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Use responsive layout for smaller screens
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 400) {
              // Stack vertically on small screens
              return Column(
                children: [
                  TextFormField(
                    controller: _stopLossController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${'stopLoss'.tr} (\$)',
                      hintText: 'usdExample'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _takeProfitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Take Profit (\$)',
                      hintText: 'usdExample100'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                  ),
                ],
              );
            } else {
              // Use horizontal layout on larger screens
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stopLossController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${'stopLoss'.tr} (\$)',
                        hintText: 'usdExample'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _takeProfitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${'takeProfit'.tr} (\$)',
                        hintText: 'usdExample100'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAIRecommenderSection() {
    return GetBuilder<ForexProvider>(
      builder: (forexProvider) {
        final paperProvider = Get.find<PaperTradingProvider>();
        // Get current price from dashboard data first, then simulation data
        double currentPrice = 0.0;
        Currency? currencyData;
        if (forexProvider.dashboardData != null) {
          // Convert symbol format to match API
          final apiSymbol = _selectedSymbol.replaceAll('/', '');
          currencyData = forexProvider.dashboardData!.currencies
              .where((c) => c.pair == apiSymbol)
              .firstOrNull;

          if (currencyData != null) {
            currentPrice = currencyData.currentValue;
          }
        }

        // Fallback to simulation data if dashboard data not available
        if (currentPrice <= 0 &&
            paperProvider.isSimulationRunning &&
            paperProvider.currentPrices.containsKey(_selectedSymbol)) {
          currentPrice = paperProvider.currentPrices[_selectedSymbol]!;
        }

        if (currentPrice <= 0) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${'aiRecommender'.tr}: ${'waitingForPriceData'.tr}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Generate recent candles for technical analysis
        final recentCandles = _generateRecentCandles(currentPrice);

        return AIRecommenderWidget(
          symbol: _selectedSymbol,
          currentPrice: currentPrice,
          recentCandles: recentCandles,
          currencyData: currencyData,
          onRecommendationChanged: () {
            // Optionally update UI based on recommendation
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildActionButtons(
    PaperTradingProvider paperProvider,
    double currentPrice,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          // Stack vertically on very small screens
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openPosition(paperProvider, currentPrice);
                  },
                  icon: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    '${'buy'.tr} $_selectedSymbol',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openPosition(paperProvider, currentPrice);
                  },
                  icon: const Icon(
                    Icons.trending_down,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    '${'sell'.tr} $_selectedSymbol',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Use horizontal layout on larger screens
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openPosition(paperProvider, currentPrice);
                  },
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: Text(
                    'submit'.tr,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  void _openPosition(PaperTradingProvider paperProvider, double currentPrice) {
    final volume = double.tryParse(_volumeController.text) ?? 0.1;

    // Use dollar amounts directly for Stop Loss and Take Profit
    double? stopLossDollars;
    double? takeProfitDollars;

    if (_stopLossController.text.isNotEmpty) {
      stopLossDollars = double.tryParse(_stopLossController.text);
    }

    if (_takeProfitController.text.isNotEmpty) {
      takeProfitDollars = double.tryParse(_takeProfitController.text);
    }

    // Add position to paper trading
    paperProvider.openPosition(
      symbol: _selectedSymbol,
      type: _selectedType,
      volume: volume,
      price: currentPrice,
      stopLossDollars: stopLossDollars,
      takeProfitDollars: takeProfitDollars,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedType == PositionType.buy ? 'buyPositionOpened'.tr : 'sellPositionOpened'.tr} $_selectedSymbol',
        ),
        backgroundColor: _selectedType == PositionType.buy
            ? Colors.green
            : Colors.red,
      ),
    );

    // Clear form
    _stopLossController.clear();
    _takeProfitController.clear();
  }

  Widget _buildPositionCard(
    Position position,
    PaperTradingProvider paperProvider,
  ) {
    final currentPrice = _getCurrentPriceForPosition(position);
    final profit = _calculateUnrealizedPnL(position, currentPrice);
    final isProfit = profit >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: position.type == PositionType.buy
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      position.symbol,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${position.type.name.toUpperCase()} ${position.volume}'),
                Text('${'open'.tr}: ${position.openPrice.toStringAsFixed(5)}'),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'current'.tr}: ${_getCurrentPriceForPosition(position).toStringAsFixed(5)}',
                ),
                if (position.stopLoss > 0)
                  Text(
                    '${'sl'.tr}: \$${_calculateDollarAmount(position).toStringAsFixed(2)}',
                  ),
              ],
            ),

            if (position.takeProfit > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'tp'.tr}: \$${_calculateDollarAmount(position, isTakeProfit: true).toStringAsFixed(2)}',
                  ),
                  const SizedBox(),
                ],
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _modifyPosition(position, paperProvider),
                    child: Text('modify'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _closePosition(position, paperProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text('close'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Account tab moved to settings page

  void _closePosition(
    Position position,
    PaperTradingProvider paperProvider,
  ) async {
    // Get current price from simulation or forex data (same as home page)
    double currentPrice = 0.0;

    if (paperProvider.isSimulationRunning &&
        paperProvider.currentPrices.containsKey(position.symbol)) {
      currentPrice = paperProvider.currentPrices[position.symbol]!;
    } else {
      final forexProvider = Get.find<ForexProvider>();
      // Try to get data from dashboard first, then fallback to rates
      ForexRate? currentRate;
      if (forexProvider.dashboardData != null) {
        // Find currency in dashboard data
        final currency = forexProvider.dashboardData!.currencies
            .where((c) => c.pair == position.symbol)
            .firstOrNull;
        if (currency != null) {
          currentRate = ForexRate(
            fromCurrency: currency.pair.split('/')[0],
            toCurrency: currency.pair.split('/')[1],
            symbol: currency.pair,
            rate: currency.currentValue,
            timestamp: DateTime.now(),
            change: currency.tomorrowChange,
            changePercent: currency.tomorrowChangePercent,
          );
        }
      } else {
        // Fallback to regular forex rates
        currentRate = forexProvider.forexRates[position.symbol];
      }

      if (currentRate != null) {
        currentPrice = currentRate.rate;
      }
    }

    if (currentPrice == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('unableToGetCurrentPrice'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await paperProvider.closePosition(position.id, currentPrice);

    if (paperProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('positionClosedSuccessfully'.tr),
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

  void _modifyPosition(Position position, PaperTradingProvider paperProvider) {
    showDialog(
      context: context,
      builder: (context) {
        final stopLossController = TextEditingController(
          text: position.stopLoss.toString(),
        );
        final takeProfitController = TextEditingController(
          text: position.takeProfit.toString(),
        );

        return AlertDialog(
          title: Text('${'modifyPosition'.tr} ${position.symbol}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stopLossController,
                decoration: InputDecoration(
                  labelText: 'stopLoss'.tr,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: takeProfitController,
                decoration: InputDecoration(
                  labelText: 'takeProfit'.tr,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                final stopLoss = double.tryParse(stopLossController.text);
                final takeProfit = double.tryParse(takeProfitController.text);

                await paperProvider.modifyPosition(
                  position.id,
                  stopLoss: stopLoss,
                  takeProfit: takeProfit,
                );

                Navigator.of(context).pop();

                if (paperProvider.error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('positionModifiedSuccessfully'.tr),
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
              },
              child: Text('modify'.tr),
            ),
          ],
        );
      },
    );
  }
}

// Interactive candlestick chart widget
class InteractiveCandlestickChart extends StatefulWidget {
  final List<Map<String, double>> candles;
  final Size size;
  final VoidCallback? onReset;
  final bool showFastMA;
  final bool showSlowMA;
  final int fastMAPeriod;
  final int slowMAPeriod;
  final int initialVisibleCandles;
  final bool externalScroll;

  const InteractiveCandlestickChart({
    super.key,
    required this.candles,
    required this.size,
    this.onReset,
    this.showFastMA = true,
    this.showSlowMA = true,
    this.fastMAPeriod = 20,
    this.slowMAPeriod = 50,
    this.initialVisibleCandles = 60,
    this.externalScroll = false,
  });

  @override
  State<InteractiveCandlestickChart> createState() =>
      _InteractiveCandlestickChartState();
}

class _InteractiveCandlestickChartState
    extends State<InteractiveCandlestickChart> {
  double _scale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  Offset? _crosshairPosition;
  int? _selectedCandleIndex;
  bool _showPriceOverlay = false;
  bool _initialized = false;

  // Track previous values for delta calculations
  double _previousScale = 1.0;

  void resetView() {
    setState(() {
      _scale = 1.0;
      _panX = 0.0; // Always keep pan values at 0 - no panning allowed
      _panY = 0.0; // Always keep pan values at 0 - no panning allowed
      _showPriceOverlay = false;
      _crosshairPosition = null;
      _selectedCandleIndex = null;
      _initialized =
          false; // Reset initialization to re-apply last 20 candles view
    });
  }

  void _initializeView() {
    if (widget.candles.isEmpty || _initialized) return;

    setState(() {
      // Calculate scale to show only a target number of candles with proper spacing
      final int targetCandles = widget.initialVisibleCandles;
      final totalCandles = widget.candles.length;

      if (totalCandles > targetCandles) {
        // Calculate scale to show exactly targetCandles
        // Scale = total candles / target candles
        _scale = totalCandles / targetCandles;

        // DISABLED: Pan positioning - axes are now fixed
        // Chart will always show the most recent candles without panning
        // final startIndex = totalCandles - targetCandles;
        // final candleSpacing = availableWidth / totalCandles;
        // final startPosition = startIndex * candleSpacing;

        // Keep pan values at 0 - no panning allowed
        _panX = 0.0;
        _panY = 0.0;
      }

      _initialized = true;
    });
  }

  void zoomIn() {
    setState(() {
      _scale = (_scale * 1.2).clamp(0.5, 5.0);
    });
  }

  void zoomOut() {
    setState(() {
      _scale = (_scale / 1.2).clamp(0.5, 5.0);
    });
  }

  @override
  void didUpdateWidget(InteractiveCandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset initialization when candles data changes
    if (oldWidget.candles != widget.candles) {
      _initialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize view to show last N candles; skip if external scroll drives width
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.externalScroll) {
        _initializeView();
      }
    });

    return GestureDetector(
      onTapDown: widget.externalScroll ? null : _onTapDown,
      onTapUp: widget.externalScroll ? null : _onTapUp,
      onTapCancel: widget.externalScroll ? null : _onTapCancel,
      onDoubleTap: widget.externalScroll ? null : () => zoomIn(),
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate, // Only zooming allowed, panning disabled
      onScaleEnd: _onScaleEnd,
      // Use deferToChild to allow vertical scrolling to pass through to page
      behavior: widget.externalScroll
          ? HitTestBehavior.translucent
          : HitTestBehavior.deferToChild,
      child: Stack(
        children: [
          CustomPaint(
            painter: InteractiveCandlestickPainter(
              candles: widget.candles,
              scale: _scale,
              panX: _panX,
              panY: _panY,
              crosshairPosition: _crosshairPosition,
              selectedCandleIndex: _selectedCandleIndex,
              showFastMA: widget.showFastMA,
              showSlowMA: widget.showSlowMA,
              fastMAPeriod: widget.fastMAPeriod,
              slowMAPeriod: widget.slowMAPeriod,
              backgroundColor: Theme.of(context).colorScheme.surface,
              gridColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.3),
              textColor: Theme.of(context).colorScheme.onSurface,
              crosshairColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.8),
              crosshairDotColor: Theme.of(context).colorScheme.onSurface,
            ),
            size: widget.size,
          ),
          if (_showPriceOverlay && _selectedCandleIndex != null)
            _buildPriceOverlay(),

          // Debug info overlay
          // Positioned(
          //   top: 8,
          //   left: 8,
          //   child: Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color: Colors.black.withOpacity(0.7),
          //       borderRadius: BorderRadius.circular(4),
          //     ),
          //     child: Text(
          //       'Scale: ${_scale.toStringAsFixed(2)}\nPan: (${_panX.toStringAsFixed(1)}, ${_panY.toStringAsFixed(1)})',
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 10,
          //         fontFamily: 'monospace',
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle zoom (scale) - use delta scale
      if (details.scale != 1.0) {
        final deltaScale = details.scale / _previousScale;
        _scale = (_scale * deltaScale).clamp(0.5, 20.0);
        _previousScale = details.scale;
      }

      // DISABLED: Pan (translation) - chart axes are now fixed
      // Only allow zooming, no panning allowed
      // final deltaPan = details.focalPoint - _previousFocalPoint;
      // Damp pan speed slightly to keep control
      // _panX += deltaPan.dx * 0.9;
      // _panY += deltaPan.dy;

      // Debug print
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // Reset tracking values
    _previousScale = 1.0;
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _crosshairPosition = details.localPosition;
      _selectedCandleIndex = _getCandleIndexAtPosition(details.localPosition);
      _showPriceOverlay = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    // Keep overlay visible for a moment
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showPriceOverlay = false;
          _crosshairPosition = null;
          _selectedCandleIndex = null;
        });
      }
    });
  }

  void _onTapCancel() {
    setState(() {
      _showPriceOverlay = false;
      _crosshairPosition = null;
      _selectedCandleIndex = null;
    });
  }

  int? _getCandleIndexAtPosition(Offset position) {
    if (widget.candles.isEmpty) return null;

    const leftPadding = 40.0;
    const rightAxisWidth = 56.0;
    final availableWidth = widget.size.width - leftPadding - rightAxisWidth;
    final candleSpacing = availableWidth / widget.candles.length;

    final adjustedX = (position.dx - leftPadding) / _scale - _panX;
    final index = (adjustedX / candleSpacing).round();

    if (index >= 0 && index < widget.candles.length) {
      return index;
    }
    return null;
  }

  Widget _buildPriceOverlay() {
    if (_selectedCandleIndex == null ||
        _selectedCandleIndex! >= widget.candles.length) {
      return const SizedBox.shrink();
    }

    final candle = widget.candles[_selectedCandleIndex!];
    final isGreen = candle['close']! > candle['open']!;

    return Positioned(
      left: _crosshairPosition!.dx + 10,
      top: _crosshairPosition!.dy - 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isGreen ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Candle ${_selectedCandleIndex! + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            _buildPriceRow(
              'open'.tr,
              candle['open']!,
              Theme.of(context).colorScheme.onSurface,
            ),
            _buildPriceRow('high'.tr, candle['high']!, Colors.green),
            _buildPriceRow('low'.tr, candle['low']!, Colors.red),
            _buildPriceRow(
              'close'.tr,
              candle['close']!,
              isGreen ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 4),
            Text(
              isGreen ? '↗ ${'bullish'.tr}' : '↘ ${'bearish'.tr}',
              style: TextStyle(
                color: isGreen ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        Text(
          value.toStringAsFixed(5),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Enhanced candlestick painter with MT5-like quality
class CandlestickPainter extends CustomPainter {
  final List<Map<String, double>> candles;

  CandlestickPainter(this.candles);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final paint = Paint();
    final padding = 60.0; // More padding for professional look
    final availableWidth = size.width - (padding * 2);
    final availableHeight = size.height - (padding * 2);

    // Calculate candle width with proper spacing
    final pixelPerCandleBase = availableWidth / candles.length;
    final candleSpacing = pixelPerCandleBase;
    final desiredBodyRatio = 0.42; // more gutter, cleaner visual at dense zoom
    final candleWidth = (pixelPerCandleBase * desiredBodyRatio).clamp(
      1.0,
      14.0,
    );

    // Find min and max values for proper scaling
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    for (final candle in candles) {
      minPrice = [
        minPrice,
        candle['low']!,
        candle['open']!,
        candle['close']!,
      ].reduce((a, b) => a < b ? a : b);
      maxPrice = [
        maxPrice,
        candle['high']!,
        candle['open']!,
        candle['close']!,
      ].reduce((a, b) => a > b ? a : b);
    }

    // Add some margin to the price range for better visualization
    final priceRange = maxPrice - minPrice;
    final priceMargin = priceRange * 0.05; // 5% margin for tighter view
    final adjustedMinPrice = minPrice - priceMargin;
    final adjustedMaxPrice = maxPrice + priceMargin;
    final adjustedPriceRange = adjustedMaxPrice - adjustedMinPrice;

    final scaleY = availableHeight / adjustedPriceRange;

    // Draw professional grid lines
    _drawProfessionalGridLines(
      canvas,
      size,
      padding,
      adjustedMinPrice,
      adjustedMaxPrice,
      scaleY,
    );

    // Draw price labels
    _drawPriceLabels(
      canvas,
      size,
      padding,
      adjustedMinPrice,
      adjustedMaxPrice,
      scaleY,
    );

    // Draw candlesticks with MT5-like quality
    // If pixel spacing is too small, skip some candles to avoid clutter
    final int step = candleSpacing < 3.0 ? (3.0 / candleSpacing).ceil() : 1;
    for (int i = 0; i < candles.length; i += step) {
      final candle = candles[i];
      final x =
          padding + (i * candleSpacing) + (candleSpacing - candleWidth) / 2;

      final isGreen = candle['close']! > candle['open']!;
      final isDoji =
          (candle['close']! - candle['open']!).abs() <
          (adjustedPriceRange * 0.001);

      // Convert prices to screen coordinates
      final highY =
          padding +
          availableHeight -
          ((candle['high']! - adjustedMinPrice) * scaleY);
      final lowY =
          padding +
          availableHeight -
          ((candle['low']! - adjustedMinPrice) * scaleY);
      final openY =
          padding +
          availableHeight -
          ((candle['open']! - adjustedMinPrice) * scaleY);
      final closeY =
          padding +
          availableHeight -
          ((candle['close']! - adjustedMinPrice) * scaleY);

      // Ensure coordinates are within bounds
      final clampedHighY = highY.clamp(padding, padding + availableHeight);
      final clampedLowY = lowY.clamp(padding, padding + availableHeight);
      final clampedOpenY = openY.clamp(padding, padding + availableHeight);
      final clampedCloseY = closeY.clamp(padding, padding + availableHeight);

      // Draw wick (high to low) with professional styling
      paint.strokeWidth = 1.0;
      paint.color = isGreen ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
      canvas.drawLine(
        Offset(x + candleWidth / 2, clampedHighY),
        Offset(x + candleWidth / 2, clampedLowY),
        paint,
      );

      // Draw body (open to close) with MT5-like appearance
      final bodyTop = clampedOpenY < clampedCloseY
          ? clampedOpenY
          : clampedCloseY;
      final bodyHeight = (clampedOpenY - clampedCloseY).abs();

      if (bodyHeight > 0.5) {
        // Fill body with gradient-like effect
        paint.style = PaintingStyle.fill;
        paint.color = isGreen
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336);
        canvas.drawRect(
          Rect.fromLTWH(x, bodyTop, candleWidth, bodyHeight),
          paint,
        );

        // Draw body border with contrasting color
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.5;
        paint.color = isGreen
            ? const Color(0xFF2E7D32)
            : const Color(0xFFD32F2F);
        canvas.drawRect(
          Rect.fromLTWH(x, bodyTop, candleWidth, bodyHeight),
          paint,
        );
      } else if (isDoji) {
        // Draw doji candle as a horizontal line
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.5;
        paint.color = const Color(0xFF9E9E9E);
        canvas.drawLine(
          Offset(x, clampedOpenY),
          Offset(x + candleWidth, clampedOpenY),
          paint,
        );
      }
    }
  }

  void _drawProfessionalGridLines(
    Canvas canvas,
    Size size,
    double padding,
    double minPrice,
    double maxPrice,
    double scaleY,
  ) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;
    final availableHeight = size.height - (padding * 2);
    final priceStep = (maxPrice - minPrice) / 8;
    for (int i = 0; i <= 8; i++) {
      final price = minPrice + (priceStep * i);
      final y = padding + availableHeight - ((price - minPrice) * scaleY);
      if (y >= padding && y <= padding + availableHeight) {
        paint.color = Colors.grey.withOpacity(0.3);
        paint.strokeWidth = 0.5;
        canvas.drawLine(
          Offset(padding, y),
          Offset(size.width - padding, y),
          paint,
        );
      }
    }
    final candleSpacing = (size.width - (padding * 2)) / candles.length;
    for (int i = 0; i <= candles.length; i += (candles.length / 12).ceil()) {
      final x = padding + (i * candleSpacing);
      if (x >= padding && x <= size.width - padding) {
        paint.color = Colors.grey.withOpacity(0.2);
        paint.strokeWidth = 0.3;
        canvas.drawLine(
          Offset(x, padding),
          Offset(x, size.height - padding),
          paint,
        );
      }
    }
  }

  void _drawPriceLabels(
    Canvas canvas,
    Size size,
    double padding,
    double minPrice,
    double maxPrice,
    double scaleY,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final availableHeight = size.height - (padding * 2);
    final priceStep = (maxPrice - minPrice) / 8;
    for (int i = 0; i <= 8; i++) {
      final price = minPrice + (priceStep * i);
      final y = padding + availableHeight - ((price - minPrice) * scaleY);
      if (y >= padding && y <= padding + availableHeight) {
        final priceText = price.toStringAsFixed(5);
        textPainter.text = const TextSpan();
        textPainter.text = TextSpan(
          text: priceText,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            size.width - padding - textPainter.width - 5,
            y - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Interactive candlestick painter with zoom, pan, and crosshair support
class InteractiveCandlestickPainter extends CustomPainter {
  final List<Map<String, double>> candles;
  final double scale;
  final double panX;
  final double panY;
  final Offset? crosshairPosition;
  final int? selectedCandleIndex;
  final bool showFastMA;
  final bool showSlowMA;
  final int fastMAPeriod;
  final int slowMAPeriod;
  final Color backgroundColor;
  final Color gridColor;
  final Color textColor;
  final Color crosshairColor;
  final Color crosshairDotColor;

  InteractiveCandlestickPainter({
    required this.candles,
    required this.scale,
    required this.panX,
    required this.panY,
    this.crosshairPosition,
    this.selectedCandleIndex,
    this.showFastMA = true,
    this.showSlowMA = true,
    this.fastMAPeriod = 20,
    this.slowMAPeriod = 50,
    required this.backgroundColor,
    required this.gridColor,
    required this.textColor,
    required this.crosshairColor,
    required this.crosshairDotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final paint = Paint();
    const leftPadding = 40.0;
    const rightAxisWidth = 56.0; // reserve space for Y-axis labels
    const padding = 40.0; // top/bottom padding
    final availableWidth = size.width - leftPadding - rightAxisWidth;
    final availableHeight = size.height - (padding * 2);

    // Apply transformations - scale first, then translate
    canvas.save();
    canvas.scale(scale);
    canvas.translate(panX / scale, panY / scale);

    // Calculate candle width with proper spacing - ensure good visibility
    final pixelPerCandleBase = availableWidth / candles.length;
    final candleSpacing = pixelPerCandleBase;
    final desiredBodyRatio = 0.42; // more gutter, cleaner visual at dense zoom
    final candleWidth = (pixelPerCandleBase * desiredBodyRatio).clamp(
      1.0,
      14.0,
    );

    // Find min and max values for proper scaling
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    for (final candle in candles) {
      minPrice = [
        minPrice,
        candle['low']!,
        candle['open']!,
        candle['close']!,
      ].reduce((a, b) => a < b ? a : b);
      maxPrice = [
        maxPrice,
        candle['high']!,
        candle['open']!,
        candle['close']!,
      ].reduce((a, b) => a > b ? a : b);
    }

    // Add some margin to the price range for better visualization
    final priceRange = maxPrice - minPrice;
    final priceMargin = priceRange * 0.1; // 10% margin
    final adjustedMinPrice = minPrice - priceMargin;
    final adjustedMaxPrice = maxPrice + priceMargin;
    final adjustedPriceRange = adjustedMaxPrice - adjustedMinPrice;

    final scaleY = availableHeight / adjustedPriceRange;

    // Draw professional grid lines
    _drawProfessionalGridLines(
      canvas,
      size,
      padding,
      adjustedMinPrice,
      adjustedMaxPrice,
      scaleY,
    );

    // Draw price labels
    _drawPriceLabels(
      canvas,
      size,
      padding,
      adjustedMinPrice,
      adjustedMaxPrice,
      scaleY,
    );

    // Draw candlesticks with MT5-like quality
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x =
          leftPadding + (i * candleSpacing) + (candleSpacing - candleWidth) / 2;

      final isGreen = candle['close']! > candle['open']!;
      final isDoji =
          (candle['close']! - candle['open']!).abs() <
          (adjustedPriceRange * 0.001);
      final isSelected = selectedCandleIndex == i;

      // Highlight selected candle with professional styling
      if (isSelected) {
        paint.color = Colors.amber.withOpacity(0.2);
        paint.style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(x - 3, padding, candleWidth + 6, availableHeight),
          paint,
        );
      }

      // Convert prices to screen coordinates
      final highY =
          padding +
          availableHeight -
          ((candle['high']! - adjustedMinPrice) * scaleY);
      final lowY =
          padding +
          availableHeight -
          ((candle['low']! - adjustedMinPrice) * scaleY);
      final openY =
          padding +
          availableHeight -
          ((candle['open']! - adjustedMinPrice) * scaleY);
      final closeY =
          padding +
          availableHeight -
          ((candle['close']! - adjustedMinPrice) * scaleY);

      // Ensure coordinates are within bounds
      final clampedHighY = highY.clamp(padding, padding + availableHeight);
      final clampedLowY = lowY.clamp(padding, padding + availableHeight);
      final clampedOpenY = openY.clamp(padding, padding + availableHeight);
      final clampedCloseY = closeY.clamp(padding, padding + availableHeight);

      // Draw wick (high to low) with professional styling
      paint.strokeWidth = isSelected ? 2.0 : (candleSpacing < 2.0 ? 0.8 : 1.0);
      paint.color = isGreen ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
      canvas.drawLine(
        Offset(x + candleWidth / 2, clampedHighY),
        Offset(x + candleWidth / 2, clampedLowY),
        paint,
      );

      // Draw body (open to close) with MT5-like appearance
      final bodyTop = clampedOpenY < clampedCloseY
          ? clampedOpenY
          : clampedCloseY;
      final bodyHeight = (clampedOpenY - clampedCloseY).abs();

      if (bodyHeight > 0.5) {
        // Fill body with professional colors
        paint.style = PaintingStyle.fill;
        paint.color = isGreen
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336);
        canvas.drawRect(
          Rect.fromLTWH(x, bodyTop, candleWidth, bodyHeight),
          paint,
        );

        // Draw body border with contrasting color
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = isSelected ? 1.5 : 0.5;
        paint.color = isGreen
            ? const Color(0xFF2E7D32)
            : const Color(0xFFD32F2F);
        canvas.drawRect(
          Rect.fromLTWH(x, bodyTop, candleWidth, bodyHeight),
          paint,
        );
      } else if (isDoji) {
        // Draw doji candle as a horizontal line
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = isSelected ? 2.0 : 1.5;
        paint.color = const Color(0xFF9E9E9E);
        canvas.drawLine(
          Offset(x, clampedOpenY),
          Offset(x + candleWidth, clampedOpenY),
          paint,
        );
      }
    }

    // Draw Moving Averages (thin lines in dense modes)
    if (showFastMA) {
      _drawMovingAverage(
        canvas,
        size,
        padding,
        adjustedMinPrice,
        scaleY,
        fastMAPeriod,
        const Color(0xFF2196F3),
        candleSpacing,
      );
    }
    if (showSlowMA) {
      _drawMovingAverage(
        canvas,
        size,
        padding,
        adjustedMinPrice,
        scaleY,
        slowMAPeriod,
        const Color(0xFFFFC107),
        candleSpacing,
      );
    }

    // Draw crosshair
    if (crosshairPosition != null) {
      _drawCrosshair(canvas, size, crosshairPosition!);
    }

    canvas.restore();
  }

  void _drawMovingAverage(
    Canvas canvas,
    Size size,
    double padding,
    double adjustedMinPrice,
    double scaleY,
    int period,
    Color color,
    double candleSpacing,
  ) {
    if (candles.length < period || period <= 1) return;
    final availableWidth = size.width - (padding * 2);
    final candleSpacing = availableWidth / candles.length;
    final path = Path();
    bool hasMoved = false;
    final prices = candles.map((c) => c['close']!).toList();
    for (int i = 0; i < prices.length; i++) {
      if (i + 1 < period) continue;
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += prices[j];
      }
      final ma = sum / period;
      final x = padding + (i * candleSpacing) + (candleSpacing / 2);
      final y =
          padding +
          (size.height - (padding * 2)) -
          ((ma - adjustedMinPrice) * scaleY);
      if (!hasMoved) {
        path.moveTo(x, y);
        hasMoved = true;
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = candleSpacing < 2.0 ? 0.8 : 1.5
      ..color = color.withOpacity(0.9);
    canvas.drawPath(path, paint);
  }

  void _drawProfessionalGridLines(
    Canvas canvas,
    Size size,
    double padding,
    double minPrice,
    double maxPrice,
    double scaleY,
  ) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.2)
      ..strokeWidth = 0.5;

    final availableHeight = size.height - (padding * 2);

    // Draw horizontal grid lines with better spacing
    final priceStep = (maxPrice - minPrice) / 8; // More grid lines
    for (int i = 0; i <= 8; i++) {
      final price = minPrice + (priceStep * i);
      final y = padding + availableHeight - ((price - minPrice) * scaleY);

      if (y >= padding && y <= padding + availableHeight) {
        // Main grid lines
        paint.color = Colors.grey.withOpacity(0.3);
        paint.strokeWidth = 0.5;
        canvas.drawLine(
          Offset(padding, y),
          Offset(size.width - padding, y),
          paint,
        );
      }
    }

    // Draw vertical grid lines
    final candleSpacing = (size.width - (padding * 2)) / candles.length;
    for (int i = 0; i <= candles.length; i += (candles.length / 12).ceil()) {
      final x = padding + (i * candleSpacing);
      if (x >= padding && x <= size.width - padding) {
        paint.color = Colors.grey.withOpacity(0.2);
        paint.strokeWidth = 0.3;
        canvas.drawLine(
          Offset(x, padding),
          Offset(x, size.height - padding),
          paint,
        );
      }
    }
  }

  void _drawPriceLabels(
    Canvas canvas,
    Size size,
    double padding,
    double minPrice,
    double maxPrice,
    double scaleY,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final availableHeight = size.height - (padding * 2);
    final priceStep = (maxPrice - minPrice) / 8;

    for (int i = 0; i <= 8; i++) {
      final price = minPrice + (priceStep * i);
      final y = padding + availableHeight - ((price - minPrice) * scaleY);

      if (y >= padding && y <= padding + availableHeight) {
        final priceText = price.toStringAsFixed(5);
        textPainter.text = TextSpan(
          text: priceText,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        );
        textPainter.layout();

        // Position text on the right side
        textPainter.paint(
          canvas,
          Offset(
            size.width - padding - textPainter.width - 5,
            y - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawCrosshair(Canvas canvas, Size size, Offset position) {
    final paint = Paint()
      ..color = crosshairColor.withOpacity(0.8)
      ..strokeWidth = 1.0;

    // Draw vertical line
    canvas.drawLine(
      Offset(position.dx, 0),
      Offset(position.dx, size.height),
      paint,
    );

    // Draw horizontal line
    canvas.drawLine(
      Offset(0, position.dy),
      Offset(size.width, position.dy),
      paint,
    );

    // Draw center dot
    paint.color = crosshairDotColor;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(position, 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! InteractiveCandlestickPainter) return true;

    return oldDelegate.candles != candles ||
        oldDelegate.scale != scale ||
        oldDelegate.panX != panX ||
        oldDelegate.panY != panY ||
        oldDelegate.crosshairPosition != crosshairPosition ||
        oldDelegate.selectedCandleIndex != selectedCandleIndex;
  }
}
