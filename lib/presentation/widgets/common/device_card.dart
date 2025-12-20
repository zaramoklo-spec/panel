import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:ui';
import '../../../data/models/device.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/date_utils.dart' as utils;
import '../../../core/utils/popup_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/multi_device_provider.dart';
import '../../providers/device_provider.dart';
import '../../../data/services/storage_service.dart';

class DeviceCard extends StatefulWidget {
  final Device device;
  final VoidCallback onTap;
  final VoidCallback? onPing;
  final bool isPinging;
  final VoidCallback? onNote;
  final bool isNoting;
  final bool isNew;
  final VoidCallback? onDelete;
  final bool isDeleting;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    this.onPing,
    this.isPinging = false,
    this.onNote,
    this.isNoting = false,
    this.isNew = false,
    this.onDelete,
    this.isDeleting = false,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
  }

  Color _getNoteColor() {
    if (widget.device.notePriority == null || widget.device.notePriority == 'none') {
      return Colors.transparent;
    }
    
    switch (widget.device.notePriority) {
      case 'highbalance':
        return Colors.green.shade500;
      case 'lowbalance':
        return Colors.red.shade500;
      default:
        return Colors.transparent;
    }
  }

  Widget _buildNotePreview(bool isDark) {
    final Color accentColor = _getNoteColor();
    final Color borderColor = accentColor == Colors.transparent
        ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08))
        : accentColor.withOpacity(0.4);
    final Color backgroundColor = accentColor == Colors.transparent
        ? (isDark ? const Color(0xFF1E2435) : const Color(0xFFF4F3FF))
        : accentColor.withOpacity(isDark ? 0.25 : 0.14);
    final Color titleColor = accentColor == Colors.transparent
        ? (isDark ? Colors.white : Colors.deepPurple.shade600)
        : accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_rounded,
                size: 14,
                color: titleColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.device.notePriorityLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                widget.device.noteTimeAgo,
                style: TextStyle(
                  fontSize: 8,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.device.noteMessage ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(11.2),
              decoration: BoxDecoration(
                gradient: widget.isNew
                    ? LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF10B981).withOpacity(0.2),
                                const Color(0xFF059669).withOpacity(0.15),
                              ]
                            : [
                                const Color(0xFF10B981).withOpacity(0.15),
                                const Color(0xFF059669).withOpacity(0.1),
                              ],
                      )
                    : null,
                color: widget.isNew
                    ? null
                    : (widget.device.isPending
                        ? (isDark ? const Color(0xFF2D2416) : Colors.orange.shade50)
                        : (isDark ? const Color(0xFF252B3D) : Colors.white)),
                borderRadius: BorderRadius.circular(10.24),
                border: Border.all(
                  color: widget.isNew
                      ? const Color(0xFF10B981).withOpacity(0.4)
                      : (widget.device.isPending
                          ? Colors.orange.withOpacity(0.3)
                          : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2))),
                  width: widget.isNew ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isNew
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : (widget.device.isPending
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.black.withOpacity(isDark ? 0.2 : 0.05)),
                    blurRadius: widget.isNew ? 12 : 8,
                    offset: const Offset(0, 2),
                    spreadRadius: widget.isNew ? 2 : 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6.4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.device.isOnline
                                ? [Colors.green.shade400, Colors.teal.shade400]
                                : [Colors.red.shade400, Colors.pink.shade400],
                          ),
                          borderRadius: BorderRadius.circular(6.4),
                        ),
                        child: Icon(
                          widget.device.isOnline
                              ? Icons.smartphone_rounded
                              : Icons.phone_android_outlined,
                          color: Colors.white,
                          size: 14.4,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.device.model,
                                    style: const TextStyle(
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (widget.device.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.8, vertical: 1.6),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(3.84),
                                    ),
                                    child: const Text(
                                      '✓',
                                      style: TextStyle(fontSize: 7.2, color: Colors.white),
                                    ),
                                  ),
                                if (widget.device.isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.8, vertical: 1.6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(3.84),
                                    ),
                                    child: const Text(
                                      '⏳',
                                      style: TextStyle(fontSize: 6.4, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${widget.device.deviceId}',
                              style: TextStyle(
                                fontSize: 8,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      if (widget.device.isActive) ...[
                        if (widget.onPing != null)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                              ),
                              borderRadius: BorderRadius.circular(6.4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF14B8A6).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.isPinging ? null : () {
                                  widget.onPing?.call();
                                },
                                borderRadius: BorderRadius.circular(6.4),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.4),
                                  child: widget.isPinging
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.wifi_tethering_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                ),
                              ),
                            ),
                          ),

                        if (widget.onNote != null)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(6.4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.isNoting ? null : () {
                                  widget.onNote?.call();
                                },
                                borderRadius: BorderRadius.circular(6.4),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.4),
                                  child: widget.isNoting
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.note_add_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(6.4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  if (kIsWeb) {
                                    final storageService = StorageService();
                                    final openMode = storageService.getDeviceOpenMode();
                                    if (openMode == 'tab') {
                                      openDeviceInNewTab(widget.device.deviceId);
                                    } else {
                                      openDevicePopup(widget.device.deviceId);
                                    }
                                  } else if (defaultTargetPlatform == TargetPlatform.windows) {
                                    // Headless refresh before opening device (no UI blocking)
                                    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
                                    deviceProvider.refreshSingleDevice(widget.device.deviceId);
                                    
                                    final multiDeviceProvider = Provider.of<MultiDeviceProvider>(context, listen: false);
                                    multiDeviceProvider.openDevice(widget.device);
                                  } else {
                                    openDevicePopup(widget.device.deviceId);
                                  }
                                },
                                borderRadius: BorderRadius.circular(6.4),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.4),
                                  child: Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),

                      ],

                      if (widget.onDelete != null)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(6.4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.isDeleting ? null : () => widget.onDelete?.call(),
                              borderRadius: BorderRadius.circular(6.4),
                              child: Padding(
                                padding: const EdgeInsets.all(6.4),
                                child: widget.isDeleting
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete_forever_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(width: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.4, vertical: 3.2),
                        decoration: BoxDecoration(
                          color: widget.device.isOnline
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5.12),
                          border: Border.all(
                            color: widget.device.isOnline
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: widget.device.isOnline ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.device.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: widget.device.isOnline ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 0.8, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                  const SizedBox(height: 10),

                  if (widget.device.hasNote) ...[
                    _buildNotePreview(isDark),
                    const SizedBox(height: 12),
                  ],

                  if (widget.device.isActive)
                    Row(
                      children: [
                        _Stat(
                          icon: Icons.battery_charging_full_rounded,
                          label: '${widget.device.batteryLevel}%',
                          color: _getBatteryColor(widget.device.batteryLevel),
                        ),
                        const SizedBox(width: 10),
                        _Stat(
                          icon: Icons.message_rounded,
                          label: '${widget.device.stats.totalSms}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        _Stat(
                          icon: Icons.contacts_rounded,
                          label: '${widget.device.stats.totalContacts}',
                          color: Colors.purple,
                        ),
                        const Spacer(),
                        Text(
                          utils.DateUtils.timeAgoEn(widget.device.lastPing),
                          style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 11.2,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Awaiting approval',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 8.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          utils.DateUtils.timeAgoEn(widget.device.registeredAt),
                          style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (_getNoteColor() != Colors.transparent)
              Positioned(
                left: 0,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _getNoteColor(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.24),
                      bottomLeft: Radius.circular(10.24),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 60) return Colors.green;
    if (level > 30) return Colors.orange;
    return Colors.red;
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.2, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 8.8,
          ),
        ),
      ],
    );
  }
}