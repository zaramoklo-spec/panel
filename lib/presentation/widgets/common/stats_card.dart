import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11.2, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF252B3D)
              : Colors.white,
          borderRadius: BorderRadius.circular(8.96),
          border: Border.all(
            color: cardColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 17.6,
                color: cardColor,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: TextStyle(
                fontSize: 17.6,
                fontWeight: FontWeight.w800,
                color: cardColor,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final int totalDevices;
  final int activeDevices;
  final int pendingDevices;
  final int onlineDevices;
  final Function(String)? onStatTap;

  const StatsRow({
    super.key,
    required this.totalDevices,
    required this.activeDevices,
    required this.pendingDevices,
    required this.onlineDevices,
    this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(9.6),
      child: LayoutBuilder(
        builder: (context, constraints) {

          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        label: 'Total',
                        value: '$totalDevices',
                        icon: Icons.devices_rounded,
                        color: Colors.blue,
                        onTap: () => onStatTap?.call('all'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatsCard(
                        label: 'Active',
                        value: '$activeDevices',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                        onTap: () => onStatTap?.call('active'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        label: 'Pending',
                        value: '$pendingDevices',
                        icon: Icons.hourglass_bottom_rounded,
                        color: Colors.orange,
                        onTap: () => onStatTap?.call('pending'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatsCard(
                        label: 'Online',
                        value: '$onlineDevices',
                        icon: Icons.wifi_rounded,
                        color: Colors.teal,
                        onTap: () => onStatTap?.call('online'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: StatsCard(
                  label: 'Total',
                  value: '$totalDevices',
                  icon: Icons.devices_rounded,
                  color: Colors.blue,
                  onTap: () => onStatTap?.call('all'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatsCard(
                  label: 'Active',
                  value: '$activeDevices',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  onTap: () => onStatTap?.call('active'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatsCard(
                  label: 'Pending',
                  value: '$pendingDevices',
                  icon: Icons.hourglass_bottom_rounded,
                  color: Colors.orange,
                  onTap: () => onStatTap?.call('pending'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatsCard(
                  label: 'Online',
                  value: '$onlineDevices',
                  icon: Icons.wifi_rounded,
                  color: Colors.teal,
                  onTap: () => onStatTap?.call('online'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}