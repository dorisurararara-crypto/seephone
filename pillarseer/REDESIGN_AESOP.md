# Pillar Seer — Aesop Luxury 전면 재디자인 (새 세션 인계)

> 이 문서는 새 세션 시작 시 사용자가 한 마디 ("이어서" / "체크해줘" / "재디자인 시작") 만 하면
> Claude 가 이 md 를 읽고 자율로 진행하기 위한 handoff 문서.
>
> 한 명의 코더에게 인계하듯 작성. 모호한 표현 X.

---

## 🎯 한 줄 mandate

**Pillar Seer 의 모든 화면을 `mockups/05_aesop_luxury.html` 톤으로 전면 재디자인.**

사용자 표현: "디자인이 너무 구려, 고급스럽게." Aesop Luxury 선택.

---

## 🎨 디자인 spec (Aesop Luxury)

### Reference
- 파일: `pillarseer/mockups/05_aesop_luxury.html`
- 영감: Aesop, apothecary, 잡지 magazine sub-headers, very minimal text-only luxury
- 키워드: 베이지 / taupe / 차분한 세리프 / 텍스트 위주 / 라이트 럭셔리 / 절제

### Palette (lock in)
```dart
// lib/theme/app_theme.dart — 전면 교체
static const bg = Color(0xFFEDE6D6);       // apothecary cream
static const paper = Color(0xFFE5DCC8);    // accent surface (slightly darker cream)
static const ink = Color(0xFF2A2520);      // primary text (deep brown-black, not pure black)
static const inkLight = Color(0xFF5A5247); // secondary text (warm gray-brown)
static const taupe = Color(0xFF7C7166);    // muted label
static const line = Color(0xFFC9BFA9);     // divider/border
static const accent = Color(0xFFA88A4E);   // single gold-brown accent (use sparingly)

// CTA 는 ink 배경 + bg 텍스트 (역상)
// 카드/section 구분은 paper 배경
// 강조 단어는 accent + italic serif
```

### Typography
```yaml
# pubspec.yaml — google_fonts 이미 있음. 추가 폰트 X (font 다양화 X, 절제)
fonts:
  primary_sans: Inter (Latin) + Noto Sans KR (한국어)   # body, labels
  primary_serif: Noto Serif KR + (Cormorant Garamond italic 강조용)

# 폰트 weight 사용 룰
labels (small caps, letter-spacing 5px): 500 weight
body text: 400 weight (한국어 자연스러움)
hero (한자 일주, magazine headline): 300 weight (얇은 세리프)
emphasis italic: Cormorant Garamond italic 400 (Latin 만, 한국어 X)
```

### 핵심 디자인 룰
1. **emoji 전면 제거** (🎯🔮⚖️🪐🌸🌀⚡ → 한자/letter-spacing 4-6px UPPERCASE label 로 대체)
2. **letter-spacing UPPERCASE** 라벨 패턴 (예: `DAY MASTER`, `FOUR PILLARS`, `CHART ATTRIBUTES`)
3. **여백 generous** — section 사이 32-36px, content padding 24px
4. **divider** = 1px solid line color, full-width
5. **카드 그림자 X** — 배경색 차이 (bg vs paper) 로만 구분
6. **CTA** = 검정 배경 + 베이지 글자 + uppercase + letter-spacing 5px (`CONTINUE READING`)
7. **둥근 모서리 X 또는 매우 작게** (border-radius 0~4px)
8. **그라데이션 X**
9. **gold 액센트는 한 곳만** (격국 한자 또는 강조 italic phrase)
10. **한자 (한국어) 패턴**: 한자 큰 글자 + 작은 한국어 보조 (예: "偏印 편인격")

