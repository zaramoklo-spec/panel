import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../presentation/providers/device_provider.dart';
import '../../../presentation/providers/multi_device_provider.dart';
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
  int _refreshKey = 0;
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(minutes: 1);
  static const Duration _webRefreshInterval = Duration(minutes: 3);
  static const Duration _popupRefreshInterval = Duration(seconds: 5);
  StreamSubscription? _deviceUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    if (widget.device != null) {
      _currentDevice = widget.device;
      _startAutoRefresh();
      _listenToDeviceUpdates();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshDevice(showSnackbar: false, silent: true);
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshDevice(showSnackbar: false, silent: true);
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
          final isUpdated = updatedDevice.isOnline != _currentDevice!.isOnline ||
              updatedDevice.status != _currentDevice!.status ||
              updatedDevice.batteryLevel != _currentDevice!.batteryLevel;
          
          if (isUpdated && mounted) {
            setState(() {
              _currentDevice = updatedDevice;
              _refreshKey++;
            });
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
      _refreshDevice(showSnackbar: false, silent: true);
    });
  }

  Future<void> _refreshDevice({bool showSnackbar = true, bool silent = false}) async {
    if (_isRefreshing || _currentDevice == null) return;

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
    if (_isPinging || _currentDevice == null) return;

    setState(() => _isPinging = true);

    final deviceProvider = context.read<DeviceProvider>();

    try {
      final success = await deviceProvider.sendCommand(
        _currentDevice!.deviceId,
        'ping',
        parameters: {'type': 'firebase'},
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isPinging = false);
        await _refreshDevice();
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
  void dispose() {
    _autoRefreshTimer?.cancel();
    _deviceUpdateSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingDevice) {
      return Scaffold(
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
                      onTap: (_isPinging || _isRefreshing) ? null : _handlePingDevice,
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
                Container(
                  margin: const EdgeInsets.only(right: 9.6, top: 6.4, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 6.4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentDevice!.isOnline
                          ? [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF059669).withOpacity(0.2)
                      ]
                          : [
                        const Color(0xFFEF4444).withOpacity(0.2),
                        const Color(0xFFDC2626).withOpacity(0.2)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.24),
                    border: Border.all(
                      color: _currentDevice!.isOnline
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFFEF4444).withOpacity(0.4),
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
                          color: _currentDevice!.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_currentDevice!.isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                                  .withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentDevice!.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: _currentDevice!.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
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
        body: TabBarView(
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