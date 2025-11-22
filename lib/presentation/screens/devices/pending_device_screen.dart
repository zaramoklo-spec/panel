import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/device.dart';
import '../../../core/utils/date_utils.dart' as utils;
import '../../providers/device_provider.dart';
import 'device_detail_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PendingDeviceScreen extends StatelessWidget {
  final Device device;

  const PendingDeviceScreen({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 9.6, top: 6.4, bottom: 8),
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
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _checkStatus(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 60,
              20,
              32,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  const Color(0xFFF59E0B).withOpacity(0.2),
                  const Color(0xFFD97706).withOpacity(0.1),
                ]
                    : [
                  const Color(0xFFF59E0B).withOpacity(0.1),
                  const Color(0xFFD97706).withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(19.2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 38.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Awaiting Permissions',
                  style: TextStyle(
                    fontSize: 22.4,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This device needs permissions to be activated',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                      borderRadius: BorderRadius.circular(15.36),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(7.68),
                              ),
                              child: const Icon(
                                Icons.smartphone_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Device Information',
                              style: TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _InfoRow(
                          icon: Icons.devices_rounded,
                          label: 'Model',
                          value: device.model,
                          isDark: isDark,
                        ),
                        _InfoRow(
                          icon: Icons.business_rounded,
                          label: 'Manufacturer',
                          value: device.manufacturer,
                          isDark: isDark,
                        ),
                        _InfoRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'Device ID',
                          value: device.deviceId,
                          isDark: isDark,
                        ),
                        _InfoRow(
                          icon: Icons.android_rounded,
                          label: 'Android Version',
                          value: device.osVersion,
                          isDark: isDark,
                        ),
                        _InfoRow(
                          icon: Icons.circle_rounded,
                          label: 'Status',
                          value: device.isOnline ? 'Online' : 'Offline',
                          valueColor: device.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          isDark: isDark,
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Registered',
                          value:
                          utils.DateUtils.formatForDisplay(device.registeredAt),
                          isDark: isDark,
                        ),
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Last Connection',
                          value: utils.DateUtils.timeAgoEn(device.lastPing),
                          isDark: isDark,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                      borderRadius: BorderRadius.circular(15.36),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(7.68),
                              ),
                              child: const Icon(
                                Icons.list_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Setup Instructions',
                              style: TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _InstructionStep(
                          number: 1,
                          title: 'Open the App',
                          description: 'Launch the app on your device',
                        ),
                        const SizedBox(height: 16),
                        const _InstructionStep(
                          number: 2,
                          title: 'Grant SMS Permission',
                          description: 'Allow the app to access messages',
                        ),
                        const SizedBox(height: 16),
                        const _InstructionStep(
                          number: 3,
                          title: 'Grant Contacts Permission',
                          description: 'Allow the app to access contacts',
                        ),
                        const SizedBox(height: 16),
                        const _InstructionStep(
                          number: 4,
                          title: 'Check Status',
                          description: 'Tap the refresh button to verify',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12.8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _checkStatus(context),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 17.6,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Check Status',
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkStatus(BuildContext context) async {
    final deviceProvider = context.read<DeviceProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final updatedDevice = await deviceProvider.getDevice(device.deviceId);

    if (context.mounted) {
      Navigator.pop(context);

      if (updatedDevice != null) {
        if (updatedDevice.isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(device: updatedDevice),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 12),
                  Text(
                    'Device activated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.68)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Still awaiting permissions'),
              backgroundColor: const Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.68)),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error checking device status'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.68)),
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14.4,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w700,
                color: valueColor ??
                    (isDark ? Colors.white : const Color(0xFF1E293B)),
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

class _InstructionStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final bool isLast;

  const _InstructionStep({
    required this.number,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.8,
          height: 28.8,
          decoration: BoxDecoration(
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
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10.4,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF64748B),
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}