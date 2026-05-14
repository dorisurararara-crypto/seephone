# Round 79 — Sprint 1 가설 도출 (사용자 "안 맞아" 원인 8가설)

> Sprint 1 산출물. **audit only / 코드·test 변경 0**. Top 3 fix 후보 도출이 목표.
>
> **이 문서는 개발 audit 용 — 사용자에게 노출 안 됨**. 코드 reference (file:line) / 영문 약어 (예: H1·diff·grep) 는 개발자 용어. 사용자 UI 본문은 별도 sprint 5-7 에서 한국 MZ 중학생 K-POP 팬 직설 친근 해요체 만 노출. UI 본문에는 한자 jargon · 영문 약어 · 개발자 용어 전부 0.

## 0. 사용자 불만 (verbatim)

> "우리 앱은 진짜 안 맞아. 운세의신 무료-평생사주가 진짜 잘 맞았어."
> 추가: "내 사주 = 평생사주만 나오게."

## 1. 현재 상태 (Sprint 1 audit 결과)

### 1.1 5행 계산 위치
- `lib/services/manseryeok_service.dart:22` — `monthBranchBoost = 3.0` (Round 75 calibration).
- `lib/services/manseryeok_service.dart:27-34` — `stemWeight 1.4` / `dayStemSelfBonus 1.2` / `rootMainBonus 1.6` / `rootMiddleBonus 0.6` / `rootTraceBonus 0.3` / `monthRootMultiplier 1.5` / `exactLuBonus 0.8` / `pillarWeights [0.8, 1.4, 1.6, 1.1]`.
- `lib/services/manseryeok_service.dart:474-549` — `_calculateElements(monthBoost=3.0)` 5행 분포 계산.
- `lib/services/thong_geun_service.dart:1-155` — 통근 강도 0~3 (없음/여기/중기/본기). `jijangGanRatio` table.

### 1.2 신강·격국·용신·십신
- `lib/services/strength_service.dart:37-40` — threshold (`70 / 55 / 45 / 30`).
- `lib/services/strength_service.dart:51-110` — 강도 = 일간 element + 인성 element + 통근 bonus (월지 ×1.5).
- `lib/services/gyeokguk_service.dart:25-39` — 월지 본기 십신 → 격국 (8 정격 + 건록·양인). 한자 jargon 본문 포함 ("정관격 — 책임감·명예..." `desc` 필드).
- `lib/services/yongsin_service.dart:18-26` — 일간 + 강약 + 5행 분포 → 용신 + 희신 + reason.

### 1.3 신살
- `lib/services/shinsa_service.dart:1-240` — 8 신살 (`check(...)` count): 역마 / 도화 / 화개 / 천을귀인 / 문창귀인 / 양인 / 괴강 / 백호.
- `lib/services/today_event_service.dart:328-344` — `shinsaPriority` 24 신살 우선순위 list (8 핵심 + 12 신살 8 + 공망 + extra). 12 신살 (천살·지살·장성·반안·망신·육해·년살·화개살) 은 `lib/services/today_event_service.dart:316` 의 "12 신살" 그룹.
- `lib/services/gong_mang_service.dart:1-114` — 공망 단독.

### 1.4 합·충·형·파·해
- `lib/services/hapchung_service.dart` — Round 78 sprint 6 wire 완료.

### 1.5 personalization (UI 본문 영역) — H3 핵심 영역
- `lib/services/personalization_engine.dart:94-146` — `PersonalizationEngine.buildFor(saju)`.
  - **derive: dayMaster / dayMasterElement / monthBranch / season / dominantEl / deficitEl / isStrong**.
  - **DERIVE 안 됨: 격국 / 용신 / 십신 freq / 신살 / 통근 / 합충 / 강도 score**.
  - chartHash 는 4기둥 + 5행 + 나이 → seed deterministic.
  - 본문 fallback (`_fallbackHeadKo/_fallbackBodyKo/_fallbackActionKo/_fallbackCautionKo`) 은 dominantEl + deficitEl + season 만 사용. **격국·십신 jargon 없는 본문이지만 그만큼 사주 derive 약함.**
