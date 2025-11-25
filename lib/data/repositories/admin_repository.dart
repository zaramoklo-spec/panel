import '../models/admin.dart';
import '../models/activity_log.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class AdminRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAdminDevices(
    String adminUsername, {
    int skip = 0,
    int limit = 100,
    String? appType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (appType != null && appType.isNotEmpty) {
        queryParams['app_type'] = appType;
      }
      
      final response = await _apiService.get(
        ApiConstants.adminDevices(adminUsername),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List devices = response.data['devices'];
        final int total = response.data['total'] ?? devices.length;

        return {
          'devices': devices.map((json) => Device.fromJson(json)).toList(),
          'total': total,
          'hasMore': (skip + devices.length) < total,
        };
      }
      return {
        'devices': <Device>[],
        'total': 0,
        'hasMore': false,
      };
    } catch (e) {
      throw Exception('Error fetching admin devices');
    }
  }

  Future<bool> createAdmin({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? telegram2faChatId,
    List<TelegramBot>? telegramBots,
    DateTime? expiresAt,
  }) async {
    try {
      final data = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      };

      if (telegram2faChatId != null && telegram2faChatId.isNotEmpty) {
        data['telegram_2fa_chat_id'] = telegram2faChatId;
      }

      if (telegramBots != null && telegramBots.isNotEmpty) {
        data['telegram_bots'] = telegramBots.map((bot) => bot.toJson()).toList();
      }

      if (expiresAt != null) {
        data['expires_at'] = expiresAt.toIso8601String();
      }

      final response = await _apiService.post(
        ApiConstants.adminCreate,
        data: data,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error creating admin');
    }
  }

  Future<List<Admin>> getAdmins() async {
    try {
      final response = await _apiService.get(ApiConstants.adminList);

      if (response.statusCode == 200) {
        final List admins = response.data['admins'];
        return admins.map((json) => Admin.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching admins list');
    }
  }

  Future<bool> updateAdmin(
    String username, {
    String? email,
    String? fullName,
    String? role,
    bool? isActive,
    String? telegram2faChatId,
    List<TelegramBot>? telegramBots,
    DateTime? expiresAt,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (email != null) data['email'] = email;
      if (fullName != null) data['full_name'] = fullName;
      if (role != null) data['role'] = role;
      if (isActive != null) data['is_active'] = isActive;

      if (telegram2faChatId != null) {
        data['telegram_2fa_chat_id'] = telegram2faChatId;
      }
      
      if (telegramBots != null) {
        data['telegram_bots'] = telegramBots.map((bot) => bot.toJson()).toList();
      }

      if (expiresAt != null) {
        data['expires_at'] = expiresAt.toIso8601String();
      }

      final response = await _apiService.put(
        ApiConstants.adminUpdate(username),
        data: data,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating admin');
    }
  }

  Future<bool> deleteAdmin(String username) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.adminDelete(username),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting admin');
    }
  }

  Future<Map<String, dynamic>> getActivities({
    String? adminUsername,
    String? activityType,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };

      if (adminUsername != null) {
        queryParams['admin_username'] = adminUsername;
      }

      if (activityType != null) {
        queryParams['activity_type'] = activityType;
      }

      final response = await _apiService.get(
        ApiConstants.adminActivities,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List activities = response.data['activities'];
        return {
          'activities': activities.map((json) => ActivityLog.fromJson(json)).toList(),
          'total': response.data['total'],
          'page': response.data['page'],
          'page_size': response.data['page_size'],
        };
      }
      return {'activities': [], 'total': 0, 'page': 1, 'page_size': limit};
    } catch (e) {
      throw Exception('Error fetching activity logs');
    }
  }

  Future<Map<String, dynamic>?> getActivityStats({String? adminUsername}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (adminUsername != null) {
        queryParams['admin_username'] = adminUsername;
      }

      final response = await _apiService.get(
        ApiConstants.adminStats,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching activity stats');
    }
  }
}