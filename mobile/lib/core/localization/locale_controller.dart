import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const String _prefsKey = 'app_locale'; // stores "en" / "ne"

  Locale? _locale;
  Locale? get locale => _locale;

  /// Load saved locale from device (must be awaited before runApp for best UX)
  Future<void> loadFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);

    if (code == null || code.trim().isEmpty) {
      _locale = null; // system default
    } else {
      _locale = Locale(code.trim());
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }

    notifyListeners();
  }

  Future<void> setEnglish() => setLocale(const Locale('en'));
  Future<void> setNepali() => setLocale(const Locale('ne'));

  /// if backend returns "EN"/"NP" (or "NE")
  Future<void> setFromBackendCode(String? code) async {
    final c = (code ?? '').toUpperCase().trim();
    if (c == "NP" || c == "NE") {
      await setNepali();
    } else if (c == "EN") {
      await setEnglish();
    } else {
      await setLocale(null); // system default
    }
  }
}