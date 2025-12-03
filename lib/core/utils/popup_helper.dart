import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:js/js.dart';

void openDevicePopup(String deviceId) {
  if (!kIsWeb) return;
  
  final currentUrl = Uri.base.toString().split('#')[0];
  final deviceUrl = '$currentUrl#/device/$deviceId';
  
  openDevicePopupJS(deviceUrl);
}

@JS('openDevicePopup')
external void openDevicePopupJS(String url);
