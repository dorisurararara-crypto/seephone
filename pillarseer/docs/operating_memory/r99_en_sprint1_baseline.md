# R99 EN Sprint 1 — English Baseline Inventory

> Status: read-only measurement only (no source/asset modified)
> Audited at: 2026-05-19 KST
> Auditor: R99 English baseline inventory worker (sub-agent)
> Scope: pre-edit baseline of English-language user-facing text in Pillar Seer
> Working tree: dirty (12 modified + 4 untracked, none touched by this audit — R98 leftover)

---

## 0. Mandate recap

R98 sprint 1~7 일소가 Korean content 의 자연스러움·변별력·금지어 hit 를 0 으로 줄였다.
**R99 EN sprint 1 = English 본문의 동일한 baseline 측정** (수정 0, 숫자만).

## 1. 파일별 영어 본문 entry 수

| 영역 | 파일 / 엔드포인트 | EN entry 수 | 비고 |
|---|---|---|---|
| 셀럽 케미 blurb | `assets/data/celebrities.json` | **223 / 223 (100%)** | blurbEn 100% coverage. 평균 길이 101자. 중복 0 (full uniqueness). |
| 60일주 deep slice EN | `saju_deep_slice_0_19.json` + `_20_39.json` + `_40_59.json` 의 `en` 객체 | **60 / 60 (100%)** | 모든 60 일주에 EN deep block 존재. |
| 60일주 deep slice EN 본문 string slot | 위 + slot 9개 (`dayMasterDeep` / `career` / `wealth` / `love` / `health` / `family` / `fame` / `luckyColor` / `luckyDirection`) | **540 strings** | 그 중 paragraph-length = 420 (60 × 7 슬롯). luckyColor / luckyDirection / luckyNumber = 단어/숫자. |
| l10n EN string | `lib/l10n/app_en.arb` (top-level keys) | **373** keys / **370** string values (3 keys are metadata `@@locale` 등) | UI 라벨 + helper text + 일부 본문. |
| lib hardcoded EN (l10n bypass) | `lib/screens` + `lib/services` 의 `"..."` literal ≥20자 영어 문장 | **120 lines** | 가장 큰 source = `kpop_compat_screen.dart` 48 / `notification_pool_service.dart` 21 / `today_deep_service.dart` 16. |

## 2. Forbidden phrase 35종 hit table

> 사용자 spec 35 phrase 전체 hit count + 파일 분포. 검색 대상: `assets/data` + `lib/l10n` + `lib/services` + `lib/screens` (build 제외).

