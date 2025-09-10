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
        title: Text(
          'forexToday'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0), // Colors.blue[800]
                Color(0xFF1976D2), // Colors.blue[600]
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
            return _buildLoadingState();
          }

          if (forexProvider.dashboardError != null || forexProvider.ratesError != null) {
            return _buildErrorState(forexProvider);
          }

          // Show dashboard data if available, otherwise fallback to rates
          if (forexProvider.dashboardData != null) {
            return _buildDashboardView(forexProvider.dashboardData!);
          }
          
          // If dashboard failed, show error message
          if (forexProvider.dashboardError != null) {
            return _buildDashboardErrorState(forexProvider);
          }

          final rates = forexProvider.forexRates.values.toList();
          
          if (rates.isEmpty) {
            return _buildEmptyState();
          }

          return _buildRatesView(rates, forexProvider);
        },
      ),
    );
  }

  // Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'loadingForexData'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Error state
  Widget _buildErrorState(ForexProvider forexProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'errorLoadingData'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              forexProvider.dashboardError ?? forexProvider.ratesError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                forexProvider.loadForexDashboard(forceRefresh: true);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dashboard error state
  Widget _buildDashboardErrorState(ForexProvider forexProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_outlined,
              size: 48,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              'dashboardUnavailable'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The forex dashboard API is not available. Please check if the backend server is running on localhost:5001',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                forexProvider.loadForexDashboard(forceRefresh: true);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'noDataAvailable'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rates view (fallback when dashboard is not available)
  Widget _buildRatesView(List<ForexRate> rates, ForexProvider forexProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await forexProvider.loadForexDashboard();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rates.length,
        itemBuilder: (context, index) {
          return _buildCompactForexCard(rates[index]);
        },
      ),
    );
  }

  // Compact forex card for rates view
  Widget _buildCompactForexCard(ForexRate rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rate.symbol,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                rate.rate.toStringAsFixed(4),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${rate.fromCurrency} to ${rate.toCurrency}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _formatDateTime(rate.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dashboard.currencies.length,
        itemBuilder: (context, index) {
          return _buildCompactCurrencyCard(dashboard.currencies[index]);
        },
      ),
    );
  }

  // Build compact currency card with predictions
  Widget _buildCompactCurrencyCard(Currency currency) {
    final isUp = currency.tomorrowChange >= 0;
    final changeColor = isUp ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header with pair and trend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency.pair,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: changeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currency.tomorrowTrend.toUpperCase(),
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Current price and change
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency.formattedCurrentValue,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      isUp ? '+${currency.tomorrowChange.toStringAsFixed(4)}' : currency.tomorrowChange.toStringAsFixed(4),
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currency.formattedTomorrowChangePercent,
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Tomorrow prediction
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'tomorrow'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  currency.tomorrowPrediction.toStringAsFixed(4),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isUp ? '+${currency.tomorrowChange.toStringAsFixed(4)}' : currency.tomorrowChange.toStringAsFixed(4),
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currency.formattedTomorrowChangePercent,
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 7-Day Predictions (if available)
          if (currency.forecast7Days.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '7DayPredictions'.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...currency.forecast7Days.asMap().entries.map((entry) {
                    final dayIndex = entry.key;
                    final prediction = entry.value;
                    final dayName = _getDayName(dayIndex);
                    
                    // Calculate day-to-day change for trend analysis
                    double change = 0.0;
                    double changePercent = 0.0;
                    bool isDayUp = false;
                    Color dayChangeColor = Colors.grey;
                    
                    if (dayIndex == 0) {
                      // For first day, show change from current value
                      change = prediction - currency.currentValue;
                      changePercent = currency.currentValue != 0 ? (change / currency.currentValue) * 100 : 0.0;
                    } else {
                      // For subsequent days, show change from previous day
                      final previousDayPrediction = currency.forecast7Days[dayIndex - 1];
                      change = prediction - previousDayPrediction;
                      changePercent = previousDayPrediction != 0 ? (change / previousDayPrediction) * 100 : 0.0;
                    }
                    
                    isDayUp = change >= 0;
                    dayChangeColor = isDayUp ? Colors.green : Colors.red;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                prediction.toStringAsFixed(4),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                change.abs() < 0.001 
                                  ? (isDayUp ? '+${change.toStringAsFixed(6)}' : change.toStringAsFixed(6))
                                  : (isDayUp ? '+${change.toStringAsFixed(5)}' : change.toStringAsFixed(5)),
                                style: TextStyle(
                                  color: dayChangeColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                changePercent.abs() < 0.01 
                                  ? (isDayUp ? '+${changePercent.toStringAsFixed(3)}%' : '${changePercent.toStringAsFixed(3)}%')
                                  : (isDayUp ? '+${changePercent.toStringAsFixed(2)}%' : '${changePercent.toStringAsFixed(2)}%'),
                                style: TextStyle(
                                  color: dayChangeColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
