import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/translation_controller.dart';
import '../models/comprehensive_models.dart';
import '../services/comprehensive_api_service.dart';


class EnhancedSypPage extends StatefulWidget {
  const EnhancedSypPage({super.key});

  @override
  State<EnhancedSypPage> createState() => _EnhancedSypPageState();
}

class _EnhancedSypPageState extends State<EnhancedSypPage> {
  ComprehensiveResponse? _comprehensiveData;
  bool _isLoading = false;
  String? _error;
  final ComprehensiveApiService _apiService = ComprehensiveApiService();

  @override
  void initState() {
    super.initState();
    
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComprehensiveData();
    });
  }

  Future<void> _loadComprehensiveData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getComprehensiveData();
      setState(() {
        _comprehensiveData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadComprehensiveData();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadComprehensiveData();
              },
              child: Text('retry'.tr),
            ),
          ],
        ),
      );
    }

    if (_comprehensiveData == null) {
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
            color: Theme.of(context).colorScheme.surface,
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
                            'blackMarketRate'.tr,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _comprehensiveData!.cityRates['damascus']?.formattedMid ?? '0.0',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'sypPerUsd'.tr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      _buildRateInfo('ask'.tr, _comprehensiveData!.cityRates['damascus']?.ask.toDouble() ?? 0.0, Colors.red[600]!),
                      _buildRateInfo('bid'.tr, _comprehensiveData!.cityRates['damascus']?.bid.toDouble() ?? 0.0, Colors.green[600]!),
                      _buildRateInfo('spread'.tr, _comprehensiveData!.cityRates['damascus']?.spread.toDouble() ?? 0.0, Colors.orange),
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
                    'dailyChange'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'change'.tr}:'),
                      Text(
                        '0 SYP', // City rates don't have change data, showing placeholder
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'changePercent'.tr}:'),
                      Text(
                        '0.00%', // City rates don't have change percentage data, showing placeholder
                        style: TextStyle(
                          color: Colors.grey,
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
                    'tradingData'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildOhlcvInfo('open'.tr, _comprehensiveData!.ohlcv.open)),
                      Expanded(child: _buildOhlcvInfo('high'.tr, _comprehensiveData!.ohlcv.high)),
                      Expanded(child: _buildOhlcvInfo('low'.tr, _comprehensiveData!.ohlcv.low)),
                      Expanded(child: _buildOhlcvInfo('close'.tr, _comprehensiveData!.ohlcv.close)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'volume'.tr}:'),
                      Text(
                        _comprehensiveData!.ohlcv.formattedVolume,
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
                        'cityComparison'.tr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCityComparison(),
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
                    '${'lastUpdated'.tr}: ${DateTime.now().toString().split('.')[0]}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityComparison() {
    if (_comprehensiveData == null) return const SizedBox();
    
    // Filter to show only aleppo and idlib (exclude damascus as it's shown in main card)
    final comparisonCities = _comprehensiveData!.cityRates.entries
        .toList();
    
    return Column(
      children: comparisonCities.map((entry) {
        final cityName = entry.key;
        final cityRate = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cityName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    cityRate.formattedMid,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ask: ${cityRate.formattedAsk}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bid: ${cityRate.formattedBid}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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
