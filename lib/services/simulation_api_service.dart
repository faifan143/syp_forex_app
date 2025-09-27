import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config_service.dart';

class SimulationApiService {
  static String get baseUrl => ApiConfigService.forexApiBaseUrl;

  /// Get M1 simulation data for a specific currency
  static Future<SimulationData?> getSimulationData(String currency) async {
    final url = '$baseUrl/simulation/$currency';
    
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();
      
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('data')) {
        }
        
        final simulationData = SimulationData.fromJson(data);
        
        return simulationData;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
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
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert simulation data to chart candles format
  static List<Map<String, double>> convertToChartCandles(
    SimulationData simulationData,
  ) {
    
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
        errorCount++;
        continue;
      }
    }
    
    
    if (candles.isNotEmpty) {
    }

    return candles;
  }

  /// Get current price from simulation data (most recent close price)
  static double? getCurrentPrice(SimulationData simulationData) {
    
    if (simulationData.data.isEmpty) {
      return null;
    }

    try {
      final lastRecord = simulationData.data.last;
      final price = (lastRecord['close'] as num).toDouble();
      return price;
    } catch (e, stackTrace) {
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
