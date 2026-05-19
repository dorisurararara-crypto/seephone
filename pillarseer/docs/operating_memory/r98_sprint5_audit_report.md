# R98 Sprint 5 — 사주 변별력 Audit Report

**작성**: sub-agent (read-only audit harness)
**대상 commit**: working tree (dirty — 10 modified files + 4 untracked)
**테스트**: 5 test file × 48 case = ALL PASS
**JSON parse**: OK
**JSON count**: keys 70 / strings 1400 (목표값 일치)
**Verdict**: **FAIL** — JSON 구조와 회귀 테스트는 통과하지만 user-facing 본문에 sprint 2 risk pattern이 대량 잔존해 자연스러움 + 변별력 두 축에서 출시 불가.

---

## 1. PASS/FAIL 한 줄
FAIL — `life_paragraphs.json`에 sprint 2 risk(`분위기 분위기` 12 / `광택 있는 결이` 46 / `단톡 안 한 마디로 분위기` 80 / `분위기예요` 145 / `결을 …풍겨요` 10) 잔존 + S0~S6 7 일주 personality boilerplate 거의 동일.

## 2. Count evidence
| 항목 | 값 | 목표 | 결과 |
|---|---|---|---|
| `life_paragraphs.json` top-level key count | 70 | 70 | PASS |
| `life_paragraphs.json` string entry count | 1400 | 1400 | PASS |
| JSON parse | OK | OK | PASS |
| flutter test (round82_oneline_jargon / natural_prose_joiner / round80_oneline_personalization / round84_today_screen_ctx / r98_korean_josa) | 48/48 pass | all pass | PASS |

## 3. Forbidden phrase evidence (user-facing 본문 기준)

### 3-A. 사용자 OCR 원문 5개 (mandate: 0건)
- "본인 스타일대로 가는 쪽이 정답이에요" → **0건** PASS
- "사람들이 본인을 바로 기억해요" → **0건** PASS
- "그게 오늘 본인의 장점이에요" → **0건** PASS
- "배움이 잘 자리잡는 흐름이에요" → **0건** PASS
- "오늘 충분한 수면 한 시간이" → **0건** PASS

### 3-B. 짧은 금지어 (data 파일 기준 hits 만 노출)
| 금지어 | `life_paragraphs.json` | `saju_deep_slice_*.json` | comment |
|---|---|---|---|
| 결이에요 | 0 | 0 | data 클린 (lib 본문에는 `compatibility_screen.dart` 의도된 합성 결 어귀 다수 — 검토 대상) |
| 시그니처 | 0 | 0 | data 클린 (lib 주석 + `notification_pool_service.dart:172` "그 곡이 너의 시그니처가 돼요" 1건 user-facing — **fix 필요**) |
| 본성이 | 0 | 0 | data 클린 (lib 주석만) |
| 그대로 묻어나요 | 0 | 0 | PASS |
| 자아의 무게로 자리잡고 있어요 | 0 | 0 | PASS |
| 정답이에요 | 0 | 0 | data 클린 (lib에 `new_year_2026_screen.dart` 2건 + `kpop_compat_screen.dart` 2건 — 의도된 풀이 멘트로 보이나 R98 표현 룰 재확인 필요) |
| 두 배로 | 0 | 0 | data 클린 (lib `life_overview_service.dart:89` 1건 "매력이 두 배로 진해져요" user-facing — **fix 필요**) |
| 단정하고 세련된 본성이 | 0 | 0 | PASS |
| 단 한 번의 정답 | 0 | 0 | PASS |
| 다음 분기 전체 | 0 | 0 | PASS |
| 한 단계 위 | 0 | 0 | PASS |
| 본인답게 가는 게 | 0 | 0 | PASS (다만 `본인답게 가는 한 걸음`/`본인 페이스가 본인답게` `saju_deep_slice_*.json`에 다수 존재 — Sprint 7에서 정량 가드 필요) |

