# R101 Sprint 1 — 한국어 본문 영문 leak + 메뉴 개편 + 신규 팬심 1/2순위 Baseline

> Status: baseline measurement only (no source/asset/test edits)
> Audited at: 2026-05-19 KST
> Auditor: R101 sprint 1 sub-agent (read-only)
> Scope: 사용자 mandate verbatim — "왜 한국어에 영어가 들어와? 그냥 최애와의 궁합보기로 메뉴명을 바꾸고 우리 궁합보는거 그대로 사용해서 설명나오게 해줘 그냥 우리 앱에 있는 궁합보기를 연예인이랑 하는 느낌이라고 생각하면돼 설명도 그대로 해주고 그리고 새로운 메뉴를 만들거야 이 메뉴야 이걸 팬심 1순위로 해주고 디지털 처방전을 2순위 최애와 궁합보기를 팬심 3순위로해줘"
> 절대 룰: 본 sprint 중 어떤 lib/assets/test 도 수정하지 않음. baseline 측정 + sprint 2~7 작업 범위만.

---

## 0. git status snapshot

```
(clean)
```

Recent commits: `34e194e` (1.0.0+60 R100 케미 본문 반복감 일소 외부 베타 자동 제출), `02fbf29` (R99 영문 자연 정제), `eff85eb` (R98 본문 자연 한국어 정제).

---

## 1. Menu / route inventory — `lib/screens/reports/reports_home_screen.dart` (305 lines)

### 1.1 현재 노출 카드 (4장, build() 안에 inline `final cards = <_Card>[...]`, 위치 line 21~56)

| 순서 | eyebrow (KO) | title (KO) | route | size | 진입점 file |
|---:|---|---|---|---|---|
| **1** | `'팬심 1순위 · FAN PICK'` | **`'최애와 케미'`** | `/reports/kpop-compat` | hero (badge + accent) | `lib/screens/reports/kpop_compat_screen.dart` (4,352 lines) |
| 2 | `'연애 · 인간관계'` | `'궁합 보기'` | `/reports/compatibility` | large | `lib/screens/reports/compatibility_screen.dart` (2,535 lines) |
| 3 | `'올해 흐름'` | `'2026 신년운세'` | `/reports/new-year-2026` | normal | `lib/screens/reports/new_year_2026_screen.dart` |
| 4 | `'가볍게 보기'` | `'꿈 풀이'` | `/reports/dream` | normal | `lib/screens/reports/dream_screen.dart` |

### 1.2 hero badge (line 226~248)
- `if (isHero) ...` block 안에 `'팬심 1순위 · TOP PICK'` 라벨. 사용자 mandate 와 충돌 → sprint 3 에서 신규 1순위 카드가 hero badge 차지.
- 색상: `AppColors.accent` 배경 + 흰 글씨.

### 1.3 K-POP 케미 vs 일반 궁합 메뉴명 (사용자 verbatim 차이)

| 현재 (코드) | 사용자 요청 |
|---|---|
| `'최애와 케미'` (라벨, hero, line 25) → `kpop-compat` route | **`'최애와의 궁합보기'` 로 메뉴명 변경**. 진입 후 본문은 `compatibility_screen.dart` 의 5섹션 그대로 사용. 셀럽 picker 만 유지 (사용자: "연예인이랑 하는 느낌"). |
| `'궁합 보기'` (line 33) → `compatibility-screen` route | 메뉴 자체는 유지될지 미정. 본문 엔진을 셀럽 어댑터에서 재사용 → 향후 일반 궁합 카드는 보존 가능. |

### 1.4 router 등록 (`lib/router.dart`)
- line 17: `import 'screens/reports/kpop_compat_screen.dart';`
- line 38: protected 목록 `/reports/kpop-compat`
- line 102~105: `GoRoute(path: '/reports/kpop-compat', builder: ... KpopCompatScreen())`
- 즉 sprint 3 의 메뉴 개편은 reports_home_screen.dart 의 cards 리스트만 손대면 충분, route 자체는 그대로 보존 가능 (label 만 교체).

### 1.5 "팬심" 카테고리 prior art
- 현재 reports_home_screen.dart 안에 `'팬심 1순위 · FAN PICK'` eyebrow 와 `'팬심 1순위 · TOP PICK'` hero badge **단 1곳** (R87 sprint 1 cmt). 별도 카테고리 enum / 분류 모델은 없음 — pure label.
- 따라서 sprint 3 의 "팬심 1순위 (전생) / 2순위 (처방전) / 3순위 (최애 케미)" 우선순위는 카드 순서 + eyebrow 문자열만 재배치하면 됨.

