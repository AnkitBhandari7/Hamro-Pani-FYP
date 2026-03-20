import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale? locale) {
    _locale = locale;
    notifyListeners();
  }

  void setEnglish() => setLocale(const Locale('en'));
  void setNepali() => setLocale(const Locale('ne'));

  /// if backend returns "EN"/"NP"
  void setFromBackendCode(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    if (c == "NP" || c == "NE") {
      setNepali();
    } else if (c == "EN") {
      setEnglish();
    } else {
      setLocale(null); // system default
    }
  }
}
