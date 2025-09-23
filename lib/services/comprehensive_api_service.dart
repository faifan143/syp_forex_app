import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/comprehensive_models.dart';
import 'api_config_service.dart';
import 'lstm_prediction_engine.dart';

class ComprehensiveApiService {
  /// Get comprehensive SYP data from port 5002
  Future<ComprehensiveResponse> getComprehensiveData({int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final url = ApiConfigService.getSypApiUrl('/api/comprehensive');

        // Make actual HTTP request to the SYP API server
        final response = await _makeHttpRequest(url, attempt);

        // Parse the JSON response from the server
        final jsonData = _parseHttpResponse(response);

        // Convert server response to our model
        final serverResponse = _convertServerResponse(jsonData);

        // Generate local Damascus predictions using REAL server data
        final localDamascusPrediction = await _generateLocalDamascusPrediction(
          serverResponse.cityRates['damascus'],
        );

        // Return server data but with local Damascus predictions
        return ComprehensiveResponse(
          damascusPrediction:
              localDamascusPrediction, // Use local prediction with real data
          currencies: serverResponse.currencies, // Use server data
          cityRates: serverResponse.cityRates, // Use server data
          ohlcv: serverResponse.ohlcv, // Use server data
        );
      } catch (e) {
        if (attempt == retries) {
          rethrow;
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
    }

    throw HttpException(
      'Failed to load comprehensive data after ${retries + 1} attempts',
    );
  }

  /// Make HTTP request to SYP API server
  Future<http.Response> _makeHttpRequest(String url, int attempt) async {
    try {
      // API call delay
      final delay = 500 + (DateTime.now().millisecondsSinceEpoch % 800);
      await Future.delayed(Duration(milliseconds: delay));

      // Make the actual HTTP request
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'SYPApp/1.0.0',
              'X-API-Version': '2.1.3',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response;
      } else {
        throw HttpException(
          'SYP API server returned error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // If it's a connection error, provide a more specific message
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        throw HttpException(
          'SYP API server is not running. Please check the server configuration in settings.',
        );
      }

      rethrow;
    }
  }

  /// Parse HTTP response from SYP API server
  Map<String, dynamic> _parseHttpResponse(http.Response response) {
    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (!jsonData.containsKey('damascus_prediction') ||
          !jsonData.containsKey('currencies') ||
          !jsonData.containsKey('city_rates') ||
          !jsonData.containsKey('ohlcv')) {
        throw FormatException('Invalid response format from SYP API server');
      }

      return jsonData;
    } catch (e) {
      throw FormatException('Failed to parse SYP API response: $e');
    }
  }

  /// Generate local Damascus prediction using our superior algorithm with REAL data
  Future<DamascusPrediction> _generateLocalDamascusPrediction(
    CityRates? damascusRates,
  ) async {
    // Use real Damascus data from server if available
    if (damascusRates != null) {
     

      return LSTMPredictionEngine.generateDamascusPrediction(
        damascusRates.ask,
        damascusRates.bid,
      );
    } else {
      // If no Damascus data available, throw error instead of using fallback
      throw Exception(
        'LSTM Error: No Damascus data available from server. '
        'Cannot generate prediction without real market data.',
      );
    }
  }

  /// Convert server response to ComprehensiveResponse model
  ComprehensiveResponse _convertServerResponse(Map<String, dynamic> jsonData) {
    try {
      // Parse damascus prediction
      final damascusPredictionData =
          jsonData['damascus_prediction'] as Map<String, dynamic>;
      final damascusPrediction = DamascusPrediction(
        ask: (damascusPredictionData['ask'] as num).toDouble(),
        bid: (damascusPredictionData['bid'] as num).toDouble(),
      );

      // Parse currencies
      final currenciesData = jsonData['currencies'] as List;
      final currencies = currenciesData.map((currencyJson) {
        return CurrencyData(
          name: currencyJson['name'] as String,
          ask: (currencyJson['ask'] as num).toDouble(),
          bid: (currencyJson['bid'] as num).toDouble(),
          mid: (currencyJson['mid'] as num).toDouble(),
          change: (currencyJson['change'] as num).toDouble(),
          changePercentage: (currencyJson['change_percentage'] as num)
              .toDouble(),
          previousRates: currencyJson['previous_rates'] != null
              ? PreviousRates.fromJson(currencyJson['previous_rates'])
              : null,
          dataSource:
              currencyJson['data_source'] as String? ?? 'syp_api_server',
        );
      }).toList();

      // Parse city rates
      final cityRatesData = jsonData['city_rates'] as Map<String, dynamic>;
      final cityRates = <String, CityRates>{};
      cityRatesData.forEach((city, rateData) {
        cityRates[city] = CityRates(
          ask: (rateData['ask'] as num).toDouble(),
          bid: (rateData['bid'] as num).toDouble(),
        );
      });

      // Parse OHLCV data
      final ohlcvData = jsonData['ohlcv'] as Map<String, dynamic>;
      final ohlcv = OHLCVData(
        open: (ohlcvData['open'] as num).toDouble(),
        high: (ohlcvData['high'] as num).toDouble(),
        low: (ohlcvData['low'] as num).toDouble(),
        close: (ohlcvData['close'] as num).toDouble(),
        volume: (ohlcvData['volume'] as num).toDouble(),
      );

      return ComprehensiveResponse(
        damascusPrediction: damascusPrediction,
        currencies: currencies,
        cityRates: cityRates,
        ohlcv: ohlcv,
      );
    } catch (e) {
      throw FormatException('Failed to convert server response: $e');
    }
  }
}
