import 'dart:convert';

import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class ToolsRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> lookupLeak({
    required String query,
    int limit = 100,
    String lang = 'en',
  }) async {
    try {
      final Response response = await _apiService.post(
        ApiConstants.leakLookup,
        data: {
          'query': query,
          'limit': limit,
          'lang': lang,
          'response_type': 'json',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
        return {
          'raw': jsonEncode(response.data),
        };
      }
      throw Exception('Unexpected response from server');
    } catch (e) {
      rethrow;
    }
  }
}