### 1.6 메뉴 순서 코드 위치
- `reports_home_screen.dart` line 21~56 의 `cards = <_Card>[...]` 리스트 순서 자체.
- line 148~153 의 `cards.asMap().entries.map((e) => _CardRow(card: e.value, highlight: e.key == 0, ...))` 에서 index 0 만 highlight + hero treatment.

---

## 2. 영문 leak baseline — `lib/screens/reports/kpop_compat_screen.dart` (4,352 lines)

### 2.1 핵심 root cause — `dayPillarName` field

`assets/data/celebrities.json` (223명) 의 **모든 `dayPillarName` 값이 영어 element+animal 표기**:

```json
"dayPillarName": "Fire Rabbit"       // IU
"dayPillarName": "Water Rat"         // Jennie
"dayPillarName": "Water Rabbit"      // 홍은채 (LE SSERAFIM)
"dayPillarName": "Water Dog"         // 솔라, 운학 등
"dayPillarName": "Earth Tiger"       // Mingyu 등
... (총 60 갑자 중 47종 사용)
```

`jq -r '.[].dayPillarName' assets/data/celebrities.json | sort -u | wc -l` → **47**.

이 영문 라벨이 KO 본문에 6+ 위치에서 직접 inject 되고 있음.

### 2.2 사용자 OCR 4 line source 매핑

| 사용자 OCR | source line | injection path |
|---|---|---|
| **"홍은채가 Water Rabbit 일주가 그린 AFIM 홍은채"** | `kpop_compat_screen.dart` **L1562**, **L1574**, **L1559**, **L1566**, **L1567**, **L1571**, **L1576**, **L1578**, **L1582** (FAM 2 8 skeleton) | `'$shortName, $pillarTag 일주가 그린 $blurbExtra.'` 등에서 `pillarTag = pillarName = star.dayPillarName` (= `"Water Rabbit"`) 직접 inject. `blurbExtra` 는 blurbKo 의 뒤절반 → `"AFIM 홍은채"` (= "LE SSERAFIM 홍은채" 의 절단된 후반부). OCR `"AFIM"` 은 blurbExtra slicing (L1430~1444) 의 결과로 `LE SS` 앞이 잘림. |
| **"복합 anchor 가 같이 걸린"** | `kpop_compat_screen.dart` **L2404** | `_composeScoreBandTexture()` band 5종 중 하나의 KO prefix: `'복합 anchor 가 같이 걸린 진한 흐름 — '`. **"anchor" 한글 본문 그대로 노출**. |
| **"홍은채 단 한 줄 — LE SSERAFIM 홍은채"** | `kpop_compat_screen.dart` **L3473** (`_closerPoolKo[42]`) | `r'$shortName 단 한 줄 — $blurbTail 너의 결이 옆에 있으면 그 한 줄이 둘만의 시그니처가 돼요.'`. `blurbTail = blurbKo` (예: `"LE SSERAFIM 홍은채. 기본 성향은..."`) → 시작이 영어 그룹명. 셀럽 blurbKo 의 **62/223 (28%)** 가 영문 그룹명으로 시작 (`LE SSERAFIM / BLACKPINK / SEVENTEEN / BTS / TWICE / aespa / IVE / ITZY / STAYC / ATEEZ / TXT / ZEROBASEONE / RIIZE / BOYNEXTDOOR / ILLIT / TWS / XG / BABYMONSTER / NCT / KISS OF LIFE / ENHYPEN / Stray Kids / 2PM / SHINee / EXO / MAMAMOO / fromis / fifty / MEOVV / tripleS / VIVIZ` 등). |

### 2.3 영문 leak 위치 통계

| 패턴 | KO 본문 안 노출 count |
|---|---:|
| `"anchor"` 한글 본문 (kpop_compat_screen.dart) | **311** matches (L2104~2146 NONE pool 48종 + band prefix L2404 + 기타) |
| `"anchor"` 한글 본문 (compatibility_screen.dart) | **20** matches (L1606, L1608, L1782, L1902, L2009, L2246 등 KO branch + EN branch 혼합) |
| `dayPillarName` 영문 KO 본문 inject (kpop_compat) | **L1482, L1486, L1494, L1498, L1556, L1559, L1562, L1566, L1567, L1571, L1574, L1576, L1578, L1582, L1624** (15+ skeleton lines) |
| `blurbKo` 의 영문 그룹명 head (`LE SSERAFIM / BLACKPINK / ...`) | celebrities.json **62/223** (28%) — `_closerPoolKo` 48종 + `_starIdentityLead` FAM 0 8 skeleton 에 inject |
| `"day pillar"` EN-only text 가 EN branch 인데 KO 사용자 환경에서 노출 위험 0 (lang flag 분기됨) | 0 |
| `"signature"` KO 본문 inject | 0 (단 `r'$shortName 단 한 줄 — ... 둘만의 시그니처가 돼요'` 한국어 시그니처 형태 1곳 OK) |

