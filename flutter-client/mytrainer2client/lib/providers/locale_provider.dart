import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_locale_code';
  Locale? _locale;
  bool _loaded = false;

  Locale? get locale => _locale;
  bool get loaded => _loaded;
  String get localeCode => _locale?.languageCode ?? 'system';

  Future<void> loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _locale = switch (code) {
      'en' => const Locale('en'),
      'bg' => const Locale('bg'),
      _ => null,
    };
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    switch (code) {
      case 'en':
        _locale = const Locale('en');
        await prefs.setString(_prefsKey, 'en');
        break;
      case 'bg':
        _locale = const Locale('bg');
        await prefs.setString(_prefsKey, 'bg');
        break;
      default:
        _locale = null;
        await prefs.remove(_prefsKey);
        break;
    }
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    final next = _locale?.languageCode == 'en' ? 'bg' : 'en';
    await setLocaleCode(next);
  }
}
