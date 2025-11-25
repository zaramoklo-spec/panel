class Contact {
  final String id;
  final String deviceId;
  final String contactId;
  final String name;
  final String phoneNumber;
  final String? email;
  final DateTime syncedAt;

  Contact({
    required this.id,
    required this.deviceId,
    required this.contactId,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.syncedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      contactId: json['contact_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      syncedAt: _parseTimestamp(json['synced_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'device_id': deviceId,
      'contact_id': contactId,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'synced_at': syncedAt.toIso8601String(),
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