### 2.4 P0 → P2 fix list (sprint 2 scope)

| 우선순위 | 위치 | 현재 | 목표 |
|---|---|---|---|
| **P0-1** | `kpop_compat_screen.dart` L1403 `final pillarName = star.dayPillarName.trim();` | `"Water Rabbit"` 영문 그대로 사용 → L1556~1582 FAM 2 8 skeleton 모두 KO 본문에 영문 inject | KO 분기에서 `pillarName` 을 `star.dayPillar` (한자 2자) + `pairKorean` (한글 음, 예: `"계묘"`) 로 치환. EN 분기는 영문 그대로 유지. |
| **P0-2** | `kpop_compat_screen.dart` L2404 `'복합 anchor 가 같이 걸린 진한 흐름 — '` | `"anchor"` 단어 KO 본문 노출 | 자연 한국어 ("복합 흐름이 같이 걸린 진한 자리 —" 등) |
| **P0-3** | `kpop_compat_screen.dart` L2104~2146 NONE relPool KO 48개 중 21줄 | `"직접 anchor 가 없는..."` , `"합·충 anchor 없는..."` 등 21줄에 `anchor` 평문 | `"직접 신호 없는..."` , `"합·충 자리 없는..."` 등 한국어 단어로 |
| **P0-4** | `kpop_compat_screen.dart` `_closerPoolKo` 48종 (L3430~3478) | `$blurbTail` inject 결과 `"LE SSERAFIM 홍은채"` 같은 영문 그룹명이 KO closer 본문 헤드로 노출 | (a) `blurbTail` 추출시 영문 그룹명 prefix 제거, 또는 (b) celebrities.json `blurbKo` 의 영문 그룹명 head 62건을 한국어 표기로 정규화 (`LE SSERAFIM → 르세라핌` 등). 옵션 (a) 안전. |
| **P0-5** | `compatibility_screen.dart` L1606, L1608, L1782, L1902, L2009, L2246, L1504, L1528, L1958 | `"오행 직접 anchor 없는 자리"`, `"$pName 직접 anchor 없는 결"`, `"오행 보완 anchor 까지 추가로 걸려 있어요"`, `"객관적 anchor 자리"` 등 13곳 KO 본문 anchor 잔존 | 한국어 단어로 |
| **P1** | `lib/services/today_deep_service.dart`, `personalization_engine.dart`, `life_paragraph_service.dart`, `today_event_service.dart`, `notification_pool_service.dart` 등 30+ source 의 `anchor` 변수명·주석 | 변수·주석은 위험 0 (compile-only) — 본문 inject 만 잡으면 됨 | 노출 string literal 만 scan |
| **P1** | `assets/data/saju_deep_slice_*.json`, `life_fragments.json`, `wealth_detail.json`, `sipsin_persona.json` 의 EN-only field 내 `"anchor"`, `"signature"` | EN 사용자 노출용이므로 OK | 유지 |
| **P2** | `assets/data/celebrities.json` `blurbKo` 의 영문 그룹명 prefix 62/223 | 사용자 mandate `"왜 한국어에 영어가 들어와"` 직격 — 다만 브랜드 표기는 일부 허용 가능 (`BTS`, `BLACKPINK` 는 한국 미디어 표기 그대로 쓰임) | (a) 한국 미디어 표준 한국어 표기 (`르세라핌`, `세븐틴`) 로 정규화 또는 (b) 닫는 한국어 음 + 영문 병기 (`LE SSERAFIM 르세라핌`) 가능. 본 R101 sprint 2 는 P0 만 처리, P2 는 sprint 3 이후. |