### Mockup 참고 layout (Result 화면)
```
┌──────────────────────────────┐
│ P I L L A R   S E E R  [chip]│  appbar, border-bottom 1px
├──────────────────────────────┤
│ DAY MASTER · 日 柱            │  meta (taupe, letter-spacing 5)
│ 丁卯 — Fire Rabbit            │  hero name (serif 36, ink)
│ Yin Fire seated on Wood       │  sub (small, ink-light, italic accent words)
│ Rabbit. A candle resting on   │
│ a spring branch...            │
├──────────────────────────────┤  paper bg
│ A READING                     │  label
│ 한결같은 사람. 속도보다 깊이로  │  body 15px line-height 1.85
│ 흐르고, 오랜 시간 속에서       │
│ 본질이 드러나는 사주.          │
├──────────────────────────────┤
│ CHART ATTRIBUTES              │  label
│ ┌─────────┬─────────┐         │  grid 2×2
│ │FORMAT   │YONGSIN  │         │
│ │偏印 편인격│木 나무  │         │  serif 18, gold accent on hanja
│ ├─────────┼─────────┤         │
│ │STRENGTH │VOID     │         │
│ │身旺 신왕 │戌 · 亥   │         │
│ └─────────┴─────────┘         │
├──────────────────────────────┤  paper bg
│ FOUR PILLARS · 四 柱           │
│ YR  MO  DAY  HR              │
│ 癸  丁  丁   —              │  serif 26, day pillar gold
│ 酉  巳  卯   —              │
├──────────────────────────────┤
│   CONTINUE READING            │  ink bg, bg color text
├──────────────────────────────┤
│ KASI · 입춘·12절 · 진태양시·균시차│  foot
└──────────────────────────────┘
```

---

## 📂 변경해야 할 파일 (체크리스트)

### 1. 테마 (가장 먼저)
- [ ] `lib/theme/app_theme.dart` — AppColors 전면 교체
  - 기존 `cosmicBlack`, `midnightPurple`, `spiritIndigo`, `mysticViolet`, `celestialGold`, `ghostlyWhite`, `moonlightGray`, `fadedSilver`, `cardSurface`, `cardBorder`, `cardBorderStrong`, `fireRed`, `forestJade`, `phoenixRed`, `ancientBronze`, `lunarSilver`, `deepOceanBlue`
  - 새 palette: `bg`, `paper`, `ink`, `inkLight`, `taupe`, `line`, `accent` 만
  - **모든 기존 상수 alias 유지** (예: `celestialGold = accent`) — 코드 전체 수정 안 해도 작동하게
  - 새 코드는 새 이름 사용

### 2. Splash
- [ ] `lib/screens/splash_screen.dart`
  - RadialGradient 보라 → solid `bg`
  - 별 dots → 작은 dot ornament 1-3개 (또는 제거)
  - logo gold shimmer → 작은 ink letter-spacing
  - tagline "절기·진태양시·DST" → italic Cormorant `Solar-term · True-solar-time · DST aware`

### 3. Input screen
- [ ] `lib/screens/input_screen.dart`
  - 별자리 배경 제거 또는 단순화
  - `_IconField` 둥근 모서리 작게 (radius 4)
  - 한자 watermark (`命`) 더 옅게 + 한쪽 코너로 + 큰 serif
  - CTA submit button → ink bg, letter-spacing UPPERCASE

### 4. Result screen (가장 큰 작업)
- [ ] `lib/screens/result_screen.dart`
  - AppBar 단순화 (정밀모드 chip 작게)
  - `_ThreeHitCard` → Vogue 스타일 editorial
  - `_MyeongliSummaryCard` chips → **그리드 2×2** 또는 magazine-style 리스트
  - `_PillarGrid` → 가로 4 columns no card, border-top/bottom
  - `_DayMasterCard` → 큰 한자 + italic phrase
  - 11 accordion → group header (작은 letter-spacing) + 얇은 divider
  - emoji 제거 (🎯🔮⚖️🪐🌸🌀⚡)
  - CTA → uppercase ink-bg

### 5. Home
- [ ] `lib/screens/home_screen.dart`
  - `_Header`, `_StreakChip`, `_Date`, `_ScoreCircle`, `_Quote`, `_TodayPillarRow`, `_HourlyFlowCard`, `_CategoryGrid`, `_LuckyCard`
  - 모두 paper / bg 두 톤 + ink + taupe accent
  - ScoreCircle 큰 동그라미 → 큰 serif 숫자 + thin underline
  - 카테고리 4종 grid → 2×2 letter-spacing label + serif 점수

### 6. Settings / Profile / Discover / Reports / Tojeong / Compatibility / DatePicking / Dream
- [ ] 각 화면도 같은 룰로
  - 그라데이션 제거
  - 보라/금 → ink/accent
  - card decoration 단순화
  - emoji → uppercase label