- `lib/screens/result_screen.dart:990` — `_ForYouTodaySection.build()` 에서 `PersonalizationEngine.buildFor(result)` 호출. **result_screen 의 가장 personal 한 영역인데 격국·용신·신살 wire X.**
- DynamicTextResolver 는 home_screen / today_deep_service / new_year_2026_screen 만 wire.

### 1.6 화면 분리 영역 (D)
- `lib/screens/result_screen.dart:50-85` — `kTodayEventDetailAnchor` GlobalKey + `/result?anchor=today_event` deep-link scroll.
- `lib/screens/result_screen.dart:4021+` — `_TodayEventDetailSection` (today_event_service wire).
- `lib/screens/home_screen.dart:1622` — `_TodayEventCard` 클릭 → `/result?anchor=today_event` push.
- `lib/screens/home_screen.dart:1714+` — `_TodayDeepReadingSection` (home 에도 있음).
- `lib/router.dart` — `/today` 경로 없음. `protected` list 에 `/result`, `/result/share`, `/onboarding`... `/today` 없음.

### 1.7 baseline 보존 의무
- **5행 골든 1995-10-27 男 → 16/21/17/41/4** (`test/critical_regression_test.dart`, `test/celebrity_calibration_test.dart` 등).
- 495 test PASS (R78 결과).

---

## 2. 가설 8개 (H1~H8)

### H1 — 5행 % 가중치가 unsin 와 ±5% 이상 어긋남
- **증거**: Round 75 calibration 은 1995-10-27 男 골든 (16/21/17/41/4 = 金 41%) 한 sample 기반. 다른 sample 의 unsin 비교 X.
- **위치**: `lib/services/manseryeok_service.dart:22-34` (8 상수).
- **검증 방법**: Sprint 2 의 Playwright sample 10개 × 우리 앱 결과 vs unsin 결과 5행 % diff 측정. 평균 ≥ 5%p 이면 가설 통과.
- **예상 fix**: `monthBranchBoost` ∈ {2.5, 3.0, 3.5} 시도 + `rootMainBonus / rootMiddleBonus / rootTraceBonus` 비율 재calibration. **5행 골든 보존 의무**.
- **5행 골든 영향**: **5행 계산 영향 高** — 모든 가중치 변경 시 1995-10-27 男 16/21/17/41/4 깨질 위험 高. 후보 시도 후 골든 통과만 채택.
- **우선순위**: 高 (가장 높은 % 정확도 직결).

### H2 — 격국 anchor 가 본문에 충분히 wire 안 됨
- **증거**: `lib/services/personalization_engine.dart` 의 PillarProfile derive 에 격국 (`GyeokgukService.judge` 결과) 없음. fallback 본문에도 격국 anchor 0.
  - `lib/services/gyeokguk_service.dart:42-126` — `_gyeokgukOf(god)` 안 `desc` 필드 ("책임감·명예·사회적 인정의 흐름") 격국 anchor 본문 정의되어 있으나 `_ForYouTodaySection` 에서 사용 X.
- **위치**: `lib/services/personalization_engine.dart:94-146` (buildFor), `lib/services/gyeokguk_service.dart:42-126` (격국 desc 본문 정의), `lib/screens/result_screen.dart:990` (UI consumer).
- **검증 방법**: 같은 일간 다른 격국 (예: 1995-10-27 男 정관격 vs 가상 식신격) 두 sample 의 PersonalReading.bodyKo diff 측정. diff < 30% 이면 가설 통과.
- **예상 fix**: PillarProfile 에 `gyeokguk` / `yongsin` 필드 추가 + `_ForYouTodaySection` 을 DynamicTextResolver 기반으로 재작성 (R78 sprint 3 패턴 따라).
- **5행 골든 영향**: **5행 계산 영향 0 — 1995-10-27 男 16/21/17/41/4 변화 0** (본문 변경만).
- **우선순위**: 高 (사용자가 가장 직접 체감 — 본문 매칭률 직결).

### H3 — 해석 본문이 사주 결과와 분리됨 (R78 personalization 영역 deprecation 후보)
- **증거 (강력)**:
  - `lib/services/personalization_engine.dart:96-146` — buildFor 가 derive 하는 ctx 가 PillarProfile (dayMaster + dominantEl + deficitEl + season + isStrong) 뿐.
  - 격국 / 용신 / 십신 freq / 신살 / 통근 / 합충 / strength score 사주의 핵심 derive 전부 미반영.
  - `lib/services/personalization_engine.dart` 안 `_atoms` 의 condition function 도 PillarProfile field 만 query (격국·용신 condition 0).
