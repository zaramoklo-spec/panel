import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;

@JS('window.open')
external JSObject? _windowOpen(String url, String target, String features);

void openDevicePopup(String deviceId) {
  if (!kIsWeb) return;
  
  final currentUrl = Uri.base.toString().split('#')[0];
  final deviceUrl = '$currentUrl#/device/$deviceId';
  
  const width = 414;
  const height = 896;
  
  @JS('window.screen.width')
  external int get _screenWidth;
  
  @JS('window.screen.height')
  external int get _screenHeight;
  
  final screenWidth = _screenWidth;
  final screenHeight = _screenHeight;
  
  final left = ((screenWidth - width) / 2).round();
  final top = ((screenHeight - height) / 2).round();
  
  final features = 'width=$width,height=$height,left=$left,top=$top,resizable=yes,scrollbars=yes,toolbar=no,menubar=no,location=no,status=no';
  
  _windowOpen(deviceUrl, '_blank', features);
}
