# Pillar Seer Round 79 — 종합 calibration plan (Sprint 4 산출)

> Sprint 1 (가설 8개) + Sprint 2 (Playwright unsin 6 sample reverse) + Sprint 3 (Community 9 키워드 + 7 page fetch) 종합.
> **audit 용 — 사용자 노출 X**. Sprint 5-7 코드 변경 영역 + Sprint 8 새 골든 test spec 결정.

## 1. Top 3 calibration 우선순위 (Sprint 5-6 입력)

### HIGH 1 — H3 본문 wire (PersonalizationEngine deprecation)
- **영역**: `lib/screens/result_screen.dart:982-1049` 의 `_ForYouTodaySection` + `lib/services/personalization_engine.dart:94-443` 전체.
- **사용자 felt 직결도**: 가장 높음 (D2 본문 매칭률 / D7 사주 derive).
- **fix direction**: `_ForYouTodaySection.build()` 에서 `PersonalizationEngine.buildFor(result)` 호출을 SajuContext + DynamicTextResolver 기반 4 line 합성으로 마이그레이션.
- **derive 추가**: 격국 / 용신 / 십신 freq / 신살 freq / 통근 / 강도 — R78 SajuContext 의 field 모두 wire.
- **PersonalReading 호환**: test/widget_test.dart:94-125 + test/integration_flow_test.dart:64 의 호출 signature 보존 (`headlineKo/bodyKo/actionKo/cautionKo` 필드 유지).
- **5행 영향**: 0 (본문 변경만).

### HIGH 2 — D1 만세력 일주 정확도 audit (Sprint 6)
- **영역**: `lib/services/manseryeok_service.dart` 전체 (특히 자시 day-crossover / 진태양시 보정 / 입추·입춘 boundary).
- **사용자 felt 직결도**: 매우 높음 (Sprint 2 일주 일치율 50% + D1 dimension).
- **fix direction**:
  - Sample #2 (1988-07-15) 일간 庚 ↔ 우리 辛 — KASI vs unsin 시차 audit. 절기 (입추·하지) 처리 검토.
  - Sample #4 (1992-12-31 23:30) 일간 壬 ↔ 우리 辛 — 자시 day-crossover audit. `useLateNightZasi` 옵션 검토.
  - Sample #5 (1990-08-08 12:00) 일간 庚 ↔ 우리 乙 — 1990-08-08 절기 (입추 8/7~8/8 경계) 검토.
- **위험**: 만세력 raw 변경은 5행 골든 baseline 깨질 위험 매우 高. 단순 옵션 변경 (`useLateNightZasi=true` 등) 만 시도하고 골든 깨지면 채택 X. 깊은 algorithmic fix 는 Round 80 deferred.
- **5행 영향**: 일주 변경 시 매우 큼 — 골든 보존 필수.

### MID 3 — H1 5행 가중치 (Sprint 5)
- **영역**: `lib/services/manseryeok_service.dart:22-34` (8 상수).
- **사용자 felt 직결도**: 中 (% 정확도, 본문 매칭률보다 낮음).
- **fix direction (한정)**:
  - Sprint 3 의 F1/F3 학파 표준 (본기 > 여기 > 중기) vs 우리 앱 (본기 > 중기 > 여기) 순서 swap 검토.
  - 현재 `rootMainBonus=1.6 / rootMiddleBonus=0.6 / rootTraceBonus=0.3`. swap 후보: `rootMainBonus=1.6 / rootMiddleBonus=0.3 / rootTraceBonus=0.6` (학파 표준 정합).
- **5행 영향**: 매우 큼 — 1995-10-27 男 17시 16/21/17/41/4 보존 mandate. swap 시 골든 깨지면 채택 X.
- **트레이드오프**: 골든 보존 + 다른 sample 의 unsin diff 평균 ↓ 둘 다 어려움. 골든 우선.

### NEGATIVE — H4 신살 list 확장
- **영역**: `lib/services/shinsa_service.dart` (8 신살) + `lib/services/today_event_service.dart:328-344` (24 priority).
- **결정**: Sprint 2 (unsin 신살 노출 0건) + Sprint 3 (자평진전·적천수·난강망 학파 신살 기피) 종합 — **추가 작업 X**.
- **단**: Sprint 6 의 신살 anchor 본문 wire 는 H3 의 일부로 진행 (DynamicTextResolver 의 shinsa freq 입력).

