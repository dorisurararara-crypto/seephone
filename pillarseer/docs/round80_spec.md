# Round 80 — 개인화 broken + 차트 색상 + R79 deferred 4영역

> Sprint 1 산출물. **audit + spec only / 코드·test 변경 0**. 7 의제 분할 + sprint plan.
>
> **이 문서는 개발 audit 용 — 사용자에게 노출 안 됨**. 코드 reference (file:line) / 영문 약어 (예: C1·H1·diff·grep) 는 개발자 용어. 사용자 UI 본문은 별도 sprint 5+ 에서 한국 MZ 중학생 K-POP 팬 직설 친근 해요체 만 노출. UI 본문에는 한자 jargon · 영문 약어 · 개발자 용어 전부 0.

## 0. 사용자 불만 (verbatim · 2026-05-15 main Claude 세션)

> "벼린 칼 같은 사람이에요 이건 항상 나오는거야? 여자친구도 똑같이 나오던데 그리고 사진1에서 왜 더 적은데 점에 색깔이 달라? 더 많은게 색깔이 있고 이것도 여자친구랑 점수가 다 똑같아 우연이야? 사진2도 여자친구랑 똑같고 이것도 우연이야?"

핵심 4 단언:
1. "벼린 칼 같은" 멘트가 본인 + 여자친구 둘 다 동일.
2. radar(?) 차트에서 점수 큰 점이 색 X / 점수 작은 점에 색 + 강조.
3. 6각 점수 본인 vs 여자친구 거의 동일.
4. 다른 화면(사진2) 도 본인 vs 여자친구 동일.

→ **개인화 결정론** + **차트 색상 직관 어긋남** = critical. R79 deferred 4영역 보다 시급.

---

## 1. 진단 (Sprint 1 audit 결과 — 코드 변경 0)

### C1 — `_oneLinerFor` 5행 dominant 5종 매핑만 사용 (60일주 무시)

- **위치**: `lib/services/deep_content_service.dart:404-421`
- **현재 코드**:
  ```dart
  static String _oneLinerFor(bool ko, String day60ji, String name, String dom) {
    const koMap = {
      '木': '쭉 뻗는 나무 같은',
      '火': '환하게 타오르는 불 같은',
      '土': '큰 산 같은',
      '金': '벼린 칼 같은',
      '水': '깊은 물 같은',
    };
    ...
    return ko ? (koMap[dom] ?? '한결같은') : '$fallback-energy';
  }
  ```
- **문제**: `day60ji` (60일주) 인자 받지만 함수 안에서 사용 X. dominant 5행 5종만 분기.
- **결과**: 한국 인구 1/5 동일 멘트. 본인 + 여친 둘 다 金 dominant 면 "벼린 칼 같은" 동일 노출.
- **R77/R78 메모리 reference**: "60일주 1440 phrase" pool 은 `lib/services/notification_pool_service.dart`, `lib/services/today_event_service.dart` 에만 wire — `deep_content_service` 는 자체 5종 fallback 만.

### C2 — `_todayHookFor` + `_whyReasonFor` 5종/5×5 매핑 (60일주 무시)

- **위치**: `lib/services/deep_content_service.dart:436-469`
- **현재 코드**: `_todayHookFor(bool ko, String ji, String dom)` → dom 5종 매핑만 / `_whyReasonFor(bool ko, String ji, String name, String dom, String def)` → dom × def 5×5 매핑.
- **문제**: 같음 (`ji` 인자 받지만 사용 X).
- **결과**: 같은 dominant + deficit 페어 (예: 金 dominant + 木 deficit) 인 사람들 동일 멘트.

### C3 — 6각 점수 변별력 미약 (`_stableJitter ±2`)

- **위치**: `lib/services/six_axis_score_service.dart:413-419`
- **현재 코드**:
  ```dart
  static int _stableJitter(String day60ji, String axisKey) {
    final seed = (day60ji.codeUnits.fold<int>(0, (a, b) => a + b) +
                  axisKey.codeUnits.fold<int>(0, (a, b) => a + b)) % 5;
    return seed - 2; // -2 ~ +2
  }
  ```
