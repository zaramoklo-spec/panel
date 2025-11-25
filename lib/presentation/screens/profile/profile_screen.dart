import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../auth/login_screen.dart';
import 'change_password_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/date_utils.dart' as utils;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final adminProvider = context.read<AdminProvider>();
      if (authProvider.currentAdmin != null) {
        adminProvider.fetchActivityStats(
          adminUsername: authProvider.currentAdmin!.username,
        );
        adminProvider.fetchActivities(
          adminUsername: authProvider.currentAdmin!.username,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final admin = authProvider.currentAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (admin == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading profile')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await adminProvider.fetchActivityStats(adminUsername: admin.username);
          await adminProvider.fetchActivities(adminUsername: admin.username);
        },
        child: CustomScrollView(
          slivers: [

            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: -50,
                      right: -50,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Stack(
                              children: [

                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 25,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 43.5,
                                    backgroundColor: Colors.white.withOpacity(0.9),
                                    child: Text(
                                      admin.fullName.isNotEmpty
                                          ? admin.fullName[0].toUpperCase()
                                          : admin.username[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ),

                                if (admin.isActive)
                                  Positioned(
                                    right: 2.4,
                                    bottom: 2.4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1.5,
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        width: 11.2,
                                        height: 11.2,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Text(
                              admin.fullName,
                              style: const TextStyle(
                                fontSize: 17.6,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9.6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12.8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '@${admin.username}',
                                style: const TextStyle(
                                  fontSize: 10.4,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            _RoleChip(role: admin.role),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () => _showLogoutDialog(context, authProvider),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [

                        Row(
                          children: [
                            Expanded(
                              child: _QuickStatCard(
                                icon: Icons.login_rounded,
                                value: '${admin.loginCount}',
                                label: 'Logins',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QuickStatCard(
                                icon: Icons.calendar_today_rounded,
                                value: utils.DateUtils.formatForDisplay(admin.createdAt).split(' ')[0],
                                label: 'Joined',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        _SectionCard(
                          icon: Icons.person_rounded,
                          title: 'Account Details',
                          color: Colors.blue,
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.email_rounded,
                                label: 'Email Address',
                                value: admin.email,
                              ),
                              const SizedBox(height: 12),
                              _DetailRow(
                                icon: Icons.badge_rounded,
                                label: 'Username',
                                value: '@${admin.username}',
                              ),
                              const SizedBox(height: 12),
                              _DetailRow(
                                icon: Icons.shield_rounded,
                                label: 'Role',
                                value: _getRoleText(admin.role),
                              ),
                              if (admin.lastLogin != null) ...[
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: Icons.access_time_rounded,
                                  label: 'Last Login',
                                  value: utils.DateUtils.timeAgoEn(admin.lastLogin!),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (adminProvider.activityStats != null)
                          _SectionCard(
                            icon: Icons.bar_chart_rounded,
                            title: 'Statistics',
                            color: Colors.green,
                            child: _buildStatsGrid(adminProvider.activityStats!),
                          ),

                        const SizedBox(height: 10),

                        if (adminProvider.activities.isNotEmpty)
                          _SectionCard(
                            icon: Icons.history_rounded,
                            title: 'Recent Activity',
                            color: Colors.orange,
                            child: Column(
                              children: adminProvider.activities
                                  .take(6)
                                  .map((activity) => _ActivityItem(activity: activity))
                                  .toList(),
                            ),
                          ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.lock_reset_rounded,
                                label: 'Change Password',
                                color: Colors.deepPurple,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const ChangePasswordDialog(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final statItems = stats['stats'] as Map<String, dynamic>? ?? {};
    final items = statItems.entries.take(4).toList();

    return Column(
      children: List.generate((items.length / 2).ceil(), (rowIndex) {
        final startIndex = rowIndex * 2;
        final endIndex = (startIndex + 2).clamp(0, items.length);
        final rowItems = items.sublist(startIndex, endIndex);

        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < (items.length / 2).ceil() - 1 ? 8 : 0),
          child: Row(
            children: [
              for (var i = 0; i < rowItems.length; i++) ...[
                Expanded(
                  child: _StatBox(
                    value: '${rowItems[i].value}',
                    label: rowItems[i].key,
                    index: startIndex + i,
                  ),
                ),
                if (i < rowItems.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        );
      }),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrator';
      case 'admin':
        return 'Administrator';
      case 'viewer':
        return 'Viewer';
      default:
        return role;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7.68),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 19.2),
              ),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout from your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );

                try {
                  await authProvider.logout();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('error in log out'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.68),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9.6, vertical: 4.8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 11.2, color: config.color),
          const SizedBox(width: 5),
          Text(
            config.text,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w700,
              fontSize: 9.6,
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color, String text}) _getRoleConfig(String role) {
    switch (role) {
      case 'super_admin':
        return (
        icon: Icons.admin_panel_settings_rounded,
        color: Colors.red,
        text: 'Super Admin'
        );
      case 'admin':
        return (
        icon: Icons.manage_accounts_rounded,
        color: Colors.blue,
        text: 'Administrator'
        );
      case 'viewer':
        return (
        icon: Icons.visibility_rounded,
        color: Colors.green,
        text: 'Viewer'
        );
      default:
        return (
        icon: Icons.person_rounded,
        color: Colors.grey,
        text: role
        );
    }
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(9.6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.96),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(6.4),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.4,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(11.2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.96),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                padding: const EdgeInsets.all(5.6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(5.76),
                ),
                child: Icon(icon, color: color, size: 14.4),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14.4,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 8.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final int index;

  const _StatBox({
    required this.value,
    required this.label,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(9.6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(7.68),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14.4,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 8.8,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final dynamic activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28.8,
            height: 28.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(5.76),
            ),
            child: Icon(
              Icons.circle,
              size: 8,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description ?? 'Activity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  utils.DateUtils.timeAgoEn(activity.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 8.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7.68),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(7.68),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 14.4),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}