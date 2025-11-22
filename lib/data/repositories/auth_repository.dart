import 'package:dio/dio.dart';
import '../models/admin.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Step 1: Login - returns temp_token or access_token (if 2FA disabled)
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if 2FA is enabled
        if (data['temp_token'] != null) {
          // 2FA enabled - return temp token and message
          return {
            'requires_2fa': true,
            'temp_token': data['temp_token'],
            'expires_in': data['expires_in'],
            'message': data['message'],
          };
        } else {
          // 2FA disabled - direct login
          await _storageService.saveToken(data['access_token']);
          await _storageService.saveAdminInfo(data['admin']);

          return {
            'requires_2fa': false,
            'admin': Admin.fromJson(data['admin']),
          };
        }
      }
      return {'requires_2fa': false};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Incorrect username or password');
      }
      throw Exception('Error connecting to server');
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }

  // Step 2: Verify OTP and get final access token
  Future<Admin?> verify2FA(
    String username,
    String otpCode,
    String tempToken, {
    String? fcmToken,
  }) async {
    try {
      final data = {
        'username': username,
        'otp_code': otpCode,
        'temp_token': tempToken,
      };
      
      if (fcmToken != null && fcmToken.isNotEmpty) {
        data['fcm_token'] = fcmToken;
      }
      
      final response = await _apiService.post(
        ApiConstants.verify2fa,
        data: data,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save final access token
        await _storageService.saveToken(data['access_token']);
        await _storageService.saveAdminInfo(data['admin']);

        return Admin.fromJson(data['admin']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid or expired OTP code');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid OTP code');
      }
      throw Exception('Error verifying OTP');
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }

  Future<Admin?> getCurrentAdmin() async {
    try {
      final response = await _apiService.get(ApiConstants.me);

      if (response.statusCode == 200) {
        final admin = Admin.fromJson(response.data);
        await _storageService.saveAdminInfo(response.data);
        return admin;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post(ApiConstants.logout);
    } catch (e) {

    } finally {
      await _storageService.clearAll();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null;
  }

  Future<Admin?> getStoredAdmin() async {
    final adminData = await _storageService.getAdminInfo();
    if (adminData != null) {
      return Admin.fromJson(adminData);
    }
    return null;
  }
}