- **위치**: `lib/services/personalization_engine.dart:94-443` (전체, 350 line). `lib/screens/result_screen.dart:990` 가 유일한 UI consumer.
- **검증 방법**: 실제 grep 결과 (`grep -rn "PersonalizationEngine.buildFor" lib/ test/`):
  ```
  lib/screens/result_screen.dart:990:    final p = PersonalizationEngine.buildFor(result);
  test/widget_test.dart:94:      final p1 = PersonalizationEngine.buildFor(r1, now: DateTime(2026, 5, 12));
  test/widget_test.dart:95:      final p2 = PersonalizationEngine.buildFor(r2, now: DateTime(2026, 5, 12));
  test/widget_test.dart:110:      final p1 = PersonalizationEngine.buildFor(iu, now: DateTime(2026, 5, 12));
  test/widget_test.dart:111:      final p2 = PersonalizationEngine.buildFor(v, now: DateTime(2026, 5, 12));
  test/widget_test.dart:125:      final p = PersonalizationEngine.buildFor(r);
  test/integration_flow_test.dart:64:      final p = PersonalizationEngine.buildFor(r);
  ```
  → **UI consumer 1곳 (lib/screens/result_screen.dart:990) + test 호출 6곳**. test 호출은 UI render 영향 0. 같은 일간 다른 격국 두 sample 의 4 line (head/body/action/caution) diff 측정. **diff <10% 이면 H3 강력 통과**.
- **추가 검증 (DynamicTextResolver 미사용 적출)**:
  - `grep -rn "DynamicTextResolver" lib/` → wire 위치: `lib/screens/home_screen.dart:368, 390`, `lib/screens/reports/new_year_2026_screen.dart:334-335`, `lib/services/today_deep_service.dart:126-127, 134-135`.
  - **`lib/screens/result_screen.dart` (가장 핵심 영역) 안 DynamicTextResolver 호출 0** — `_ForYouTodaySection.build` 가 격국·용신·신살 freq·통근·strength 어느 것도 derive 본문에 wire 안 함.
  - **result_screen.dart 의 section 단위 적출** (DynamicTextResolver 미사용 + 격국·용신 derive 0 후보 — sprint 5 진입 시 마이그레이션 대상):
    1. `_ForYouTodaySection` (`lib/screens/result_screen.dart:982-1049`) — PersonalizationEngine.buildFor 만 사용. 가장 직접 마이그레이션 대상.
    2. `_ChartAttributesSection` (`lib/screens/result_screen.dart:566-794`) — yongsin.yongsin label 만 노출 (`lib/screens/result_screen.dart:641-642`), 본문 격국 anchor 0.
    3. `_FourPillarsSection` (`lib/screens/result_screen.dart:795-885`) — 사주 raw 표시 only, 본문 derive 0.
    4. `_ThreeStrokesSection` (`lib/screens/result_screen.dart:886-981`) — 정적 본문 가능성 (audit 보강 후 결정).
    5. `_FiveElementsSection` (`lib/screens/result_screen.dart:1050-1215`) — % 표시, 본문 derive 0.
    6. `_LifeThemesBlock` (`lib/screens/result_screen.dart:2174-2393`) — life themes 정적 본문 후보 (audit 후 결정).
    7. `_ProHooksSection` (`lib/screens/result_screen.dart:2394-2729`) — paywall hooks, 본문 derive 적음.
  - sprint 5 마이그레이션 우선순위: 1 (`_ForYouTodaySection`) → 다음 sprint 잠재 후보.
- **예상 fix**: 두 옵션.
  - (a) PersonalizationEngine 폐기 → `_ForYouTodaySection` 을 DynamicTextResolver + SajuContext 기반으로 재작성 (R78 패턴).
  - (b) PillarProfile 에 격국/용신/신살 필드 추가 + `_atoms` condition 확장. 둘 다 가능하나 (a) 가 R78 트랙과 정합.