### 3-C. `당신` 분포 (user-facing 본문 분류)
- `life_paragraphs.json` / `saju_deep_slice_*.json` → **0건** (반말+본인 톤 통일 PASS)
- `lib/**.dart` → 30 hits. 대부분 user-facing:
  - **l10n 라벨 (intentional)**: `app_localizations_ko.dart` 10건 — `당신의 사주`, `당신은`, `당신의 데이터는…`, `당신의 괘` 등 → R98 톤 정책 결정 필요. 본문은 반말, 라벨은 `당신` 혼용 = 톤 불일치.
  - **본문 (user-facing, fix 후보)**:
    - `daily_service.dart:241` "당신이 여백을 만들어 주면…"
    - `deep_content_service.dart:736` "당신의 $ji 일주는…"
    - `today_event_service.dart:884` "오늘은 당신의 사주가…"
    - `new_year_2026_screen.dart:420-445` 6 분기 본문 모두 `당신` 사용
    - `discover_screen.dart:734,757` "당신이 키워주는 관계 / 당신이 누르는 관계"
    - `date_picking_screen.dart:118,126,134` 3 line
    - `result_screen.dart:843,853,884` 3 line
- **주석/test intentional**: `ziwei_service.dart:274` `lucky_chips_service.dart:8` 톤 가이드 주석만.

## 4. S0~S6 변별력 표

7 일주의 `personality / early_life / wealth_invest / affection.M / affection.F / innate_character.M / innate_character.F` 7 슬롯을 비교.

### 4-A. 변별 성공 (오행/지지 이미지가 일주마다 다름)
| 일주 | 핵심 metaphor (personality 첫 어귀) |
|---|---|
| S0 갑자 | 곧게 자라는 나무 같은 결 (木) |
| S1 신묘 | 단정하고 세련된 손길 (金) |
| S2 병오 | 활기 넘치는 무대 체질 (火) |
| S3 경오 | 강하지만 정 깊은 쇠 (金+火 통근) |
| S4 임자 | 큰 강처럼 흐르는 시야 (水) |
| S5 무진 | 흔들리지 않는 중심 (土) |
| S6 계해 | 작은 빗방울처럼 부드러운 감각 (水) |

→ 첫 어귀 prefix는 7개 모두 unique. **PASS**.

### 4-B. 변별 실패 (boilerplate copy-paste)
같은 카테고리 안에서 metaphor 한 줄만 갈아끼우고 나머지 본문은 동일.

#### `personality` 공통 boilerplate
> "친구들 사이에서 '쟤 은근 진심이다' 라는 평을 자주 들어요. 화가 났을 때는 그 자리에서 표현하는 쪽이고, 오래 묵혀두지 않아요. 한 가지에 깊이 빠지면 주변이 안 보일 정도로 몰입…"

→ S0/S1/S2/S3/S4/S5/S6 personality 후반부 모두 거의 동일 (어미만 변형).

#### `innate_character.M` 공통 boilerplate
> "고유 분위기가 더해져서 친구와 동료 사이에서 본인 색이 또렷하게 자리잡아요. 강하게 누르거나 명령하는 스타일이 아니라, 옆에 두고 싶은 친근한 형/오빠 같은 느낌이 강해요. 의리 있고 한 번 (본인/가까운) 사람이라고 생각한 상대한테는 끝까지 챙기는 모습이 자주 나와요."

→ S0~S6 7 일주 M 7/7 동일. F도 유사.

#### `affection.M` 공통 boilerplate
> "처음의 산뜻한 텐션은 줄어들고 일상에서 챙기고 챙김 받는 자리에 자리 잡아요."
> "사소한 약속을 잘 지키는 본인의 성격이 신뢰로 바뀌어요."
> "몰입할 때 연락이 늦어질 수 있으니, 짧게라도 톡 한 줄 챙기는 (습관/게 핵심이에요)."

→ S0~S6 7 일주 affection.M 6+/7 동일.

#### `wealth_invest` 공통 boilerplate
> "한 곳에 다 넣기보다 분산이 잘 맞고, 단기보다는 1~3년 정도 들고 가는 호흡이 본인 성격에 맞아요. 자기가 잘 아는 분야 안에서 고르면 손맛이 좋아요. 잘 모르는 쪽에 친구 추천만 듣고 들어가는…"

