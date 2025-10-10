library fullscreen_chart_page;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../providers/paper_trading_provider.dart';
import '../controllers/translation_controller.dart';
import '../controllers/theme_controller.dart';

// Candle data model for custom painter
class CandleData {
  final double x;
  final double open;
  final double high;
  final double low;
  final double close;
  final DateTime time;

  CandleData({
    required this.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.time,
  });
}

class FullscreenChartPage extends StatefulWidget {
  final String symbol;
  final String timeframe;
  final List<Map<String, double>> initialCandles;

  const FullscreenChartPage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.initialCandles,
  });

  @override
  State<FullscreenChartPage> createState() => _FullscreenChartPageState();
}

class _FullscreenChartPageState extends State<FullscreenChartPage>
    with TickerProviderStateMixin {
  // Controllers
  final ThemeController _themeController = Get.find<ThemeController>();
  final TranslationController _translationController =
      Get.find<TranslationController>();

  // Chart data
  List<Map<String, double>> _candles = [];
  String _currentSymbol = '';
  String _currentTimeframe = '';

  // Debug tracking
  double _lastMinPrice = 0.0;
  double _lastMaxPrice = 0.0;

  // Chart viewport
  double _scrollOffset = 0.0;
  double _zoomLevel = 1.0;
  int _visibleCandleCount = 100;
  double _candleWidth = 8.0;

  // Price range
  double _minPrice = 0.0;
  double _maxPrice = 0.0;
  double _priceRange = 0.0;

  // Interaction state
  Offset? _crosshairPosition;
  bool _isDragging = false;
  double _lastDragX = 0.0;
  double _lastScale = 1.0;

  // Indicators
  bool _showMA20 = true;
  bool _showMA50 = false;
  bool _showVolume = false;

  // Animation
  late AnimationController _priceUpdateController;
  
  // Listener management
  VoidCallback? _paperProviderListener;

  // Constants
  static const double AXIS_WIDTH = 60.0;
  static const double AXIS_HEIGHT = 30.0;
  static const double MIN_ZOOM = 0.5;
  static const double MAX_ZOOM = 5.0;
  static const int MIN_VISIBLE_CANDLES = 20;
  static const int MAX_VISIBLE_CANDLES = 300;

  @override
  void initState() {
    super.initState();
    _currentSymbol = widget.symbol;
    _currentTimeframe = widget.timeframe;
    _candles = List.from(widget.initialCandles);

    _priceUpdateController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize chart after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChart();
      _startLiveDataUpdates();
    });
  }

  // Start listening to live simulation data
  void _startLiveDataUpdates() {
    final paperProvider = Get.find<PaperTradingProvider>();

    // Create the listener callback
    _paperProviderListener = () {
      // Check if widget is still mounted before calling setState
      if (!mounted) return;
      
      if (paperProvider.isSimulationRunning &&
          paperProvider.chartData.containsKey(_currentSymbol)) {
        final newCandles = paperProvider.chartData[_currentSymbol]!;

        setState(() {
          _candles = List.from(newCandles);
          // Update scroll offset to show latest candles
          _scrollOffset = (_candles.length - _visibleCandleCount)
              .toDouble()
              .clamp(0, _candles.length.toDouble());
          _updatePriceRange();
        });
      }
    };

    // Add the listener
    paperProvider.addListener(_paperProviderListener!);
  }

  @override
  void dispose() {
    // Remove the listener to prevent setState after dispose
    if (_paperProviderListener != null) {
      final paperProvider = Get.find<PaperTradingProvider>();
      paperProvider.removeListener(_paperProviderListener!);
      _paperProviderListener = null;
    }
    
    _priceUpdateController.dispose();
    super.dispose();
  }

  void _initializeChart() {
    if (_candles.isEmpty) {
      // Don't return early - let the chart show empty state
      // The live data updates will populate it when real data arrives
    } else {
      // Set initial scroll to show latest candles
      _scrollOffset = (_candles.length - _visibleCandleCount).toDouble().clamp(
        0,
        _candles.length.toDouble(),
      );

      _updatePriceRange();
    }

    // Force a rebuild to ensure proper rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _updatePriceRange() {
    if (_candles.isEmpty) {
      return;
    }

    // Get current price from live simulation data or most recent candle
    double currentPrice;
    final paperProvider = Get.find<PaperTradingProvider>();

    if (paperProvider.isSimulationRunning &&
        paperProvider.currentPrices.containsKey(_currentSymbol)) {
      currentPrice = paperProvider.currentPrices[_currentSymbol]!;
    } else {
      currentPrice = _candles.last['close']!;
    }

    // Calculate visible candle range based on scroll and zoom
    final startIdx = _scrollOffset.floor().clamp(0, _candles.length - 1);
    final endIdx = (startIdx + _visibleCandleCount).clamp(0, _candles.length);
    
    // Get visible candles for price range calculation
    final visibleCandles = _candles.sublist(startIdx, endIdx);
    
    // If no visible candles, use recent candles as fallback
    final candlesForRange = visibleCandles.isNotEmpty 
        ? visibleCandles 
        : (_candles.length > 50 ? _candles.sublist(_candles.length - 50) : _candles);

    // Find min/max from visible candles
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    for (final candle in candlesForRange) {
      minPrice = minPrice < candle['low']! ? minPrice : candle['low']!;
      maxPrice = maxPrice > candle['high']! ? maxPrice : candle['high']!;
    }

    // Ensure current price is included if it's within visible range
    if (visibleCandles.isNotEmpty) {
      minPrice = minPrice < currentPrice ? minPrice : currentPrice;
      maxPrice = maxPrice > currentPrice ? maxPrice : currentPrice;
    }

    // Add adaptive buffer based on price range
    final priceRange = maxPrice - minPrice;
    final buffer = priceRange > 0 ? (priceRange * 0.05).clamp(0.0001, 0.01) : 0.01; // 5% buffer, min 0.0001, max 0.01

    // Ensure minimum price range for visibility
    final minPriceRange = 0.001; // Minimum 0.1% range
    if (priceRange < minPriceRange) {
      final center = (maxPrice + minPrice) / 2;
      minPrice = center - minPriceRange / 2;
      maxPrice = center + minPriceRange / 2;
    }

    // Check for significant price range changes
    if (_lastMinPrice != 0.0 && _lastMaxPrice != 0.0) {
      final minChange = (minPrice - buffer - _lastMinPrice).abs();
      final maxChange = (maxPrice + buffer - _lastMaxPrice).abs();
      final significantChange =
          minChange > 0.001 || maxChange > 0.001; // 0.1% change threshold

      if (significantChange) {
        // Price range changed significantly, update
      }
    }

    setState(() {
      _minPrice = minPrice - buffer;
      _maxPrice = maxPrice + buffer;
      _priceRange = _maxPrice - _minPrice;
    });

    // Update tracking values
    _lastMinPrice = _minPrice;
    _lastMaxPrice = _maxPrice;
  }

  void _handleScroll(double delta) {
    setState(() {
      // Calculate actual candle spacing for better scroll sensitivity
      final actualCandleWidth = (_candleWidth * _zoomLevel).clamp(2.0, 20.0);
      final candleSpacing = actualCandleWidth + 1.0;
      
      // Adjust scroll sensitivity based on zoom level
      final scrollSensitivity = 1.0 / candleSpacing;
      final newScrollOffset = _scrollOffset - (delta * scrollSensitivity);
      
      _scrollOffset = newScrollOffset.clamp(
        0, 
        (_candles.length - _visibleCandleCount).toDouble().clamp(0, _candles.length.toDouble())
      );
      _updatePriceRange();
    });
  }

  void _handleZoom(double scale, Offset focalPoint) {
    final oldZoom = _zoomLevel;
    final newZoom = (_zoomLevel * scale).clamp(MIN_ZOOM, MAX_ZOOM);

    if (newZoom != oldZoom) {
      // Provide haptic feedback for zoom actions
      HapticFeedback.lightImpact();
      
      // Calculate new visible candle count based on zoom level
      final baseVisibleCount = 100;
      final newVisibleCount = (baseVisibleCount / newZoom).round().clamp(
        MIN_VISIBLE_CANDLES,
        MAX_VISIBLE_CANDLES,
      );

      // Calculate actual candle spacing for focal point calculation
      final oldCandleSpacing = (_candleWidth * oldZoom).clamp(2.0, 20.0) + 1.0;
      final newCandleSpacing = (_candleWidth * newZoom).clamp(2.0, 20.0) + 1.0;

      // Adjust scroll to keep focal point stable
      final focalCandle = _scrollOffset + focalPoint.dx / oldCandleSpacing;
      final newScrollOffset = focalCandle - focalPoint.dx / newCandleSpacing;

      setState(() {
        _zoomLevel = newZoom;
        _visibleCandleCount = newVisibleCount;
        _scrollOffset = newScrollOffset.clamp(
          0,
          (_candles.length - _visibleCandleCount).toDouble().clamp(0, _candles.length.toDouble()),
        );
        _updatePriceRange();
      });
    }
  }

  void _handleDoubleTapZoom() {
    // Double-tap to zoom in/out - toggle between 1x and 2x zoom
    final targetZoom = _zoomLevel < 1.5 ? 2.0 : 1.0;
    final centerPoint = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    
    // Provide haptic feedback for double-tap zoom
    HapticFeedback.mediumImpact();
    _handleZoom(targetZoom / _zoomLevel, centerPoint);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _themeController.isDarkMode;
    final isRTL = _translationController.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0E17)
            : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildChartArea()),
              _buildToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = _themeController.isDarkMode;
    final isRTL = _translationController.isRTL;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isRTL ? Icons.arrow_forward : Icons.arrow_back,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),

          // Symbol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F26) : const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _currentSymbol,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Timeframe selector
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F26) : const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String>(
              value: _currentTimeframe,
              dropdownColor: isDark
                  ? const Color(0xFF1A1F26)
                  : const Color(0xFFF8F9FA),
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
              underline: const SizedBox(),
              isDense: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 18,
              ),
              items: ['M1', 'M5', 'M15', 'H1', 'H4', 'D1'].map((tf) {
                return DropdownMenuItem(value: tf, child: Text(tf));
              }).toList(),
              onChanged: (value) {
                if (value != null) _changeTimeframe(value);
              },
            ),
          ),

          const Spacer(),

          // Current price or no data message
          if (_candles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _candles.last['close']! >= _candles.last['open']!
                    ? (isDark
                          ? Colors.green.withOpacity(0.2)
                          : Colors.green.withOpacity(0.1))
                    : (isDark
                          ? Colors.red.withOpacity(0.2)
                          : Colors.red.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _candles.last['close']!.toStringAsFixed(5),
                style: TextStyle(
                  color: _candles.last['close']! >= _candles.last['open']!
                      ? Colors.green
                      : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'No Data',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlChart() {
    final isDark = _themeController.isDarkMode;

    if (_candles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No Real Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for dashboard data...',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return CustomPaint(
      painter: ChartPainter(
        candles: _candles,
        scrollOffset: _scrollOffset,
        zoomLevel: _zoomLevel,
        candleWidth: _candleWidth,
        visibleCandleCount: _visibleCandleCount,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        showMA20: _showMA20,
        showMA50: _showMA50,
        showVolume: _showVolume,
        crosshairPosition: _crosshairPosition,
        isDark: isDark,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildChartArea() {
    final isDark = _themeController.isDarkMode;

    return GestureDetector(
      onScaleStart: (details) {
        _isDragging = true;
        _lastDragX = details.focalPoint.dx;
        _lastScale = 1.0; // Scale starts at 1.0
      },
      onScaleUpdate: (details) {
        // Handle pinch-to-zoom with better sensitivity
        if (details.scale != _lastScale) {
          // Calculate the scale difference for smoother zooming
          final scaleDiff = details.scale / _lastScale;
          _handleZoom(scaleDiff, details.localFocalPoint);
          _lastScale = details.scale;
        } else if (details.focalPoint.dx != _lastDragX) {
          // Handle horizontal scrolling
          final delta = details.focalPoint.dx - _lastDragX;
          _handleScroll(delta);
          _lastDragX = details.focalPoint.dx;
        }
      },
      onScaleEnd: (details) {
        _isDragging = false;
      },
      onTapDown: (details) {
        setState(() {
          _crosshairPosition = details.localPosition;
        });
      },
      onTapUp: (_) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _crosshairPosition = null;
            });
          }
        });
      },
      // Add double-tap to zoom functionality
      onDoubleTap: () {
        _handleDoubleTapZoom();
      },
      // Add long press to reset zoom
      onLongPress: () {
        _resetView();
      },
      child: Container(
        color: isDark ? const Color(0xFF0A0E17) : const Color(0xFFF5F5F5),
        child: Stack(
          children: [
            // No data message if no real data available
            if (_candles.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Real Data Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for dashboard data...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),

            // Main chart area with fl_chart (full height since X-axis removed)
            Positioned.fill(
              right: AXIS_WIDTH,
              child: _buildFlChart(),
            ),

            // Fixed Y-axis (price)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: AXIS_WIDTH,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F1419)
                      : const Color(0xFFF8F9FA),
                  border: Border(
                    left: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: YAxisPainter(
                    minPrice: _minPrice,
                    maxPrice: _maxPrice,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            // X-axis (time) removed - only keeping right Y-axis
            // Positioned(
            //   left: 0,
            //   right: AXIS_WIDTH,
            //   bottom: 0,
            //   height: AXIS_HEIGHT,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: isDark
            //           ? const Color(0xFF0F1419)
            //           : const Color(0xFFF8F9FA),
            //       border: Border(
            //         top: BorderSide(
            //           color: isDark
            //               ? Colors.white.withOpacity(0.1)
            //               : Colors.black.withOpacity(0.1),
            //         ),
            //       ),
            //     ),
            //     child: CustomPaint(
            //       painter: XAxisPainter(
            //         candles: _candles,
            //         scrollOffset: _scrollOffset,
            //         candleWidth: _candleWidth,
            //         zoomLevel: _zoomLevel,
            //         visibleCandleCount: _visibleCandleCount,
            //         timeframe: _currentTimeframe,
            //         isDark: isDark,
            //       ),
            //     ),
            //   ),
            // ),

            // Crosshair info
            if (_crosshairPosition != null)
              Positioned(
                left: _crosshairPosition!.dx + 10,
                top: _crosshairPosition!.dy - 40,
                child: _buildCrosshairInfo(),
              ),

            // Zoom controls with proper touch handling
            Positioned(
              left: 8,
              top: 8,
              child: GestureDetector(
                // Stop propagation of touch events to the chart below
                onTap: () {},
                onScaleStart: (_) {},
                onScaleUpdate: (_) {},
                child: _buildZoomControls(),
              ),
            ),

            // Zoom level indicator
            Positioned(
              right: AXIS_WIDTH + 8,
              top: 8,
              child: _buildZoomIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrosshairInfo() {
    if (_crosshairPosition == null || _candles.isEmpty) return const SizedBox();

    final candleIndex =
        ((_scrollOffset + _crosshairPosition!.dx / (_candleWidth * _zoomLevel))
            .floor()
            .clamp(0, _candles.length - 1));

    if (candleIndex >= _candles.length) return const SizedBox();

    final candle = _candles[candleIndex];
    final priceAtCursor =
        _maxPrice -
        (_crosshairPosition!.dy /
                (MediaQuery.of(context).size.height - AXIS_HEIGHT - 100)) *
            _priceRange;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26).withOpacity(0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Price: ${priceAtCursor.toStringAsFixed(5)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'O: ${candle['open']!.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(width: 8),
              Text(
                'H: ${candle['high']!.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.green, fontSize: 10),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'L: ${candle['low']!.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.red, fontSize: 10),
              ),
              const SizedBox(width: 8),
              Text(
                'C: ${candle['close']!.toStringAsFixed(5)}',
                style: TextStyle(
                  color: candle['close']! >= candle['open']!
                      ? Colors.green
                      : Colors.red,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomIndicator() {
    final isDark = _themeController.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1A1F26) : const Color(0xFFF8F9FA)).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(_zoomLevel * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Zoom',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    final isDark = _themeController.isDarkMode;
    final canZoomIn = _zoomLevel < MAX_ZOOM;
    final canZoomOut = _zoomLevel > MIN_ZOOM;
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1A1F26) : const Color(0xFFF8F9FA)).withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.zoom_in,
                  color: canZoomIn 
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : (isDark ? Colors.white30 : Colors.black26),
                  size: 20,
                ),
                onPressed: canZoomIn ? () => _handleZoom(
                  1.3,
                  Offset(MediaQuery.of(context).size.width / 2, 200),
                ) : null,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Zoom In',
              ),
              Container(
                width: 28,
                height: 1,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
              IconButton(
                icon: Icon(
                  Icons.zoom_out,
                  color: canZoomOut 
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : (isDark ? Colors.white30 : Colors.black26),
                  size: 20,
                ),
                onPressed: canZoomOut ? () => _handleZoom(
                  0.7,
                  Offset(MediaQuery.of(context).size.width / 2, 200),
                ) : null,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Zoom Out',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1A1F26) : const Color(0xFFF8F9FA)).withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.fit_screen,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 20,
            ),
            onPressed: _resetView,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Reset View',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1A1F26) : const Color(0xFFF8F9FA)).withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.center_focus_strong,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 20,
            ),
            onPressed: _handleDoubleTapZoom,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Double-tap Zoom',
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final isDark = _themeController.isDarkMode;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildIndicatorToggle(
            'MA20',
            _showMA20,
            Colors.yellow,
            () => setState(() => _showMA20 = !_showMA20),
          ),
          const SizedBox(width: 8),
          _buildIndicatorToggle(
            'MA50',
            _showMA50,
            Colors.cyan,
            () => setState(() => _showMA50 = !_showMA50),
          ),
          const SizedBox(width: 8),
          _buildIndicatorToggle(
            'VOL',
            _showVolume,
            Colors.blue,
            () => setState(() => _showVolume = !_showVolume),
          ),

          const Spacer(),

          Text(
            '${'zoom'.tr}: ${(_zoomLevel * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${'candles'.tr}: $_visibleCandleCount',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorToggle(
    String label,
    bool active,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = _themeController.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? color
                : (isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : (isDark ? Colors.white54 : Colors.black54),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _changeTimeframe(String timeframe) {
    setState(() {
      _currentTimeframe = timeframe;
    });

    // Update simulation timeframe to get live data
    final paperProvider = Get.find<PaperTradingProvider>();
    if (paperProvider.isSimulationRunning) {
      // Convert timeframe format for simulation
      String simulationTimeframe = _convertTimeframeForSimulation(timeframe);
      paperProvider.updateTimeframe(simulationTimeframe);
    }

    _initializeChart();
  }

  // Convert timeframe format for simulation service
  String _convertTimeframeForSimulation(String timeframe) {
    switch (timeframe) {
      case 'M1':
        return '1m';
      case 'M5':
        return '5m';
      case 'M15':
        return '15m';
      case 'H1':
        return '1h';
      case 'H4':
        return '4h';
      case 'D1':
        return '1d';
      default:
        return '1h'; // Default fallback
    }
  }

  void _resetView() {
    // Provide haptic feedback for reset
    HapticFeedback.heavyImpact();
    
    setState(() {
      _zoomLevel = 1.0;
      _visibleCandleCount = 100;
      _scrollOffset = (_candles.length - _visibleCandleCount).toDouble().clamp(
        0,
        _candles.length.toDouble(),
      );
      _updatePriceRange();
    });
  }

  // Initialize chart with proper viewport settings
  void _initializeChartViewport() {
    if (_candles.isEmpty) return;
    
    // Set initial scroll to show latest candles
    _scrollOffset = (_candles.length - _visibleCandleCount).toDouble().clamp(
      0,
      _candles.length.toDouble(),
    );
    
    // Ensure proper initial zoom and candle count
    _zoomLevel = 1.0;
    _visibleCandleCount = 100;
    
    _updatePriceRange();
  }
}

// Chart Painter
class ChartPainter extends CustomPainter {
  final List<Map<String, double>> candles;
  final double scrollOffset;
  final double zoomLevel;
  final double candleWidth;
  final int visibleCandleCount;
  final double minPrice;
  final double maxPrice;
  final bool showMA20;
  final bool showMA50;
  final bool showVolume;
  final Offset? crosshairPosition;
  final bool isDark;

  ChartPainter({
    required this.candles,
    required this.scrollOffset,
    required this.zoomLevel,
    required this.candleWidth,
    required this.visibleCandleCount,
    required this.minPrice,
    required this.maxPrice,
    required this.showMA20,
    required this.showMA50,
    required this.showVolume,
    this.crosshairPosition,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isNotEmpty) {}
    if (candles.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    // Draw grid
    _drawGrid(canvas, size);

    // Draw candles
    _drawCandles(canvas, size);

    // Draw indicators
    if (showMA20) _drawMA(canvas, size, 20, Colors.yellow);
    if (showMA50) _drawMA(canvas, size, 50, Colors.cyan);

    // Draw crosshair
    if (crosshairPosition != null) {
      _drawCrosshair(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Add margins for grid
    final margin = 5.0;
    final availableHeight = size.height - (2 * margin);

    // Horizontal lines with proper margins
    for (int i = 0; i <= 10; i++) {
      final y = margin + availableHeight * (i / 10);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines based on actual candle spacing
    final actualCandleWidth = (candleWidth * zoomLevel).clamp(2.0, 20.0);
    final candleSpacing = actualCandleWidth + 1.0;
    final startIdx = scrollOffset.floor().clamp(0, candles.length - 1);
    final endIdx = (startIdx + visibleCandleCount).clamp(0, candles.length);

    // Draw vertical lines every 5 candles for better readability
    for (int i = startIdx; i < endIdx; i += 5) {
      final x = (i - scrollOffset) * candleSpacing;
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(Offset(x, margin), Offset(x, size.height - margin), paint);
      }
    }
  }

  void _drawCandles(Canvas canvas, Size size) {
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0 || candles.isEmpty) {
      return;
    }

    final startIdx = scrollOffset.floor().clamp(0, candles.length - 1);
    final endIdx = (startIdx + visibleCandleCount).clamp(0, candles.length);

    // Calculate actual candle width and spacing for better viewport utilization
    final actualCandleWidth = (candleWidth * zoomLevel).clamp(2.0, 20.0);
    final candleSpacing = actualCandleWidth + 1.0; // Small gap between candles

    int drawnCount = 0;
    for (int i = startIdx; i < endIdx && i < candles.length; i++) {
      final candle = candles[i];
      final x = (i - scrollOffset) * candleSpacing;

      // Skip candles outside viewport with proper bounds checking
      if (x < -actualCandleWidth || x > size.width + actualCandleWidth) continue;

      final open = candle['open']!;
      final high = candle['high']!;
      final low = candle['low']!;
      final close = candle['close']!;

      final isGreen = close >= open;

      // Calculate Y positions with proper bounds checking
      final margin = 5.0; // Top and bottom margin
      final availableHeight = size.height - (2 * margin);
      
      final priceRatio = (open - minPrice) / priceRange;
      final yOpen = margin + availableHeight * (1 - priceRatio);

      final closeRatio = (close - minPrice) / priceRange;
      final yClose = margin + availableHeight * (1 - closeRatio);

      final highRatio = (high - minPrice) / priceRange;
      final yHigh = margin + availableHeight * (1 - highRatio);

      final lowRatio = (low - minPrice) / priceRange;
      final yLow = margin + availableHeight * (1 - lowRatio);

      // Clamp Y positions to stay within bounds
      final clampedYHigh = yHigh.clamp(margin, size.height - margin);
      final clampedYLow = yLow.clamp(margin, size.height - margin);
      final clampedYOpen = yOpen.clamp(margin, size.height - margin);
      final clampedYClose = yClose.clamp(margin, size.height - margin);

      drawnCount++;

      // Draw wick (high-low line) with improved visibility
      final wickPaint = Paint()
        ..color = isGreen
            ? Colors.green.withOpacity(0.9)
            : Colors.red.withOpacity(0.9)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final wickX = x + actualCandleWidth / 2;
      canvas.drawLine(
        Offset(wickX, clampedYHigh),
        Offset(wickX, clampedYLow),
        wickPaint,
      );

      // Draw body with improved rendering
      final bodyPaint = Paint()
        ..color = isGreen ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;

      final bodyTop = clampedYOpen < clampedYClose ? clampedYOpen : clampedYClose;
      final bodyHeight = (clampedYClose - clampedYOpen).abs();

      // Ensure minimum body height for visibility
      final minBodyHeight = 1.0;
      final actualBodyHeight = bodyHeight < minBodyHeight
          ? minBodyHeight
          : bodyHeight;

      // Calculate body width with padding
      final bodyWidth = (actualCandleWidth * 0.7).clamp(2.0, 15.0);
      final bodyX = x + (actualCandleWidth - bodyWidth) / 2;

      // Draw body rectangle with rounded corners
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bodyX,
            bodyTop,
            bodyWidth,
            actualBodyHeight,
          ),
          const Radius.circular(1),
        ),
        bodyPaint,
      );

      // Draw body outline for better definition
      final outlinePaint = Paint()
        ..color = isGreen ? Colors.green.shade700 : Colors.red.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bodyX,
            bodyTop,
            bodyWidth,
            actualBodyHeight,
          ),
          const Radius.circular(1),
        ),
        outlinePaint,
      );
    }
  }

  void _drawMA(Canvas canvas, Size size, int period, Color color) {
    if (candles.length < period) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    bool firstPoint = true;

    final startIdx = scrollOffset.floor();
    final endIdx = (startIdx + visibleCandleCount + 1).clamp(0, candles.length);

    // Calculate actual candle spacing
    final actualCandleWidth = (candleWidth * zoomLevel).clamp(2.0, 20.0);
    final candleSpacing = actualCandleWidth + 1.0;

    // Add margins for MA calculation
    final margin = 5.0;
    final availableHeight = size.height - (2 * margin);

    for (int i = startIdx; i < endIdx && i < candles.length; i++) {
      if (i < period - 1) continue;

      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j]['close']!;
      }
      final ma = sum / period;

      final x = (i - scrollOffset) * candleSpacing + actualCandleWidth / 2;
      final y = margin + availableHeight * (1 - (ma - minPrice) / (maxPrice - minPrice));

      // Clamp Y position to stay within bounds
      final clampedY = y.clamp(margin, size.height - margin);

      if (x < -actualCandleWidth || x > size.width + actualCandleWidth) continue;

      if (firstPoint) {
        path.moveTo(x, clampedY);
        firstPoint = false;
      } else {
        path.lineTo(x, clampedY);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    if (crosshairPosition == null) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 0.5;

    // Add margins for crosshair
    final margin = 5.0;

    // Vertical line with margins
    canvas.drawLine(
      Offset(crosshairPosition!.dx, margin),
      Offset(crosshairPosition!.dx, size.height - margin),
      paint,
    );

    // Horizontal line with margins
    canvas.drawLine(
      Offset(0, crosshairPosition!.dy),
      Offset(size.width, crosshairPosition!.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Y-Axis Painter
class YAxisPainter extends CustomPainter {
  final double minPrice;
  final double maxPrice;
  final bool isDark;

  YAxisPainter({
    required this.minPrice,
    required this.maxPrice,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final priceRange = maxPrice - minPrice;

    if (priceRange <= 0.0001) {
      return;
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 10; i++) {
      final price = maxPrice - (priceRange * i / 10);
      final y = size.height * (i / 10);
      


      textPainter.text = TextSpan(
        text: price.toStringAsFixed(4),
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));

      if (i <= 1) {
        // Log first 2 labels
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// X-Axis Painter
class XAxisPainter extends CustomPainter {
  final List<Map<String, double>> candles;
  final double scrollOffset;
  final double candleWidth;
  final double zoomLevel;
  final int visibleCandleCount;
  final String timeframe;
  final bool isDark;

  XAxisPainter({
    required this.candles,
    required this.scrollOffset,
    required this.candleWidth,
    required this.zoomLevel,
    required this.visibleCandleCount,
    required this.timeframe,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final startIdx = scrollOffset.floor();
    final candleSpacing = candleWidth * zoomLevel;

    // Simple label interval - every 10 candles
    final labelInterval = 10;

    for (int i = 0; i < visibleCandleCount; i += labelInterval) {
      final candleIdx = startIdx + i;
      if (candleIdx >= candles.length) break;

      // Calculate x position to align with candle center
      final x = i * candleSpacing + (candleWidth * zoomLevel) / 2;
      if (x > size.width) break;

      // Simple time label - show relative candle position
      final timeLabel = '${i + 1}';

      // Skip if no valid time label
      if (timeLabel.isEmpty) continue;

      textPainter.text = TextSpan(
        text: timeLabel,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black, // Make text more visible
          fontSize: 10, // Slightly larger font
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();

      // Center the text under the candle
      final textX = x - textPainter.width / 2;
      if (textX > 0 && textX + textPainter.width < size.width) {
        textPainter.paint(canvas, Offset(textX, 2)); // Move slightly higher
      }
    }
  }

  String _generateTimeLabel(int candleIdx, int totalCandles) {
    if (candleIdx >= candles.length) return '';

    // Get the actual timestamp from the candle
    final candle = candles[candleIdx];
    final timestamp = candle['time'];

    // Fallback to current time if no timestamp
    DateTime dateTime;
    if (timestamp != null && timestamp > 0) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    } else {
      // Generate a proper chronological sequence starting from oldest to newest
      final now = DateTime.now();

      // Calculate time based on timeframe
      int timeOffset;
      switch (timeframe) {
        case 'M1':
          timeOffset = (totalCandles - candleIdx - 1); // 1 minute per candle
          dateTime = now.subtract(Duration(minutes: timeOffset));
          break;
        case 'M5':
          timeOffset =
              (totalCandles - candleIdx - 1) * 5; // 5 minutes per candle
          dateTime = now.subtract(Duration(minutes: timeOffset));
          break;
        case 'M15':
          timeOffset =
              (totalCandles - candleIdx - 1) * 15; // 15 minutes per candle
          dateTime = now.subtract(Duration(minutes: timeOffset));
          break;
        case 'H1':
          timeOffset = (totalCandles - candleIdx - 1); // 1 hour per candle
          dateTime = now.subtract(Duration(hours: timeOffset));
          break;
        case 'H4':
          timeOffset = (totalCandles - candleIdx - 1) * 4; // 4 hours per candle
          dateTime = now.subtract(Duration(hours: timeOffset));
          break;
        case 'D1':
          timeOffset = (totalCandles - candleIdx - 1); // 1 day per candle
          dateTime = now.subtract(Duration(days: timeOffset));
          break;
        default:
          timeOffset = (totalCandles - candleIdx - 1);
          dateTime = now.subtract(Duration(hours: timeOffset));
      }
    }

    switch (timeframe) {
      case 'M1':
        // 1-minute intervals: show HH:MM
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      case 'M5':
        // 5-minute intervals: show HH:MM (rounded to nearest 5)
        final minute = (dateTime.minute ~/ 5) * 5;
        return '${dateTime.hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      case 'M15':
        // 15-minute intervals: show HH:MM (rounded to nearest 15)
        final minute = (dateTime.minute ~/ 15) * 15;
        return '${dateTime.hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      case 'H1':
        // 1-hour intervals: show DD HH:00 for multi-day charts
        if (totalCandles > 24) {
          return '${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:00';
        } else {
          return '${dateTime.hour.toString().padLeft(2, '0')}:00';
        }

      case 'H4':
        // 4-hour intervals: show DD HH:00 (rounded to nearest 4 hours)
        final hour = (dateTime.hour ~/ 4) * 4;
        if (totalCandles > 6) {
          return '${dateTime.day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:00';
        } else {
          return '${hour.toString().padLeft(2, '0')}:00';
        }

      case 'D1':
        // Daily intervals: show DD/MM
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';

      default:
        // Default to hour format
        return '${dateTime.hour.toString().padLeft(2, '0')}:00';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Candlestick Painter for OHLCV data
class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double minPrice;
  final double maxPrice;
  final bool isDark;
  final bool showMA20;
  final bool showMA50;
  final bool showVolume;

  CandlestickPainter({
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
    required this.isDark,
    required this.showMA20,
    required this.showMA50,
    required this.showVolume,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    // Calculate candle width and spacing
    final candleWidth = size.width / candles.length * 0.8;
    final candleSpacing = size.width / candles.length;

    // Draw grid lines (keeping grid, removing axes)
    _drawGrid(canvas, size);
    
    // Axes removed - only keeping right Y-axis
    // _drawYAxisLabels(canvas, size, priceRange);
    // _drawXAxisLabels(canvas, size);

    // Draw candles
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = i * candleSpacing + candleSpacing / 2;
      _drawCandle(canvas, candle, x, candleWidth, size.height, priceRange);
    }

    // Draw moving averages
    if (showMA20) _drawMA(canvas, size, 20, Colors.yellow, priceRange);
    if (showMA50) _drawMA(canvas, size, 50, Colors.cyan, priceRange);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.1)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 10; i++) {
      final y = size.height * (i / 10);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical grid lines
    for (int i = 0; i <= 10; i++) {
      final x = size.width * (i / 10);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  // _drawYAxisLabels method removed - using custom right Y-axis instead

  // _drawXAxisLabels method removed - no X-axis needed

  void _drawCandle(
    Canvas canvas,
    CandleData candle,
    double x,
    double width,
    double height,
    double priceRange,
  ) {
    // Clamp Y positions to stay within bounds (with small margin)
    final margin = 2.0;
    final yHigh = (height * (1 - (candle.high - minPrice) / priceRange)).clamp(margin, height - margin);
    final yLow = (height * (1 - (candle.low - minPrice) / priceRange)).clamp(margin, height - margin);
    final yOpen = (height * (1 - (candle.open - minPrice) / priceRange)).clamp(margin, height - margin);
    final yClose = (height * (1 - (candle.close - minPrice) / priceRange)).clamp(margin, height - margin);

    final isGreen = candle.close >= candle.open;
    final color = isGreen ? Colors.green : Colors.red;

    // Draw wick (high-low line) - ensure it stays within bounds
    final wickPaint = Paint()
      ..color = color
      ..strokeWidth = 1;

    canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

    // Draw body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bodyTop = yOpen < yClose ? yOpen : yClose;
    final bodyHeight = (yClose - yOpen).abs();
    final minBodyHeight = 1.0;
    final actualBodyHeight = bodyHeight < minBodyHeight
        ? minBodyHeight
        : bodyHeight;

    // Ensure body stays within bounds
    final clampedBodyTop = bodyTop.clamp(margin, height - margin - actualBodyHeight);
    final clampedBodyHeight = actualBodyHeight.clamp(minBodyHeight, height - margin - clampedBodyTop);

    canvas.drawRect(
      Rect.fromLTWH(x - width / 2, clampedBodyTop, width, clampedBodyHeight),
      bodyPaint,
    );

    // Draw body outline
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(x - width / 2, clampedBodyTop, width, clampedBodyHeight),
      outlinePaint,
    );
  }

  void _drawMA(
    Canvas canvas,
    Size size,
    int period,
    Color color,
    double priceRange,
  ) {
    if (candles.length < period) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool firstPoint = true;
    final margin = 2.0;

    for (int i = period - 1; i < candles.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j].close;
      }
      final ma = sum / period;

      final x =
          i * (size.width / candles.length) + (size.width / candles.length) / 2;
      // Clamp Y position to stay within bounds
      final y = (size.height * (1 - (ma - minPrice) / priceRange)).clamp(margin, size.height - margin);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
