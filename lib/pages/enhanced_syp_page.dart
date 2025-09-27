import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
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

    return Obx(
      () => Directionality(
        textDirection: translationController.isRTL
            ? TextDirection.rtl
            : TextDirection.ltr,
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
      ),
    );
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
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
                          Row(
                            children: [
                              Icon(
                                IconlyBroken.swap,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'USD/SYP',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            'blackMarketRate'.tr,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _comprehensiveData!
                                    .cityRates['damascus']
                                    ?.formattedMid ??
                                '0.0',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                          Text(
                            'sypPerUsd'.tr,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                      _buildRateInfo(
                        'ask'.tr,
                        _comprehensiveData!.cityRates['damascus']?.ask
                                .toDouble() ??
                            0.0,
                        Colors.red[600]!,
                      ),
                      _buildRateInfo(
                        'bid'.tr,
                        _comprehensiveData!.cityRates['damascus']?.bid
                                .toDouble() ??
                            0.0,
                        Colors.green[600]!,
                      ),
                      _buildRateInfo(
                        'spread'.tr,
                        _comprehensiveData!.cityRates['damascus']?.spread
                                .toDouble() ??
                            0.0,
                        Colors.orange,
                      ),
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
                        _getUsdChangeText(),
                        style: TextStyle(
                          color: _getUsdChangeColor(),
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
                        _getUsdChangePercentageText(),
                        style: TextStyle(
                          color: _getUsdChangeColor(),
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
                  Row(
                    children: [
                      Icon(IconlyBroken.chart, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'tradingData'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOhlcvInfo(
                          'open'.tr,
                          _comprehensiveData!.ohlcv.open,
                        ),
                      ),
                      Expanded(
                        child: _buildOhlcvInfo(
                          'high'.tr,
                          _comprehensiveData!.ohlcv.high,
                        ),
                      ),
                      Expanded(
                        child: _buildOhlcvInfo(
                          'low'.tr,
                          _comprehensiveData!.ohlcv.low,
                        ),
                      ),
                      Expanded(
                        child: _buildOhlcvInfo(
                          'close'.tr,
                          _comprehensiveData!.ohlcv.close,
                        ),
                      ),
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
                      Icon(IconlyBroken.location, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'cityComparison'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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

          // Currencies Grid
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(IconlyBroken.swap, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'currencies'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCurrenciesGrid(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tomorrow's Prediction Card
          Card(child: _buildPredictionCard()),
        ],
      ),
    );
  }

  Widget _buildCityComparison() {
    if (_comprehensiveData == null) return const SizedBox();

    // Filter to show only aleppo and idlib (exclude damascus as it's shown in main card)
    final comparisonCities = _comprehensiveData!.cityRates.entries.toList();

    return Column(
      children: comparisonCities.map((entry) {
        final cityName = entry.key;
        final cityRate = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    IconlyBroken.location,
                    size: 16,
                    color: cityName == 'damascus'
                        ? Colors.blue[600]
                        : Colors.orange[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cityName.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    cityRate.formattedMid,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(
                        IconlyBroken.arrow_up_2,
                        size: 12,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Ask: ${cityRate.formattedAsk}',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Row(
                    children: [
                      Icon(
                        IconlyBroken.arrow_down_2,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Bid: ${cityRate.formattedBid}',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrenciesGrid() {
    if (_comprehensiveData == null || _comprehensiveData!.currencies.isEmpty) {
      return const Center(child: Text('No currency data available'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _comprehensiveData!.currencies.length,
      itemBuilder: (context, index) {
        final currency = _comprehensiveData!.currencies[index];
        return _buildCurrencyCard(currency);
      },
    );
  }

  Widget _buildCurrencyCard(CurrencyData currency) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency name
            Row(
              children: [
                Icon(IconlyBroken.wallet, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    currency.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mid rate
            Text(
              currency.formattedMid,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 4),

            // Ask and Bid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          IconlyBroken.arrow_up_2,
                          size: 10,
                          color: Colors.red[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'ask'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currency.formattedAsk,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          IconlyBroken.arrow_down_2,
                          size: 10,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'bid'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currency.formattedBid,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Change info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      IconlyBroken.arrow_up_2,
                      size: 10,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${'change'.tr}:',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  currency.formattedChange,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: currency.isPositiveChange
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      IconlyBroken.discount,
                      size: 10,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${'changePercent'.tr}:',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  currency.formattedChangePercentage,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: currency.isPositiveChange
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

  // Helper methods for USD change calculations
  CurrencyData? _getUsdCurrency() {
    if (_comprehensiveData == null) return null;
    try {
      return _comprehensiveData!.currencies.firstWhere(
        (currency) =>
            currency.name.toLowerCase().contains('usd') ||
            currency.name.toLowerCase().contains('dollar'),
      );
    } catch (e) {
      return null;
    }
  }

  String _getUsdChangeText() {
    final usdCurrency = _getUsdCurrency();
    if (usdCurrency?.previousRates == null) {
      return '0 SYP'; // No previous rates available
    }

    final currentMid = _comprehensiveData!.cityRates['damascus']?.mid ?? 0.0;
    final previousMid = usdCurrency!.previousRates!.mid;
    final change = currentMid - previousMid;

    return '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} SYP';
  }

  String _getUsdChangePercentageText() {
    final usdCurrency = _getUsdCurrency();
    if (usdCurrency?.previousRates == null) {
      return '0.00%'; // No previous rates available
    }

    final currentMid = _comprehensiveData!.cityRates['damascus']?.mid ?? 0.0;
    final previousMid = usdCurrency!.previousRates!.mid;

    if (previousMid == 0) return '0.00%';

    final changePercentage = ((currentMid - previousMid) / previousMid) * 100;
    return '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(2)}%';
  }

  Color _getUsdChangeColor() {
    final usdCurrency = _getUsdCurrency();
    if (usdCurrency?.previousRates == null) {
      return Colors.grey; // No previous rates available
    }

    final currentMid = _comprehensiveData!.cityRates['damascus']?.mid ?? 0.0;
    final previousMid = usdCurrency!.previousRates!.mid;
    final change = currentMid - previousMid;

    return change >= 0 ? Colors.green : Colors.red;
  }

  Widget _buildPredictionCard() {
    if (_comprehensiveData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'noPredictionData'.tr,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final prediction = _comprehensiveData!.damascusPrediction;
    final currentRate = _comprehensiveData!.cityRates['damascus'];

    if (currentRate == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'noCurrentRateData'.tr,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Calculate prediction change from current rate
    final currentMid = currentRate.mid;
    final predictedMid = prediction.mid;
    final change = predictedMid - currentMid;
    final changePercentage = currentMid != 0
        ? (change / currentMid) * 100
        : 0.0;

    final isPositiveChange = change >= 0;
    final changeColor = isPositiveChange ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: changeColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: changeColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(IconlyBroken.chart, color: changeColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'tomorrowsPrediction'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositiveChange
                          ? IconlyBroken.arrow_up_2
                          : IconlyBroken.arrow_down_2,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositiveChange ? 'up'.tr : 'down'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main prediction value
          Text(
            prediction.mid.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: changeColor,
            ),
          ),
          Text(
            'syp'.tr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Trading details
          Row(
            children: [
              Expanded(
                child: _buildCompactDetail(
                  'ask'.tr,
                  prediction.ask.toStringAsFixed(0),
                  Colors.red[600]!,
                ),
              ),
              Expanded(
                child: _buildCompactDetail(
                  'bid'.tr,
                  prediction.bid.toStringAsFixed(0),
                  Colors.green[600]!,
                ),
              ),
              Expanded(
                child: _buildCompactDetail(
                  'spread'.tr,
                  prediction.spread.toStringAsFixed(0),
                  Colors.grey[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Change info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'change'.tr}: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} ${'syp'.tr}',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
            child: Container(width: double.infinity, color: Colors.green[600]),
          ),
          // White stripe with stars
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [_buildStar(), _buildStar(), _buildStar()],
              ),
            ),
          ),
          // Black stripe
          Expanded(
            child: Container(width: double.infinity, color: Colors.black),
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