→ S0~S6 7 일주 wealth_invest 7/7 동일.

#### `early_life` 공통 boilerplate
> "어릴 때부터 자기만의 감이 빨리 잡힌 편이에요. 본인이 좋아하는 분야가 정해지면 그때부터 진짜 그 사람 색이 나오기 시작했어요. 고유 분위기 자기 속도가 분명하다는 신호예요."

→ S0~S6 7 일주 early_life 7/7 동일.

### 4-C. 성별 분기 점검
`affection.M` vs `affection.F` 비교 → 성별 분기 첫 어귀는 다르나, 본문 50% 이상 동일 (`고유 분위기가 더해져서 본인이 좋아하는 사람한테는 챙겨주는 걸 아끼지 않는 편이라 상대가 그 사람 곁을 떠나지 못해요. 자기가 다 줘서 자기만 비어지는 일 없게…`).

### 4-D. 한국어 자연스러움 — Sprint 2 risk pattern direct hit
- **`본인 분위기 분위기가 한 자리에 또렷이 자리잡아요`** — line 326, 774 등 (명사 중복 어색)
- **`대표 분위기 분위기가 한 자리에 또렷이 자리잡아요`** — line 550 등
- **`본인 인장 분위기가 한 자리에 또렷이 자리잡아요`** — line 522, 606, 830, 858 등
- **`단톡 안 한 마디로 분위기 풀어주는 분위기예요`** — line 13 (한 문장 안 `분위기` 2회 + `예요`)
- **`광택 있는 결이 사람들 사이에서 또렷이 빛나요`** — line 1342 (sprint 2 risk 직격 phrase)
- **`자기만의 톤 한 곡 같이 듣는 순간이 사랑 표현이에요`** — line 22, 1342 등 8건 (sprint 2 risk 명사+명사 연결)
- **`대표 색깔 한 곡 공유하는 표현이 고유 색깔이에요`** — line 22 (`색깔 한 곡`)

## 5. Sprint 2 risk 유사 패턴 top 20

| # | pattern | hit count (life_paragraphs.json) | sample line |
|---|---|---|---|
| 1 | `단톡 안 한 마디로 분위기 (풀어주는/환기시키는)` + 마침 | **80** | 13, 326, 550, 606, 774, 858, 830 ... |
| 2 | `광택 있는 결이` | **46** | 1342, 그 외 |
| 3 | `톤 한 곡` (`자기만의 톤 한 곡` / `본인만의 톤 한 곡`) | **23** | 22, 530, 615, 783, 951, 1091, 1231, 1259 |
| 4 | `분위기 분위기` (동일 단어 인접) | **12** | 326, 550, 606, 774, 830, 858, 971, 1279 |
| 5 | `결을 .{1,15} 풍겨요` | **10** | 13, 14, 69, 70, 209, 210, 237, 238 |
| 6 | `자기만의 톤 한 곡` (서브셋) | **8** | (3번 포함) |
| 7 | `색 한 곡` / `색깔 한 곡` | **7** | 22, 391, 951 |
| 8 | `인장 분위기` | **6** | 522, 606, 830, 858 |
| 9 | `대표 분위기` (`대표 분위기예요`) | 7 | 391, 530, 1342 |
| 10 | `본진 굿즈 챙기듯` | 14 | 363, 783, 1007, 1091, 1231 |
| 11 | `본진 친구들 사이에서` | 6 | 317, 345 |
| 12 | `본인 인장 한 가지로` / `본인 스타일 한 가지로` (X 한 가지로) | 9 | 326, 971, 1279 |
| 13 | `평소 자기 무게로 풍겨요` (boilerplate intro) | 28 | M/F intro 거의 전체 |
| 14 | `한 마디로 분위기 전체를 바꿔놓는` | 4 | 무진계열 |
| 15 | `같은 매력 위에 고유 분위기가 (더해져서/합쳐져서)` | 40+ | innate_character boilerplate |
| 16 | `친구들 사이에서 '쟤 은근 진심이다' 라는 평을 자주 들어요` | 21+ | personality boilerplate |
| 17 | `옆에 두고 싶은 친근한 형/오빠 같은 느낌이 강해요` | 20+ | innate_character.M boilerplate |
| 18 | `상대가 그 사람 곁을 떠나지 못해요` / `상대가 본인 곁을 떠나지 못해요` | 30+ | affection.F boilerplate |
| 19 | `한 분야 본인 분위기로 자리잡는 흐름이 매력이에요` | 12 | 무진/임자/계해 등 |
| 20 | `30·40대 들어 … 빛나기 시작해요` (mid_life intro) | 60 | 모든 60 일주 mid_life |