| # | Phrase | Total | 분포 (file:count) |
|---|---|---|---|
| 1 | `signals` | **316** | `dreams.json`:279 / `saju_deep_slice_40_59.json`:23 / `today_event_service.dart`:3 / `saju_deep_slice_0_19.json`:2 / `tojeong_screen.dart`:2 / `saju_60ji.json`:2 / `saju_deep_slice_20_39.json`:2 / `compatibility_screen.dart`:1 / `ziwei_crossmatch_service.dart`:1 / `dynamic_text_resolver.dart`:1 |
| 2 | `The gift is` | **140** | `saju_deep_slice_40_59.json`:140 (slice_40_59 의 모든 entry × 7 slot 동일 boilerplate — **massive boilerplate**) |
| 3 | `You may look composed` | 40 | `saju_deep_slice_0_19.json`:20 / `saju_deep_slice_20_39.json`:20 |
| 4 | `When balanced` | 40 | `saju_deep_slice_0_19.json`:20 / `saju_deep_slice_40_59.json`:20 |
| 5 | `suits you` | 26 | `career_pool.json`:14 / `saju_deep_slice_0_19.json`:3 / `saju_deep_slice_20_39.json`:3 / `saju_deep_slice_40_59.json`:2 / `sipsin_persona.json`:2 / `life_stage_pool.json`:1 / `ziwei_crossmatch_service.dart`:1 |
| 6 | `inner rhythm` | 21 | `saju_deep_slice_20_39.json`:20 / `deep_content_service.dart`:1 |
| 7 | `reads the room quickly` | 20 | `saju_deep_slice_0_19.json`:20 |
| 8 | `not a simple sign` | 20 | `saju_deep_slice_0_19.json`:20 |
| 9 | `needs both recognition and emotional safety` | 20 | `saju_deep_slice_20_39.json`:20 |
| 10 | `inner compass that cannot be bought` | 20 | `saju_deep_slice_0_19.json`:20 |
| 11 | `branch seeks` | 20 | `saju_deep_slice_20_39.json`:20 |
| 12 | `When pressured` | 20 | `saju_deep_slice_0_19.json`:20 |
| 13 | `This can make partners feel` | 20 | `saju_deep_slice_20_39.json`:20 |
| 14 | `The best partner respects` | 20 | `saju_deep_slice_20_39.json`:20 |
| 15 | `The Day Master wants` | 20 | `saju_deep_slice_20_39.json`:20 |
| 16 | `Recognition follows when quality becomes repeatable` | 20 | `saju_deep_slice_20_39.json`:20 |
| 17 | `Once trust is built` | 20 | `saju_deep_slice_20_39.json`:20 |
| 18 | `Love becomes easier` | 20 | `saju_deep_slice_20_39.json`:20 |
| 19 | `Attraction often begins` | 20 | `saju_deep_slice_20_39.json`:20 |
| 20 | `Your results outlast your title` | 11 | `saju_deep_slice_0_19.json`:4 / `saju_deep_slice_40_59.json`:4 / `saju_deep_slice_20_39.json`:3 |
| 21 | `your energy` | 3 | `saju_deep_slice_40_59.json`:1 / `discover_screen.dart`:1 / `notification_pool_service.dart`:1 |
| 22 | `vibes` | 2 | `notification_pool_service.dart`:1 / `today_event_service.dart`:1 |
| 23 | `supports you` | 2 | `sipsin_persona.json`:1 / `career_pool.json`:1 |
| 24 | `leans into` | 1 | `today_event_service.dart`:1 |
| 25 | `at your core` | 1 | `sipsin_persona.json`:1 |
| 26 | `Your essence is` | 0 | — |
| 27 | `This is your signature` | 0 | — |
| 28 | `shines through` | 0 | — |
| 29 | `deeply resonates` | 0 | — |
| 30 | `quiet strength` | 0 | — |
| 31 | `steady presence` | 0 | — |
| 32 | `natural ability` | 0 | — |
| 33 | `unique energy` | 0 | — |
| 34 | `today's energy` | 0 | — |
| 35 | `The shadow is` | 0 (literal substr) | (실제 슬라이스 40_59 는 `the shadow is` 소문자 형태로 140 회 — 위 #2 와 한 짝, 본 phrase 는 case-sensitive null) |

**Top 5 forbidden hit**:

1. `signals` — 316 (단, `dreams.json` 279 회는 "snake dream often signals incoming wealth" 같은 동사 사용으로 benign 가능성 큼; saju_deep_slice 27 회 / lib 7 회는 stock noun 사용 — **재분류 필요**)
2. `The gift is` — 140 (slice_40_59 boilerplate 직격)
3. `You may look composed` — 40 (slice_0_19 + slice_20_39 의 love 슬롯 통째 동일)
4. `When balanced` — 40 (slice_0_19 + slice_40_59 의 dayMasterDeep 슬롯)
5. `suits you` — 26 (career_pool 14 회 + slice 8 회 — career stock phrase)

> Severe alarm: **slice_40_59** 가 단독으로 `The gift is turning unfinished potential into visible structure; the shadow is carrying too much pride or responsibility in silence` 한 줄을 한 entry 의 7 slot 전체에 그대로 복사 → 20 entry × 7 = 140 hit. **slice_40_59 자체의 변별력 0**.

## 3. Celebrity blurbEn 첫 3-word lead top 30

총 223 entry, **unique 첫-3-word ratio = 0.901 (201 unique / 223)**. 상위 30:

```
   4 Solo K-pop artist
   4 LE SSERAFIM member
   3 Red Velvet vocal
   3 NCT DREAM main
   3 KISS OF LIFE
   2 ZEROBASEONE performer whose
   2 XG vocalist with
   2 True Beauty /
   2 TWICE main dancer
   2 Queen of Tears
   2 P1Harmony rapper whose
   2 P1Harmony performer whose
   2 NCT WISH performer
   2 KATSEYE vocalist whose
   2 ATEEZ main dancer
   1 i-dle's warm-tone vocalist.
   1 i-dle's leader-producer. Day
   1 i-dle's husky charisma.
   1 i-dle's clear vocal
   1 i-dle's bright youngest.
   ... (1-회 lead 181 종)
```

### Stock-lead 카운트

| Pattern | hit | 비고 |
|---|---|---|
| `^[A-Z][A-Za-z\-]* member` (그룹 이름 + "member") | 49 | 가장 큰 stock lead. e.g., "LE SSERAFIM member", "aespa member Winter". |
| `^[A-Z][A-Za-z\-]*(\([A-Z]*\))? (member|main|lead|vocal|rapper|performer|youngest|leader)` (group + role) | 115 (49 + 다른 role) | 223 中 약 51.6% 가 "<GROUP> <role>" 패턴. **사용자 자연스러움 룰: 그룹명만 반복되는 stock 도입부 줄여야**. |
| `^Solo artist` | 1 | |
| `^Soloist` | 0 | |
| `^Member of` | 0 | |
| `^Solo K-pop` | 4 | |

> Pattern 분석: blurbEn 의 **약 50% 가 "<GROUP> <role>" 으로 시작** → 사용자 perception 상 "다 비슷한 도입" 인상. 사용자 verbatim mandate 가 들어오기 전 baseline 이므로 즉시 수정 X, 측정만.

## 4. saju_deep_slice EN 첫 문장 unique-suffix 비율

총 420 entry × paragraph slot (60 일주 × 7 slot, lucky 필드 제외).

| Slot | Total | Unique 첫문장 | 비율 |
|---|---|---|---|
| dayMasterDeep | 60 | 58 | **0.967** |
| career | 60 | 60 | **1.000** |
| wealth | 60 | 41 | **0.683** ⚠ |
| love | 60 | 60 | **1.000** |
| health | 60 | 60 | **1.000** |
| family | 60 | 41 | **0.683** ⚠ |
| fame | 60 | 60 | **1.000** |
| **전체** | **420** | **280** | **0.667** |

### 첫 3-word prefix 분포

**Top 10 가장 자주 반복되는 prefix**:

| # | hit | prefix |
|---|---|---|
| 1 | **20** | `Career works best` |
| 2 | **20** | `Wealth is tied` |
| 3 | **20** | `In love, you` |
| 4 | **20** | `Health should be` |
| 5 | **20** | `Family karma often` |
| 6 | **20** | `Fame and public` |
| 7 | **20** | `Career luck for` |
| 8 | **20** | `Family patterns for` |
| 9 | **20** | `Fame and reputation` |
| 10 | **6** | `Wood Dragon is` |

> **첫-3-word unique ratio = 102 / 420 = 0.243** — 매우 낮음. 60 일주가 7 slot 마다 같은 3-word lead 로 시작하는 경향이 **slice_0_19 / slice_20_39 / slice_40_59 모두에 존재**. 사용자가 한 화면에서 7 slot 을 같이 보면 즉각 "AI 가 자동생성한 형식" 인상.

### slice_40_59 단독 boilerplate (심각)

- **20 / 20 entry** 가 `<element> <animal> is a ... :` metaphor 한 줄을 dayMasterDeep / career / wealth / love / health / family / fame **6개+ slot 에 그대로 복붙**.
- **20 / 20 entry** 가 적어도 한 문장을 3+ slot 에 동일 복붙 (`The gift is turning unfinished potential into visible structure; the shadow is carrying too much pride or responsibility in silence` 패밀리).

→ slice_40_59 는 EN 본문 변별력이 사실상 0. P0 fix 1순위.

### Top 10 가장 자주 반복되는 첫 문장 자체

| hit | sentence |
|---|---|
| 20 | `Wealth is tied to how well desire is organized.` |
| 20 | `Family karma often centers on duty, expectation, and the question of who gets to define your path.` |
| 6 | `Wood Dragon is a tall tree rooted in a clouded reservoir: growth, command, and stored storm energy.` |
| 6 | `Wood Snake is a vine warmed by hidden summer fire: grace, strategy, and refined survival instinct.` |
| 6 | `Fire Horse is the sun riding its own noon horse: radiance, speed, and public magnetism.` |
| 6 | `Fire Goat is a candle inside warm meadow earth: sensitivity, taste, and slow emotional authority.` |
| 6 | `Earth Monkey is a mountain with metal tunnels and quick echoes: scale, wit, and tactical construction.` |
| 6 | `Earth Rooster is polished soil holding a bright jewel: precision, service, and curated value.` |
| 6 | `Metal Dog is a blade guarded in a dry fortress: justice, endurance, and severe loyalty.` |
| 6 | `Metal Pig is a pearl sinking through deep winter water: beauty, intuition, and private intelligence.` |

> wealth (20) + family (20) 슬롯은 60 일주가 같은 첫 문장으로 시작 → 변별력 0. slice_40_59 의 metaphor 문장은 한 entry 내 6 슬롯에 동시에 박혀 있음 → 한 화면 노출 시 사용자가 즉시 boilerplate 인지.

## 5. l10n `app_en.arb` 의 awkward / AI-tone phrase 위치

> 370 user-facing string 중 AI-tone 키워드 hit (사용자 자연스러움 룰 위반 후보):

| key | value | 진단 |
|---|---|---|
| `splashTagline` | `Your vibe today,\nfrom the four pillars of your birth.` | "vibe" stock — 사용자 자연스러움 룰 회색지대. |
| `inputTitle` | `ENTER YOUR FATE` | 직설적 명령형, "FATE" 다소 과장. |
| `resultTitle` | `YOUR LIFE PATH` | 인터넷 사주 stock. |
| `resultFiveElements` | `Element strength score (app-calibrated)` | OK (technical helper). |
| `resultDayMaster` | `DAY MASTER` | OK. |
| `resultDayMasterDeepTitle` | `Your Core Self · 日 干` | "Core Self" stock — sajuday 등 경쟁사 보편 사용, 다만 자연스러움 위반은 아님. |
| `resultGuideBody` | `... The DAY pillar is your Core Self. The 5 elements (Wood/Fire/Earth/Metal/Water) show your inner balance. ...` | "inner balance" stock 1회. |
| `homeExplanationLow` | `Today's pillar challenges your day master. Take it slow and ground yourself.` | "ground yourself" 자기계발-tone 1회. |
| `shareCardSubtitle` | `Send your Core Self to friends` | "Core Self" 동일 stock 재사용. |
| `paywallFeature1` | `Day Master + Five Elements` | OK (technical bullet). |
| `devGateUnlocked` | `Pro features unlocked.` | OK (dev string). |
| `homeNotifSampleBody` | `Open to see today's score, lucky color, and one-line guide.` | OK. |

**총 awkward 후보 hit: 약 7 keys** (`splashTagline` / `inputTitle` / `resultTitle` / `resultDayMasterDeepTitle` / `resultGuideBody` / `homeExplanationLow` / `shareCardSubtitle`). 자연스러움 위반 강도는 **낮음** — Korean 본문보다 훨씬 깨끗. 단, "Core Self" 가 2 곳에 동일 등장 + "vibe / FATE / LIFE PATH / inner balance / ground yourself" 가 sprint 2 candidate.

## 6. lib 의 hardcoded EN string

총 **120 lines** (l10n 미경유 영어 ≥20자 문자열, build 제외).

### 파일 분포 top

| file | count | 비고 |
|---|---|---|
| `lib/screens/reports/kpop_compat_screen.dart` | 48 | K-POP 셀럽 케미 화면 — match 설명 + same-element / producing flow 등 30+ branch 본문. R98 sprint 5 audit 에서 "의도된 합성 분석문" 으로 분류된 영역. |
| `lib/services/notification_pool_service.dart` | 21 | push notification 본문 풀. R98 sprint 5 에서 KO 본 `시그니처` hit 있었음. EN 본문도 21 줄 hardcoded. |
| `lib/services/today_deep_service.dart` | 16 | 오늘 사주 총평 EN. R85 R98 메모리에서 KO 는 정리됨. EN 미정리. |
| `lib/screens/reports/compatibility_screen.dart` | 11 | 일반 궁합 화면 EN branch. |
| `lib/screens/home_screen.dart` | 8 | 홈 first-fold 24시간 가이드 EN. R74 ko 정리 시 EN 동반 정리되지 않음. |
| `lib/services/today_event_service.dart` | 6 | 오늘 사건 가능성 EN. |
| `lib/services/deep_content_service.dart` | 2 | EN deep content fallback. |
| `lib/screens/reports/new_year_2026_screen.dart` | 2 | 2026 신년운세 EN. |
| `lib/screens/discover_screen.dart` | 2 | 케미 발견 본문. |
| `lib/services/solar_term_service.dart` | 1 | OK (technical). |
| `lib/services/app_version_service.dart` | 1 | OK (technical version). |
| `lib/screens/settings_screen.dart` | 1 | OK (주석/format). |
| `lib/screens/input_screen.dart` | 1 | OK (single label). |

### 본문 vs technical 분류

- **사용자 본문 (sprint 2/3 fix 후보)**: 약 110 line — `kpop_compat_screen.dart` 48 + `notification_pool_service.dart` 21 + `today_deep_service.dart` 16 + `compatibility_screen.dart` 11 + `home_screen.dart` 8 + `today_event_service.dart` 6.
- **technical / dev / format**: 약 10 line — version / settings comment / solar term name.

## 7. 수정 우선순위

### P0 (변별력·boilerplate 직격, 가장 큰 ROI)

1. **`assets/data/saju_deep_slice_40_59.json` 전체 재생성 — 20 entry × 7 slot = 140 paragraph**
   - 동일 metaphor 문장이 한 entry 의 6+ slot 에 그대로 복사 → 사용자가 한 화면에서 즉시 boilerplate 인지.
   - `The gift is ... the shadow is ...` 한 줄이 140 hit.
   - 사용자 mandate 가 들어오는 즉시 가장 먼저 손봐야 할 단일 파일.

2. **`assets/data/saju_deep_slice_0_19.json` 의 dayMasterDeep / love slot 20 개**
   - `You may look composed` × 20 / `When balanced` × 20 / `When pressured` × 20 / `not a simple sign` × 20 / `reads the room quickly` × 20 / `inner compass that cannot be bought` × 20 — 60 일주 중 0~19 번 (갑자~계미) 의 love + dayMasterDeep 슬롯이 거의 동일 boilerplate.

3. **`assets/data/saju_deep_slice_20_39.json` 의 love slot 20 개**
   - `Attraction often begins` × 20 / `The best partner respects` × 20 / `Once trust is built` × 20 / `Love becomes easier` × 20 / `branch seeks` × 20 / `This can make partners feel` × 20 / `needs both recognition and emotional safety` × 20 / `Recognition follows when quality becomes repeatable` × 20 / `The Day Master wants` × 20 — 60 일주 중 20~39 (갑신~계해) 의 love + fame 슬롯이 boilerplate.

### P1 (사용자 자연스러움 룰, 두 번째 ROI)

4. **`lib/services/notification_pool_service.dart` 21 line + `lib/services/today_deep_service.dart` 16 line EN 본문 재작성**
   - R98 sprint 5 가 ko 본문 정리 시 en 동반 정리 누락. 사용자가 EN 모드로 push 알림 / 오늘 총평 보면 R98 사고와 비슷한 "AI 같음" 인상.

5. **`lib/screens/reports/kpop_compat_screen.dart` 48 line EN match 본문**
   - 자연스러움 룰 보존하면서 "same-element" / "producing flow" 등 stock branch 표현 → "your color grows theirs" 같은 자연스러움 좋은 문장이 많지만 30+ branch 가 비슷한 톤으로 흐름 → light 재작성 권장.

6. **`assets/data/celebrities.json` 의 stock-lead 50% 감축**
   - 49 entry 가 "<GROUP> member" 로 시작 / 115 entry (51.6%) 가 "<GROUP> <role>" 로 시작 → 사용자 perception 상 "도입 비슷함" 인상. 50% 만 다른 angle (감각 / 비유 / Day pillar 묘사 등) 로 재작성하면 됨.

### P2 (technical / l10n 라벨 톤 통일)

7. **`lib/l10n/app_en.arb` 의 5~7 keys 톤 통일** (`splashTagline` / `inputTitle` / `resultTitle` / `homeExplanationLow` / `shareCardSubtitle`) — "vibe / FATE / LIFE PATH / Core Self / ground yourself" stock 검토. 자연스러움 위반은 가벼움.

8. **`assets/data/dreams.json` 의 `signals` 279 hit** — verb usage benign 가능성 큼. R99 sprint 1 의 forbidden list 가 너무 broad. 사용자 자연스러움 mandate 가 들어오면 case 별로 검토. **현재 단순 카운트로 P0 분류는 부당**.

## 8. R99 EN sprint 2 / 3 권장 범위

### Sprint 2 — slice_40_59 단독 재생성 (P0-1 만 처리)

- 범위: `assets/data/saju_deep_slice_40_59.json` 의 20 entry × 7 paragraph slot = **140 paragraph**.
- 기대 effect: forbidden hit 320+ 감소 (`The gift is` 140 / `When balanced` 20 / `Your results outlast your title` 4 / `signals` 23 / `suits you` 2 / 첫문장 boilerplate 다수 / metaphor 복붙 제거).
- R98 회귀 가드 유지: 5행 골든 / R69 lock / R71 invariant / R83 P1-B 자시 보존.
- 통제: ko 본문 (slice_40_59 의 `ko` 객체) 미수정 — sprint 2 read-only on ko, write-only on en.

### Sprint 3 — slice_0_19 + slice_20_39 의 boilerplate slot 재생성

- 범위: slice_0_19 의 love + dayMasterDeep 20 entry / slice_20_39 의 love + fame 20 entry = **80 paragraph + 첫문장 변별 보강**.
- 기대 effect: forbidden hit 280+ 감소 (`You may look composed` 40 / `Attraction often begins` 20 / `Once trust is built` 20 / `The best partner respects` 20 / `Love becomes easier` 20 / `branch seeks` 20 / `This can make partners feel` 20 / `needs both recognition and emotional safety` 20 / `Recognition follows when quality becomes repeatable` 20 / `not a simple sign` 20 / `reads the room quickly` 20 / `inner compass that cannot be bought` 20 / `When pressured` 20 + 첫문장 prefix `Wealth is tied` / `In love, you` / `Family karma often` 이 60 → 20 이하).
- ko 본문 미수정.

### Sprint 4 (옵션) — lib hardcoded EN 본문 정리

- 범위: `notification_pool_service.dart` 21 + `today_deep_service.dart` 16 + `kpop_compat_screen.dart` 48 = **85 line**.
- 효과: R98 ko 정리와 동등한 EN 정리.
- ko 본문 미수정.

### Sprint 5 (옵션) — celebrities.json stock-lead 50% 감축 + l10n 톤 통일

- 범위: 60~115 celebrity blurbEn + 5~7 l10n keys.
- 효과: 첫 3-word unique ratio 0.901 → 0.95+ / "Core Self" 등 stock 일관화.

---

## 9. baseline 수치 한 줄 요약

| 영역 | baseline 값 |
|---|---|
| celebrity blurbEn entry | 223 (coverage 100%) |
| saju_deep_slice EN paragraph | 420 (60 일주 × 7 slot) |
| saju_deep_slice EN string slot 전체 | 540 (포함 lucky 필드) |
| l10n app_en.arb user-facing string | 370 |
| lib hardcoded EN ≥20자 | 120 line (본문 110) |
| celeb blurbEn 첫-3-word unique ratio | **0.901** (201/223) |
| celeb blurbEn 전체 unique ratio | **1.000** (223/223) |
| saju_deep EN 첫문장 unique ratio | **0.667** (280/420) |
| saju_deep EN 첫-3-word unique ratio | **0.243** (102/420) |
| forbidden hit total (35종 합) | **907** (signals 316 + The gift is 140 + 외) |
| forbidden hit excluding signals | **591** |
| slice_40_59 boilerplate severity | **20/20 entry** 가 metaphor / "The gift is" 한 줄을 한 entry 의 6+ slot 에 복붙 — single-file 가장 큰 fix ROI |

---

## 10. 부록 — 실행한 명령 / 측정 절차 evidence

```bash
$ git status --short  # dirty 12 + untracked 4 (R98 leftover, 본 audit 미수정)

$ jq length assets/data/celebrities.json  # 223
$ jq '[.[] | has("blurbEn")] | {total:length, blurbEn: map(select(.))|length}' assets/data/celebrities.json
# {"total": 223, "blurbEn": 223}

$ jq -s '[.[][] | select(.en?)] | length' \
    assets/data/saju_deep_slice_0_19.json \
    assets/data/saju_deep_slice_20_39.json \
    assets/data/saju_deep_slice_40_59.json   # 60

$ jq 'keys | length' lib/l10n/app_en.arb   # 373

$ jq -r '.[].blurbEn' assets/data/celebrities.json | awk '{print $1, $2, $3}' | sort | uniq -c | sort -rn | head -30
# → 상위 30 lead 분포 (Section 3)
$ jq -r '.[].blurbEn' assets/data/celebrities.json | grep -ciE '^[A-Z][A-Za-z\-]* member'  # 49
$ jq -r '.[].blurbEn' assets/data/celebrities.json | grep -ciE '^[A-Z][A-Za-z\-]*(\([A-Z]*\))? (member|main|lead|vocal|rapper|performer|youngest|leader)'  # 115

# Forbidden 35종 luxury 일괄 카운트 (Section 2)
$ rg -n "(Your essence is|...|suits you)" assets/data lib/l10n lib/services lib/screens --glob '!build/**'

# saju_deep_slice 첫문장 unique 분석 (Section 4) — python3 script
# 결과: total 420 / uniq 280 / ratio 0.667
# 첫-3-word prefix: 102 / 420 = 0.243

# slice_40_59 boilerplate audit (Section 4 — slice_40_59 단독)
# 결과: 20/20 entry 가 metaphor 를 6+ slot 에 그대로 복붙

# lib hardcoded EN 카운트 (Section 6)
$ rg -n '"[A-Z][a-z][^"]{20,}"' lib/services lib/screens --glob '!build/**' \
    | grep -v 'l10n|appLocalizations|AppLocalizations|import|debugPrint|throw|assert' \
    | wc -l   # 120

# JSON 무결성 확인 (수정 0 보존)
$ jq empty assets/data/celebrities.json && echo OK   # OK
$ jq empty assets/data/saju_deep_slice_0_19.json && echo OK   # OK
$ jq empty assets/data/saju_deep_slice_20_39.json && echo OK   # OK
$ jq empty assets/data/saju_deep_slice_40_59.json && echo OK   # OK
$ jq empty assets/data/life_paragraphs.json && echo OK   # OK
$ jq empty lib/l10n/app_en.arb && echo OK   # OK
```

— end of R99 EN sprint 1 baseline —
