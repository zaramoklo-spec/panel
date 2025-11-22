// Stub FCM Service for web platform
// This prevents compilation errors when building for web

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  Future<void> initialize() async {
    // Stub implementation - does nothing on web
    print('FCM Service is not available on web platform');
  }
  
  Future<String?> getToken() async {
    return null;
  }
}
