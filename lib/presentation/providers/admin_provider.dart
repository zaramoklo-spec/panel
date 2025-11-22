import 'package:flutter/foundation.dart';
import '../../data/models/admin.dart';
import '../../data/models/activity_log.dart';
import '../../data/models/device.dart';
import '../../data/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository = AdminRepository();

  List<Admin> _admins = [];
  List<ActivityLog> _activities = [];
  Map<String, dynamic>? _activityStats;
  List<Device> _adminDevices = [];
  int _totalAdminDevices = 0;

  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalActivities = 0;
  int _pageSize = 100;

  List<Admin> get admins => _admins;
  List<ActivityLog> get activities => _activities;
  Map<String, dynamic>? get activityStats => _activityStats;
  List<Device> get adminDevices => _adminDevices;
  int get totalAdminDevices => _totalAdminDevices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalActivities => _totalActivities;
  int get pageSize => _pageSize;

  Future<void> fetchAdmins() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _admins = await _adminRepository.getAdmins();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching admins list';
      notifyListeners();
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
      _isLoading = true;
      notifyListeners();

      final success = await _adminRepository.createAdmin(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        telegram2faChatId: telegram2faChatId,
        telegramBots: telegramBots,
        expiresAt: expiresAt,
      );

      _isLoading = false;

      if (success) {
        await fetchAdmins();
      }

      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error creating admin';
      notifyListeners();
      return false;
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
      _isLoading = true;
      notifyListeners();

      final success = await _adminRepository.updateAdmin(
        username,
        email: email,
        fullName: fullName,
        role: role,
        isActive: isActive,
        telegram2faChatId: telegram2faChatId,
        telegramBots: telegramBots,
        expiresAt: expiresAt,
      );

      _isLoading = false;

      if (success) {
        await fetchAdmins();
      }

      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error updating admin';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAdmin(String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _adminRepository.deleteAdmin(username);

      _isLoading = false;

      if (success) {
        await fetchAdmins();
      }

      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error deleting admin';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchActivities({
    String? adminUsername,
    String? activityType,
    int? page,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final skip = ((page ?? 1) - 1) * _pageSize;

      final result = await _adminRepository.getActivities(
        adminUsername: adminUsername,
        activityType: activityType,
        skip: skip,
        limit: _pageSize,
      );

      _activities = result['activities'] as List<ActivityLog>;
      _totalActivities = result['total'] as int;
      _currentPage = result['page'] as int;
      _pageSize = result['page_size'] as int;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching activity logs';
      notifyListeners();
    }
  }

  Future<void> fetchActivityStats({String? adminUsername}) async {
    try {
      _activityStats = await _adminRepository.getActivityStats(
        adminUsername: adminUsername,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching activity stats';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetActivities() {
    _activities = [];
    _currentPage = 1;
    _totalActivities = 0;
    notifyListeners();
  }
  
  // Fetch devices for specific admin (Super Admin only)
  Future<void> fetchAdminDevices(
    String adminUsername, {
    int skip = 0,
    int limit = 100,
    String? appType,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _adminRepository.getAdminDevices(
        adminUsername,
        skip: skip,
        limit: limit,
        appType: appType,
      );

      _adminDevices = result['devices'];
      _totalAdminDevices = result['total'];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching admin devices';
      notifyListeners();
    }
  }
}