### 7. Widgets
- [ ] `lib/widgets/bottom_nav.dart` — 4 tab, ink color, underline (없으면 작은 dot)
- [ ] `lib/widgets/coming_soon_modal.dart` — paper bg + ink + uppercase

### 8. L10n
- [ ] `lib/l10n/app_ko.arb`, `app_en.arb`
  - 라벨에 letter-spacing 으로 표현되는 단어들은 그대로 둠
  - `splashTrust` → "Solar-term · True-solar-time · DST aware" (Aesop 톤)
  - `resultPrecisionBadge` 그대로

### 9. Tests
- [ ] 모든 기존 test 통과 유지 (254/254)
- [ ] 새 widget test 추가 가능 (없어도 OK)

---

## 🏗️ 현재 상태 (시작 전)

### Codebase
- **Branch**: main (모든 변경 push 됨)
- **Version**: 1.0.0+29 (pubspec.yaml)
- **Tests**: 254/254 통과
- **Analyze**: clean
- **마지막 commit**: Round 61 phrase variation

### 명리학 13 services (변경 X — 단지 표시만 재디자인)
1. SolarTermService (24절기)
2. ManseryeokService (KST·DST·EoT·36 도시)
3. GongMangService (공망)
4. ShinsaService (12 신살 + 양인/괴강/백호)
5. TwelveUnsungService (12 운성)
6. HapchungService (합·충·삼합·방합·반합·형·파·해)
7. StrengthService (신왕/신약)
8. GyeokgukService (격국 10종)
9. YongsinService (용신·희신)
10. ThongGeunService (통근·투간)
11. DaewoonService (대운 8 chunks)
12. SeunService (세운)
13. SajuService (통합 wrapper)

