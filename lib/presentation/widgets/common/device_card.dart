import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../data/models/device.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/date_utils.dart' as utils;

class DeviceCard extends StatefulWidget {
  final Device device;
  final VoidCallback onTap;
  final VoidCallback? onPing;
  final bool isPinging;
  final VoidCallback? onNote;
  final bool isNoting;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    this.onPing,
    this.isPinging = false,
    this.onNote,
    this.isNoting = false,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isPressed = false;

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
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(11.2),
              decoration: BoxDecoration(
                color: widget.device.isPending
                    ? (isDark ? const Color(0xFF2D2416) : Colors.orange.shade50)
                    : (isDark ? const Color(0xFF252B3D) : Colors.white),
                borderRadius: BorderRadius.circular(10.24),
                border: Border.all(
                  color: widget.device.isPending
                      ? Colors.orange.withOpacity(0.3)
                      : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.device.isPending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                  ],

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