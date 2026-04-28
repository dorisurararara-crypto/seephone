import 'theme_style.dart';
import 'themes/v1_classic.dart';
import 'themes/v2_kitsch.dart';
import 'themes/v3_minimal.dart';
import 'themes/v4_y2k.dart';
import 'themes/v5_mystic.dart';

/// 모든 테마 등록 (생성 비용은 무시할 만함 — 인스턴스 한번 만들고 캐시).
final List<BbaksinThemeStyle> kAllThemes = <BbaksinThemeStyle>[
  V1ClassicTheme(),
  V2KitschTheme(),
  V3MinimalTheme(),
  V4Y2kTheme(),
  V5MysticTheme(),
];

/// 기본 테마 — 다크 미스틱 (V5).
const String kDefaultThemeId = 'v5_mystic';

BbaksinThemeStyle themeById(String id) =>
    kAllThemes.firstWhere((t) => t.id == id, orElse: () => kAllThemes.last);