### 2.5 영문 leak 외 (확인 후 제외)
- `"day pillar"` substring 은 kpop_compat_screen 의 EN branch 에만 9곳 — KO 사용자 화면에선 노출 0.
- `pairEnglish` (`SajuResult.pairEnglish`, L97 `'Fire Rabbit'` 등 영문 생성기) 는 KO 본문 inject 0 (영문 본문에서만 사용).
- `theme/app_theme.dart` L67 의 `Fire Rabbit` 은 주석.
- `new_year_2026_screen.dart` L191 `'병오년 · 火 馬' / 'Year of Fire Horse'` — KO branch 분기됨.

---

## 3. kpop_compat_screen.dart inventory (4,352 lines — R100 sprint 2 에서 2,262 → 4,352)

### 3.1 entry / outer wrapper 보존 후보 (sprint 4 thin wrapper 검토 시)
- `class KpopCompatScreen extends StatefulWidget` — `/reports/kpop-compat` route 진입점, **반드시 보존**.
- `_KpopCompatScreenState` 의 `build()` — TOP 1 hero + ranked list ListView, **반드시 보존**.
- `_Star` model class (L4280+) — celebrities.json deserialize. **보존**.
- `_KpopAnchors` static class (L4000~) — `relCueKo / elKoOf / jiSceneKo / saltedPick / closerPool` 등 helper. **보존**.

### 3.2 sprint 4 (선택) — thin wrapper 가능성
- `_composeVerdict()` (L1230~1342) 4 paragraph 본문 합성을 **`compatibility_screen.dart` 의 `_analyze()` 5섹션 호출로 대체** 시:
  - 사용자 mandate `"우리 궁합보는거 그대로 사용해서 설명나오게 해줘"` 직접 충족.
  - `_starIdentityLead()` (L1369~1685) + `_composeDailyBreathDetail()` + `_composeScoreBandTexture()` + `_KpopAnchors.relationVariant()` + `_KpopAnchors.closerVariant()` 의 ~2,500 라인이 dead code 가 됨. **삭제 X, 보존 (R100 회귀 가드 유지용)**.
  - 신규 wire: 셀럽을 SajuResult 로 변환 (`_Star → SajuResult adapter`) 한 후 `compatibility_screen._analyze(me, celebSaju, useKo, partnerName: star.nameKo)` 호출 → `_CompatAnalysis` 결과의 5섹션을 detail dialog 에 표시.
  - 보존해야 할 entry: `_openDetail(star)` → `showModalBottomSheet` 또는 `Navigator.push` route. dialog 의 외형/공유 버튼/TopMatchCard 는 유지.

### 3.3 셀럽 picker UI 현 상태
- TOP 1 hero card (L455 `"오늘의 케미 1위 · TOP MATCH"`) → score 가장 높은 셀럽 1명.
- ranked list — score 내림차순 223 셀럽. 필터 가능 (kind: idol/actor/athlete, gender, group 등).
- detail open → 4 paragraph (R100) → sprint 4 가 compatibility _analyze 5섹션으로 교체.

### 3.4 dayPillarName 사용 위치 전수
- L979: `'${star.dayPillarName.toUpperCase()} · ${star.kind.toUpperCase()}'` (ranked list eyebrow) — **영문 그대로 노출 (KO/EN 무관)**
- L1120: `'${star.dayPillar} · ${star.dayPillarName}'` (detail header) — KO 사용자 화면에 영문 노출
- L1403 → L1482, 1486, 1494, 1498, 1556, 1559, 1562, 1566, 1567, 1571, 1574, 1576, 1578, 1582, 1624 (KO 본문 inject 15곳)
- L4294, L4307, L4320: model field 정의 — 보존

→ **sprint 2 에서 KO 분기에 KO 음 (pairKorean) 또는 한자 (dayPillar) 만 inject 하도록 4 곳 (L979, L1120, L1403, _starIdentityLead KO branch) 수정 필요**.

---

## 4. compatibility_screen.dart inventory (2,535 lines)

### 4.1 `_analyze()` signature
```dart
_CompatAnalysis _analyze(
  SajuResult me,
  SajuResult partner,
  bool useKo, {
  String? partnerName,
}) { ... }
```
- 위치: L1419~1810 (391 lines).
- 반환: `_CompatAnalysis` — 5 섹션 (`summary` / `attract` / `friction` / `loveMarriage` / `actions`) 한 덩이.
- 외부 진입: L1108 `final a = _analyze(me, partner, useKo, partnerName: partnerName);` (`_DetailSection`).
- public wrapper: L2466 `_DetailSection.analyze()` (regression test 진입점).

