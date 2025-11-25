class ActivityLog {
  final String id;
  final String adminUsername;
  final String activityType;
  final String description;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final Map<String, dynamic> metadata;
  final bool success;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.adminUsername,
    required this.activityType,
    required this.description,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    required this.metadata,
    required this.success,
    required this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['_id'] ?? '',
      adminUsername: json['admin_username'] ?? '',
      activityType: json['activity_type'] ?? '',
      description: json['description'] ?? '',
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      deviceId: json['device_id'],
      metadata: json['metadata'] ?? {},
      success: json['success'] ?? true,
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'admin_username': adminUsername,
      'activity_type': activityType,
      'description': description,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_id': deviceId,
      'metadata': metadata,
      'success': success,
      'timestamp': timestamp.toIso8601String(),
    };
  }

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