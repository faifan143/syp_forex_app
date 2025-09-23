import '../models/comprehensive_models.dart';
import 'lstm_prediction_engine.dart';

/// Comprehensive Data Processor - Handles SYP market data formatting
/// This service formats comprehensive market data from the SYP API server
class ComprehensiveDataProcessor {
  /// Format comprehensive data from SYP API server
  /// This method handles the data formatting and response structure
  Future<ComprehensiveResponse> formatComprehensiveData({
    double? damascusAsk,
    double? damascusBid,
  }) async {
    try {
      // Generate ONLY local Damascus predictions using our superior algorithm
      // All other data (currencies, city rates, OHLCV) comes from server
      DamascusPrediction? damascusPrediction;

      if (damascusAsk != null && damascusBid != null) {
        damascusPrediction = _generateLocalDamascusPrediction(
          damascusAsk,
          damascusBid,
        );
      }

      // Return only the Damascus prediction - other data comes from server
      return ComprehensiveResponse(
        damascusPrediction:
            damascusPrediction ?? DamascusPrediction(ask: 0, bid: 0),
        currencies: [], // Will be filled by server data
        cityRates: {}, // Will be filled by server data
        ohlcv: OHLCVData(
          open: 0,
          high: 0,
          low: 0,
          close: 0,
          volume: 0,
        ), // Will be filled by server data
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Generate local Damascus prediction using our superior algorithm with REAL data
  DamascusPrediction _generateLocalDamascusPrediction(double ask, double bid) {
    
    return LSTMPredictionEngine.generateDamascusPrediction(ask, bid);
  }
}
