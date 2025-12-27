import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper class for managing keyboard behavior on web
class KeyboardHelper {
  /// Dismisses the keyboard by removing focus from all inputs
  static void dismissKeyboard(BuildContext? context) {
    if (kIsWeb && context != null) {
      // Remove focus from any focused input field
      FocusScope.of(context).unfocus();
      
      // Force blur on web to ensure keyboard is dismissed
      Future.delayed(const Duration(milliseconds: 100), () {
        html.window.document.activeElement?.blur();
      });
    } else if (context != null) {
      FocusScope.of(context).unfocus();
    }
  }
  
  /// Sets up keyboard dismissal when tapping outside inputs
  static Widget wrapWithKeyboardDismiss({
    required Widget child,
    BuildContext? context,
  }) {
    if (!kIsWeb) {
      return GestureDetector(
        onTap: () {
          if (context != null) {
            dismissKeyboard(context);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    
    return GestureDetector(
      onTap: () {
        if (context != null) {
          dismissKeyboard(context);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