### 4.2 외부 진입 (partner picker / saju input 단계)
- `compatibility_screen.dart` 자체에 partner 입력 UI 가 있음 (사주 4기둥 직접 입력 또는 셀럽 검색).
- sprint 4 의 kpop_compat 통합 시: `_analyze(me, celebSaju, useKo, partnerName: star.nameKo)` 호출 — `celebSaju` 는 `_Star.dayPillar` 한자 2자 + `_Star.birth` 로 `SajuService.compute()` 또는 light adapter 로 생성.

### 4.3 영문 leak 0 확인 — **FAIL (12 잔존)**
- L1606, 1608 `'오행 직접 anchor 없는 자리'`, `'$pName 와 직접 anchor 없는 결'` 등
- L1782 `'\n\n오행 보완 anchor 까지 추가로 걸려 있어요'`
- L1902 `'직접 anchor 없는 중립'`
- L2009 `'【객관적 anchor 자리】'`
- L2246 `'【연애】 직접 anchor 없는 중립 결'`
- L1285 `'土→火': 'Earth→Fire (reverse) — they ground your fire; even when you spike, you stay anchored.'` (EN-only OK)

→ **sprint 2 에서 compat KO 본문 12곳 anchor → 한국어** 동시 처리.

---

## 5. assets/data 영문 leak

### 5.1 `celebrities.json` (223)
- `dayPillarName` 47종 모두 영문 — **P0-1**.
- `blurbKo` 의 **62/223 (28%)** 가 영문 그룹명 head 로 시작 — **P2** (sprint 3 이후, 단 closer inject 에서 즉시 노출되므로 P0-4 와 같이 처리).
- `nameEn` 영문, `nameKo` 한국어 — 정상.

### 5.2 `life_paragraphs.json`, `saju_deep_slice_*.json` (R98 처리 후)
- `saju_deep_slice_*.json` 의 `anchor / signature / day master` 7곳은 모두 `"fame": "..."`, `"family": "..."`, `"dayMasterDeep": "..."` 같은 **EN-only field** — KO 사용자 노출 0. 유지.
- `life_paragraphs.json` — `anchor` 0 hits.
- `life_fragments.json` — `anchor` 2 hits (EN field).
- `wealth_detail.json`, `sipsin_persona.json`, `life_stage_pool.json`, `career_pool.json` — `anchor` 각 1 hit (EN field).

### 5.3 `dreams.json`, `today_event_pool.json`
- `anchor` 0. clean.

### 5.4 정리
- assets/data **KO 본문 영문 leak = celebrities.json `dayPillarName` (47/223) + `blurbKo` 영문 그룹명 head (62/223) 두 종류만**. 나머지 모든 anchor/signature/day master 잔존은 EN field 한정.

---

## 6. Sprint 2~7 file 별 작업 범위 추정

### Sprint 2 — P0 영문 leak 일소 (KO 사용자 화면 0 leak)
| File | 변경 범위 |
|---|---|
| `lib/screens/reports/kpop_compat_screen.dart` | (a) L1403 `pillarName` 가 KO branch 에서 `pairKorean` (`star.dayPillar` → korean reading) 또는 한자 (`star.dayPillar`) 사용. (b) L2404 band prefix `"복합 anchor"` → 한국어. (c) L2104~2146 KO NONE pool 48개 중 21줄 `anchor` → 한국어. (d) L3430~3478 closer KO 48 의 `$blurbTail` 영문 head 보호 — `_blurbTailClean()` helper 신규. (e) L979 ranked list eyebrow / L1120 detail header `dayPillarName` 영문 노출 → KO 분기에서 한자 또는 한국어 음 |
| `lib/screens/reports/compatibility_screen.dart` | L1504, L1528, L1606, L1608, L1782, L1902, L1958, L2009, L2246 등 KO 본문 anchor 12곳 → 한국어 |
| `test/r99_english_quality_guard_test.dart` (확장) 또는 신규 `test/r101_korean_no_english_leak_test.dart` | (a) `kpop_compat_screen.dart _starIdentityLead()` 결과 KO 본문에 `"Water|Wood|Fire|Earth|Metal"` 어절 0. (b) `_composeScoreBandTexture` KO 본문 `"anchor"` 0. (c) `_analyze()` KO 결과 5섹션 합본 `"anchor"` 0. (d) celebrities.json 의 `dayPillarName` 영문 47종이 KO 본문 inject path 에서 노출되지 않음 |

