import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ai_recommendation.dart';
import '../models/forex_models.dart';
import '../services/ai_recommender_service.dart';
import '../controllers/translation_controller.dart';

class AIRecommenderWidget extends StatefulWidget {
  final String symbol;
  final double currentPrice;
  final List<dynamic> recentCandles;
  final dynamic currencyData;
  final VoidCallback? onRecommendationChanged;

  const AIRecommenderWidget({
    Key? key,
    required this.symbol,
    required this.currentPrice,
    required this.recentCandles,
    this.currencyData,
    this.onRecommendationChanged,
  }) : super(key: key);

  @override
  State<AIRecommenderWidget> createState() => _AIRecommenderWidgetState();
}

class _AIRecommenderWidgetState extends State<AIRecommenderWidget>
    with TickerProviderStateMixin {
  AIRecommendation? _recommendation;
  bool _isLoading = false;
  String _lastLanguage = '';
  String _lastSymbol = '';
  DateTime? _lastRecommendationDate;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Generate initial recommendation
    _generateRecommendation();
  }

  @override
  void didUpdateWidget(AIRecommenderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only regenerate recommendation if symbol changes or if it's a new day
    final now = DateTime.now();
    final isNewDay =
        _lastRecommendationDate == null ||
        now.day != _lastRecommendationDate!.day ||
        now.month != _lastRecommendationDate!.month ||
        now.year != _lastRecommendationDate!.year;

    if (oldWidget.symbol != widget.symbol || isNewDay) {
      _lastSymbol = widget.symbol;
      _generateRecommendation();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generateRecommendation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    _pulseController.repeat(reverse: true);
    _fadeController.forward();

    try {
      final recommendation = await AIRecommenderService()
          .generateRecommendation(
            symbol: widget.symbol,
            currentPrice: widget.currentPrice,
            recentCandles: widget.recentCandles.cast<Candlestick>(),
            currencyData: widget.currencyData,
          );

      setState(() {
        _recommendation = recommendation;
        _isLoading = false;
        _lastRecommendationDate = DateTime.now();
      });

      _pulseController.stop();
      _fadeController.reset();
      _fadeController.forward();

      widget.onRecommendationChanged?.call();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _pulseController.stop();
      _fadeController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TranslationController>(
      builder: (translationController) {
        // Update language but don't regenerate recommendation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (translationController.currentLanguage != _lastLanguage) {
            _lastLanguage = translationController.currentLanguage;
            // Just update the UI without regenerating recommendation
            setState(() {});
          }
        });

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (_isLoading) _buildLoadingWidget(),
                if (_recommendation != null && !_isLoading)
                  _buildRecommendationWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.psychology,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'aiRecommender'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _generateRecommendation,
          icon: Icon(
            Icons.refresh,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'refreshAnalysis'.tr,
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'analyzing'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationWidget() {
    if (_recommendation == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(children: [_buildRecommendationCard()]),
    );
  }

  Widget _buildRecommendationCard() {
    final rec = _recommendation!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rec.typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rec.typeColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: rec.typeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              rec.isBuy
                  ? Icons.trending_up
                  : rec.isSell
                  ? Icons.trending_down
                  : Icons.pause,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.typeDisplayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: rec.typeColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rec.simplifiedTimeHorizon,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rec.confidenceDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final rec = _recommendation!;

    return Column(
      children: [
        const SizedBox(height: 12),
        _buildDetailRow('targetPrice'.tr, rec.formattedTargetPrice),
        _buildDetailRow('stopLossPrice'.tr, rec.formattedStopLossPrice),
        _buildDetailRow('riskRewardRatio'.tr, rec.formattedRiskRewardRatio),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFactorsSection() {
    final rec = _recommendation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'keyFactors'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rec.keyFactors
              .map((factor) => _buildFactorChip(factor))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTechnicalIndicatorsSection() {
    final rec = _recommendation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'technicalIndicators'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rec.technicalIndicators
              .map((indicator) => _buildIndicatorChip(indicator))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFundamentalFactorsSection() {
    final rec = _recommendation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'fundamentalFactors'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rec.fundamentalFactors
              .map((factor) => _buildFactorChip(factor))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFactorChip(String factor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        factor,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildIndicatorChip(String indicator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Text(
        indicator,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
