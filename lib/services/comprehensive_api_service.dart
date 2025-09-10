import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/comprehensive_models.dart';
import 'api_config_service.dart';

class ComprehensiveApiService {
  
  /// Get comprehensive SYP data from port 5002
  Future<ComprehensiveResponse> getComprehensiveData({int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final url = ApiConfigService.getSypApiUrl('/api/comprehensive');
        print('🌐 [COMPREHENSIVE_API] Fetching comprehensive data from $url (Attempt ${attempt + 1}/${retries + 1})');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 60));
        
        print('📊 [COMPREHENSIVE_API] Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ [COMPREHENSIVE_API] Comprehensive data received successfully');
          
          return ComprehensiveResponse.fromJson(data);
        } else {
          throw HttpException('Failed to load comprehensive data: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ [COMPREHENSIVE_API] Error on attempt ${attempt + 1}: $e');
        
        if (attempt == retries) {
          rethrow;
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
    }
    
    throw HttpException('Failed to load comprehensive data after ${retries + 1} attempts');
  }
}
