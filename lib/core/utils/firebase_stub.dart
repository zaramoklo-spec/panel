// Stub file for web platform where Firebase is not needed
// This prevents compilation errors when building for web

class Firebase {
  static Future<void> initializeApp() async {
    // Stub implementation - does nothing on web
  }
}

class FirebaseMessaging {
  static FirebaseMessaging instance = FirebaseMessaging._();
  
  FirebaseMessaging._();
  
  static void onBackgroundMessage(Function callback) {
    // Stub implementation - does nothing on web
  }
  
  Stream<String> get onTokenRefresh => Stream.empty();
  
  static Stream<dynamic> get onMessage => Stream.empty();
  static Stream<dynamic> get onMessageOpenedApp => Stream.empty();
  
  Future<String?> getToken() async {
    return null;
  }
  
  Future<NotificationSettings> requestPermission({
    bool? alert,
    bool? badge,
    bool? sound,
    bool? provisional,
    bool? announcement,
    bool? carPlay,
    bool? criticalAlert,
  }) async {
    return NotificationSettings(
      authorizationStatus: AuthorizationStatus.notDetermined,
      alert: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.notSupported,
    );
  }
  
  Future<NotificationSettings> getNotificationSettings() async {
    return NotificationSettings(
      authorizationStatus: AuthorizationStatus.notDetermined,
      alert: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.notSupported,
    );
  }
  
  Future<RemoteMessage?> getInitialMessage() async {
    return null;
  }
}

class RemoteMessage {
  String? messageId;
  String? from;
  int? sentTime;
  Map<String, dynamic> data = {};
  RemoteNotification? notification;
}

class RemoteNotification {
  String? title;
  String? body;
  AndroidNotification? android;
}

class AndroidNotification {}

class NotificationSettings {
  final AuthorizationStatus authorizationStatus;
  final AppleNotificationSetting alert;
  final AppleNotificationSetting badge;
  final AppleNotificationSetting sound;
  
  const NotificationSettings({
    required this.authorizationStatus,
    required this.alert,
    required this.badge,
    required this.sound,
  });
}

enum AuthorizationStatus {
  authorized,
  denied,
  notDetermined,
  provisional,
}

enum AppleNotificationSetting {
  enabled,
  disabled,
  notSupported,
}
