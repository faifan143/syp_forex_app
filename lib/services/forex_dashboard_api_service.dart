import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/forex_models.dart';
import 'api_config_service.dart';

class ForexDashboardApiService {
  
  /// Get comprehensive forex dashboard with 7-day predictions
  Future<ForexDashboardResponse> getForexDashboard({int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final url = ApiConfigService.getForexApiUrl('/forex/dashboard');
        print('🌐 [DASHBOARD_API] Fetching dashboard from $url (Attempt ${attempt + 1}/${retries + 1})');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 60));
        
        print('📊 [DASHBOARD_API] Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ [DASHBOARD_API] Dashboard data received successfully');
          
          return ForexDashboardResponse.fromJson(data);
        } else {
          throw HttpException('Failed to load dashboard: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ [DASHBOARD_API] Error on attempt ${attempt + 1}: $e');
        
        if (attempt == retries) {
          rethrow;
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
    }
    
    throw HttpException('Failed to load dashboard after ${retries + 1} attempts');
  }
}
