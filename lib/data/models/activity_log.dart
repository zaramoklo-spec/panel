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
      timestamp: DateTime.parse(json['timestamp']),
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
}