### TestFlight
- **ASC 최신 deploy**: Build #25 (Round 20-22 까지만 포함)
- **Build #26-29**: Apple 일일 한도 (90382) 도달 — 실패
- **한도 reset**: 5/13 ~00:10 KST 부터 1 slot 풀리기 시작 → 5/13 ~11:34 KST 완전 회복
- **이번 재디자인 완료 후 ONE single deploy** (Build #30 한 번만)

---

## 🚦 작업 룰 (이번 세션 교훈 반영)

### ✅ DO
1. **codex 와 의논** (`codex exec --skip-git-repo-check < ...`)
   - 디자인 review (큰 변경 전)
   - 한국어 톤 검증 (Aesop 톤 자연스러움)
   - 정직한 점수 평가
2. **HTML mockup 비교** (`mockups/05_aesop_luxury.html` 기준)
3. **`flutter analyze` + `flutter test` 매 변경 후**
4. **commit per logical change** (color theme / splash / input / result / ...)
5. **자율 진행** — 사용자 mandate "묻지 말고 끝까지"
6. **막히면 codex 또는 gemini 상의** (~/.claude-shared/global.md 룰)
7. **한국어 자연스러움** — 조사 정확, 친근하면서 고급

### ❌ DON'T
1. **TestFlight deploy 매번 X** — 모든 작업 끝나고 단 한 번 (Apple 일일 한도 25 IPA/24h)
2. **거짓말 X** — codex 점수 그대로 보고, 시간 정확히
3. **에뮬레이터 자동 실행 X** (CLAUDE.md 룰)
4. **emoji 다시 넣지 X** (Aesop 톤 어긋남)
5. **둥근 모서리 큰 거 X** (radius 0~4 까지만)
6. **그라데이션 X**

### 검증 cycle
```bash
cd /Users/seunghyeon/seephone/pillarseer
flutter analyze 2>&1 | tail -3      # No issues found
flutter test 2>&1 | tail -3         # 254/254 통과
git status --short                  # 변경 확인
git add <changed files>
git commit -m "ux(pillarseer): Aesop redesign — <section>"
git push
```

### codex 검증 패턴
```bash
cat > /tmp/pillarseer_codex_logs/aesop_roundN.md <<'EOF'
# Round N — <무엇>
변경: <code paths>
질문: 1) Aesop 톤 맞나? 2) 9.0+ 점수? 3) 다음 단계?
EOF
codex exec --skip-git-repo-check < /tmp/pillarseer_codex_logs/aesop_roundN.md \
  > /tmp/pillarseer_codex_logs/aesop_roundN.log 2>&1
```

---

## 📋 Phase 분할 (권장 순서)

### Phase 1 — Foundation (1-2h)
1. Theme palette 전면 교체 (`app_theme.dart`)
2. 기존 색상 alias 추가 (backwards compat)
3. analyze + test 통과 확인

### Phase 2 — 핵심 화면 (2-3h)
4. Splash redesign
5. Input screen redesign
6. Result screen first viewport (ThreeHit / Summary / Pillars / DayMaster)

### Phase 3 — Accordion + sections (2h)
7. Result accordion 11개 모두 Aesop 톤
8. emoji 제거 + uppercase label
9. Group header 단순화

### Phase 4 — Home + 나머지 (2h)
10. Home (Score / Quote / Pillar / Hourly / Category / Lucky / Promo)
11. Settings, Profile, Discover
12. Reports (Compatibility, Tojeong, DatePicking, Dream)

### Phase 5 — 검증 + deploy (1h)
13. 전체 flutter test 통과
14. codex 최종 audit (Aesop 톤 + 점수)
15. version bump 1.0.0+30
16. **단 한 번** `bash scripts/deploy_testflight.sh 30` (Apple 한도 reset 후)
17. ASC seed beta meta + 외부 베타 그룹 ganzitester 자동 제출

총 예상: 8-10시간 자율 작업.

---

## 📁 핵심 파일 path

```
/Users/seunghyeon/seephone/pillarseer/
├── REDESIGN_AESOP.md                       # 이 문서
├── pubspec.yaml                            # version 1.0.0+29 → +30
├── mockups/05_aesop_luxury.html            # 디자인 reference (모바일 viewport)
├── mockups/index.html                      # 8개 비교
├── lib/
│   ├── theme/app_theme.dart                # palette 전면 교체 (1순위)
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── input_screen.dart
│   │   ├── result_screen.dart              # 가장 큰 작업
│   │   ├── home_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── discover_screen.dart
│   │   └── reports/
│   │       ├── reports_home_screen.dart
│   │       ├── compatibility_screen.dart
│   │       ├── tojeong_screen.dart
│   │       ├── date_picking_screen.dart
│   │       └── dream_screen.dart
│   ├── widgets/
│   │   ├── bottom_nav.dart
│   │   └── coming_soon_modal.dart
│   ├── services/                           # 변경 X (명리학 계산은 그대로)
│   └── l10n/
│       ├── app_ko.arb
│       └── app_en.arb
├── test/                                   # 254 tests, 모두 통과 유지
└── scripts/deploy_testflight.sh            # 마지막에 한 번만 실행
```

---

## 🆘 막히면

1. **codex 상의** (디자인 톤, 한국어, 명리학 표현)
2. **mockup 5 참고** — 모든 디자인 결정의 ground truth
3. **gemini -p "..."** (codex 응답 느릴 때)
4. **사용자 대기 큐** 에 적기 (Apple 2FA, 신규 계정 등 진짜 사람만 가능한 일만)

---

## 🎯 완료 기준

- [ ] 모든 화면 Aesop Luxury 톤 (mockup 5 일치)
- [ ] emoji 0개 (한자 + uppercase label 로 대체)
- [ ] flutter analyze clean
- [ ] flutter test 254+/254+ 통과
- [ ] codex Aesop 톤 평가 9.0+
- [ ] Build #30 deploy 성공 → ASC VALID
- [ ] TestFlight 외부 그룹 ganzitester 자동 심사 제출

---

## 📞 한국 사용자 mandate (이전 세션 교훈)

- "디자인이 너무 구려, 고급스럽게" — Aesop Luxury 선택
- "3시간 자율" 패턴 — 묻지 말고 끝까지
- "거짓말 X" — 시간/점수 정확히 보고
- "쉬워야·명확해야·친숙해야·도움이 되어야" — 4 기준 (Aesop 톤도 동일 적용)

새 세션에서 사용자가 "이어서" 한 마디 → 이 문서 읽고 자율 시작.

작성: 2026-05-12, 이전 세션 결과 9.85/10 점.