## 6. 반드시 고쳐야 할 문장 (P0)

코드/data 위치 기준:
1. `assets/data/life_paragraphs.json:13` `갑자.innate_character.M` 끝: `단톡 안 한 마디로 분위기 풀어주는 분위기예요.` → `분위기` 2회 + `예요` 마침. **명백한 어색 sprint 2 risk 직격**.
2. `assets/data/life_paragraphs.json:326` `갑인.innate_character.M`: `본인 분위기 분위기가 한 자리에 또렷이 자리잡아요.` → 명사 중복.
3. `assets/data/life_paragraphs.json:550` `정묘.innate_character.M`: `대표 분위기 분위기가 한 자리에 또렷이 자리잡아요.` → 명사 중복.
4. `assets/data/life_paragraphs.json:1342` `신유.affection.M`: `광택 있는 결이 사람들 사이에서 또렷이 빛나요.` → sprint 2 risk phrase 직격.
5. `assets/data/life_paragraphs.json:13~979 (전체 30+ 줄)` `단톡 안 한 마디로 분위기 풀어주는 (분위기/리듬/색/톤/느낌/인상/스타일)예요.` → 끝 명사만 바꾼 동일 boilerplate 30+회 반복.
6. `assets/data/life_paragraphs.json` 전체 일주 60개 `personality` slot — 일주마다 첫 어귀(자연 metaphor)만 다르고 후반부 boilerplate (`친구들 사이에서 '쟤 은근 진심이다' 라는 평…`) 동일 → 변별력 0.
7. `assets/data/life_paragraphs.json` 60 일주 `wealth_invest` slot — `한 곳에 다 넣기보다 분산이 잘 맞고, 단기보다는 1~3년` 등 60건 거의 동일.
8. `assets/data/life_paragraphs.json` 60 일주 `innate_character.M` slot — `옆에 두고 싶은 친근한 형/오빠` boilerplate 60건 거의 동일.
9. `lib/services/life_overview_service.dart:89` `매력이 두 배로 진해져요` → 금지어 `두 배로` user-facing.
10. `lib/services/notification_pool_service.dart:172` `그 곡이 너의 시그니처가 돼요` → 금지어 `시그니처` user-facing.

## 7. Sprint 7 test로 고정할 추천 case top 5

**모두 source mutation 없이 read-only assert. dirty 파일 건드리지 않음.**

### Case 1 — `life_paragraphs.json` 60 일주 `personality` 후반부 변별력 가드 (P0)
```dart
test('R98 sprint 7 — personality 후반부 boilerplate 60 일주 unique-suffix 60% 이상', () {
  final data = jsonDecode(File('assets/data/life_paragraphs.json').readAsStringSync());
  final tails = <String>[];
  data.forEach((k, v) {
    if (v is Map && v['personality'] is String) {
      final s = v['personality'] as String;
      // 첫 metaphor 어귀 (첫 마침표) 제거 후 후반부 hash
      final idx = s.indexOf('.');
      if (idx > 0) tails.add(s.substring(idx + 1));
    }
  });
  final uniq = tails.toSet().length;
  expect(uniq / tails.length, greaterThan(0.6),
    reason: 'personality 후반부 변별 — 현재 boilerplate 동일 비율 ~85%');
});
```

