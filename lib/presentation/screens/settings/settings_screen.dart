import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications enabled' : 'Notifications disabled',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [

          const _SectionHeader(title: 'Notifications'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 6.4),
            child: SwitchListTile(
              secondary: Icon(
                _notificationsEnabled 
                    ? Icons.notifications_active 
                    : Icons.notifications_off,
                color: _notificationsEnabled 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey,
              ),
              title: const Text('Push Notifications'),
              subtitle: Text(
                _notificationsEnabled 
                    ? 'Receive notifications from admins' 
                    : 'Notifications are disabled',
              ),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),

          const SizedBox(height: 16),

          const _SectionHeader(title: 'Appearance'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 6.4),
            child: Column(
              children: [

                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(_getThemeText(themeProvider.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context),
                ),

                const Divider(height: 1),

                SwitchListTile(
                  secondary: const Icon(Icons.brightness_6),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Quick toggle to dark theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    if (value) {
                      themeProvider.setThemeMode(ThemeMode.dark);
                    } else {
                      themeProvider.setThemeMode(ThemeMode.light);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const _SectionHeader(title: 'About'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 6.4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Server Address'),
                  subtitle: Text("Unknown"),
                  trailing: const Icon(Icons.copy, size: 16),
                  onTap: () {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 6.4),
            child: InkWell(
              onTap: () => _launchTelegram(),
              borderRadius: BorderRadius.circular(7.68),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(7.68),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9.6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.code,
                        color: Theme.of(context).primaryColor,
                        size: 22.4,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developed by',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suki',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.send,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Auto (System)'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchTelegram() async {
    final Uri telegramUrl = Uri.parse('https://t.me/L0VES0UTHK0REA');

    try {
      if (await canLaunchUrl(telegramUrl)) {
        await launchUrl(
          telegramUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {

        final Uri webUrl = Uri.parse('https://t.me/L0VES0UTHK0REA');
        await launchUrl(webUrl);
      }
    } catch (e) {
      debugPrint('Error launching Telegram: $e');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