- **5행 골든 영향**: **5행 계산 영향 0 — 1995-10-27 男 16/21/17/41/4 변화 0** (본문 변경. `test/widget_test.dart:94-125` + `test/integration_flow_test.dart:64` 의 PersonalReading 호출 호환 유지 의무).
- **우선순위**: 高 (Round 79 잠재 대박 — 사용자 "안 맞아" 의 가장 직접 원인 가능성).

### H4 — 신살 적용 범위가 좁음
- **증거**: `lib/services/shinsa_service.dart` 안 8 신살 (역마/도화/화개/천을귀인/문창귀인/양인/괴강/백호). `lib/services/today_event_service.dart:328` 의 `shinsaPriority` 24 list 와 합치면 약 24개 (8 핵심 + 12 신살 + 공망 + extra). unsin 신살 개수는 sprint 2 (Playwright) / sprint 3 (WebSearch) 결과로 확정 — 본 sprint 1 에서는 추정 X, sprint 2/3 후 H4 통과 여부 판정.
- **위치**: `lib/services/shinsa_service.dart:1-240` (8 `check(...)` 호출 분포), `lib/services/today_event_service.dart:328-344` (24 priority list).
- **검증 방법**: Sprint 2 Playwright sample 의 신살 list 합집합 (unsin 결과 텍스트에서 신살 추출) vs 우리 8 핵심 + 24 priority 비교. 평생사주 영역 (`lib/screens/result_screen.dart`) 노출 vs 오늘 영역 (`lib/services/today_event_service.dart`) 노출 분리 audit 도 함께. **diff 결과로 H4 통과/부정 판정 — sprint 1 에서는 통과 단정 X**.
- **예상 fix**: shinsa_service.dart 의 핵심 8 → unsin 핵심 list 와 일치 (학파 검증). 24 list 안 missing 신살 식별. **후보는 sprint 2/3 결과 받기 전 확정 X** — sprint 2 의 Playwright 합집합 + sprint 3 의 WebSearch 학파 검증 후 결정. (예시 후보로 천덕귀인 / 월덕귀인 / 학당 / 금여 등 거론 가능하나 본 sprint 1 에서는 확정 X).  의료·금융·사망 단정 X.
- **5행 골든 영향**: **5행 계산 영향 0 — 1995-10-27 男 16/21/17/41/4 변화 0** (본문 길어짐 + 라벨 추가).
- **우선순위**: 中 (sprint 2/3 결과 후 확정).

### H5 — 십신 강약 임계값이 보수적
- **증거**: `lib/services/strength_service.dart:37-40` — `thresholdVeryStrong=70 / Strong=55 / Balanced=45 / Weak=30`. 강도 base = dayMasterElement % + inseong % (line 87 `int strong = elementValue(dm) + elementValue(ins);`). 따라서 일간 + 인성 합계 70+ 이어야 신강 — 일반 sample 은 대부분 신약·신쇠로 분류될 가능성.
- **위치**: `lib/services/strength_service.dart:37-40` (threshold), `lib/services/strength_service.dart:86-110` (강도 계산), `lib/services/strength_service.dart:112-131` (label dispatch).
- **검증 방법**: Sprint 2 sample 10개의 우리 앱 strength label 분포 vs unsin 의 신강·신왕·중화·신약 분포 비교. 분포 차이 ≥ 30% 이면 가설 통과.
- **예상 fix**: threshold 조정 (예: 60/45/35/20) — 단 본문 흐름과 함께 검토. **모든 후보 시도 후 1995-10-27 男 정관격 신강·신약 expected 라벨 보존** (test/critical_regression_test.dart 의 strength assertion 있으면 함께 검토).
- **5행 골든 영향**: **5행 계산 영향 0 — 1995-10-27 男 16/21/17/41/4 변화 0** (% 자체 변경 X). 단 strength label 변경 시 yongsin (신강→식상·재성·관성 / 신약→인성·비겁) 변동 → 본문 변동 가능.
- **우선순위**: 中 (sprint 2 sample 분포 분석 후 확정).

