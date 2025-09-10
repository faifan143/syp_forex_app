import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../providers/forex_provider.dart';
import '../models/forex_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load forex dashboard data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forexProvider = Get.find<ForexProvider>();
      forexProvider.loadForexDashboard(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('forexToday'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final forexProvider = Get.find<ForexProvider>();
              forexProvider.loadForexDashboard(forceRefresh: true);
            },
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: GetBuilder<ForexProvider>(
        builder: (forexProvider) {
          if (forexProvider.isLoadingDashboard || forexProvider.isLoadingRates) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('loadingForexData'.tr),
                ],
              ),
            );
          }

          if (forexProvider.dashboardError != null || forexProvider.ratesError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'errorLoadingData'.tr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forexProvider.dashboardError ?? forexProvider.ratesError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      forexProvider.loadForexDashboard(forceRefresh: true);
                    },
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            );
          }

          // Show dashboard data if available, otherwise fallback to rates
          if (forexProvider.dashboardData != null) {
            return _buildDashboardView(forexProvider.dashboardData!);
          }
          
          // If dashboard failed, show error message
          if (forexProvider.dashboardError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_outlined,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'dashboardUnavailable'.tr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The forex dashboard API is not available. Please check if the backend server is running on localhost:5001',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      forexProvider.loadForexDashboard(forceRefresh: true);
                    },
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            );
          }

          final rates = forexProvider.forexRates.values.toList();
          
          if (rates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.currency_exchange,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text('noDataAvailable'.tr),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await forexProvider.loadForexDashboard();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Today\'s Forex Pairs',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current rates and tomorrow\'s predictions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Forex Pairs List
                ...rates.map((rate) => _buildForexPairCard(rate)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForexPairCard(ForexRate rate) {

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with symbol and rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate.symbol,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${rate.fromCurrency} to ${rate.toCurrency}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rate.rate.toStringAsFixed(5),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Tomorrow's Prediction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tomorrow\'s Prediction: ',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    (rate.rate + (rate.rate * (rate.changePercent ?? 0) / 100)).toStringAsFixed(5),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Last Updated
            Text(
              'Last updated: ${_formatDateTime(rate.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'justNow'.tr;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Get day name for predictions
  String _getDayName(int dayIndex) {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: dayIndex + 1));
    final weekdays = ['monday'.tr, 'tuesday'.tr, 'wednesday'.tr, 'thursday'.tr, 'friday'.tr, 'saturday'.tr, 'sunday'.tr];
    return weekdays[targetDate.weekday - 1];
  }


  // Build enhanced dashboard view with predictions
  Widget _buildDashboardView(ForexDashboardResponse dashboard) {
    return RefreshIndicator(
      onRefresh: () async {
        final forexProvider = Get.find<ForexProvider>();
        await forexProvider.loadForexDashboard();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // // Dashboard Header
          // Card(
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             Icon(
          //               Icons.dashboard,
          //               color: Theme.of(context).colorScheme.primary,
          //             ),
          //             const SizedBox(width: 8),
          //             Text(
          //               'forexDashboard'.tr,
          //               style: Theme.of(context).textTheme.headlineSmall,
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 8),
          //         Text(
          //           'lastUpdated'.tr + ': ${_formatTimestamp(dashboard.timestamp)}',
          //           style: Theme.of(context).textTheme.bodySmall,
          //         ),
          //         const SizedBox(height: 4),
          //         Text(
          //           '${dashboard.totalCurrencies} ${'currencies'.tr} • ${'predictions'.tr}: ${dashboard.features.sevenDayPredictions ? 'enabled'.tr : 'disabled'.tr}',
          //           style: Theme.of(context).textTheme.bodySmall,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          
          // const SizedBox(height: 16),
          
          // Currency Cards with Predictions
          ...dashboard.currencies.map((currency) => _buildCurrencyCard(currency)),
        ],
      ),
    );
  }

  // Build individual currency card with predictions
  Widget _buildCurrencyCard(Currency currency) {
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
                  currency.pair,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: currency.isTomorrowTrendUp 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currency.tomorrowTrend.toUpperCase(),
                    style: TextStyle(
                      color: currency.isTomorrowTrendUp 
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Current Price
            Row(
              children: [
                Text(
                  currency.formattedCurrentValue,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currency.tomorrowChange >= 0 ? '+${currency.tomorrowChange.toStringAsFixed(4)}' : currency.tomorrowChange.toStringAsFixed(4),
                  style: TextStyle(
                    color: currency.tomorrowChange >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currency.formattedTomorrowChangePercent,
                  style: TextStyle(
                    color: currency.tomorrowChange >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Predictions Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'predictions'.tr,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tomorrow Prediction
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('tomorrow'.tr),
                      Row(
                        children: [
                          Text(
                            currency.tomorrowPrediction.toStringAsFixed(4),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.tomorrowChange >= 0 ? '+${currency.tomorrowChange.toStringAsFixed(4)}' : currency.tomorrowChange.toStringAsFixed(4),
                            style: TextStyle(
                              color: currency.tomorrowChange >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currency.formattedTomorrowChangePercent,
                            style: TextStyle(
                              color: currency.tomorrowChange >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 7-Day Predictions
                  if (currency.forecast7Days.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '7DayPredictions'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...currency.forecast7Days.asMap().entries.map((entry) {
                      final dayIndex = entry.key;
                      final prediction = entry.value;
                      final dayName = _getDayName(dayIndex);
                      final change = prediction - currency.currentValue;
                      final changePercent = (change / currency.currentValue) * 100;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  prediction.toStringAsFixed(4),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  change >= 0 ? '+${change.toStringAsFixed(4)}' : change.toStringAsFixed(4),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: change >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  change >= 0 ? '+${changePercent.toStringAsFixed(1)}%' : '${changePercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: change >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
