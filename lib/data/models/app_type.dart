class AppTypeInfo {
  final String appType;
  final String displayName;
  final String icon;
  final int count;

  AppTypeInfo({
    required this.appType,
    required this.displayName,
    required this.icon,
    required this.count,
  });

  factory AppTypeInfo.fromJson(Map<String, dynamic> json) {
    return AppTypeInfo(
      appType: json['app_type'] ?? '',
      displayName: json['display_name'] ?? '',
      icon: json['icon'] ?? '??',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_type': appType,
      'display_name': displayName,
      'icon': icon,
      'count': count,
    };
  }

  // Helper getters
  bool get hasDevices => count > 0;
  
  String get summary => '$displayName ($count)';
  
  // App type specific styling
  int get colorValue {
    switch (appType.toLowerCase()) {
      case 'sexychat':
        return 0xFFFF6B9D; // Pink
      case 'mparivahan':
      case 'mp':
        return 0xFF4CAF50; // Green
      case 'sexyhub':
        return 0xFF9C27B0; // Purple
      default:
        return 0xFF2196F3; // Blue
    }
  }
  
  String get colorHex {
    switch (appType.toLowerCase()) {
      case 'sexychat':
        return '#FF6B9D'; // Pink
      case 'mparivahan':
      case 'mp':
        return '#4CAF50'; // Green
      case 'sexyhub':
        return '#9C27B0'; // Purple
      default:
        return '#2196F3'; // Blue
    }
  }
}

class AppTypesResponse {
  final List<AppTypeInfo> appTypes;
  final int total;

  AppTypesResponse({
    required this.appTypes,
    required this.total,
  });

  factory AppTypesResponse.fromJson(Map<String, dynamic> json) {
    return AppTypesResponse(
      appTypes: (json['app_types'] as List)
          .map((appType) => AppTypeInfo.fromJson(appType))
          .toList(),
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_types': appTypes.map((appType) => appType.toJson()).toList(),
      'total': total,
    };
  }

  bool get hasAppTypes => appTypes.isNotEmpty;
  
  // Get app type by name
  AppTypeInfo? getAppType(String appType) {
    try {
      return appTypes.firstWhere(
        (type) => type.appType.toLowerCase() == appType.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get total device count
  int get totalDevices => appTypes.fold(0, (sum, type) => sum + type.count);
}
