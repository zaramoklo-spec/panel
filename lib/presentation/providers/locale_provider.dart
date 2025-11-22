import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/locale_service.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  final LocaleService _localeService = LocaleService();
  bool _isLoading = false;

  Locale get locale => _locale;
  LocaleService get localeService => _localeService;
  bool get isLoading => _isLoading;

  // Get translated string
  String t(String key) => _localeService.translate(key);

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      
      await _localeService.load(languageCode);
      _locale = Locale(languageCode);
    } catch (e) {
      // Fallback to English
      await _localeService.load('en');
      _locale = const Locale('en');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _localeService.load(locale.languageCode);
      _locale = locale;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      debugPrint('Error setting locale: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
