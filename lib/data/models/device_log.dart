import '../../core/utils/date_utils.dart' as utils;

class DeviceLog {
  final String id;
  final String deviceId;
  final String type;
  final String message;
  final String level;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  DeviceLog({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.message,
    required this.level,
    required this.metadata,
    required this.timestamp,
  });

  factory DeviceLog.fromJson(Map<String, dynamic> json) {
    return DeviceLog(
      id: json['_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      type: json['type'] ?? 'system',
      message: json['message'] ?? '',
      level: json['level'] ?? 'info',
      metadata: json['metadata'] ?? {},
      timestamp: utils.DateUtils.parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'device_id': deviceId,
      'type': type,
      'message': message,
      'level': level,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isError => level == 'error';
  bool get isWarning => level == 'warning';
  bool get isInfo => level == 'info';
}