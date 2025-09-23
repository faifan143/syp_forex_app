import '../models/forex_models.dart';
import 'forex_api_service.dart';

/// Forex Dashboard API Service - Handles communication with the Forex API server
/// This service provides real-time forex data and predictions from our backend service
/// running on port 5001. It manages API requests, error handling, and response parsing.
class ForexDashboardApiService {
  // Forex API service for handling the actual API calls
  final ForexApiService _forexApiService = ForexApiService();

  /// Get comprehensive forex dashboard with 7-day predictions
  /// This method calls the Forex API server and returns formatted dashboard data
  Future<ForexDashboardResponse> getForexDashboard({int retries = 2}) async {
    // Delegate to the forex API service
    // This handles the HTTP communication with the Forex API server
    return await _forexApiService.getForexDashboard(retries: retries);
  }

  /// Test connection to the Forex API server
  Future<bool> testConnection() async {
    return await _forexApiService.testConnection();
  }

  /// Get API statistics
  Map<String, dynamic> getApiStats() {
    return _forexApiService.getApiStats();
  }
}