- **호출** (line 176/196/212/233/244): `* 3` 또는 `* 2` 곱해 ±4~6 점 변동.
- **베이스 점수**: 5행 비율 + 일간 element 만으로 계산 (`_elPercent`).
- **문제**: 본인 + 여친 5행 분포 비슷하면 베이스 거의 동일, jitter ±6 정도로는 사용자 체감 동일.
- **격국 / 용신 / 십신 freq / 신살 / 통근 / 합충** 모두 점수에 wire X.

### C4 — radar 색상이 점수가 아닌 `crossMatches` 기준 (사용자 직관 어긋남)

- **위치**: `lib/widgets/six_axis_radar.dart:254-275`
- **현재 코드**:
  ```dart
  final matched = score.crossMatches[axes[i]] ?? false;
  final dotPaint = Paint()
    ..color = matched ? AppColors.accent : AppColors.ink
    ..style = PaintingStyle.fill;
  canvas.drawCircle(p, matched ? 4.2 : 3.0, dotPaint);
  if (matched) { /* outer ring 7px */ }
  ```
- **문제**: `matched` (cross-match — surface vs deep 둘 다 동일 결론) = accent(brand color) + 큰 점 + ✨ ring. **점수 크기와 무관**.
- **사용자 직관 어긋남**: "값 큰 점이 강조되어야" 가 일반 직관. 우리 앱은 cross-match 로 강조 → 사용자가 의미 모르고 "왜 작은 점에 색깔?" 인식.
- **라벨**: `_MatchBadge` "깊게 봐도 다시 잡힌 핵심 N/6 ✨" 가 있긴 하지만 user 인지율 ↓.

### C5 — `PersonalizationEngine.buildFor` derive 빈약 (R78 wire 후에도 남은 공백)

- **위치**: `lib/services/personalization_engine.dart:94-146`
- **R78 sprint 5 fix 후 현재 derive**: dayMaster / dayMasterElement / monthBranch / season / dominantEl / deficitEl / isStrong + (R79 sprint 5) gyeokguk anchor + yongsin anchor + (R79 sprint 6) shinsa anchor.
- **여전히 derive X**: 일주 60종 명시 phrase / 십신 freq distribution / 통근 강도 / 합·충·형·파·해 / 강도 score 정밀.
- **결과**: anchor 8 entry / 5 entry / 8 entry 만 추가됨 → 전체 multinomial 표본 공간이 작아 본인 + 여친 동일 격국·용신·신살 trio 면 동일 anchor.

### D1~D4 — R79 deferred (메모리 [project_pillarseer_round_79.md:88-92])

