// Stub file for flutter_local_notifications on web platform

class FlutterLocalNotificationsPlugin {
  Future<void> initialize(dynamic settings, {Function? onDidReceiveNotificationResponse}) async {
    // Stub implementation
  }
  
  Future<void> show(
    int id,
    String? title,
    String? body,
    dynamic notificationDetails, {
    String? payload,
  }) async {
    // Stub implementation - does nothing on web
    print('Notification (web stub): $title - $body');
  }
  
  dynamic resolvePlatformSpecificImplementation<T>() {
    return null;
  }
}

class AndroidNotificationChannel {
  final String id;
  final String name;
  final String? description;
  final dynamic importance;
  final bool enableVibration;
  final bool playSound;
  final bool showBadge;
  
  const AndroidNotificationChannel(
    this.id,
    this.name, {
    this.description,
    this.importance,
    this.enableVibration = false,
    this.playSound = false,
    this.showBadge = false,
  });
}

class AndroidFlutterLocalNotificationsPlugin {}

class Importance {
  static const max = 'max';
  static const high = 'high';
}

class NotificationDetails {
  final dynamic android;
  final dynamic iOS;
  
  const NotificationDetails({this.android, this.iOS});
}

class AndroidNotificationDetails {
  const AndroidNotificationDetails(
    String channelId,
    String channelName, {
    String? channelDescription,
    dynamic importance,
    dynamic priority,
    String? icon,
    bool? enableVibration,
    bool? playSound,
    bool? showWhen,
    dynamic styleInformation,
    String? ticker,
  });
}

class DarwinNotificationDetails {
  const DarwinNotificationDetails({
    bool? presentAlert,
    bool? presentBadge,
    bool? presentSound,
  });
}

class BigTextStyleInformation {
  const BigTextStyleInformation(String bigText);
}

class Priority {
  static const high = 'high';
}

class NotificationResponse {
  final String? payload;
  const NotificationResponse({this.payload});
}