### Deferred (Round 80 후보)
- **D3 조후용신 wire** (`yongsin_service` 에 계절 보정 추가).
- **D6 시간 입력 picker UX** (`input_screen` 의 30분 boundary 시각화).
- **만세력 algorithmic 깊은 fix** (sample #2/#4/#5 일간 완전 정합).

---

## 2. Sprint 5-7 코드 변경 영역 file:line

### Sprint 5 — H3 본문 wire (HIGH 1) + H1 가중치 swap (MID 3)

**파일 변경**:
- `lib/services/personalization_engine.dart:94-146` (buildFor) + `lib/services/personalization_engine.dart:160-443` (`_atoms` + fallback) — `PersonalizationEngine.buildFor` 시그니처 보존 + 내부에서 SajuContext + DynamicTextResolver 호출 (PersonalReading return). 또는 deprecation 후 신규 service 추가 + `_ForYouTodaySection` 만 마이그레이션.
- `lib/screens/result_screen.dart:982-1049` — `_ForYouTodaySection.build()` 호출 부분 (test 호환 위해 `PersonalizationEngine.buildFor` 시그니처 유지 권장).
- `lib/services/manseryeok_service.dart:30-31` — `rootMiddleBonus 0.6 ↔ rootTraceBonus 0.3` swap 시도 (1995-10-27 男 17시 골든 보존 시에만).

**test 변경 (Sprint 8 영역 — 본 sprint 에서 spec 만)**:
- `test/critical_regression_test.dart:1-200` — 5행 골든 보존 assertion (G1).
- `test/integration_flow_test.dart:60-130` — PersonalReading 호출 호환 (이미 있음 — line 64 의 `PersonalizationEngine.buildFor(r)` 보존).

### Sprint 6 — D1 만세력 audit + H4 (negative) 본문 anchor wire

**파일 변경**:
- `lib/services/manseryeok_service.dart:225-665` — sample #2/#4/#5 일간 audit.
  - `lib/services/manseryeok_service.dart` 안 `useLateNightZasi` 옵션 audit (자시 23:30 → 다음날 일주).
  - 절기 boundary (입추 8/7~8/8 / 입춘 2/4) 처리 검토 + `lib/services/solar_term_service.dart` cross-check.
- `lib/services/dynamic_text_resolver.dart:39-300` — 신살 freq anchor 본문 pool wire (H3 의 일부).

### Sprint 7 — 화면 분리 (Task D)

**파일 변경**:
- `lib/router.dart:21-100` — `/today` GoRoute 추가 + `protected` list (line 27-40) 에 `/today` 등록.
- `lib/screens/today_screen.dart` (신규 파일) — `_TodayEventDetailSection` + `_TodayDeepReadingSection` 이동.
- `lib/screens/result_screen.dart:50-85` (anchor scroll wire 제거) + `lib/screens/result_screen.dart:147-149` (`_TodayEventDetailSection` mount 제거) + `lib/screens/result_screen.dart:4021-4500` (section class 이동).
- `lib/screens/home_screen.dart:1622` — `_TodayEventCard` push target `/result?anchor=today_event` → `/today`.
- `lib/services/notification_service.dart:1-252` — deep-link payload migration (현재 payload `/result?anchor=today_event` 발견 line 보강 audit).
- `lib/router.dart:21-100` — `/result?anchor=today_event` → `/today` redirect rule.

---

## 3. 새 골든 test 5+ spec (Sprint 8 입력)

| # | 입력 | expected 우리 앱 (현재 정합) | 보존 anchor | unsin 비교 |
|---|---|---|---|---|
| G1 (golden baseline) | 1995-10-27 男 17:00 양력 | 일주 辛卯 / 5행 16/21/17/41/4 | **절대 보존 mandate** (사용자 명시) | unsin 25/8/8/38/21 — diff ±13%p (golden mandate 우선) |
| G2 | 1995-10-27 男 13:30 양력 | 일주 辛卯 / 5행 28/16/22/31/3 | 일주 일치 / 5행 합계 100 | unsin 29/15/18/18/21 — diff < 15%p (계산 정확도 검증) |
| G3 | 2001-02-04 女 00:30 양력 | 일주 戊戌 / 5행 1/1/73/9/17 | 일주 일치 / 입춘 boundary 정상 | unsin 10/0/33/15/42 (sprint 6 audit 후 비교) |
| G4 | 1990-08-08 男 12:00 양력 | 일주 乙巳 / 5행 34/16/8/27/15 | **현재 일주는 unsin 庚 와 불일치** — sprint 6 audit | 입추 boundary 처리 검증 |
| G5 | 1992-12-31 男 23:30 양력 | 일주 辛巳 / 5행 2/6/11/34/46 | **현재 일주는 unsin 壬 와 불일치** — sprint 6 audit | 자시 day-crossover 처리 검증 |
| G6 (PersonalReading) | 1995-10-27 男 17:00 + 격국·용신 wire | PersonalReading 4 line 모두 격국 anchor 포함 | DynamicTextResolver 마이그레이션 검증 | unsin 패턴 정합 |
| G7 (라우터) | `/today` route + deep-link redirect | `/today` accessible / `/result?anchor=today_event` redirect | 화면 분리 mandate | unsin 패턴 정합 (result 평생사주만) |

---

## 4. 5행 골든 보존 mandate (재확인)

- **G1 (1995-10-27 男 17:00 양력) → 일주 辛卯 + 5행 16/21/17/41/4** — **절대 보존**.
- 모든 Sprint 5-7 코드 변경 시 G1 assertion 통과 mandate.
- 위반 시: 변경 즉시 revert / 채택 X / sprint 재시도.

---

## 5. NON-GOAL (Round 79 안 함)

- TestFlight 배포 X (Sprint 10 trigger 까지).
- 자미두수 hidden 변경 X.
- 알림 picker 변경 X.
- profile / reports / discover 본문 overhaul X (화면 분리 외).
- 만세력 algorithmic 깊은 fix (sample #2/#4/#5 일간 완전 정합) — Round 80 deferred.
- D3 조후용신 wire — Round 80 deferred.

---

## 6. Sprint 5-9 진행 계획

- **Sprint 5**: H3 본문 wire (HIGH 1) + H1 가중치 swap (MID 3) + 5행 골든 G1 가드.
- **Sprint 6**: D1 만세력 audit (HIGH 2) + 신살 anchor 본문 (H3 일부).
- **Sprint 7**: 화면 분리 (Task D) — `/today` route 신설.
- **Sprint 8**: 새 골든 test G1~G7 추가 + 회귀 가드.
- **Sprint 9**: cleanup + memory + 인수인계.
- **Sprint 10**: TestFlight 1.0.0+39 배포 (사용자 명시 trigger).
- **Sprint 11**: 인수인계 업데이트.

---

> Sprint 5 진입 — H3 본문 wire 부터 시작. PersonalizationEngine 마이그레이션 + 5행 골든 G1 보존 가드.
