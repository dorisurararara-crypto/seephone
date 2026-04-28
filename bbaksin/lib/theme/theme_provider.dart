import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_style.dart';
import 'theme_registry.dart';

const _kPrefKey = 'theme_id';

/// 현재 선택된 테마 ID. SharedPreferences 에 저장.
class ThemeIdNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return kDefaultThemeId;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kPrefKey);
    if (saved != null && saved != state) {
      state = saved;
    }
  }

  Future<void> setTheme(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, id);
  }
}

final themeIdProvider =
    NotifierProvider<ThemeIdNotifier, String>(ThemeIdNotifier.new);

/// 현재 테마 인스턴스.
final currentThemeProvider = Provider<BbaksinThemeStyle>((ref) {
  final id = ref.watch(themeIdProvider);
  return themeById(id);
});
