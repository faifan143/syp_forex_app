import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config_service.dart';

class SimulationApiService {
  static String get baseUrl => ApiConfigService.forexApiBaseUrl;

  /// Get M1 simulation data for a specific currency
  static Future<SimulationData?> getSimulationData(String currency) async {
    final url = '$baseUrl/simulation/$currency';
    print('🌐 [API_CALL] GET $url');
    print('🌐 [API_CALL] Using API Host: ${ApiConfigService.forexApiHost}:${ApiConfigService.forexApiPort}');
    print('🌐 [API_CALL] Headers: {"Content-Type": "application/json"}');
    print('🌐 [API_CALL] Timeout: 30 seconds');
    
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();
      
      print('🌐 [API_RESPONSE] Status Code: ${response.statusCode}');
      print('🌐 [API_RESPONSE] Response Time: ${stopwatch.elapsedMilliseconds}ms');
      print('🌐 [API_RESPONSE] Content Length: ${response.body.length} bytes');
      print('🌐 [API_RESPONSE] Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('🌐 [API_RESPONSE] Parsing JSON response...');
        final data = json.decode(response.body);
        print('🌐 [API_RESPONSE] JSON parsed successfully');
        print('🌐 [API_RESPONSE] Response keys: ${data.keys.toList()}');
        
        if (data.containsKey('data')) {
          print('🌐 [API_RESPONSE] Data array length: ${(data['data'] as List).length}');
          if ((data['data'] as List).isNotEmpty) {
            print('🌐 [API_RESPONSE] First data record: ${(data['data'] as List).first}');
            print('🌐 [API_RESPONSE] Last data record: ${(data['data'] as List).last}');
          }
        }
        
        print('🌐 [API_RESPONSE] Creating SimulationData object...');
        final simulationData = SimulationData.fromJson(data);
        print('🌐 [API_RESPONSE] SimulationData created successfully');
        print('🌐 [API_RESPONSE] Currency: ${simulationData.currency}');
        print('🌐 [API_RESPONSE] Pair: ${simulationData.pair}');
        print('🌐 [API_RESPONSE] Total Records: ${simulationData.totalRecords}');
        print('🌐 [API_RESPONSE] Data Length: ${simulationData.data.length}');
        print('🌐 [API_RESPONSE] Columns: ${simulationData.columns}');
        
        return simulationData;
      } else {
        print('❌ [API_ERROR] HTTP ${response.statusCode}');
        print('❌ [API_ERROR] Response Body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ [API_EXCEPTION] Error fetching simulation data for $currency: $e');
      print('❌ [API_EXCEPTION] Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Get list of available simulation data
  static Future<List<String>?> getAvailableCurrencies() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/simulation'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<String>.from(data['available_currencies'] ?? []);
        }
      }
      print('Error fetching available currencies: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Exception fetching available currencies: $e');
      return null;
    }
  }

  /// Convert simulation data to chart candles format
  static List<Map<String, double>> convertToChartCandles(
    SimulationData simulationData,
  ) {
    print('🔄 [CHART_CONVERSION] Starting conversion of simulation data to chart candles');
    print('🔄 [CHART_CONVERSION] Input data length: ${simulationData.data.length}');
    
    final candles = <Map<String, double>>[];
    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < simulationData.data.length; i++) {
      final record = simulationData.data[i];
      try {
        // Parse datetime to get timestamp
        final datetime = DateTime.parse(record['Datetime'] as String);
        final timestamp = datetime.millisecondsSinceEpoch / 1000.0;
        
        final open = (record['open'] as num).toDouble();
        final high = (record['high'] as num).toDouble();
        final low = (record['low'] as num).toDouble();
        final close = (record['close'] as num).toDouble();
        final volume = (record['volume'] as num).toDouble();
        
        if (i < 3 || i >= simulationData.data.length - 3) {
          print('🔄 [CHART_CONVERSION] Record $i: $datetime -> O:$open H:$high L:$low C:$close V:$volume');
        }

        candles.add({
          'timestamp': timestamp,
          'open': open,
          'high': high,
          'low': low,
          'close': close,
          'volume': volume,
        });
        successCount++;
      } catch (e, stackTrace) {
        print('❌ [CHART_CONVERSION] Error parsing simulation record $i: $e');
        print('❌ [CHART_CONVERSION] Record data: $record');
        print('❌ [CHART_CONVERSION] Stack trace: $stackTrace');
        errorCount++;
        continue;
      }
    }
    
    print('✅ [CHART_CONVERSION] Conversion completed:');
    print('✅ [CHART_CONVERSION] - Successfully converted: $successCount records');
    print('✅ [CHART_CONVERSION] - Errors: $errorCount records');
    print('✅ [CHART_CONVERSION] - Total candles: ${candles.length}');
    
    if (candles.isNotEmpty) {
      print('✅ [CHART_CONVERSION] First candle: ${candles.first}');
      print('✅ [CHART_CONVERSION] Last candle: ${candles.last}');
    }

    return candles;
  }

  /// Get current price from simulation data (most recent close price)
  static double? getCurrentPrice(SimulationData simulationData) {
    print('💰 [CURRENT_PRICE] Getting current price from simulation data');
    print('💰 [CURRENT_PRICE] Data length: ${simulationData.data.length}');
    
    if (simulationData.data.isEmpty) {
      print('❌ [CURRENT_PRICE] No data available');
      return null;
    }

    try {
      final lastRecord = simulationData.data.last;
      final price = (lastRecord['close'] as num).toDouble();
      print('✅ [CURRENT_PRICE] Current price: $price');
      print('✅ [CURRENT_PRICE] Last record: $lastRecord');
      return price;
    } catch (e, stackTrace) {
      print('❌ [CURRENT_PRICE] Error getting current price: $e');
      print('❌ [CURRENT_PRICE] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get price at specific time from simulation data
  static double? getPriceAtTime(
    SimulationData simulationData,
    DateTime targetTime,
  ) {
    try {
      // Find the closest record to the target time
      Map<String, dynamic>? closestRecord;
      Duration? closestDifference;

      for (final record in simulationData.data) {
        final recordTime = DateTime.parse(record['Datetime'] as String);
        final difference = (recordTime.difference(targetTime)).abs();

        if (closestDifference == null || difference < closestDifference) {
          closestDifference = difference;
          closestRecord = record;
        }
      }

      if (closestRecord != null) {
        return (closestRecord['close'] as num).toDouble();
      }

      return null;
    } catch (e) {
      print('Error getting price at time: $e');
      return null;
    }
  }
}

class SimulationData {
  final String currency;
  final String pair;
  final String filename;
  final int totalRecords;
  final List<String> columns;
  final List<Map<String, dynamic>> data;
  final SimulationMetadata metadata;

  SimulationData({
    required this.currency,
    required this.pair,
    required this.filename,
    required this.totalRecords,
    required this.columns,
    required this.data,
    required this.metadata,
  });

  factory SimulationData.fromJson(Map<String, dynamic> json) {
    return SimulationData(
      currency: json['currency'] ?? '',
      pair: json['pair'] ?? '',
      filename: json['filename'] ?? '',
      totalRecords: json['total_records'] ?? 0,
      columns: List<String>.from(json['columns'] ?? []),
      data: List<Map<String, dynamic>>.from(json['data'] ?? []),
      metadata: SimulationMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'pair': pair,
      'filename': filename,
      'total_records': totalRecords,
      'columns': columns,
      'data': data,
      'metadata': metadata.toJson(),
    };
  }
}

class SimulationMetadata {
  final String? firstTimestamp;
  final String? lastTimestamp;
  final int fileSizeBytes;
  final String dataType;
  final String timeframe;

  SimulationMetadata({
    this.firstTimestamp,
    this.lastTimestamp,
    required this.fileSizeBytes,
    required this.dataType,
    required this.timeframe,
  });

  factory SimulationMetadata.fromJson(Map<String, dynamic> json) {
    return SimulationMetadata(
      firstTimestamp: json['first_timestamp'],
      lastTimestamp: json['last_timestamp'],
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      dataType: json['data_type'] ?? '',
      timeframe: json['timeframe'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_timestamp': firstTimestamp,
      'last_timestamp': lastTimestamp,
      'file_size_bytes': fileSizeBytes,
      'data_type': dataType,
      'timeframe': timeframe,
    };
  }
}
