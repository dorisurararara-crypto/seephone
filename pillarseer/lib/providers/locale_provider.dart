// Pillar Seer — locale (언어) provider.
// 시스템 기본 / English / 한국어 3개 옵션. shared_preferences 에 영속화.

import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsLocaleKey = 'app.locale';

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kPrefsLocaleKey);
    if (code == null || code.isEmpty) {
      state = null;
      return;
    }
    state = Locale(code);
  }

  Future<void> setLocale(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_kPrefsLocaleKey);
      state = null;
    } else {
      await prefs.setString(_kPrefsLocaleKey, languageCode);
      state = Locale(languageCode);
    }
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
