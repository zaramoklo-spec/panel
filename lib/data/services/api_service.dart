import 'dart:async';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import 'storage_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final StorageService _storage = StorageService();
  
  final _sessionExpiredController = StreamController<bool>.broadcast();
  Stream<bool> get sessionExpiredStream => _sessionExpiredController.stream;
  
  Function()? onSessionExpired;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          
          if (statusCode == 401 || statusCode == 403) {
            final isLoginEndpoint = error.requestOptions.path.contains('/auth/login') ||
                error.requestOptions.path.contains('/auth/verify-2fa');
            
            if (!isLoginEndpoint) {
              final headers = error.response?.headers;
              final data = error.response?.data;
              
              final sessionExpiredHeader = headers?.value('x-session-expired')?.toLowerCase() == 'true';
              final sessionExpiredInBody = data is Map && (data['session_expired'] == true || data['redirect_to_login'] == true);
              
              if (sessionExpiredHeader || sessionExpiredInBody) {
                debugPrint('Session expired detected - Status: $statusCode, Header: $sessionExpiredHeader, Body: $sessionExpiredInBody');
                debugPrint('Endpoint: ${error.requestOptions.path}');
                debugPrint('Clearing storage and redirecting to login...');
                
                await _storage.clearAll();
                
                debugPrint('Storage cleared. Emitting session expired event...');
                _sessionExpiredController.add(true);
                
                if (onSessionExpired != null) {
                  onSessionExpired!();
                }
                
                debugPrint('Session expired handled - user will be redirected to login');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
