import 'dart:async';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../core/constants/api_constants.dart';
import 'storage_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final StorageService _storage = StorageService();
  
  // Stream ???? session expired events
  final _sessionExpiredController = StreamController<bool>.broadcast();
  Stream<bool> get sessionExpiredStream => _sessionExpiredController.stream;
  
  // Callback for session expired (???? backward compatibility)
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
          // Handle 401 Unauthorized & 403 Forbidden (Session Expired)
          final statusCode = error.response?.statusCode;
          
          if (statusCode == 401 || statusCode == 403) {
            // Check if it's not the login endpoint
            final isLoginEndpoint = error.requestOptions.path.contains('/auth/login') ||
                error.requestOptions.path.contains('/auth/verify-2fa');
            
            if (!isLoginEndpoint) {
              // Session expired due to single session control or token invalid
              await _storage.clearAll();
              
              // Notify via stream
              _sessionExpiredController.add(true);
              
              // Notify via callback (???? backward compatibility)
              if (onSessionExpired != null) {
                onSessionExpired!();
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
