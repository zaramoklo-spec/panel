import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'PanelDB',
      publicKey: 'PanelPublicKey',
    ),
  );
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) async {
    if (kIsWeb) {

      await _prefs?.setString('access_token', token);
    } else {

      await _secureStorage.write(key: 'access_token', value: token);
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return _prefs?.getString('access_token');
    } else {
      return await _secureStorage.read(key: 'access_token');
    }
  }

  Future<void> deleteToken() async {
    if (kIsWeb) {
      await _prefs?.remove('access_token');
    } else {
      await _secureStorage.delete(key: 'access_token');
    }
  }

  Future<void> saveAdminInfo(Map<String, dynamic> admin) async {
    final data = jsonEncode(admin);
    if (kIsWeb) {
      await _prefs?.setString('admin_info', data);
    } else {
      await _secureStorage.write(key: 'admin_info', value: data);
    }
  }

  Future<Map<String, dynamic>?> getAdminInfo() async {
    String? data;
    if (kIsWeb) {
      data = _prefs?.getString('admin_info');
    } else {
      data = await _secureStorage.read(key: 'admin_info');
    }
    
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  Future<void> deleteAdminInfo() async {
    if (kIsWeb) {
      await _prefs?.remove('admin_info');
    } else {
      await _secureStorage.delete(key: 'admin_info');
    }
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString('theme_mode', mode);
  }

  String getThemeMode() {
    return _prefs?.getString('theme_mode') ?? 'system';
  }

  Future<void> setLanguage(String lang) async {
    await _prefs?.setString('language', lang);
  }

  String getLanguage() {
    return _prefs?.getString('language') ?? 'en';
  }

  Future<void> saveSmsFontSize(double fontSize) async {
    await _prefs?.setDouble('sms_font_size', fontSize);
  }

  double getSmsFontSize() {
    return _prefs?.getDouble('sms_font_size') ?? 11.0;
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      await _prefs?.clear();
    } else {
      await _secureStorage.deleteAll();
      await _prefs?.clear();
    }
  }
}