### Case 2 — sprint 2 risk 정량 가드 (P0)
```dart
test('R98 sprint 7 — life_paragraphs.json sprint 2 risk 패턴 0', () {
  final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
  final risks = {
    '분위기 분위기': RegExp(r'분위기 분위기'),
    '광택 있는 결이': RegExp(r'광택 있는 결이'),
    '단톡 안 한 마디로 분위기': RegExp(r'단톡 안 한 마디로 분위기'),
    '결을 …풍겨요': RegExp(r'결을 .{1,15}풍겨요'),
    '자기만의 톤 한 곡': RegExp(r'(자기만의|본인만의|본인다운 색|대표 분위기|대표 색깔|고유한 색깔) 한 곡'),
  };
  risks.forEach((label, re) {
    final n = re.allMatches(raw).length;
    expect(n, 0, reason: '$label hit $n 회 (R98 sprint 5 audit 기준 baseline: 분위기 분위기 12 / 광택 있는 결이 46 / 단톡 80 / 결을 풍겨요 10 / 톤 한 곡 23)');
  });
});
```

### Case 3 — innate_character M boilerplate 한 줄 가드 (P0)
```dart
test('R98 sprint 7 — innate_character.M "옆에 두고 싶은 친근한 형/오빠" boilerplate 빈도 ≤ 5 일주', () {
  final data = jsonDecode(File('assets/data/life_paragraphs.json').readAsStringSync());
  int hit = 0;
  data.forEach((k, v) {
    final s = (v is Map ? v['innate_character'] is Map ? v['innate_character']['M'] : null : null);
    if (s is String && s.contains('옆에 두고 싶은 친근한 형/오빠')) hit++;
  });
  expect(hit, lessThanOrEqualTo(5),
    reason: '현재 60+ 일주 중 20+ 일주 동일 boilerplate — 변별력 0');
});
```

### Case 4 — wealth_invest 60 일주 분산 boilerplate 가드 (P1)
```dart
test('R98 sprint 7 — wealth_invest 60 일주 "1~3년 정도 들고 가는" boilerplate 빈도 ≤ 10', () {
  final data = jsonDecode(File('assets/data/life_paragraphs.json').readAsStringSync());
  int hit = 0;
  data.forEach((k, v) {
    final s = v is Map ? v['wealth_invest'] : null;
    if (s is String && s.contains('1~3년 정도 들고 가는')) hit++;
  });
  expect(hit, lessThanOrEqualTo(10),
    reason: 'wealth_invest copy-paste boilerplate');
});
```

### Case 5 — `당신` user-facing 본문 가드 (P1)
```dart
test('R98 sprint 7 — life_paragraphs.json + saju_deep_slice 당신 0 / lib user-facing ≤ l10n 라벨 한정', () {
  for (final p in ['life_paragraphs.json','saju_deep_slice_0_19.json','saju_deep_slice_20_39.json','saju_deep_slice_40_59.json']) {
    final raw = File('assets/data/$p').readAsStringSync();
    expect(RegExp(r'당신(은|의|이|에게)').hasMatch(raw), false,
      reason: '$p user-facing 본문에 "당신" 사용 — 반말+본인 톤 통일 룰 위반');
  }
});
```

## 8. 실행한 명령과 결과

