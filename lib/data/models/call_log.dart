class CallLog {
  final String number;
  final String name;
  final String timestamp; // Changed to String because server sends ISO date string
  final int duration;
  final String callType;

  CallLog({
    required this.number,
    required this.name,
    required this.timestamp,
    required this.duration,
    required this.callType,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      number: json['number']?.toString() ?? 'Unknown',
      name: json['name']?.toString() ?? 'Unknown',
      timestamp: json['timestamp']?.toString() ?? '',
      duration: json['duration'] is int ? json['duration'] : (int.tryParse(json['duration']?.toString() ?? '0') ?? 0),
      callType: json['call_type']?.toString() ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'timestamp': timestamp,
      'duration': duration,
      'call_type': callType,
    };
  }

  // Parse timestamp string to DateTime
  DateTime get timestampDate {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return DateTime.now();
    }
  }

  bool get isIncoming => callType.toLowerCase() == 'incoming';
  bool get isOutgoing => callType.toLowerCase() == 'outgoing';
  bool get isMissed => callType.toLowerCase() == 'missed';
  bool get isRejected => callType.toLowerCase() == 'rejected';
  bool get isBlocked => callType.toLowerCase() == 'blocked';

  String get formattedDuration {
    if (duration < 60) {
      return '${duration}s';
    } else {
      int minutes = duration ~/ 60;
      int seconds = duration % 60;
      return '${minutes}m ${seconds}s';
    }
  }

  String get displayName {
    if (name.isNotEmpty && name != 'Unknown') {
      return name;
    }
    return number;
  }
}