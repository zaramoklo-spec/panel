import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/admin.dart';
import '../../providers/admin_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditAdminDialog extends StatefulWidget {
  final Admin admin;

  const EditAdminDialog({
    super.key,
    required this.admin,
  });

  @override
  State<EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<EditAdminDialog> {
  late String _selectedRole;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.admin.role;
    _isActive = widget.admin.isActive;
  }

  Future<void> _updateAdmin() async {
    setState(() => _isLoading = true);

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateAdmin(
      widget.admin.username,
      role: _selectedRole != widget.admin.role ? _selectedRole : null,
      isActive: _isActive != widget.admin.isActive ? _isActive : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Admin updated successfully! ✨',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Error updating admin',
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
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return const Color(0xFFEF4444);
      case 'admin':
        return const Color(0xFF6366F1);
      case 'viewer':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.shield_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'viewer':
        return Icons.visibility_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(6.4),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Text('Edit Admin'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getRoleColor(widget.admin.role).withOpacity(0.1),
                    _getRoleColor(widget.admin.role).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getRoleColor(widget.admin.role).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRoleColor(widget.admin.role).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getRoleIcon(widget.admin.role),
                          size: 18,
                          color: _getRoleColor(widget.admin.role),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.admin.username,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.admin.fullName,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.admin.isActive
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.admin.isActive
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.admin.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: widget.admin.isActive
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: widget.admin.email,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Created',
                    value: _formatDate(widget.admin.createdAt),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Update Role',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),

            _RoleCard(
              role: 'super_admin',
              label: 'Super Admin',
              description: 'Full access to everything',
              icon: Icons.shield_rounded,
              color: const Color(0xFFEF4444),
              selected: _selectedRole == 'super_admin',
              onTap: () => setState(() => _selectedRole = 'super_admin'),
            ),
            const SizedBox(height: 8),

            _RoleCard(
              role: 'admin',
              label: 'Admin',
              description: 'Manage devices and settings',
              icon: Icons.admin_panel_settings_rounded,
              color: const Color(0xFF6366F1),
              selected: _selectedRole == 'admin',
              onTap: () => setState(() => _selectedRole = 'admin'),
            ),
            const SizedBox(height: 8),

            _RoleCard(
              role: 'viewer',
              label: 'Viewer',
              description: 'Read-only access',
              icon: Icons.visibility_rounded,
              color: const Color(0xFF10B981),
              selected: _selectedRole == 'viewer',
              onTap: () => setState(() => _selectedRole = 'viewer'),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (_isActive ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 16,
                      color: _isActive ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Status',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isActive ? 'Account is active' : 'Account is inactive',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                    activeColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _updateAdmin,
          icon: _isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save_rounded, size: 16),
          label: Text(_isLoading ? 'Saving...' : 'Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: isDark ? Colors.white54 : Colors.black54),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '•',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? color : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