### Sprint 3 — 메뉴 개편
| File | 변경 범위 |
|---|---|
| `lib/screens/reports/reports_home_screen.dart` | (a) L21~56 cards 리스트 재구성 — `[전생 시나리오(hero), 기운 처방전(large), 최애와의 궁합보기(large)]` + 기존 `2026 신년운세 / 꿈 풀이` 보존 또는 정리. (b) L25 `'최애와 케미'` → `'최애와의 궁합보기'`. (c) hero badge label 유지 (line 238). (d) 신규 1순위 카드 route `/reports/past-life` 추가. (e) 신규 2순위 카드 route `/reports/energy-prescription` 추가. |
| `lib/router.dart` | 신규 2 route 추가 + protected 목록 확장. |
| `lib/l10n/app_ko.arb`, `app_en.arb`, `app_localizations*.dart` | reports home 신규 label (optional, 현재 inline string 이라 필수 아님) |

### Sprint 4 — kpop_compat 본문 엔진을 compatibility _analyze 로 교체
| File | 변경 범위 |
|---|---|
| `lib/screens/reports/kpop_compat_screen.dart` | (a) detail dialog 의 `_composeVerdict()` 호출 → `_compatAdapter(star, me, useKo)` 호출로 교체. (b) adapter 가 `_Star → SajuResult` 변환 후 `_DetailSection._analyze()` 호출 → 5섹션 본문 표시. (c) 기존 verdict 4 paragraph 코드 (~2,500 line) 는 dead code 보존 (R100 회귀 가드용). |
| `lib/screens/reports/compatibility_screen.dart` | `_DetailSection._analyze()` public 노출 (이미 L2466 wrapper 존재). 메서드 signature 보존. |
| `test/r101_celeb_compat_uses_analyze_test.dart` (신규) | (a) 셀럽 1명 detail 결과가 `_analyze()` 결과와 같은 5섹션 구조. (b) `_composeVerdict()` 호출 0. |

### Sprint 5 — 전생 시나리오 (팬심 1순위) 데이터 model + 화면
| File | 변경 범위 |
|---|---|
| `lib/services/past_life_service.dart` (신규) | 사주 keyword 7종 (원진살 / 도화살 / 역마살 / 천을귀인 / 공망 / 합 / 충) 기반 전생 시나리오 생성. **재사용**: `shinsa_service.dart` (역마/도화/천을귀인), `gong_mang_service.dart` (공망), `hapchung_service.dart` (천간합/지지합/충/형). **신규**: 원진살 (子-未, 丑-午, 寅-酉, 卯-申, 辰-亥, 巳-戌). |
| `assets/data/past_life_pool.json` (신규) | keyword 별 시나리오 templates. **사용자 verbatim 예시**: 원진살 → `"이번 생에서도 솔라에게 돈 뺏기지만 행복할 운명"`. 셀럽×사용자 별 시나리오 1개씩 (~223 = 셀럽 수 × 셀럽 사주 키워드 N개). 또는 keyword 별 generic template + 셀럽 이름 inject. |
| `lib/screens/reports/past_life_screen.dart` (신규) | 화면 — `/reports/past-life` route. 셀럽 picker → 시나리오 표시. 본문 카드형. |

### Sprint 6 — 기운 처방전 (팬심 2순위) 데이터 model + 화면
| File | 변경 범위 |
|---|---|
| `lib/services/energy_prescription_service.dart` (신규) | (a) 사용자 5행 분포 추출 — `me.elements.deficit` (이미 `SajuResult.elements.deficit` 존재, `lib/models/saju_result.dart` L26). (b) 부족 5행 = argmin (이미 `FiveElements.deficit` getter). (c) 셀럽 5행 매핑 — `_Star.dayPillar.chunGanElement` (천간 5행). (d) 처방 = 사용자 deficit 5행 = 셀럽 dayPillar 5행 인 셀럽 list. (e) 노래 처방 = celebrities.json `song` field 신규 추가 (현재 fields: `id/birth/dayPillar/dayPillarName/blurbKo/blurbEn/nameKo/nameEn/kind/gender` — `song` 없음). |
| `assets/data/celebrities.json` (확장) | 223 entry 에 `songKo` (대표곡 한국어) 필드 추가. 검수 필요. **대안**: 별도 `assets/data/celeb_songs.json` 파일에 id→songKo 매핑. |
| `lib/screens/reports/energy_prescription_screen.dart` (신규) | 카드 UI — `RepaintBoundary` + screenshot 패키지 (`screenshot` 또는 `RenderRepaintBoundary.toImage()`) 로 공유 가능. Flutter native screenshot 가능. 사용자 mandate 의 "디지털 처방전" 컨셉. |

