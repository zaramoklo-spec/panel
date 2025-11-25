import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/device.dart';
import '../../../providers/device_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditSettingsDialog extends StatefulWidget {
  final Device device;

  const EditSettingsDialog({
    super.key,
    required this.device,
  });

  @override
  State<EditSettingsDialog> createState() => _EditSettingsDialogState();
}

class _EditSettingsDialogState extends State<EditSettingsDialog> {
  late bool _smsForwardEnabled;
  late bool _autoReplyEnabled;
  late TextEditingController _smsForwardNumberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _smsForwardEnabled = widget.device.settings.smsForwardEnabled;
    _autoReplyEnabled = widget.device.settings.autoReplyEnabled;
    _smsForwardNumberController = TextEditingController(
      text: widget.device.settings.forwardNumber ?? '',
    );
  }

  @override
  void dispose() {
    _smsForwardNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    final deviceProvider = context.read<DeviceProvider>();

    final newSettings = DeviceSettings(
      smsForwardEnabled: _smsForwardEnabled,
      forwardNumber: _smsForwardNumberController.text.isNotEmpty
          ? _smsForwardNumberController.text
          : null,
      monitoringEnabled: true,
      autoReplyEnabled: _autoReplyEnabled,
    );

    final settingsSaved = await deviceProvider.updateDeviceSettings(
      widget.device.deviceId,
      newSettings,
    );

    if (!settingsSaved) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackbar('Failed to save settings');
      }
      return;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.4),
          ),
        ),
      );

      await deviceProvider.refreshDevices();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
              Container(
                padding: const EdgeInsets.all(14.4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
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
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 14.4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Device Settings',
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _SettingSection(
                        icon: Icons.forward_to_inbox_rounded,
                        title: 'SMS Forwarding',
                        subtitle: 'Forward messages to another number',
                        isDark: isDark,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(7.68),
                              ),
                              child: SwitchListTile(
                                title: Text(
                                  _smsForwardEnabled ? 'Enabled' : 'Disabled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.4,
                                  ),
                                ),
                                value: _smsForwardEnabled,
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                  setState(() => _smsForwardEnabled = value);
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 9.6,
                                  vertical: 1.6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7.68),
                                ),
                              ),
                            ),
                            if (_smsForwardEnabled) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _smsForwardNumberController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontSize: 10.4,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Forward Number',
                                  hintText: '+1234567890',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(4.8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(5.12),
                                    ),
                                    child: const Icon(
                                      Icons.message_rounded,
                                      size: 11.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7.68),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7.68),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF6366F1),
                                      width: 1.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _SettingSection(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Auto Reply',
                        subtitle: 'Automatically reply to messages',
                        isDark: isDark,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(7.68),
                              ),
                              child: SwitchListTile(
                                title: Text(
                                  _autoReplyEnabled ? 'Enabled' : 'Disabled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.4,
                                  ),
                                ),
                                subtitle: Text(
                                  _autoReplyEnabled
                                      ? 'Auto reply is active'
                                      : 'Auto reply is disabled',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                value: _autoReplyEnabled,
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                  setState(() => _autoReplyEnabled = value);
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 9.6,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7.68),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _SettingSection(
                        icon: Icons.visibility_rounded,
                        title: 'Device Monitoring',
                        subtitle: 'Monitor device activities (Always Active)',
                        isDark: isDark,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(7.68),
                              ),
                              child: SwitchListTile(
                                title: const Text(
                                  'Enabled (Locked)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.4,
                                  ),
                                ),
                                subtitle: const Text(
                                  'This setting cannot be changed',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: true,
                                onChanged: null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 9.6,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7.68),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),

              Container(
                padding: const EdgeInsets.all(14.4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(7.68),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 9.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7.68),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 14.4,
                            height: 14.4,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 11.2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isDark;

  const _SettingSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(6.4),
              ),
              child: Icon(icon, color: Colors.white, size: 12.8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8.8,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}