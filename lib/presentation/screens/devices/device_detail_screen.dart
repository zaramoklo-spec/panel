import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/services/websocket_service.dart';
import '../../../presentation/providers/device_provider.dart';
import '../../../presentation/providers/multi_device_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../core/utils/popup_helper.dart';
import 'tabs/device_info_tab.dart';
import 'tabs/device_sms_tab.dart';
import 'tabs/device_contacts_tab.dart';
import 'tabs/device_calls_tab.dart';
import 'tabs/device_logs_tab.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device? device;
  final String? deviceId;

  const DeviceDetailScreen({
    super.key,
    this.device,
    this.deviceId,
  }) : assert(device != null || deviceId != null, 'Either device or deviceId must be provided');

  factory DeviceDetailScreen.fromDeviceId(String deviceId) {
    return DeviceDetailScreen(deviceId: deviceId);
  }

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Device? _currentDevice;
  final DeviceRepository _repository = DeviceRepository();
  bool _isRefreshing = false;
  bool _isPinging = false;
  bool _isLoadingDevice = false;
  bool _isDeleting = false;
  bool _isMarking = false;
  bool _isDeviceMarked = false;
  int _refreshKey = 0;
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(minutes: 1);
  static const Duration _webRefreshInterval = Duration(minutes: 3);
  static const Duration _popupRefreshInterval = Duration(seconds: 5);
  StreamSubscription? _deviceUpdateSubscription;
  StreamSubscription? _websocketSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    if (widget.device != null) {
      _currentDevice = widget.device;
      _startAutoRefresh();
      _listenToDeviceUpdates();
      _listenToWebSocket(); // ✅ Add WebSocket listener for direct device
      _checkMarkedStatus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshDevice(showSnackbar: false, silent: true, headless: true);
      });
    } else if (widget.deviceId != null) {
      _isLoadingDevice = true;
      _loadDeviceFromId(widget.deviceId!);
    }
  }

  Future<void> _loadDeviceFromId(String deviceId) async {
    try {
      final deviceProvider = context.read<DeviceProvider>();
      Device? device = deviceProvider.getDeviceById(deviceId);
      
      if (device == null) {
        final updatedDevice = await _repository.getDevice(deviceId);
        if (updatedDevice != null) {
          device = updatedDevice;
        } else {
          throw Exception('Device not found');
        }
      }
      
      if (mounted) {
        setState(() {
          _currentDevice = device;
          _isLoadingDevice = false;
        });
        _startAutoRefresh();
        _listenToDeviceUpdates();
        _listenToWebSocket();
        _checkMarkedStatus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshDevice(showSnackbar: false, silent: true, headless: true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDevice = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to load device: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadDeviceFromId(deviceId),
            ),
          ),
        );
      }
    }
  }
  
  void _listenToDeviceUpdates() {
    if (_currentDevice == null) return;

    // On web, skip periodic header updates to reduce UI load
    if (kIsWeb) return;
    
    _deviceUpdateSubscription?.cancel();
    _deviceUpdateSubscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (!mounted || _currentDevice == null) {
        _deviceUpdateSubscription?.cancel();
        return;
      }
      
      try {
        final deviceProvider = context.read<DeviceProvider>();
        final updatedDevice = deviceProvider.getDeviceById(_currentDevice!.deviceId);
        
        if (updatedDevice != null) {
          // Check for meaningful changes
          final hasStatusChange = updatedDevice.isOnline != _currentDevice!.isOnline ||
              updatedDevice.status != _currentDevice!.status ||
              updatedDevice.batteryLevel != _currentDevice!.batteryLevel ||
              updatedDevice.isUninstalled != _currentDevice!.isUninstalled;
          
          final hasDataChange = updatedDevice.stats.totalSms != _currentDevice!.stats.totalSms ||
              updatedDevice.stats.totalContacts != _currentDevice!.stats.totalContacts;
          
          if (hasStatusChange || hasDataChange) {
            // 🔍 LOG: Device update from provider
            print('🔄 [PROVIDER] Device update detected');
            print('🔄 [PROVIDER] hasStatusChange: $hasStatusChange, hasDataChange: $hasDataChange');
            print('🔄 [PROVIDER] BEFORE - lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');
            print('🔄 [PROVIDER] OLD last_ping: ${_currentDevice!.lastPing}');
            print('🔄 [PROVIDER] NEW last_ping: ${updatedDevice.lastPing}');
            
            // Headless update: update device silently
            _currentDevice = updatedDevice;
            
            print('🔄 [PROVIDER] AFTER - lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');
            
            // Only trigger setState for critical UI changes (status, battery)
            // Data changes (SMS count, contacts) don't need immediate UI update
            if (hasStatusChange && mounted) {
              setState(() {
                _refreshKey++;
              });
            } else if (hasDataChange) {
              // Just update refresh key for tab rebuilds without full setState
              _refreshKey++;
            }
          }
        }
      } catch (e) {
        if (mounted) {
          _deviceUpdateSubscription?.cancel();
        }
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    
    Duration refreshInterval;
    if (kIsWeb) {
      if (isInPopupWindow()) {
        refreshInterval = _popupRefreshInterval;
      } else {
        refreshInterval = _webRefreshInterval;
      }
    } else {
      refreshInterval = _autoRefreshInterval;
    }
    
    _autoRefreshTimer = Timer.periodic(refreshInterval, (_) {
      if (!mounted) {
        _autoRefreshTimer?.cancel();
        return;
      }
      _refreshDevice(showSnackbar: false, silent: true, headless: true);
    });
  }

  Future<void> _refreshDevice({bool showSnackbar = true, bool silent = false, bool headless = false}) async {
    if (_isRefreshing || _currentDevice == null) return;

    // Headless mode: update device silently without UI blocking
    if (headless) {
      try {
        final deviceProvider = context.read<DeviceProvider>();
        // Use headless refresh from provider to update device in background
        await deviceProvider.refreshSingleDevice(_currentDevice!.deviceId);
        
        // Get updated device from provider without setState
        final updatedDevice = deviceProvider.getDeviceById(_currentDevice!.deviceId);
        if (updatedDevice != null && mounted) {
          // Update current device silently without triggering rebuild
          _currentDevice = updatedDevice;
        }
      } catch (e) {
        // Silently fail in headless mode
        debugPrint('Headless refresh failed: $e');
      }
      return;
    }

    if (!silent) {
      setState(() => _isRefreshing = true);
    }

    try {
      final updatedDevice = await _repository.getDevice(_currentDevice!.deviceId);
      if (updatedDevice != null && mounted) {
        setState(() {
          _currentDevice = updatedDevice;
          _isRefreshing = false;
          if (!silent) {
            _refreshKey++;
          }
        });
        
        if (mounted && showSnackbar && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Device information updated',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        setState(() => _isRefreshing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Failed to refresh device: ${e.toString()}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePingDevice() async {
    if (_isPinging || _currentDevice == null || _currentDevice!.isUninstalledStatus) return;

    // 🔍 LOG: Before ping
    print('🔵 [PING] BEFORE PING - Device: ${_currentDevice!.deviceId}');
    print('🔵 [PING] last_ping: ${_currentDevice!.lastPing}');
    print('🔵 [PING] last_online_update: ${_currentDevice!.lastOnlineUpdate}');
    print('🔵 [PING] lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');

    setState(() => _isPinging = true);

    // 🔍 LOG: After setState
    print('🟡 [PING] AFTER setState - lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');

    final deviceProvider = context.read<DeviceProvider>();

    try {
      print('🟠 [PING] Sending command...');
      final success = await deviceProvider.sendCommand(
        _currentDevice!.deviceId,
        'ping',
        parameters: {'type': 'firebase'},
      );
      print('🟠 [PING] Command sent - success: $success');

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isPinging = false);
        
        // 🔍 LOG: Before refresh
        print('🟣 [PING] BEFORE REFRESH - lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');
        
        await _refreshDevice();
        
        // 🔍 LOG: After refresh
        print('🟢 [PING] AFTER REFRESH - Device: ${_currentDevice!.deviceId}');
        print('🟢 [PING] last_ping: ${_currentDevice!.lastPing}');
        print('🟢 [PING] last_online_update: ${_currentDevice!.lastOnlineUpdate}');
        print('🟢 [PING] lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    success 
                        ? 'Ping command sent successfully!'
                        : 'Failed to send ping command',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPinging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Error sending ping: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteDevice() async {
    if (_currentDevice == null || _isDeleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete device?'),
          content: const Text('Device will be removed from the list but history stays.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final deviceProvider = context.read<DeviceProvider>();

    final success = await deviceProvider.deleteDevice(_currentDevice!.deviceId);

    if (!mounted) return;

    setState(() => _isDeleting = false);

    if (success) {
      final multiDeviceProvider = Provider.of<MultiDeviceProvider>(context, listen: false);
      multiDeviceProvider.closeDevice(_currentDevice!.deviceId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Device deleted',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Failed to delete device',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  bool _isInMultiDeviceView() {
    try {
      final multiDeviceProvider = Provider.of<MultiDeviceProvider>(context, listen: false);
      final deviceId = _currentDevice?.deviceId ?? widget.deviceId;
      if (deviceId != null) {
        return multiDeviceProvider.openDevices.any((d) => d.deviceId == deviceId);
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _deviceUpdateSubscription?.cancel();
    _websocketSubscription?.cancel();
    
    // Unsubscribe from WebSocket when leaving
    if (_currentDevice != null) {
      try {
        final webSocketService = WebSocketService();
        webSocketService.unsubscribeFromDevice(_currentDevice!.deviceId);
      } catch (e) {
        // Silent error handling
      }
    }
    
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkMarkedStatus() async {
    if (_currentDevice == null) return;
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentAdmin?.isSuperAdmin != true) {
      return;
    }

    try {
      final result = await _repository.getMarkedDeviceInfo();
      if (mounted && result != null) {
        setState(() {
          _isDeviceMarked = result['success'] == true && 
                           result['device_id'] == _currentDevice?.deviceId;
        });
      }
    } catch (e) {
      // Silent error handling
      if (mounted) {
        setState(() {
          _isDeviceMarked = false;
        });
      }
    }
  }

  Future<void> _handleMarkDevice() async {
    if (_isMarking || _currentDevice == null) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentAdmin?.isSuperAdmin != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only super admin can mark devices'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // If already marked, unmark directly (no SIM selection needed)
    if (_isDeviceMarked) {
      setState(() => _isMarking = true);

      try {
        // For unmark, we still need to call mark-device endpoint (it toggles)
        // Use the current device's sim_slot (we can use 0 as default since it's a toggle)
        final result = await _repository.markDevice(_currentDevice!.deviceId, simSlot: 0);
        
        if (mounted) {
          setState(() => _isMarking = false);
          
          if (result != null && result['success'] == true) {
            final isMarked = result['is_marked'] == true;
            setState(() => _isDeviceMarked = isMarked);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      isMarked ? Icons.check_circle_rounded : Icons.bookmark_remove_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMarked 
                          ? 'Device marked successfully'
                          : 'Device unmarked successfully',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: isMarked ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to unmark device'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isMarking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
      return;
    }

    // If not marked, show SIM selection dialog first
    final selectedSimSlot = await _showSimSelectionDialog();
    if (selectedSimSlot == null) return; // User cancelled

    setState(() => _isMarking = true);

    try {
      final result = await _repository.markDevice(_currentDevice!.deviceId, simSlot: selectedSimSlot);
      
      if (mounted) {
        setState(() => _isMarking = false);
        
        if (result != null && result['success'] == true) {
          final isMarked = result['is_marked'] == true;
          setState(() => _isDeviceMarked = isMarked);
          
          final simInfo = _currentDevice!.simInfo;
          String simLabel = 'SIM ${selectedSimSlot + 1}';
          if (simInfo != null && simInfo.isNotEmpty) {
            final sim = simInfo.firstWhere(
              (s) => s.simSlot == selectedSimSlot,
              orElse: () => simInfo.first,
            );
            if (sim.phoneNumber.isNotEmpty) {
              simLabel = 'SIM ${selectedSimSlot + 1} (${sim.phoneNumber})';
            } else if (sim.carrierName.isNotEmpty) {
              simLabel = 'SIM ${selectedSimSlot + 1} (${sim.carrierName})';
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Device marked successfully with $simLabel',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to mark device'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMarking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<int?> _showSimSelectionDialog() async {
    if (_currentDevice == null) return null;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int? selectedSimSlot; // Variable that persists in closure
    
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
              borderRadius: BorderRadius.circular(12.8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(14.4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.8),
                      topRight: Radius.circular(12.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6.4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6.4),
                        ),
                        child: const Icon(
                          Icons.sim_card_rounded,
                          color: Colors.white,
                          size: 14.4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select SIM Card',
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.all(4.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content and Footer in StatefulBuilder
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(14.4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select SIM card for marking:',
                                style: TextStyle(
                                  fontSize: 10.4,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              if (_currentDevice!.simInfo != null && _currentDevice!.simInfo!.isNotEmpty)
                                ..._currentDevice!.simInfo!.map((sim) {
                                  final isSelected = selectedSimSlot == sim.simSlot;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            selectedSimSlot = sim.simSlot;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF8B5CF6).withOpacity(0.1)
                                                : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF8B5CF6)
                                                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: (isSelected ? const Color(0xFF8B5CF6) : Colors.grey).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.sim_card_rounded,
                                                  size: 14,
                                                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'SIM ${sim.simSlot + 1}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: isSelected
                                                            ? const Color(0xFF8B5CF6)
                                                            : (isDark ? Colors.white : Colors.black87),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      sim.carrierName.isNotEmpty ? sim.carrierName : 'Unknown carrier',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        color: isDark ? Colors.white60 : Colors.black54,
                                                      ),
                                                    ),
                                                    if (sim.phoneNumber.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        sim.phoneNumber,
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 16,
                                                  color: Color(0xFF8B5CF6),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                })
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSimSlotButton(
                                        0,
                                        'SIM 1',
                                        selectedSimSlot == 0,
                                        isDark,
                                        () => setDialogState(() => selectedSimSlot = 0),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildSimSlotButton(
                                        1,
                                        'SIM 2',
                                        selectedSimSlot == 1,
                                        isDark,
                                        () => setDialogState(() => selectedSimSlot = 1),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        // Footer
                        Container(
                          padding: const EdgeInsets.all(14.4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12.8),
                              bottomRight: Radius.circular(12.8),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 9.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7.68),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                    ),
                                    borderRadius: BorderRadius.circular(7.68),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: selectedSimSlot != null
                                        ? () => Navigator.pop(context, selectedSimSlot)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 9.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7.68),
                                      ),
                                      disabledBackgroundColor: Colors.transparent,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bookmark_rounded, size: 12.8),
                                        SizedBox(width: 6),
                                        Text(
                                          'Mark Device',
                                          style: TextStyle(
                                            fontSize: 11.2,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    return result;
  }

  Widget _buildSimSlotButton(int slot, String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                )
              : null,
          color: !isSelected
              ? (isDark ? const Color(0xFF0F1419) : Colors.white)
              : null,
          borderRadius: BorderRadius.circular(6.4),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sim_card_rounded,
              size: 11.2,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _listenToWebSocket() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentAdmin?.isSuperAdmin != true) return;
    if (_currentDevice == null) return;
    
    try {
      final webSocketService = WebSocketService();
      _websocketSubscription?.cancel();
      
      // Subscribe to this device for real-time updates
      webSocketService.subscribeToDevice(_currentDevice!.deviceId);
      
      // Listen for device updates (status, battery, online/offline changes)
      webSocketService.deviceStream.listen((event) {
        if (!mounted || _currentDevice == null) return;
        
        try {
          if (event['device_id'] == _currentDevice!.deviceId) {
            // 🔍 LOG: WebSocket event received
            print('📡 [WS] Event received for device: ${event['device_id']}');
            print('📡 [WS] is_online: ${event['is_online']}');
            print('📡 [WS] status: ${event['status']}');
            print('📡 [WS] last_ping: ${event['last_ping']}');
            print('📡 [WS] last_online_update: ${event['last_online_update']}');
            print('📡 [WS] BEFORE UPDATE - lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');
            
            // Update device status in real-time
            setState(() {
              if (event['is_online'] != null) {
                _currentDevice = Device.fromJson({
                  ..._currentDevice!.toJson(),
                  'is_online': event['is_online'],
                  'status': event['status'] ?? _currentDevice!.status,
                  'battery_level': event['battery_level'] ?? _currentDevice!.batteryLevel,
                  // ❌ DON'T use DateTime.now() as fallback! Keep existing timestamps if not provided
                  'last_ping': event['last_ping'] ?? _currentDevice!.lastPing.toIso8601String(),
                  'last_online_update': event['last_online_update'] ?? _currentDevice!.lastOnlineUpdate?.toIso8601String(),
                  'updated_at': event['updated_at'] ?? _currentDevice!.updatedAt?.toIso8601String(),
                });
                
                print('📡 [WS] AFTER UPDATE - lastPingTimeAgo: ${_currentDevice!.lastPingTimeAgo}');
              }
            });
          }
        } catch (e) {
          print('❌ [WS] Error: $e');
          // Silent error handling
        }
      });
      
      // Listen for device_marked and device_unmarked events
      _websocketSubscription = webSocketService.deviceMarkedStream.listen((event) {
        if (!mounted || _currentDevice == null) return;
        
        try {
          if (event['device_id'] == _currentDevice!.deviceId) {
            final type = event['type'];
            setState(() {
              _isDeviceMarked = type == 'device_marked';
            });
          }
        } catch (e) {
          // Silent error handling
        }
      });
      
      // Listen for SMS sent via mark events
      webSocketService.smsSentViaMarkStream.listen((event) {
        if (!mounted) return;
        
        try {
          final deviceId = event['device_id'];
          final adminUsername = event['admin_username'];
          final currentAdmin = authProvider.currentAdmin?.username;
          
          // Only show notification if it's for the current admin
          if (currentAdmin != null && adminUsername == currentAdmin) {
            final deviceName = event['device_name'] ?? deviceId;
            final simSlot = event['sim_slot'] ?? 0;
            
            // Show SnackBar with SMS sent notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SMS send request created for device $deviceName via SIM ${simSlot + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          // Silent error handling
        }
      });
    } catch (e) {
      // Silent error handling
    }
  }

  // SMS confirmation dialog removed - SMS is sent directly now

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingDevice) {
      return Scaffold(
        resizeToAvoidBottomInset: !kIsWeb,
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (kIsWeb && isInPopupWindow()) {
                closePopupWindow();
              } else if (defaultTargetPlatform == TargetPlatform.windows && _isInMultiDeviceView()) {
                final deviceId = _currentDevice?.deviceId ?? widget.deviceId;
                if (deviceId != null) {
                  final multiDeviceProvider = Provider.of<MultiDeviceProvider>(context, listen: false);
                  multiDeviceProvider.closeDevice(deviceId);
                } else {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: false,
              pinned: false,
              snap: false,
              expandedHeight: 200,
              toolbarHeight: 56,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.all(6.4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(7.68),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if (kIsWeb && isInPopupWindow()) {
                      closePopupWindow();
                    } else if (defaultTargetPlatform == TargetPlatform.windows && _isInMultiDeviceView()) {
                      final deviceId = _currentDevice?.deviceId ?? widget.deviceId;
                      if (deviceId != null) {
                        final multiDeviceProvider = Provider.of<MultiDeviceProvider>(context, listen: false);
                        multiDeviceProvider.closeDevice(deviceId);
                      } else {
                        Navigator.pop(context);
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 6.4, top: 6.4, bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (_isPinging || _isRefreshing || _currentDevice?.isUninstalledStatus == true) ? null : _handlePingDevice,
                      borderRadius: BorderRadius.circular(10.24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF14B8A6).withOpacity(isDark ? 0.2 : 0.15),
                              const Color(0xFF0D9488).withOpacity(isDark ? 0.15 : 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.24),
                          border: Border.all(
                            color: const Color(0xFF14B8A6).withOpacity(0.3),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF14B8A6).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isPinging
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
                                ),
                              )
                            : Icon(
                                Icons.wifi_tethering_rounded,
                                size: 18,
                                color: const Color(0xFF14B8A6),
                              ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 6.4, top: 6.4, bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (_isRefreshing || _isPinging) ? null : _refreshDevice,
                      borderRadius: BorderRadius.circular(10.24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10.24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: _isRefreshing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                      ),
                    ),
                  ),
                ),
                if (context.read<AuthProvider>().currentAdmin?.isSuperAdmin == true)
                  Container(
                    margin: const EdgeInsets.only(right: 6.4, top: 6.4, bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (_isMarking || _isRefreshing || _isPinging) ? null : _handleMarkDevice,
                        borderRadius: BorderRadius.circular(10.24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDeviceMarked
                                  ? [
                                      const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.15),
                                      const Color(0xFF059669).withOpacity(isDark ? 0.15 : 0.1),
                                    ]
                                  : [
                                      const Color(0xFF8B5CF6).withOpacity(isDark ? 0.2 : 0.15),
                                      const Color(0xFF7C3AED).withOpacity(isDark ? 0.15 : 0.1),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(10.24),
                            border: Border.all(
                              color: (_isDeviceMarked ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)).withOpacity(0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isDeviceMarked ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isMarking
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                                  ),
                                )
                              : Icon(
                                  _isDeviceMarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  size: 18,
                                  color: _isDeviceMarked ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                                ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(right: 9.6, top: 6.4, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 6.4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentDevice!.isUninstalledStatus
                          ? [
                        const Color(0xFFEF4444).withOpacity(0.2),
                        const Color(0xFFDC2626).withOpacity(0.2)
                      ]
                          : (_currentDevice!.isOnline
                              ? [
                            const Color(0xFF10B981).withOpacity(0.2),
                            const Color(0xFF059669).withOpacity(0.2)
                          ]
                              : [
                            const Color(0xFFEF4444).withOpacity(0.2),
                            const Color(0xFFDC2626).withOpacity(0.2)
                          ]),
                    ),
                    borderRadius: BorderRadius.circular(10.24),
                    border: Border.all(
                      color: _currentDevice!.isUninstalledStatus
                          ? const Color(0xFFEF4444).withOpacity(0.4)
                          : (_currentDevice!.isOnline
                              ? const Color(0xFF10B981).withOpacity(0.4)
                              : const Color(0xFFEF4444).withOpacity(0.4)),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.4,
                        height: 6.4,
                        decoration: BoxDecoration(
                          color: _currentDevice!.isUninstalledStatus
                              ? const Color(0xFFEF4444)
                              : (_currentDevice!.isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_currentDevice!.isUninstalledStatus
                                  ? const Color(0xFFEF4444)
                                  : (_currentDevice!.isOnline
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444)))
                                  .withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentDevice!.isUninstalledStatus
                            ? 'Uninstalled'
                            : (_currentDevice!.isOnline ? 'Online' : 'Offline'),
                        style: TextStyle(
                          color: _currentDevice!.isUninstalledStatus
                              ? const Color(0xFFEF4444)
                              : (_currentDevice!.isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444)),
                          fontWeight: FontWeight.w700,
                          fontSize: 10.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 60, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        const Color(0xFF6366F1).withOpacity(0.25),
                        const Color(0xFF8B5CF6).withOpacity(0.15),
                      ]
                          : [
                        const Color(0xFF6366F1).withOpacity(0.12),
                        const Color(0xFF8B5CF6).withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(13.6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(14.4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.5),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smartphone_rounded,
                              color: Colors.white,
                              size: 27.2,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentDevice!.model,
                                  style: TextStyle(
                                    fontSize: 20.8,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currentDevice!.manufacturer,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_currentDevice!.isOnline 
                                  ? const Color(0xFF10B981) 
                                  : const Color(0xFFEF4444)).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _currentDevice!.isOnline 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: _currentDevice!.isOnline 
                                          ? const Color(0xFF10B981) 
                                          : const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentDevice!.lastPingTimeAgo,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _currentDevice!.isOnline 
                                            ? const Color(0xFF10B981) 
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentDevice!.lastPingFormatted,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark 
                                        ? Colors.white.withOpacity(0.6) 
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(11.52),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                size: 13.6,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _currentDevice!.deviceId,
                                style: TextStyle(
                                  fontSize: 10.4,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(7.68),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.white54
                      : const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Info', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('SMS', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Contacts', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Calls', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Logs', style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
                isDark: isDark,
              ),
            ),
          ];
        },
        body: Column(
          children: [
            if (_currentDevice?.isUninstalledStatus == true)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade300,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Uninstalled',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade200,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This device was marked as uninstalled ${_currentDevice!.uninstalledTimeAgo}. The app was uninstalled or data was cleared.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  DeviceInfoTab(key: ValueKey('${_currentDevice!.deviceId}_info_$_refreshKey'), device: _currentDevice!),
                  DeviceSmsTab(key: ValueKey('${_currentDevice!.deviceId}_sms_$_refreshKey'), device: _currentDevice!),
                  DeviceContactsTab(key: ValueKey('${_currentDevice!.deviceId}_contacts_$_refreshKey'), device: _currentDevice!),
                  DeviceCallsTab(key: ValueKey('${_currentDevice!.deviceId}_calls_$_refreshKey'), device: _currentDevice!),
                  DeviceLogsTab(key: ValueKey('${_currentDevice!.deviceId}_logs_$_refreshKey'), device: _currentDevice!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _StickyTabBarDelegate({required this.tabBar, required this.isDark});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(3.2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10.24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}