### Sprint 7 — 회귀 가드 + 외부 베타 제출
| File | 변경 범위 |
|---|---|
| `test/r101_*` 신규 7~10건 | (a) `r101_korean_no_english_leak_test.dart` — KO 본문 `"Water|Wood|Fire|Earth|Metal"` 어절 0. (b) `r101_compat_celeb_adapter_test.dart` — 셀럽 detail 이 `_analyze()` 5섹션 호출. (c) `r101_menu_order_test.dart` — reports_home cards [전생, 처방전, 최애 케미] 순서. (d) `r101_past_life_keyword_test.dart` — 7종 keyword 별 시나리오 1개 이상. (e) `r101_energy_prescription_test.dart` — deficit 5행 셀럽 추천 정확. |
| 기존 가드 보존 | R71/R98/R99/R100 회귀 가드 100% 보존. |
| `pubspec.yaml` build | `1.0.0+60` → `1.0.0+61`. 외부 베타 자동 제출. |

---

## 7. 위험 5개

### 위험 #1 — `dayPillarName` 영문이 ranked list eyebrow / detail header 에 hardcoded
- L979, L1120 의 영문 노출은 KO/EN 무관 (toUpperCase). 단순 KO branch 분기 추가가 아니라 ranked list 디자인 전체 검토 필요. R96~R100 사용자 검수 동안 노출돼 있었으나 mandate 직격은 처음 — 검증 없이 수정 시 ranked list 시각 무게 깨질 위험.

### 위험 #2 — `_closerPoolKo` 48개 의 `$blurbTail` inject 가 셀럽 blurbKo 영문 그룹명에 의존
- `blurbKo` 한국어 정규화는 P2 로 미루더라도, sprint 2 의 `_blurbTailClean()` helper 가 영문 그룹명 prefix 를 strip 하면 closer 본문 첫 단어가 사라져 어색해질 수 있음. helper 의 정규식 안전성 검증 (`celebrities.json` 223 entry × 48 closer = 10,704 path 산출).

### 위험 #3 — sprint 4 의 kpop_compat → compatibility _analyze 어댑터
- `_Star.dayPillar` (한자 2자) 만으로는 `SajuResult` 의 4기둥 8자 + 5행 분포가 불충분. `me.elements.deficit` 같은 5행 분포 비교는 셀럽 측에서 birth + dayPillar 만 가지고 부분 reconstruct 필요. **lookup 방식**: `SajuService` 의 light path 호출 + 셀럽 4기둥 8자 보강. 또는 `_analyze()` 가 5행을 안 쓰는 분기만 통과시키도록 partial SajuResult fake 가능.

### 위험 #4 — 전생 시나리오 (sprint 5) keyword pool 영문 leak
- past_life_pool.json 신규 작성 시 codex / sub-agent 영문 leak (R98~R100 반복 패턴). 데이터 생성 후 KO leak guard test 가 sprint 2 의 guard 를 그대로 통과해야 함 — 데이터 생성 전 가드 lock.

### 위험 #5 — 사용자 mandate ambiguity
- 사용자: `"새로운 메뉴를 만들거야 이 메뉴야"` — "이 메뉴야" 가 무엇을 가리키는지 verbatim 에 explicit 없음. 추정: **전생 시나리오** (사용자 verbatim 예시 `"이번 생에서도 솔라에게 돈 뺏기지만 행복할 운명"` 이 sprint 5 의 정확한 컨셉). 사용자 추가 확인 필요할 수도 있으나 mandate 흐름상 reasonable inference. sprint 5 가 mock 1~2 screen 만들고 사용자 검수 후 데이터 확장 권장.

---

## 8. Sprint 2~7 metric summary

| Sprint | Goal | Test target |
|---|---|---|
| Sprint 2 | KO 본문 영문 leak 0 (`anchor` / `Water Rabbit` / `LE SSERAFIM` 영문 head) | KO 본문 영문 어절 0, anchor 평문 0 |
| Sprint 3 | 메뉴 4장 → 5장 ([전생(hero), 처방전, 최애 케미, 신년운세, 꿈]) 순서 lock | reports_home cards 순서 가드 |
| Sprint 4 | kpop_compat 본문 = compatibility _analyze (셀럽 어댑터) | `_composeVerdict()` deprecated path 호출 0, `_analyze()` 호출 1 per detail |
| Sprint 5 | 전생 시나리오 화면 + 7 keyword × 시나리오 1개 이상 | past_life_pool keyword coverage |
| Sprint 6 | 기운 처방전 화면 + 5행 deficit 별 셀럽 매칭 + (옵션) 노래 처방 | deficit 별 셀럽 추천 정확 |
| Sprint 7 | 회귀 가드 통과 + 외부 베타 1.0.0+61 자동 제출 | flutter analyze 0, flutter test all pass |

