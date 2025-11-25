import 'dart:convert';
import 'package:flutter/services.dart';

class LocaleService {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  Map<String, dynamic> _localizedStrings = {};

  Future<void> load(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );
      _localizedStrings = json.decode(jsonString);
    } catch (e) {

      String jsonString = await rootBundle.loadString(
        'assets/translations/en.json',
      );
      _localizedStrings = json.decode(jsonString);
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String t(String key) => translate(key);
}
