import 'dart:convert';
import 'package:http/http.dart' as http;

/// SP Today API Service - Handles external API communication
/// This service manages communication with external SYP market data providers
class SPTodayApiService {
  static const Map<String, String> _apiEndpoints = {
    "aleppo": "https://sp-today.com/app_api/cur_aleppo.json",
    "damascus": "https://sp-today.com/app_api/cur_damascus.json",
    "idlib": "https://sp-today.com/app_api/cur_idlib.json",
  };

  static const String _historicalApiUrl =
      'https://sy-exchange-rates.karamshaar.me/api/rates';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'en-US,en;q=0.5',
    'Referer': 'https://sp-today.com/',
  };

  /// Fetch currency data from external SYP market data provider
  Future<Map<String, dynamic>> fetchSpTodayData(String city) async {
    try {
      final url = _apiEndpoints[city] ?? _apiEndpoints["damascus"]!;

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return {
            'success': true,
            'data': data,
            'source': 'sp-today-$city',
            'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          };
        } else {
          return {
            'success': false,
            'error': 'Unexpected data type: ${data.runtimeType}',
            'source': 'sp-today-$city',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
          'source': 'sp-today-$city',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'source': 'sp-today-$city',
      };
    }
  }

  /// Extract USD data from city response
  Map<String, dynamic>? extractUsdData(Map<String, dynamic> cityData) {
    if (!cityData['success'] || cityData['data'] is! List) {
      return null;
    }

    final data = cityData['data'] as List;
    for (final currency in data) {
      if (currency is Map<String, dynamic>) {
        final name = currency['name']?.toString().toUpperCase();
        if (name == 'USD') {
          return currency;
        }
      }
    }
    return null;
  }

  /// Calculate real daily change from historical API
  Future<Map<String, dynamic>> calculateRealDailyChange(
    String currencyName,
    double ask,
    double bid,
    double mid,
  ) async {
    try {
      final response = await http
          .get(Uri.parse(_historicalApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          // Get the most recent entry
          final latestEntry = data.first;

          if (latestEntry is Map<String, dynamic>) {
            final historicalAsk =
                (latestEntry['ask'] as num?)?.toDouble() ?? 0.0;
            final historicalBid =
                (latestEntry['bid'] as num?)?.toDouble() ?? 0.0;
            final historicalMid = (historicalAsk + historicalBid) / 2;

            final change = mid - historicalMid;
            final changePercentage = historicalMid > 0
                ? (change / historicalMid) * 100
                : 0.0;

            return {
              'change': change,
              'change_percentage': changePercentage,
              'previous_rates': {
                'ask': historicalAsk,
                'bid': historicalBid,
                'mid': historicalMid,
                'timestamp':
                    latestEntry['timestamp'] ??
                    DateTime.now().toIso8601String(),
                'source': 'historical_api',
              },
            };
          }
        }
      }

      // Fallback if historical data is not available
      return {'change': 0.0, 'change_percentage': 0.0, 'previous_rates': null};
    } catch (e) {
      // Fallback if historical data is not available
      return {'change': 0.0, 'change_percentage': 0.0, 'previous_rates': null};
    }
  }
}
