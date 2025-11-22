import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../../core/utils/date_utils.dart' as utils;
import '../../../presentation/widgets/common/empty_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActivityLogsScreen extends StatefulWidget {
  final String? adminUsername;
  final String? adminFullName;
  final bool isMyActivities;

  const ActivityLogsScreen({
    super.key,
    this.adminUsername,
    this.adminFullName,
    this.isMyActivities = false,
  });

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  String? _selectedAdmin;
  String? _selectedActivityType;

  @override
  void initState() {
    super.initState();
    _selectedAdmin = widget.adminUsername;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchActivities(
            adminUsername: _selectedAdmin,
          );
      if (!widget.isMyActivities) {
        context.read<AdminProvider>().fetchAdmins();
      }
    });
  }

  String _getTitle() {
    if (widget.isMyActivities) {
      return 'My Activities';
    } else if (widget.adminFullName != null) {
      return '${widget.adminFullName}\'s Activities';
    }
    return 'Activity Logs';
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          if (!widget.isMyActivities && widget.adminUsername == null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.filter_alt_outlined),
                iconSize: 20,
                tooltip: 'Filter Type',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (value) {
                  setState(() {
                    _selectedActivityType = value == 'all' ? null : value;
                  });
                  adminProvider.fetchActivities(
                    adminUsername: _selectedAdmin,
                    activityType: _selectedActivityType,
                  );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.all_inclusive, size: 12),
                        ),
                        const SizedBox(width: 10),
                        const Text('All'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  ..._buildActivityTypeMenuItems(),
                ],
              ),
            ),
          if (!widget.isMyActivities && widget.adminUsername == null && adminProvider.admins.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.people_outline),
                iconSize: 20,
                tooltip: 'Filter Admin',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (value) {
                  setState(() {
                    _selectedAdmin = value == 'all' ? null : value;
                  });
                  adminProvider.fetchActivities(
                    adminUsername: _selectedAdmin,
                    activityType: _selectedActivityType,
                  );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.all_inclusive, size: 12),
                        ),
                        const SizedBox(width: 10),
                        const Text('All'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...adminProvider.admins.map(
                    (admin) => PopupMenuItem(
                      value: admin.username,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(Icons.person, size: 12),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  admin.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '@${admin.username}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error',
                  subtitle: adminProvider.errorMessage,
                  actionText: 'Retry',
                  onAction: () => adminProvider.fetchActivities(
                    adminUsername: _selectedAdmin,
                    activityType: _selectedActivityType,
                  ),
                )
              : adminProvider.activities.isEmpty
                  ? EmptyState(
                      icon: Icons.history_outlined,
                      title: 'No Logs Found',
                      subtitle: 'No activities recorded',
                    )
                  : RefreshIndicator(
                      onRefresh: () => adminProvider.fetchActivities(
                        adminUsername: _selectedAdmin,
                        activityType: _selectedActivityType,
                      ),
                      child: CustomScrollView(
                        slivers: [
                          if (_selectedAdmin != null && !widget.isMyActivities && widget.adminUsername == null)
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                                child: Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: const Color(0xFF6366F1),
                                    radius: 12,
                                    child: const Icon(Icons.filter_list, size: 10, color: Colors.white),
                                  ),
                                  label: Text('Filtered: $_selectedAdmin', style: const TextStyle(fontSize: 11)),
                                  deleteIcon: const Icon(Icons.close, size: 12),
                                  onDeleted: () {
                                    setState(() => _selectedAdmin = null);
                                    adminProvider.fetchActivities(
                                      activityType: _selectedActivityType,
                                    );
                                  },
                                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          if (!widget.isMyActivities && widget.adminUsername == null)
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ModernStatCard(
                                        icon: Icons.list_alt_rounded,
                                        label: 'Total',
                                        value: adminProvider.totalActivities.toString(),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF2563EB),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _ModernStatCard(
                                        icon: Icons.description_rounded,
                                        label: 'Page',
                                        value: '${adminProvider.currentPage}',
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF10B981),
                                            Color(0xFF059669),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _ModernStatCard(
                                        icon: Icons.visibility_rounded,
                                        label: 'Showing',
                                        value: adminProvider.activities.length.toString(),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFF59E0B),
                                            Color(0xFFD97706),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          SliverPadding(
                            padding: const EdgeInsets.all(10),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final activity = adminProvider.activities[index];
                                  return _EnhancedActivityCard(activity: activity);
                                },
                                childCount: adminProvider.activities.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  List<PopupMenuEntry<String>> _buildActivityTypeMenuItems() {
    final items = [
      {'value': 'login', 'icon': Icons.login, 'label': 'Login', 'color': Colors.green},
      {'value': 'logout', 'icon': Icons.logout, 'label': 'Logout', 'color': Colors.orange},
      {'value': 'create_admin', 'icon': Icons.person_add, 'label': 'Create', 'color': Colors.blue},
      {'value': 'update_admin', 'icon': Icons.edit, 'label': 'Update', 'color': Colors.blue},
      {'value': 'delete_admin', 'icon': Icons.person_remove, 'label': 'Delete', 'color': Colors.red},
    ];

    return items.map((item) => PopupMenuItem<String>(
      value: item['value'] as String,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(item['icon'] as IconData, size: 12, color: item['color'] as Color),
          ),
          const SizedBox(width: 10),
          Text(item['label'] as String),
        ],
      ),
    )).toList();
  }
}

class _ModernStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  const _ModernStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedActivityCard extends StatelessWidget {
  final dynamic activity;

  const _EnhancedActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final color = _getActivityColor(activity.activityType);
    final icon = _getActivityIcon(activity.activityType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
              ? Colors.black.withOpacity(0.2)
              : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.description ?? 'Activity',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.alternate_email,
                            size: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            activity.adminUsername,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: activity.success
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activity.success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        activity.success ? 'OK' : 'Fail',
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _DetailChip(
                  icon: Icons.label_rounded,
                  label: activity.activityType.toUpperCase(),
                  color: color,
                ),
                if (activity.ipAddress != null)
                  _DetailChip(
                    icon: Icons.location_on_rounded,
                    label: activity.ipAddress!,
                    color: Colors.grey,
                  ),
                _DetailChip(
                  icon: Icons.schedule_rounded,
                  label: utils.DateUtils.timeAgoEn(activity.timestamp),
                  color: Colors.grey,
                ),
              ],
            ),

            if (activity.metadata != null && activity.metadata.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          size: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Details',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...activity.metadata.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}: ',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8.5,
                                    ),
                              ),
                              Expanded(
                                child: Text(
                                  '${entry.value}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 8.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'login':
        return const Color(0xFF10B981);
      case 'logout':
        return const Color(0xFFF59E0B);
      case 'create_admin':
      case 'update_admin':
        return const Color(0xFF3B82F6);
      case 'delete_admin':
      case 'delete_data':
        return const Color(0xFFEF4444);
      case 'view_device':
      case 'view_sms':
      case 'view_contacts':
        return const Color(0xFF8B5CF6);
      case 'send_command':
        return const Color(0xFF14B8A6);
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'login':
        return Icons.login_rounded;
      case 'logout':
        return Icons.logout_rounded;
      case 'create_admin':
        return Icons.person_add_rounded;
      case 'update_admin':
        return Icons.edit_rounded;
      case 'delete_admin':
        return Icons.person_remove_rounded;
      case 'view_device':
        return Icons.phone_android_rounded;
      case 'view_sms':
        return Icons.message_rounded;
      case 'view_contacts':
        return Icons.contacts_rounded;
      case 'send_command':
        return Icons.send_rounded;
      case 'delete_data':
        return Icons.delete_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}