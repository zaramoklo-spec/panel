import '../../core/utils/date_utils.dart' as utils;

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
  final String? deliveryStatus;
  final String? deliveryDetails;
  final String? simPhoneNumber;
  final int? simSlot;

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
    this.deliveryStatus,
    this.deliveryDetails,
    this.simPhoneNumber,
    this.simSlot,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      from: json['from'],
      to: json['to'],
      body: json['body'] ?? '',
      timestamp: utils.DateUtils.parseTimestamp(json['timestamp']),
      type: json['type'] ?? 'inbox',
      isRead: json['is_read'] ?? false,
      isFlagged: json['is_flagged'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      receivedAt: utils.DateUtils.parseTimestamp(json['received_at']),
      deliveryStatus: json['delivery_status'] ?? json['status'],
      deliveryDetails: json['delivery_details'],
      simPhoneNumber: json['sim_phone_number'],
      simSlot: json['sim_slot'],
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
      'delivery_status': deliveryStatus,
      'delivery_details': deliveryDetails,
      'sim_phone_number': simPhoneNumber,
      'sim_slot': simSlot,
    };
  }

  bool get isInbox => type == 'inbox';
  bool get isSent => type == 'sent';
  // For inbox: sender is from (the person who sent us the SMS)
  // For sent: sender is from (our phone number) or simPhoneNumber as fallback
  String get sender {
    if (isSent) {
      // For sent SMS, show from (our phone number) or simPhoneNumber as fallback
      return from ?? simPhoneNumber ?? to ?? 'Unknown';
    } else {
      // For inbox SMS, show from (the sender)
      return from ?? to ?? 'Unknown';
    }
  }
  bool get hasDeliveryStatus =>
      deliveryStatus != null && deliveryStatus!.isNotEmpty;
}