### H6 — 용신 5축 wire 누락 → **부정 결과 (negative finding)**
- 본래 가설: yongsin 5축이 wire 안 되어 사용자가 추상 "용신 木이에요" 만 봄.
- **증거 (반증)**: 다음 위치에서 5축 wire 완료 확인:
  - `lib/services/yongsin_service.dart:128-167` — `guideAxesKo(yongsin)` 5행 × 5축 25 entry record.
  - `lib/services/yongsin_service.dart:217-225` — `oneAxisLineKo/En(yongsin, seed)` 1축 1줄 dispatch.
  - `lib/services/today_deep_service.dart:149-150` — `YongsinService.oneAxisLineKo/En(ctx.yongsin, ctx.chartSeed)` actions 끝에 join (실제 5축 wire 확인).
  - `lib/screens/result_screen.dart:1497-1559` (Yongsin section — label + reason + compensationGuide).
  - `lib/screens/home_screen.dart:368-390` (DynamicTextResolver.yongsinSuffix wire — 격국+용신 suffix).
- **위치**: `lib/services/yongsin_service.dart:1-232` 전체, `lib/services/today_deep_service.dart:149-150`, `lib/screens/result_screen.dart:1497-1559`, `lib/screens/home_screen.dart:368-390`.
- **검증 방법 (수행 완료)**: grep `oneAxisLineKo` → wire 있음. grep `guideAxesKo` → 5축 25 entry 정의됨. wire 위치 4곳 모두 확인.
- **예상 fix**: 추가 작업 X. (단 H3 PersonalizationEngine 폐기 후 `_ForYouTodaySection` 안 yongsin suffix 추가 wire 후보 — Top 3 fix 의 H3 안 포함).
- **5행 골든 영향**: **5행 계산 영향 0** (1995-10-27 男 16/21/17/41/4 변화 0).
- **우선순위**: 低 (R78 검증 통과 / negative finding — 본 라운드 작업 0).

### H7 (검증 전 가설) — 합·충 본문 dynamic 정도 audit 후보
- **본 sprint 1 에서는 검증 안 함**. 정적 vs 동적 비율은 sprint 2 의 Playwright 결과 + sprint 5 진입 전 audit 으로 확정.
- **위치**: `lib/services/hapchung_service.dart:1-376` (합/충/형/파/해 5종 + 삼합 + 방합 분석).
  - `lib/screens/result_screen.dart:19` (import), `lib/screens/result_screen.dart:1881` (analyzeChart), `lib/screens/result_screen.dart:1896` (findSamhap), `lib/screens/result_screen.dart:1902` (findBanghap), `lib/screens/result_screen.dart:1971` (hapInterpretation), `lib/screens/result_screen.dart:2038` (chungInterpretation).
- **가설 (확정 X)**: `hapInterpretation(ko)` / `chungInterpretation(ko)` 본문이 사주별 derive 가 아닌 정적 return 일 가능성 — 본 sprint 에서 source 확인 안 함. sprint 5 진입 전 audit 후 통과 여부 결정.
- **검증 방법**: 같은 일간 다른 시지/년지 두 sample 의 합·충 본문 diff 측정. **sprint 1 에서는 통과 단정 X**.
- **예상 fix (가설 통과 시)**: DynamicTextResolver wire 추가 (격국·용신 anchor 조합 본문).
- **5행 골든 영향**: **5행 계산 영향 0 — 1995-10-27 男 16/21/17/41/4 변화 0** (본문만).
- **우선순위**: 中 (검증 후 결정).

### H8 — 대운 흐름 표현이 추상 → **부정 결과 (negative finding)**
- 본래 가설: 같은 대운 키워드 다른 사주여도 본문이 비슷함.
- **증거 (반증)**: R78 sprint 7 대운·신년 12달 동적화 완료.
  - `lib/services/daewoon_service.dart:1-330` (R75 chain wire — 대운 전체 chain 계산).
  - `lib/services/life_stage_service.dart:1-260` (3 phase paragraph DaewoonService.chain wire — Round 73 sprint 2).
  - `lib/screens/result_screen.dart:162-163` (LIFE STAGE 섹션 mount), `lib/screens/result_screen.dart:3356-3412` (`_LifeStageSection` widget), `lib/screens/result_screen.dart:3371` (`LifeStageService.compute` 호출).
  - `lib/screens/reports/new_year_2026_screen.dart:334-335` (DynamicTextResolver gyeokgukAnchor + yongsinSuffix wire 완료).
