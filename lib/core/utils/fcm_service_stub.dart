


class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  Future<void> initialize() async {

    print('FCM Service is not available on web platform');
  }
  
  Future<String?> getToken() async {
    return null;
  }
}