```bash
$ git status --short
 M assets/data/life_paragraphs.json
 M assets/data/saju_deep_slice_0_19.json
 M assets/data/saju_deep_slice_20_39.json
 M assets/data/saju_deep_slice_40_59.json
 M lib/screens/home_screen.dart
 M lib/screens/reports/compatibility_screen.dart
 M lib/screens/reports/kpop_compat_screen.dart
 M lib/services/dynamic_text_resolver.dart
 M lib/services/personalization_engine.dart
 M lib/services/today_deep_service.dart
?? docs/operating_memory/r98_sprint1_baseline.md
?? docs/operating_memory/r98_sprint6_benchmark.md
?? lib/services/korean_josa.dart
?? test/r98_korean_josa_test.dart
→ dirty (사용자/다른 agent 작업 — 본 audit는 read-only)

$ jq 'keys | length' assets/data/life_paragraphs.json
70

$ jq '[.. | strings] | length' assets/data/life_paragraphs.json
1400

$ rg -n "결이에요|시그니처|본성이|그대로 묻어나요|자아의 무게로 자리잡고 있어요|정답이에요|두 배로" assets/data/life_paragraphs.json lib assets/data/saju_deep_slice_*.json
→ data 파일 0건 (PASS). lib 비결정 hits 8건 (위 3-B 표 참조 — `notification_pool_service.dart:172` 시그니처 / `life_overview_service.dart:89` 두 배로 = user-facing fix 필요)

$ rg -n "단 한 번의 정답|다음 분기 전체|한 단계 위|본인답게 가는 게|단정하고 세련된 본성이"
→ 0건 (PASS)

$ rg -n "본인 스타일대로 가는 쪽이 정답이에요|사람들이 본인을 바로 기억해요|그게 오늘 본인의 장점이에요|배움이 잘 자리잡는 흐름이에요|오늘 충분한 수면 한 시간이"
→ 0건 (사용자 OCR 원문 PASS)

$ rg -c "분위기 분위기" assets/data/life_paragraphs.json → 12
$ rg -c "인장 분위기" assets/data/life_paragraphs.json → 6
$ rg -c "단톡 안 한 마디로 분위기" assets/data/life_paragraphs.json → 80
$ rg -c "광택 있는 결이" assets/data/life_paragraphs.json → 46
$ rg -c "톤 한 곡" assets/data/life_paragraphs.json → 23
$ rg -c "색 한 곡" assets/data/life_paragraphs.json → 7
$ rg -c "분위기예요" assets/data/life_paragraphs.json → 145
$ rg -c "결을 .{1,15}풍겨요" assets/data/life_paragraphs.json → 10
$ rg -c "자기만의 톤 한 곡" assets/data/life_paragraphs.json → 8

$ flutter test test/round82_oneline_jargon_test.dart test/natural_prose_joiner_test.dart test/round80_oneline_personalization_test.dart test/round84_today_screen_ctx_test.dart test/r98_korean_josa_test.dart
→ All 48 tests passed!
```

## 9. 권고 (Codex head 결정용)

- **JSON 구조·5 회귀 테스트 통과** → 5행 골든 + R69 lock + R71~R80 시그니처 보존 PASS.
- **본문 자연스러움 + 변별력은 출시 불가**. 사용자가 1.0.0+58 외부 베타로 실기기 검증 시 보일 위험 phrase 다수.
- **Source mutation 권고 안 함** (read-only audit). Codex head가 Sprint 6 generator agent에 다음 4개 task 던지는 게 안전:
  1. `life_paragraphs.json` 60 일주 × 7+ slot 후반부 boilerplate를 **일주 고유 metaphor anchor 기반**으로 재생성 (단, 5행 골든 + R69 lock 토큰은 보존).
  2. `분위기 분위기` / `광택 있는 결이` / `단톡 안 한 마디로 분위기` 3대 risk phrase **정량 0 달성** 후 Sprint 7 가드 test로 회귀 잠금.
  3. `lib/services/notification_pool_service.dart:172` + `life_overview_service.dart:89` 2 line **단발 fix** (R98 lexicon 위반).
  4. `l10n` 라벨 vs 본문 `당신` 톤 통일 정책 결정 (Codex head). 본문 0건은 PASS, 라벨이 `당신`이면 정책으로 OK / 본문도 `당신`이면 lib 9 hits fix.

— end of audit report —

---

## R98 Sprint 7 correction note (2026-05-19)

Sprint 2-bis 보고서가 명시한 `"한 가지에 깊이 빠지면 주변이 안 보일 정도로 몰입"` count 30 은 stale/outdated 였고, fresh worktree 기준 Sprint 7 guard 실측은 61 이었다 (threshold 35 통과 못 함). R98 Sprint 7 fix 에서 36 개 personality 라인을 일주별 고유 metaphor 문구로 다양화하여 25 로 감축 (≤ 30 mandate 달성, threshold 35 보존, 5행 골든 + R69 lock + Sprint 2 risk phrase 0 모두 회귀 없음).