- **위치**: `lib/services/daewoon_service.dart:1-330`, `lib/services/life_stage_service.dart:1-260`, `lib/screens/result_screen.dart:3356-3412`, `lib/screens/reports/new_year_2026_screen.dart:334-335`.
- **검증 방법 (수행 완료)**: `test/life_stage_service_test.dart:1-146` 안 "같은 60갑자 일주 + 다른 천간/지지 = phrase ≥30% 차별 (Jaccard)" assertion (이미 PASS) 이 동적화 보존 가드. `test/life_stage_service_test.dart` 자체가 가설 반증.
- **예상 fix**: 추가 작업 X (R78 sprint 7 wire 완료).
- **5행 골든 영향**: **5행 계산 영향 0** (1995-10-27 男 16/21/17/41/4 변화 0).
- **우선순위**: 低 (R78 검증 통과 / negative finding — 본 라운드 작업 0).

---

## 3. Top 3 fix 후보 (Sprint 5-6 입력)

1. **H3 (高 / 잠재 대박)** — `_ForYouTodaySection` 의 PersonalizationEngine 호출을 SajuContext + DynamicTextResolver 로 마이그레이션. 격국·용신·신살 freq·통근·strength 모두 derive 본문에 wire. **사용자 "안 맞아" 의 가장 직접 원인 후보**.
2. **H2 (高)** — 격국 anchor 본문 mapping 확대. `dynamic_text_resolver` 에 격국별 / 격국+십신 본문 pool 추가. PersonalReading 의 head/body/action/caution 4 line 모두 격국 derive 분기.
3. **H1 (高 / 정량)** — Sprint 2 Playwright sample 결과 평균 fit. 5행 골든 1995-10-27 男 16/21/17/41/4 보존하면서 다른 sample 의 unsin diff ≤ 5%p 목표.

**Top 3 우선순위 결정**: H3 ≥ H2 > H1.
- H1 는 5행 % 정량 보정 (sprint 5 의 가중치 영역).
- H3 + H2 는 본문 매칭률 직결 (사용자가 직접 체감).
- 사용자 발화 "안 맞아" 는 **5행 % 정확도 (H1) 보다 본문 매칭률 (H3·H2)** 가능성 높음 — R78 까지 5행 % 는 R75 가중치 보정으로 보존됨. 새 라운드 추가 가치 = 본문 연결.

**결정 기준 (분기 트랙)**:
- **트랙 1 (본문 매칭률)**: H3 → H2 순서. sprint 5 의 `_ForYouTodaySection` 마이그레이션 (H3) → sprint 5-6 의 격국 anchor 본문 pool 확대 (H2). 5행 % 자체 변경 X — 골든 보존 자동.
- **트랙 2 (5행 % 정확도)**: H1 만. sprint 5 의 `lib/services/manseryeok_service.dart:22-34` 가중치 후보 시도 + 골든 1995-10-27 男 16/21/17/41/4 보존 후보만 채택. 트랙 1 과 독립 — 가중치 후보 통과 못해도 트랙 1 결과는 별 영향 0.
- **분기 이유**: 본문 (트랙 1) 변경은 5행 계산 영향 0 / 5행 (트랙 2) 변경은 본문 변경 0. 두 트랙 병행 시 회귀 가드 단순.

## 4. H4·H5·H7 (中) — Sprint 6 의존
- H4 신살 list 확대는 Sprint 2 의 unsin 합집합 결과 받은 후.
- H5 strength threshold 는 Sprint 2 sample 분포 분석 후.
- H7 합·충 본문 dynamic 화는 H2 / H3 fix 후 자동 개선 가능.

## 5. H6·H8 (低)
- R78 sprint 5 / sprint 7 산출 검증만 (Sprint 5 시 30분 audit).

## 6. NON-GOAL (재확인)
- TestFlight 배포 X (Sprint 10 trigger 까지).
- 자미두수 hidden 변경 X.
- 알림 picker 변경 X.
- profile / reports / discover 화면 본문 overhaul X (화면 분리 외).
- ChatGPT/Gemini API 호출 X.

---

> Sprint 2 의 Playwright sample 결과로 H1·H2·H4·H5·H7 검증 → Sprint 4 종합 calibration plan 확정 → Sprint 5-6 코드 변경.