| ID | 의제 | 위치 |
|---|---|---|
| D1 | 만세력 algorithmic fix (sample #2/#4/#5 일간 정합 — KASI vs unsin 시차/야자시/절기 boundary) | `lib/services/manseryeok_service.dart:474-549` + `tool/playwright_unsin_*.dart` |
| D2 | 조후용신 wire (계절 보정) | `lib/services/yongsin_service.dart:18-26` |
| D3 | 시간 입력 picker UX (30분 boundary 시각화 + 야자시 학파 선택) | `lib/screens/onboarding_screen.dart` (시간 입력 영역) |
| D4 | H1 가중치 조건부 swap (rootMiddleBonus ↔ rootTraceBonus, 5행 골든 보존 algorithmic 해법) | `lib/services/manseryeok_service.dart:22-34` |

---

## 2. 절대 보존 (모든 sprint G1 골든 가드)

- **5행 골든**: 1995-10-27 男 17:00 양력 → 木 16 / 火 21 / 土 17 / 金 41 / 水 4 + 일주 辛卯.
  - test: `test/critical_regression_test.dart`, `test/celebrity_calibration_test.dart`, `test/round79_golden_test.dart`.
- **R71-R79 시그니처**: 60일주 1440 phrase (today_event/notification) / 자미두수 hidden / 6각 radar / 십신 음양 10분류 / SajuContext + DynamicTextResolver / 알림 hh:mm picker / /today route.
- **테스트**: 504 PASS (R79 종료 시점) — Round 80 종료 시점 ≥ 504 PASS + 신규 테스트 추가.
- **flutter analyze**: 0 error.
- **사용자 mandate**: TestFlight 명시 X 면 배포 X.

---

## 3. Sprint 계획 (10 sprint)

| # | 의제 | 산출물 | codex 평가 | 5행 골든 |
|---|---|---|---|---|
| 1 | spec 작성 (본 문서) | `docs/round80_spec.md` | 9.9+ | 보존 |
| 2 | C1 — `_oneLinerFor` 60일주 phrase wire | `deep_content_service` 변경 + 골든 test 추가 | 9.9+ | 보존 |
| 3 | C2 — `_todayHookFor` + `_whyReasonFor` 60일주 phrase wire | `deep_content_service` 변경 + test | 9.9+ | 보존 |
| 4 | C3 — 6각 점수 변별력 확대 (격국·십신·신살 weighting + jitter range ↑) | `six_axis_score_service` 변경 + test | 9.9+ | 보존 |
| 5 | C4 — radar 색상 재설계 (값 강조 + matched 보조 채널) | `six_axis_radar` 변경 + screenshot test | 9.9+ | 보존 |
| 6 | C5 — `PersonalizationEngine` 십신 freq + 통근 + 합충 derive 확장 | `personalization_engine` + `dynamic_text_resolver` 변경 + test | 9.9+ | 보존 |
| 7 | D1 — 만세력 algorithmic fix (sample #2/#4/#5 일간) | `manseryeok_service` 변경 + 6 sample 테스트 (5행 골든 보존 algorithmic 해법) | 9.9+ | 보존 |
| 8 | D2 + D4 — 조후용신 wire + H1 조건부 swap | `yongsin_service` + `manseryeok_service` 변경 + test | 9.9+ | 보존 |
| 9 | D3 — 시간 picker UX (onboarding) | `onboarding_screen` 변경 + golden screenshot | 9.9+ | 보존 |
| 10 | cleanup + memory R80 + 인수인계 + 회귀 가드 + (사용자 mandate 후) TestFlight 1.0.0+40 | memory + handoff doc | 9.9+ | 보존 |

각 sprint 끝 codex audit (planner / generator / evaluator harness pattern). PASS 9.9+ 못 받으면 그 sprint 안에서 반복.

---

## 4. 산출 phrase pool 디자인 (C1/C2 sprint 2-3)

### oneLine — 60일주 × dominant 변동 (현재 5종 → 목표 60+)

옵션 A — 60일주 × 5행 풀 (300 phrase): 일주 명시 phrase + dominant 강조.
- 예: 辛卯 + 金 dominant → "벼리고 갈수록 단단해지는 결을 가진"
- 예: 辛卯 + 木 dominant (deficit 金) → "겉은 부드럽고 속은 단단한 결을 가진"
- 매핑: `60ji × 5dom = 300 entry`

옵션 B (추천) — 60일주 base phrase 60 + dominant 보조 5 = 65 phrase, 조합으로 60 + 5 = 300 variant 생성.
- base (60): 일주별 핵심 결 (辛卯 → "차분하게 결을 다듬는")
- 보조 (5): dominant 강조 형용사 (金 → "한결같이 / 벼린 듯이")
- 최종: "{보조} {base} 사람" 또는 base 단독.
- 토큰 효율 + 변별력 둘 다 달성.

### todayHook — 60일주 × dominant × 요일/주차 cycle (1440+ variant)

옵션: 60일주 × 5dom × 7요일 = 2100 variant. R77 메모리 "60일주 1440 phrase" pool 재활용.

### whyReason — 60일주 × dominant × deficit (1500 variant)

60 × 5 × 5 = 1500. 또는 dominant·deficit 조합 25종 × 60일주 base 60 = 1500 variant.

→ Sprint 2-3 generator 가 phrase pool 작성 + tone audit (한자 jargon 0 / 한국 MZ 친근 해요체 / 양면 단정).

---

## 5. C3 점수 변별력 확대 디자인 (Sprint 4)

### 현재 베이스 (line 170-244)
- love: 일간 element 베이스 + 식상 freq + ±5 jitter
- work: 관성 freq + 강약 + ±9 jitter
- money: 재성 freq + 일간 element + ±9 jitter
- health: 5행 균형 + ±6 jitter
- fame: 정관 freq + 인성 freq + ±9 jitter

### 추가 anchor 후보
1. **격국별 baseline shift** (8 정격 + 건록 + 양인 = 10 격국) — 정관격 → fame +5 / 식신격 → money +5 / 칠살격 → work +8 / 양인격 → 건강 -3 등.
2. **용신/희신 강도** — 일간 강약 따라 ±5 보정.
3. **신살** — 천을귀인 → fame +3 / 도화 → love +5 / 양인 → work +5 / 화개 → 학문 +3 / 백호 → 健康 -2.
4. **통근 강도** — 일간 통근 ↑ → 全 baseline +3 (자기 영역 강함).
5. **합·충** — 일주 충 → health -5 / 일주 합 → love +5.
6. **jitter range ↑** — `% 7` 로 -3~+3 (현재 ±2) 또는 `% 9` 로 -4~+4.

→ 같은 5행 분포라도 격국·용신·신살 다르면 6각 분포 ±15~30 점 차이 발생.

### 골든 가드
- 1995-10-27 男 17:00 → 6각 점수 baseline test (Round 80 sprint 4 generator 가 신규 골든 추가).
- 점수 ±5 이내 변동 OK / 그 이상 차이 = 회귀 fail.

---

## 6. C4 차트 색상 재설계 (Sprint 5)

### 현재 (modal mismatch)
- 색·크기·ring 모두 `crossMatches` 기준.

### 옵션 A (추천) — 값 = 채도, matched = ring + label ✨
- 점 색: 단일 base color (ink), 채도/투명도는 값 비례 (값 크면 진하게).
- ring: matched 인 축에만 외곽 ring (얇은 accent).
- label ✨: matched 축 라벨 옆에 ✨ 만.

### 옵션 B — 값 = ring 굵기, matched = 색 (현재 방식 유지)
- 변별력 ↓ — 사용자 직관 어긋남 그대로.

### 옵션 C — 값 = 색상 (heat), matched = label ✨
- 값 0-30 → 회색 / 30-60 → ink / 60-100 → accent.
- matched = ✨ label 만.

→ Sprint 5 generator 가 옵션 A / C 비교 후 codex 평가.

---

## 7. 산출 commit 정책

- 각 sprint 끝 단일 commit: `feat(pillarseer): Round 80 sprint N — <한 줄 요약> (codex 9.XX PASS)`
- 메모리: sprint 9 또는 10 에 update (R79 stale 도 같이).
- 인수인계.md: sprint 10 에서 Round 80 섹션 추가.
- TestFlight 1.0.0+40 = 사용자 명시 후만.

---

## 8. NON-GOAL (Round 80 X)

- TestFlight 자동 배포 (사용자 mandate).
- 자미두수 UI 노출 (Round 70 숨김 유지).
- 새 기능 (구독·Firebase·RevenueCat 등 — 사용자 mandate 후 별도 라운드).
- 영어 i18n 새 콘텐츠 (영문 leak fix 만 회귀 가드).
- 평생사주 17 섹션 본문 의미 유사도 ↑ (R74 영역 — Round 81+).

---

> 본 spec = round80_spec ground truth. 각 sprint 의 generator subagent 는 본 spec 의 해당 ID (C1/C2/.../D4) 정확히 구현. 매 sprint 끝 codex audit 9.9+ PASS 까지 generator 반복.
