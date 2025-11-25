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
      timestamp: _parseTimestamp(json['timestamp']),
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

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();
    }
    
    if (timestamp is String) {
      try {
        final date = DateTime.parse(timestamp);
        if (date.isUtc) {
          return date.toLocal();
        }
        return date;
      } catch (e) {
        return DateTime.now();
      }
    }
    
    if (timestamp is DateTime) {
      if (timestamp.isUtc) {
        return timestamp.toLocal();
      }
      return timestamp;
    }
    
    return DateTime.now();
  }
}