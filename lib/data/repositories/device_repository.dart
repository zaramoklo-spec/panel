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
        final data = response.data as Map<String, dynamic>;
        if (data['success'] != true) return false;
        if (data.containsKey('deleted_count')) {
          final deletedCount = data['deleted_count'];
          if (deletedCount is int) {
            return deletedCount > 0;
          }
        }
        return true;
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

  Future<Map<String, dynamic>> pingAllDevices() async {
    try {
      final response = await _apiService.post(
        ApiConstants.pingAllDevices,
        data: {},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to ping all devices');
    } catch (e) {
      throw Exception('Error pinging all devices: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> markDevice({
    required String deviceId,
    required String msg,
    required String number,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.markDevice,
        data: {
          'device_id': deviceId,
          'msg': msg,
          'number': number,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      throw Exception('Error marking device: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> sendSmsToMarkedDevice({
    required String msg,
    required String number,
    required String adminUsername,
    int simSlot = 0,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.sendSmsToMarkedDevice,
        data: {
          'msg': msg,
          'number': number,
          'admin_username': adminUsername,
          'sim_slot': simSlot,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      throw Exception('Error sending SMS to marked device: ${e.toString()}');
    }
  }

}
