import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../providers/syp_provider.dart';
import '../controllers/translation_controller.dart';


class EnhancedSypPage extends StatefulWidget {
  const EnhancedSypPage({super.key});

  @override
  State<EnhancedSypPage> createState() => _EnhancedSypPageState();
}

class _EnhancedSypPageState extends State<EnhancedSypPage> {
  @override
  void initState() {
    super.initState();
    
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sypProvider = Get.find<SypProvider>();
      sypProvider.loadCurrentRates();
      sypProvider.loadForecast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final translationController = Get.find<TranslationController>();
    
    return Obx(() => Directionality(
      textDirection: translationController.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNewFlag(),
              const SizedBox(width: 8),
              Text('syrianPound'.tr),
            ],
          ),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final sypProvider = Get.find<SypProvider>();
                sypProvider.loadCurrentRates();
                sypProvider.loadForecast();
              },
              tooltip: 'refresh'.tr,
            ),
          ],
        ),
        body: _buildCurrentRatesTab(),
      ),
    ));
  }

  Widget _buildCurrentRatesTab() {
    return GetBuilder<SypProvider>(
      builder: (sypProvider) {
        if (sypProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (sypProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${sypProvider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    sypProvider.loadCurrentRates();
                    sypProvider.loadForecast();
                  },
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        final currentRates = sypProvider.currentRates;
        final forecast = sypProvider.forecast;
        
        if (currentRates == null) {
          return Center(child: Text('noDataAvailable'.tr));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Rate Card
              Card(
                elevation: 4,
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'USD/SYP',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Black Market Rate',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currentRates.currentRates.mid.toStringAsFixed(2),
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'SYP per USD',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRateInfo('Ask', currentRates.currentRates.ask, Colors.red[600]!),
                          _buildRateInfo('Bid', currentRates.currentRates.bid, Colors.green[600]!),
                          _buildRateInfo('Spread', currentRates.currentRates.spread, Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Change Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Change',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('change'.tr + ':'),
                          Text(
                            '${currentRates.currentRates.change.toStringAsFixed(2)} SYP',
                            style: TextStyle(
                              color: currentRates.currentRates.change >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('changePercent'.tr + ':'),
                          Text(
                            '${currentRates.currentRates.changePercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: currentRates.currentRates.changePercentage >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // OHLCV Data
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trading Data',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildOhlcvInfo('Open', currentRates.ohlcv.open)),
                          Expanded(child: _buildOhlcvInfo('High', currentRates.ohlcv.high)),
                          Expanded(child: _buildOhlcvInfo('Low', currentRates.ohlcv.low)),
                          Expanded(child: _buildOhlcvInfo('Close', currentRates.ohlcv.close)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('volume'.tr + ':'),
                          Text(
                            '${currentRates.ohlcv.volume.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                 
                    ],
                  ),
                ),
              ),
              
       
              const SizedBox(height: 16),
              
     // City Comparison Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_city, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'City Comparison',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCityComparison(currentRates),
                    ],
                  ),
                ),
              ),

                     const SizedBox(height: 16),
              
              // Last Updated
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.update, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: ${_formatDateTime(currentRates.timestamp)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Forecast Section
              if (forecast != null) ...[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Tomorrow\'s Forecast',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Predicted Rate',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  forecast.prediction.rate.toStringAsFixed(2),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Expected Change',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  '${forecast.prediction.expectedChange.toStringAsFixed(2)} SYP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: forecast.prediction.expectedChange >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('confidence'.tr + ':'),
                            Text(
                              '${forecast.prediction.confidenceInterval.rangePct.toStringAsFixed(1)}% range',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                     
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
         
              
         
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityComparison(currentRates) {
    // Simulate city data - in real app this would come from API
    final cities = [
      {'name': 'Aleppo', 'rate': currentRates.currentRates.mid, 'change': 0.27},
      {'name': 'Damascus', 'rate': currentRates.currentRates.mid + 5, 'change': 0.31},
      {'name': 'Idlib', 'rate': currentRates.currentRates.mid - 3, 'change': 0.22},
    ];
    
    return Column(
      children: cities.map((city) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              city['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  '${(city['rate'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(city['change'] as double).toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: (city['change'] as double) >= 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMarketAnalysis(currentRates, forecast) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('marketTrend'.tr + ':'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: currentRates.currentRates.change >= 0 ? Colors.green[600] : Colors.red[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentRates.currentRates.change >= 0 ? 'BULLISH' : 'BEARISH',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('volatility'.tr + ':'),
            Text(
              currentRates.ohlcv.dayType == 'calm' ? 'Low' : 'Normal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Spread:'),
            Text(
              '${currentRates.currentRates.spread.toStringAsFixed(2)} SYP',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (forecast != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('tomorrowOutlook'.tr + ':'),
              Text(
                forecast.prediction.expectedChange >= 0 ? 'Positive' : 'Negative',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: forecast.prediction.expectedChange >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRateInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOhlcvInfo(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildNewFlag() {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      child: Column(
        children: [
          // Green stripe
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.green[600],
            ),
          ),
          // White stripe with stars
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildStar(),
                  _buildStar(),
                  _buildStar(),
                ],
              ),
            ),
          ),
          // Black stripe
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStar() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