---

## 9. Doc Update Transaction (본 측정)

### 2026-05-19 — R101 sprint 1 baseline

- Before state: 사용자 1.0.0+60 실기기 OCR 4 line (Water Rabbit / 복합 anchor / LE SSERAFIM 단 한 줄 / dayPillar 영문 노출) + mandate "한국어에 영어가 들어와", "최애와의 궁합보기로 메뉴명", "우리 궁합보는거 그대로", "팬심 1순위 (신규 전생) / 2순위 (디지털 처방전) / 3순위 (최애 케미)". R100 sprint 1 baseline 은 반복감만 측정, 영문 leak 미측정.
- After state: 4 OCR source 매핑 완료 (L1562, L2404, L3473, L979/L1120). KO 본문 anchor 잔존 kpop_compat 311 hit / compat 20 hit (이 중 KO 본문 inject = kpop 22+ / compat 12 곳). dayPillarName 영문 47종 inject 위치 15곳 식별. blurbKo 영문 head 62/223. 신규 메뉴 1/2/3순위 + sprint 2~7 file 별 작업 범위 + 위험 5개 산출.
- Files intentionally changed: `docs/operating_memory/r101_sprint1_baseline.md` (신규, 본 baseline 문서만).
- Files NOT changed: `lib/**`, `assets/**`, `test/**` (절대 룰).
- Commands proving state:
  - `git status --short` → clean
  - `wc -l lib/screens/reports/{kpop_compat,compatibility,reports_home}_screen.dart` → 4352 / 2535 / 305
  - `rg -n "anchor" lib/screens/reports/kpop_compat_screen.dart | wc -l` → 311
  - `rg -n "anchor" lib/screens/reports/compatibility_screen.dart | wc -l` → 20
  - `jq -r '.[].dayPillarName' assets/data/celebrities.json | sort -u | wc -l` → 47
  - `jq -r '.[].blurbKo' assets/data/celebrities.json | rg "^(LE SSERAFIM|BLACKPINK|...)" | wc -l` → 62
- New failure learned: R100 sprint 2 가 closer pool 5 → 48 확장 + identityLead 6×8 family 매트릭스 추가하면서 `dayPillarName` 영문 field 의 KO 본문 inject 지점이 **늘어남** (1462 → 15 hardcoded 위치). R99 EN-only 정제 sprint 가 KO leak 검사를 별도로 하지 않은 점. R100 의 variant pool 확장이 한국어 자연스러움보다 entropy 확보를 우선해 anchor 평문이 그대로 흘러간 점.
- Rule promoted: variant pool / skeleton 매트릭스 확장 시 **셀럽 데이터 field 의 언어성 (영문/한국어)** 을 KO branch / EN branch 어느 쪽에 inject 하는지 명시적 검증 필요. 데이터 field 가 영문이면 KO 분기에서 별도 normalizer (`pairKorean`, `groupKo`) 호출 의무.
- Open risk: sprint 4 의 `_Star → SajuResult` 어댑터가 5행 분포 (deficit/dominant) 를 부분 reconstruct 해야 함 — 셀럽 dayPillar 한자 2자 + birth 만으로는 month/hour pillar 미상. `_analyze()` 가 5행 의존 branch 호출 시 fake `FiveElements` 가 어떻게 계산될지 sprint 4 가 결정 필요.
- Next session first action: Sprint 2 시작 — §2.4 의 P0 5개 fix. 첫 step: `_starIdentityLead()` KO branch 의 `pillarName` 변수를 `star.dayPillar` (한자) + helper `_pillarKoNameOf(star.dayPillar)` (한자→한글 음, 예: `癸卯 → '계묘'`) 로 치환. `lib/models/saju_result.dart` 의 `Pillar.pairKorean` (L105+) 재사용.
- quality: routing 10/10, safety 10/10 (수정 0), accuracy 9/10 (OCR source line 직접 grep 으로 검증), tests 9/10 (test 후보만 작성), content 9/10, efficiency 9/10

— end of R101 sprint 1 baseline —
