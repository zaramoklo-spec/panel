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
      syncedAt: DateTime.parse(json['synced_at']),
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
}