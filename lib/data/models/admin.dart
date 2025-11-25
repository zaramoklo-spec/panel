
class TelegramBot {
  final int botId;
  final String botName;
  final String token;
  final String chatId;

  TelegramBot({
    required this.botId,
    required this.botName,
    required this.token,
    required this.chatId,
  });

  factory TelegramBot.fromJson(Map<String, dynamic> json) {
    return TelegramBot(
      botId: json['bot_id'] ?? 0,
      botName: json['bot_name'] ?? '',
      token: json['token'] ?? '',
      chatId: json['chat_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bot_id': botId,
      'bot_name': botName,
      'token': token,
      'chat_id': chatId,
    };
  }

  bool get isConfigured => token.isNotEmpty && chatId.isNotEmpty;
  
  String get botPurpose {
    switch (botId) {
      case 1:
        return 'Device Notifications';
      case 2:
        return 'SMS Notifications';
      case 3:
        return 'Admin Activity Logs';
      case 4:
        return 'Login/Logout Logs';
      case 5:
        return 'Reserved for Future';
      default:
        return 'Unknown';
    }
  }
}

class Admin {
  final String username;
  final String email;
  final String fullName;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final DateTime? lastLogin;
  final int loginCount;
  final DateTime createdAt;
  final String? deviceToken;
  final String? telegram2faChatId;
  final List<TelegramBot>? telegramBots;
  final List<String>? fcmTokens;
  final DateTime? expiresAt;

  Admin({
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.permissions,
    required this.isActive,
    this.lastLogin,
    required this.loginCount,
    required this.createdAt,
    this.deviceToken,
    this.telegram2faChatId,
    this.telegramBots,
    this.fcmTokens,
    this.expiresAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null
          ? _parseTimestamp(json['last_login'])
          : null,
      loginCount: json['login_count'] ?? 0,
      createdAt: _parseTimestamp(json['created_at']),
      deviceToken: json['device_token'],
      telegram2faChatId: json['telegram_2fa_chat_id'],
      telegramBots: json['telegram_bots'] != null
          ? (json['telegram_bots'] as List)
              .map((bot) => TelegramBot.fromJson(bot))
              .toList()
          : null,
      fcmTokens: json['fcm_tokens'] != null
          ? List<String>.from(json['fcm_tokens'])
          : null,
      expiresAt: json['expires_at'] != null
          ? _parseTimestamp(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'permissions': permissions,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'login_count': loginCount,
      'created_at': createdAt.toIso8601String(),
      if (deviceToken != null) 'device_token': deviceToken,
      if (telegram2faChatId != null) 'telegram_2fa_chat_id': telegram2faChatId,
      if (telegramBots != null)
        'telegram_bots': telegramBots!.map((bot) => bot.toJson()).toList(),
      if (fcmTokens != null) 'fcm_tokens': fcmTokens,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin';
  bool get isViewer => role == 'viewer';
  
  bool get hasTelegramBots => telegramBots != null && telegramBots!.isNotEmpty;
  bool get has2faConfigured => telegram2faChatId != null && telegram2faChatId!.isNotEmpty;
  
  int get configuredBotsCount {
    if (telegramBots == null) return 0;
    return telegramBots!.where((bot) => bot.isConfigured).length;
  }
  
  bool get hasFcmTokens => fcmTokens != null && fcmTokens!.isNotEmpty;
  
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  bool get hasExpiry => expiresAt != null;
  
  String get expiryStatus {
    if (expiresAt == null) return 'Never (Unlimited)';
    if (isExpired) return 'Expired';
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.inDays > 30) return '${(diff.inDays / 30).round()} months remaining';
    if (diff.inDays > 0) return '${diff.inDays} days remaining';
    if (diff.inHours > 0) return '${diff.inHours} hours remaining';
    return '${diff.inMinutes} minutes remaining';
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