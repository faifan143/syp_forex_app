import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/forex_provider.dart';
import '../models/forex_models.dart';

class ForexChartsPage extends StatefulWidget {
  const ForexChartsPage({super.key});

  @override
  State<ForexChartsPage> createState() => _ForexChartsPageState();
}

class _ForexChartsPageState extends State<ForexChartsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ForexProvider>();
      provider.initializeData();
      provider.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Stop auto-refresh when leaving page
    final provider = context.read<ForexProvider>();
    provider.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Live Forex Charts'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = context.read<ForexProvider>();
              provider.refreshData();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugDialog(context),
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: Consumer<ForexProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Header with pair selection and timeframe
              _buildHeader(provider),
              
              // Main chart area
              Expanded(
                child: _buildChartArea(provider),
              ),
              
              // Market watch panel
              _buildMarketWatch(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ForexProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Demo mode toggle
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: provider.useDemoData 
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: provider.useDemoData 
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        provider.useDemoData ? Icons.games : Icons.cloud,
                        color: provider.useDemoData ? Colors.orange : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.useDemoData 
                              ? '🎮 Demo Mode - Using sample data'
                              : '☁️ Live Mode - Alpha Vantage API',
                          style: TextStyle(
                            color: provider.useDemoData ? Colors.orange : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => provider.toggleDemoData(),
                icon: Icon(provider.useDemoData ? Icons.cloud : Icons.games),
                label: Text(provider.useDemoData ? 'Switch to Live' : 'Switch to Demo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.useDemoData ? Colors.blue : Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Currency pair selector
          Row(
            children: [
              const Text('Currency Pair:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: provider.selectedPair,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: provider.availablePairs.map((pair) {
                    return DropdownMenuItem(
                      value: pair['symbol'],
                      child: Text(pair['symbol']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setSelectedPair(value);
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Timeframe selector
          Row(
            children: [
              const Text('Timeframe:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: provider.selectedTimeframe,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: provider.availableTimeframes.map((tf) {
                    return DropdownMenuItem(
                      value: tf['value'],
                      child: Text(tf['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setSelectedTimeframe(value);
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Current price display
          if (provider.chartData != null) _buildPriceDisplay(provider.chartData!),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(ForexChartData chartData) {
    final isUp = chartData.isPriceUp;
    final color = isUp ? Colors.green : Colors.red;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chartData.symbol,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${chartData.timeframe} Chart',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (chartData.metadata != null && chartData.metadata!.contains('Demo'))
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Demo Data',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(chartData.currentPrice),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${chartData.priceChange >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '\$').format(chartData.priceChange)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${chartData.priceChangePercent >= 0 ? '+' : ''}${chartData.priceChangePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea(ForexProvider provider) {
    if (provider.isLoadingChart) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chart data...'),
          ],
        ),
      );
    }

    if (provider.chartError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Chart Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    provider.chartError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  if (provider.chartError!.contains('API Rate Limit')) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Try Demo Mode!',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Switch to demo mode to see charts with sample data while waiting for API limits to reset.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => provider.refreshData(),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.toggleDemoData(),
                  icon: const Icon(Icons.games),
                  label: const Text('Try Demo Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (provider.chartData == null || provider.chartData!.candles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Chart Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select a currency pair and timeframe to view charts',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chart title
          Text(
            '${provider.chartData!.symbol} - ${provider.chartData!.timeframe}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Candlestick chart
          Expanded(
            child: _buildCandlestickChart(provider.chartData!),
          ),
          
          // Last updated info
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Last updated: ${DateFormat('MMM dd, yyyy HH:mm:ss').format(provider.chartData!.lastUpdate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandlestickChart(ForexChartData chartData) {
    final candles = chartData.candles.reversed.toList(); // Reverse for chart display
    
    // Create data points for the chart
    final List<FlSpot> openSpots = [];
    final List<FlSpot> highSpots = [];
    final List<FlSpot> lowSpots = [];
    final List<FlSpot> closeSpots = [];
    
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      openSpots.add(FlSpot(i.toDouble(), candle.open));
      highSpots.add(FlSpot(i.toDouble(), candle.high));
      lowSpots.add(FlSpot(i.toDouble(), candle.low));
      closeSpots.add(FlSpot(i.toDouble(), candle.close));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.01,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(4),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0 && value.toInt() < candles.length) {
                  final candle = candles[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM dd').format(candle.timestamp),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          // Open price line
          LineChartBarData(
            spots: openSpots,
            isCurved: false,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
          // High price line
          LineChartBarData(
            spots: highSpots,
            isCurved: false,
            color: Colors.green,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
          // Low price line
          LineChartBarData(
            spots: lowSpots,
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
          // Close price line (main line)
          LineChartBarData(
            spots: closeSpots,
            isCurved: false,
            color: Colors.orange,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black.withValues(alpha: 0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final candle = candles[touchedSpot.x.toInt()];
                return LineTooltipItem(
                  'O: ${candle.open.toStringAsFixed(4)}\n'
                  'H: ${candle.high.toStringAsFixed(4)}\n'
                  'L: ${candle.low.toStringAsFixed(4)}\n'
                  'C: ${candle.close.toStringAsFixed(4)}\n'
                  '${DateFormat('MMM dd, yyyy').format(candle.timestamp)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMarketWatch(ForexProvider provider) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Market Watch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (provider.isLoadingRates)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (provider.ratesError != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error: ${provider.ratesError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  if (provider.ratesError!.contains('API Rate Limit')) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 Tip: Switch to demo mode to see sample data!',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.forexRates.length,
                itemBuilder: (context, index) {
                  final symbol = provider.forexRates.keys.elementAt(index);
                  final rate = provider.forexRates[symbol]!;
                  
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rate.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rate.rate.toStringAsFixed(4),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(rate.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    final provider = context.read<ForexProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Forex Charts Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏷️ Selected Pair: ${provider.selectedPair}'),
              Text('⏰ Selected Timeframe: ${provider.selectedTimeframe}'),
              Text('🎮 Demo Mode: ${provider.useDemoData ? "✅ Enabled" : "❌ Disabled"}'),
              Text('📊 Chart Data: ${provider.chartData != null ? "✅ Loaded" : "❌ Not loaded"}'),
              if (provider.chartData != null) ...[
                Text('🕯️ Candles: ${provider.chartData!.candles.length}'),
                Text('💰 Current Price: \$${provider.chartData!.currentPrice.toStringAsFixed(4)}'),
                Text('📈 Price Change: ${provider.chartData!.priceChange.toStringAsFixed(4)}'),
                Text('📊 Change %: ${provider.chartData!.priceChangePercent.toStringAsFixed(2)}%'),
                if (provider.chartData!.metadata != null)
                  Text('📝 Metadata: ${provider.chartData!.metadata}'),
              ],
              const SizedBox(height: 16),
              Text('💱 Forex Rates: ${provider.forexRates.length} loaded'),
              Text('⏳ Chart Loading: ${provider.isLoadingChart}'),
              Text('⏳ Rates Loading: ${provider.isLoadingRates}'),
              if (provider.chartError != null) Text('🚨 Chart Error: ${provider.chartError}'),
              if (provider.ratesError != null) Text('🚨 Rates Error: ${provider.ratesError}'),
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
              provider.debugCurrentState();
            },
            child: const Text('Debug State'),
          ),
        ],
      ),
    );
  }
}
