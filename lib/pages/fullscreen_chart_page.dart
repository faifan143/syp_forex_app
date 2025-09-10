import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../providers/paper_trading_provider.dart';
import '../providers/forex_provider.dart';
import '../controllers/translation_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/paper_trading_models.dart';
import '../models/forex_models.dart';
import '../services/realistic_data_generator.dart';

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
  final TranslationController _translationController = Get.find<TranslationController>();
  
  // Chart data
  List<Map<String, double>> _candles = [];
  String _currentSymbol = '';
  String _currentTimeframe = '';
  
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
  
  // Indicators
  bool _showMA20 = true;
  bool _showMA50 = false;
  bool _showVolume = false;
  
  // Animation
  late AnimationController _priceUpdateController;
  
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
    });
  }

  @override
  void dispose() {
    _priceUpdateController.dispose();
    super.dispose();
  }

  void _initializeChart() {
    if (_candles.isEmpty) return;
    
    // Set initial scroll to show latest candles
    _scrollOffset = (_candles.length - _visibleCandleCount).toDouble().clamp(0, _candles.length.toDouble());
    _updatePriceRange();
    
    // Force a rebuild to ensure proper rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Trigger a repaint
        });
      }
    });
  }

  void _updatePriceRange() {
    if (_candles.isEmpty) return;
    
    final startIdx = _scrollOffset.floor().clamp(0, _candles.length - 1);
    final endIdx = (startIdx + _visibleCandleCount).clamp(0, _candles.length);
    
    double min = double.infinity;
    double max = double.negativeInfinity;
    
    for (int i = startIdx; i < endIdx && i < _candles.length; i++) {
      final candle = _candles[i];
      min = min > candle['low']! ? candle['low']! : min;
      max = max < candle['high']! ? candle['high']! : max;
    }
    
    // Ensure we have valid values
    if (min == double.infinity || max == double.negativeInfinity) {
      min = _candles.first['low']!;
      max = _candles.first['high']!;
    }
    
    // Add 5% padding
    final padding = (max - min) * 0.05;
    setState(() {
      _minPrice = min - padding;
      _maxPrice = max + padding;
      _priceRange = _maxPrice - _minPrice;
    });
  }

  void _handleScroll(double delta) {
    setState(() {
      _scrollOffset = (_scrollOffset - delta / (_candleWidth * _zoomLevel))
          .clamp(0, (_candles.length - _visibleCandleCount).toDouble());
      _updatePriceRange();
    });
  }

  void _handleZoom(double scale, Offset focalPoint) {
    final oldZoom = _zoomLevel;
    final newZoom = (_zoomLevel * scale).clamp(MIN_ZOOM, MAX_ZOOM);
    
    if (newZoom != oldZoom) {
      // Calculate new visible candle count
      final newVisibleCount = (_visibleCandleCount / scale)
          .round()
          .clamp(MIN_VISIBLE_CANDLES, MAX_VISIBLE_CANDLES);
      
      // Adjust scroll to keep focal point stable
      final focalCandle = _scrollOffset + focalPoint.dx / (_candleWidth * oldZoom);
      final newScrollOffset = focalCandle - focalPoint.dx / (_candleWidth * newZoom);
      
      setState(() {
        _zoomLevel = newZoom;
        _visibleCandleCount = newVisibleCount;
        _scrollOffset = newScrollOffset.clamp(0, (_candles.length - _visibleCandleCount).toDouble());
        _updatePriceRange();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _themeController.isDarkMode;
    final isRTL = _translationController.isRTL;
    
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E17) : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildChartArea(),
              ),
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
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.1),
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
              dropdownColor: isDark ? const Color(0xFF1A1F26) : const Color(0xFFF8F9FA),
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
              items: ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'].map((tf) {
                return DropdownMenuItem(
                  value: tf,
                  child: Text(tf),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _changeTimeframe(value);
              },
            ),
          ),
          
          const Spacer(),
          
          // Current price
          if (_candles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _candles.last['close']! >= _candles.last['open']! 
                    ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1))
                    : (isDark ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.1)),
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
            ),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    final isDark = _themeController.isDarkMode;
    
    return GestureDetector(
      onScaleStart: (details) {
        _isDragging = true;
        _lastDragX = details.focalPoint.dx;
      },
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          _handleZoom(details.scale, details.localFocalPoint);
        } else {
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
      child: Container(
        color: isDark ? const Color(0xFF0A0E17) : const Color(0xFFF5F5F5),
        child: Stack(
          children: [
            // Main chart area with clipping
            Positioned.fill(
              right: AXIS_WIDTH,
              bottom: AXIS_HEIGHT,
              child: ClipRect(
                child: CustomPaint(
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
                    crosshairPosition: _crosshairPosition != null 
                        ? Offset(_crosshairPosition!.dx, 
                                 _crosshairPosition!.dy)
                        : null,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            
            // Fixed Y-axis (price)
            Positioned(
              right: 0,
              top: 0,
              bottom: AXIS_HEIGHT,
              width: AXIS_WIDTH,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8F9FA),
                  border: Border(
                    left: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
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
            
            // Fixed X-axis (time)
            Positioned(
              left: 0,
              right: AXIS_WIDTH,
              bottom: 0,
              height: AXIS_HEIGHT,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8F9FA),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: XAxisPainter(
                    candles: _candles,
                    scrollOffset: _scrollOffset,
                    candleWidth: _candleWidth,
                    zoomLevel: _zoomLevel,
                    visibleCandleCount: _visibleCandleCount,
                    timeframe: _currentTimeframe,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            
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
          ],
        ),
      ),
    );
  }

  Widget _buildCrosshairInfo() {
    if (_crosshairPosition == null || _candles.isEmpty) return const SizedBox();
    
    final candleIndex = ((_scrollOffset + _crosshairPosition!.dx / (_candleWidth * _zoomLevel))
        .floor()
        .clamp(0, _candles.length - 1));
    
    if (candleIndex >= _candles.length) return const SizedBox();
    
    final candle = _candles[candleIndex];
    final priceAtCursor = _maxPrice - (_crosshairPosition!.dy / 
        (MediaQuery.of(context).size.height - AXIS_HEIGHT - 100)) * _priceRange;
    
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
              Text('O: ${candle['open']!.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
              const SizedBox(width: 8),
              Text('H: ${candle['high']!.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.green, fontSize: 10)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('L: ${candle['low']!.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.red, fontSize: 10)),
              const SizedBox(width: 8),
              Text('C: ${candle['close']!.toStringAsFixed(5)}',
                  style: TextStyle(
                    color: candle['close']! >= candle['open']! ? Colors.green : Colors.red,
                    fontSize: 10,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26).withOpacity(0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                onPressed: () => _handleZoom(1.2, Offset(MediaQuery.of(context).size.width / 2, 200)),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Container(
                width: 24,
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
                onPressed: () => _handleZoom(0.8, Offset(MediaQuery.of(context).size.width / 2, 200)),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26).withOpacity(0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.white70, size: 18),
            onPressed: _resetView,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildIndicatorToggle('MA20', _showMA20, Colors.yellow, 
              () => setState(() => _showMA20 = !_showMA20)),
          const SizedBox(width: 8),
          _buildIndicatorToggle('MA50', _showMA50, Colors.cyan,
              () => setState(() => _showMA50 = !_showMA50)),
          const SizedBox(width: 8),
          _buildIndicatorToggle('VOL', _showVolume, Colors.blue,
              () => setState(() => _showVolume = !_showVolume)),
          
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

  Widget _buildIndicatorToggle(String label, bool active, Color color, VoidCallback onTap) {
    final isDark = _themeController.isDarkMode;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? color : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
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
      // Generate new data for demonstration
      _candles = RealisticDataGenerator.generateCandlestickData(
        symbol: _currentSymbol,
        count: 500,
      );
      _initializeChart();
    });
  }

  void _resetView() {
    setState(() {
      _zoomLevel = 1.0;
      _visibleCandleCount = 100;
      _scrollOffset = (_candles.length - _visibleCandleCount).toDouble().clamp(0, _candles.length.toDouble());
      _updatePriceRange();
    });
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
    if (candles.isEmpty || size.width <= 0 || size.height <= 0) return;

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
      ..color = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.1)
      ..strokeWidth = 1;

    // Horizontal lines
    for (int i = 1; i < 10; i++) {
      final y = size.height * (i / 10);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    final visibleWidth = candleWidth * zoomLevel * visibleCandleCount;
    final candleSpacing = candleWidth * zoomLevel;
    
    for (int i = 0; i < visibleCandleCount; i += 10) {
      final x = i * candleSpacing;
      if (x < size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  void _drawCandles(Canvas canvas, Size size) {
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0 || candles.isEmpty) return;
    
    final startIdx = scrollOffset.floor().clamp(0, candles.length - 1);
    final endIdx = (startIdx + visibleCandleCount).clamp(0, candles.length);
    
    for (int i = startIdx; i < endIdx && i < candles.length; i++) {
      final candle = candles[i];
      final x = (i - scrollOffset) * candleWidth * zoomLevel;
      
      if (x < -candleWidth * zoomLevel || x > size.width) continue;
      
      final open = candle['open']!;
      final high = candle['high']!;
      final low = candle['low']!;
      final close = candle['close']!;
      
      final isGreen = close >= open;
      
      // Calculate Y positions
      final yOpen = size.height * (1 - (open - minPrice) / priceRange);
      final yClose = size.height * (1 - (close - minPrice) / priceRange);
      final yHigh = size.height * (1 - (high - minPrice) / priceRange);
      final yLow = size.height * (1 - (low - minPrice) / priceRange);
      
      // Draw wick
      final wickPaint = Paint()
        ..color = isGreen ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8)
        ..strokeWidth = 1;
      
      canvas.drawLine(
        Offset(x + candleWidth * zoomLevel / 2, yHigh),
        Offset(x + candleWidth * zoomLevel / 2, yLow),
        wickPaint,
      );
      
      // Draw body
      final bodyPaint = Paint()
        ..color = isGreen ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;
      
      final bodyTop = yOpen < yClose ? yOpen : yClose;
      final bodyHeight = (yClose - yOpen).abs();
      
      // Ensure minimum body height for visibility
      final minBodyHeight = 0.5;
      final actualBodyHeight = bodyHeight < minBodyHeight ? minBodyHeight : bodyHeight;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, bodyTop, candleWidth * zoomLevel - 2, actualBodyHeight),
          const Radius.circular(1),
        ),
        bodyPaint,
      );
    }
  }

  void _drawMA(Canvas canvas, Size size, int period, Color color) {
    if (candles.length < period) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    bool firstPoint = true;
    
    final startIdx = scrollOffset.floor();
    final endIdx = (startIdx + visibleCandleCount + 1).clamp(0, candles.length);
    
    for (int i = startIdx; i < endIdx && i < candles.length; i++) {
      if (i < period - 1) continue;
      
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j]['close']!;
      }
      final ma = sum / period;
      
      final x = (i - scrollOffset) * candleWidth * zoomLevel;
      final y = size.height * (1 - (ma - minPrice) / (maxPrice - minPrice));
      
      if (x < -candleWidth || x > size.width) continue;
      
      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    if (crosshairPosition == null) return;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Vertical line
    canvas.drawLine(
      Offset(crosshairPosition!.dx, 0),
      Offset(crosshairPosition!.dx, size.height),
      paint,
    );
    
    // Horizontal line
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
    if (priceRange == 0) return;
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i <= 10; i++) {
      final price = maxPrice - (priceRange * i / 10);
      final y = size.height * (i / 10);
      
      textPainter.text = TextSpan(
        text: price.toStringAsFixed(5),
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(4, y - textPainter.height / 2),
      );
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
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final startIdx = scrollOffset.floor();
    final candleSpacing = candleWidth * zoomLevel;
    
    // Draw time labels every N candles based on zoom
    final labelInterval = (10 / zoomLevel).round().clamp(1, 50);
    
    for (int i = 0; i < visibleCandleCount; i += labelInterval) {
      final candleIdx = startIdx + i;
      if (candleIdx >= candles.length) break;
      
      // Calculate x position to align with candle center
      final x = i * candleSpacing + (candleWidth * zoomLevel) / 2;
      if (x > size.width) break;
      
      // Generate realistic time based on timeframe
      final timeLabel = _generateTimeLabel(candleIdx, candles.length);
      
      textPainter.text = TextSpan(
        text: timeLabel,
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      
      // Center the text under the candle
      final textX = x - textPainter.width / 2;
      if (textX > 0 && textX + textPainter.width < size.width) {
        textPainter.paint(
          canvas,
          Offset(textX, 4),
        );
      }
    }
  }

  String _generateTimeLabel(int candleIdx, int totalCandles) {
    final progress = candleIdx / totalCandles;
    
    switch (timeframe) {
      case 'M1':
        // 1-minute intervals: 09:30, 09:31, 09:32...
        final totalMinutes = (progress * 6.5 * 60).floor(); // 6.5 hours of trading
        final hour = 9 + (totalMinutes ~/ 60);
        final minute = totalMinutes % 60;
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        
      case 'M5':
        // 5-minute intervals: 09:30, 09:35, 09:40...
        final totalMinutes = (progress * 6.5 * 60).floor();
        final hour = 9 + (totalMinutes ~/ 60);
        final minute = (totalMinutes % 60) ~/ 5 * 5; // Round to nearest 5
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        
      case 'M15':
        // 15-minute intervals: 09:30, 09:45, 10:00...
        final totalMinutes = (progress * 6.5 * 60).floor();
        final hour = 9 + (totalMinutes ~/ 60);
        final minute = (totalMinutes % 60) ~/ 15 * 15; // Round to nearest 15
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        
      case 'M30':
        // 30-minute intervals: 09:30, 10:00, 10:30...
        final totalMinutes = (progress * 6.5 * 60).floor();
        final hour = 9 + (totalMinutes ~/ 60);
        final minute = (totalMinutes % 60) ~/ 30 * 30; // Round to nearest 30
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        
      case 'H1':
        // 1-hour intervals: 09:00, 10:00, 11:00...
        final hour = 9 + (progress * 6.5).floor();
        return '${hour.toString().padLeft(2, '0')}:00';
        
      case 'H4':
        // 4-hour intervals: 09:00, 13:00, 17:00...
        final hour = 9 + (progress * 6.5).floor() * 4;
        return '${hour.toString().padLeft(2, '0')}:00';
        
      case 'D1':
        // Daily intervals: 01/01, 02/01, 03/01...
        final day = 1 + (progress * 30).floor();
        return '${day.toString().padLeft(2, '0')}/01';
        
      default:
        // Default to hour format
        final hour = 9 + (progress * 6.5).floor();
        return '${hour.toString().padLeft(2, '0')}:00';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}