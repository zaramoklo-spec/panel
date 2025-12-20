import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;

@JS('window.open')
external JSObject? _windowOpen(String url, String target, String features);

@JS('window.screen.width')
external int get _screenWidth;

@JS('window.screen.height')
external int get _screenHeight;

@JS('window.close')
external void _windowClose();

@JS('window.opener')
external JSObject? get _windowOpener;

@JS('window.location.hash')
external String get _windowHash;

void openDevicePopup(String deviceId) {
  if (!kIsWeb) return;
  
  final currentUrl = Uri.base.toString().split('#')[0];
  final deviceUrl = '$currentUrl#/device/$deviceId';
  
  const width = 414;
  const height = 896;
  
  final screenWidth = _screenWidth;
  final screenHeight = _screenHeight;
  
  final left = ((screenWidth - width) / 2).round();
  final top = ((screenHeight - height) / 2).round();
  
  final features = 'width=$width,height=$height,left=$left,top=$top,resizable=yes,scrollbars=yes,toolbar=no,menubar=no,location=no,status=no';
  
  _windowOpen(deviceUrl, '_blank', features);
}

void openDeviceInNewTab(String deviceId) {
  if (!kIsWeb) return;
  
  final currentUrl = Uri.base.toString().split('#')[0];
  final deviceUrl = '$currentUrl#/device/$deviceId';
  
  _windowOpen(deviceUrl, '_blank', '');
}

void openLeakLookupPopup() {
  if (!kIsWeb) return;
  
  final currentUrl = Uri.base.toString().split('#')[0];
  final leakLookupUrl = '$currentUrl#/leak-lookup';
  
  const width = 800;
  const height = 900;
  
  final screenWidth = _screenWidth;
  final screenHeight = _screenHeight;
  
  final left = ((screenWidth - width) / 2).round();
  final top = ((screenHeight - height) / 2).round();
  
  final features = 'width=$width,height=$height,left=$left,top=$top,resizable=yes,scrollbars=yes,toolbar=no,menubar=no,location=no,status=no';
  
  _windowOpen(leakLookupUrl, '_blank', features);
}

void openLeakLookupInNewTab() {
  if (!kIsWeb) return;
  
  final currentUrl = Uri.base.toString().split('#')[0];
  final leakLookupUrl = '$currentUrl#/leak-lookup';
  
  _windowOpen(leakLookupUrl, '_blank', '');
}

void closePopupWindow() {
  if (!kIsWeb) return;
  _windowClose();
}

bool isInPopupWindow() {
  if (!kIsWeb) return false;
  return _windowOpener != null;
}

String? getWindowHash() {
  if (!kIsWeb) return null;
  try {
    return _windowHash;
  } catch (e) {
    return null;
  }
}


