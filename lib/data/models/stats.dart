// ============================================
// Stats Model
// در پوشه models بساز: models/stats.dart
// ============================================

class Stats {
  final int totalDevices;
  final int activeDevices;
  final int pendingDevices;
  final int onlineDevices;
  final int offlineDevices;

  Stats({
    required this.totalDevices,
    required this.activeDevices,
    required this.pendingDevices,
    required this.onlineDevices,
    required this.offlineDevices,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      totalDevices: json['total_devices'] ?? 0,
      activeDevices: json['active_devices'] ?? 0,
      pendingDevices: json['pending_devices'] ?? 0,
      onlineDevices: json['online_devices'] ?? 0,
      offlineDevices: json['offline_devices'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_devices': totalDevices,
      'active_devices': activeDevices,
      'pending_devices': pendingDevices,
      'online_devices': onlineDevices,
      'offline_devices': offlineDevices,
    };
  }

  @override
  String toString() {
    return 'Stats(total: $totalDevices, active: $activeDevices, pending: $pendingDevices, online: $onlineDevices, offline: $offlineDevices)';
  }
}