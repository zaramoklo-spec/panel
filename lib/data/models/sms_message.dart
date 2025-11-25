class SmsMessage {
  final String id;
  final String deviceId;
  final String? from;
  final String? to;
  final String body;
  final DateTime timestamp;
  final String type;
  final bool isRead;
  final bool isFlagged;
  final List<String> tags;
  final DateTime receivedAt;

  SmsMessage({
    required this.id,
    required this.deviceId,
    this.from,
    this.to,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.isRead,
    required this.isFlagged,
    required this.tags,
    required this.receivedAt,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      from: json['from'],
      to: json['to'],
      body: json['body'] ?? '',
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'], isUtc: true).toLocal()
          : _parseTimestamp(json['timestamp']),
      type: json['type'] ?? 'inbox',
      isRead: json['is_read'] ?? false,
      isFlagged: json['is_flagged'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      receivedAt: json['received_at'] != null
          ? _parseTimestamp(json['received_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'device_id': deviceId,
      'from': from,
      'to': to,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'is_read': isRead,
      'is_flagged': isFlagged,
      'tags': tags,
      'received_at': receivedAt.toIso8601String(),
    };
  }

  bool get isInbox => type == 'inbox';
  bool get isSent => type == 'sent';
  String get sender => from ?? to ?? 'Unknown';

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
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
    
    return DateTime.now();
  }
}