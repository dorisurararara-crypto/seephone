# Round 83 — P1 정확도 / UX 신뢰 7 항목 통합 fix plan

> Sprint 1 산출물. **audit + spec only / Flutter 코드 변경 0 / test 변경 0 / 배포 0**.
>
> **본 문서는 개발자 audit 전용 — 최종 사용자에게 절대 노출 안 됨.**
>
> 본 spec 안의 영문 단어 (P1-A~G / sprint 2~10 / G1~G7 / M1~M5 / fix / wire / mount / first-fold / deep-link / spec / commit / blacklist / risk / weightProfile / boundary / disclaimer) 와 한국어 도메인 단어 ("결" / "흐름" / "기운") 는 모두 개발자 planner / generator / evaluator 가 코드 위치·동작·검증을 빠르게 공유하기 위한 작업 용어. 본 spec 안에서 사용된 단어가 사용자 UI 에 그대로 노출되는 것은 **금지**.
>
> 단, R83 의 핵심 영역 = 사주 정확도 / transparency → **사주 도메인 명시 어휘 화이트리스트** ("사주 / 일주 / 대운 / 용신 / 격국 / 진태양시 / 자시 / 절기 / 음력 / 양력 / 도시 경도 / 억부용신 / 조후용신 / 격국용신") 는 사용자 노출 OK. 단 어휘 옆에 1줄 평이 풀이 wire 필수. 자세한 mandate 는 §4 M5 참고.

## 0. Round Overview

| 항목 | 값 |
|---|---|
| Round | 83 |
| 시작일 | 2026-05-15 (R82 sprint 14a 종결 직후) |
| 예정 sprint 수 | 10 (sprint 1 spec / sprint 2~8 P1 7 항목 fix / sprint 9 회귀 가드 / sprint 10 memory + (사용자 mandate 후) 배포) |
| 직전 Round | 82 (사용자 9문제 + 외부 reviewer 4 fix 통합, sprint 14a 까지 commit `d488b1a`, sprint 14b 배포 사용자 mandate 대기) |
| 사용자 trigger 시점 | R82 sprint 14a 종결 직후 사용자 mandate "R83 시작 — 더 수정 후 한 번에 배포" |
| 본 sprint 1 산출물 | `docs/round83_spec.md` (markdown 1개) |
| 본 sprint 1 코드 변경 | 0 (docs only) |
| 본 sprint 1 test 변경 | 0 (docs only) |
| 본 sprint 1 배포 | X (M2 mandate 준수) |
| Planner spec plan | `/tmp/plan_pillarseer_r83_s1.md` (12 섹션, 본 spec 안에 모두 반영) |
| 입력 backlog | `docs/round83_backlog.md` (P1 7 항목 ground truth) |

### 사용자 trigger 의도

R82 가 사용자 9문제 + 외부 reviewer 의 작은 fix 4개에 집중했어요 (commit `d488b1a` / 610 test / 5행 골든 보존). R82 sprint 14b 의 1.0.0+40 외부 베타 제출은 M2 mandate "내가 배포하라고 할때만해" 준수로 사용자 mandate 를 기다리고 있어요.

사용자 의도는 "R82 + R83 을 묶어서 1.0.0+40 통합 빌드 한 번에 외부 베타" 예요. R83 은 사용자가 직접 느낀 UI 정합 (UI 정보 과부하 / 어색한 표현 / 잘못된 탭 노출) 다음 단계 = **사주 정확도 / 신뢰도 transparency** 단계예요.

R83 의 P1 7 항목 모두 사용자 신뢰도와 바로 연결돼요:

- 만세력 algorithmic (P1-A / P1-C) → "이 앱 사주 계산 맞아?" 사용자 의구심 해소.
- 23시 자시 학파 (P1-B) → 30분 boundary 출생자 mismatch 해소.
- 용신 분리 표시 (P1-D) → 억부 / 조후 / 격국 3 layer 사용자 transparent.
- 출생 시간 모름 (P1-E) → 시주 미포함 결과 disclaimer.
- 셀럽 신뢰도 (P1-F) → discover_screen 셀럽 카드 라벨 "공개 생일 기반".
- "사주 계산 기준" 페이지 (P1-G) → 진태양시 / 자시 학파 / 절기 / 음력 / 도시 경도 명시. 글로벌 진출 (Co-Star) 단계 전 한국 mandate 단계 신뢰도 baseline.

### Planner spec plan 7 섹션 ↔ 본 spec 매핑

평가 조건 = planner spec plan 의 핵심 7 섹션을 본 spec 안에 모두 반영해요. 매핑은 다음과 같아요.

| Planner 섹션 (7개) | 본 spec 위치 |
|---|---|
| 1. 제품 컨텍스트 + 사용자 trigger | §0 Round Overview + §0 사용자 trigger 의도 |
| 2. P1 7 항목 표 + 항목별 진단 + fix 방향 | §1 P1 7 항목 표 + §2 항목별 진단 |
| 3. Sprint plan 10 sprint user story testable | §3 Sprint plan (sprint 1~10 표 + user story 1줄) |
| 4. 사용자 mandate M1~M5 + R70 (영구) + 디자인 톤 / 사주 도메인 어휘 화이트리스트 | §4 M1~M5 + R70 |
| 5. NON-GOAL list + Deferred list | §5 NON-GOAL + §7 Deferred |
| 6. R82 학습 (codex moving goalpost) | §6 R82 학습 |
| 7. 검증 plan G1~G7 + Round 73~82 reference + 인수인계 boundary | §7 검증 plan + §8 Round 73~82 reference + §8 R82 → R83 → R84 chain |

planner spec plan 원문은 12 subsection 으로 세분되어 있지만 본 spec 의 7 섹션 매핑이 12 subsection 의 내용을 모두 흡수해요. 본 spec 의 §0~§9 구조는 R82 spec 패턴 답습.

---

## 1. P1 7 항목 표 (P1-A ~ P1-G)

본 표는 `docs/round83_backlog.md` § 1 P1 7 row 를 기반으로 본 R83 에서 영향 범위 / 회귀 위험 / 검증 plan 컬럼을 보강한 것이에요.

| # | 항목 | 추정 위치 | fix 방향 | 영향 범위 | 회귀 위험 | 검증 plan |
|---|---|---|---|---|---|---|
| P1-A | 만세력 algorithmic 깊은 fix (Unsin/KASI 기준 + 일주 불일치 sample) | `solar_term_service.dart` 입추 / 입춘 / 동지 ±5분 + `manseryeok_service.dart` 야자시 / 조자시 학파 boundary | 사용자 추가 정성 sample ≥10 (R79 baseline 6 sample 와 별개 신규 sample) cross-check 후 절기·자시 boundary 보정 | solar_term_service + manseryeok_service + 5행 raw 분포 (M4 mandate 보존) | **高** (5행 골든 보존 algorithmic 어려움) | 사용자 추가 sample ≥10 의 일주 unsin 100% 일치 + R79 baseline 6 sample 의 #2/#4/#5 mismatch 잔존 추적 + 5행 골든 sample 보존 + R69 lock 보존 |
| P1-B | 23시 자시 학파 입력 안내 | `input_screen.dart` 시간 picker 영역 + helper text widget + arb key | 23h 영역 helper text + 30분 boundary 시각화 ("자시 = 23:00~01:00 / 학파 별 30분 boundary 다름") | input_screen widget + arb ko/en key + R76 hh:mm picker wire | **中** (시간 picker widget 변경) | 23h 영역 helper text mount + "자시" 어휘 1줄 풀이 wire + R76 picker 보존 |
| P1-C | H1 swap rootMiddleBonus ↔ rootTraceBonus | `manseryeok_service.dart:22~34` weightProfile 분리 | 두 모드 분리 (`appCalibrated` / `traditionalHiddenStem`) + 사용자 추가 정성 sample 비교 결과 audit 문서 | manseryeok_service 5행 raw 분포 algorithm + 5행 골든 mandate | **高** (5행 골든 algorithmic 보존 어려움) | weightProfile 두 모드 분리 + appCalibrated 모드 5행 골든 보존 + traditionalHiddenStem 모드 새 baseline 명시 |
| P1-D | 용신 억부/조후/격국 분리 표시 | `result_screen.dart` 용신 카드 영역 + `yongsin_service.dart` 3 layer 분리 | R80 sprint 6 D2 조후용신 wire 완료 base + 억부 / 조후 / 격국 3 영역 카드 분리 + 각 1줄 평이 설명 | result_screen 용신 카드 widget + yongsin_service 3 layer | **中** (result_screen widget 변경 + R82 sprint 7 first-fold 4 펼침 conflict 가능) | 용신 카드 3 영역 mount + "억부용신 / 조후용신 / 격국용신" 어휘 1줄 풀이 wire + 5행 골든 보존 + 첫 fold 4 펼침 보존 (카드 접힘 상태 mount) |
| P1-E | 출생 시간 모름 처리 | `input_screen.dart` "시간 모름" 체크박스 + `models/saju_result.dart` 시주 nullable + `result_screen.dart` 대운/성향 카드 흐림 처리 | "시간 모름" 옵션 + 시주 미포함 결과 disclaimer + 시간 영향 큰 영역 (대운/성향) 흐림 처리 | input_screen + saju_result model + result_screen 카드 영역 | **中** (data model 변경 + R75 5행 calibration conflict 가능) | 시주 nullable case disclaimer mount + 시주 있음 case 5행 골든 보존 + 시주 모름 case 시주 영향 분리 |
| P1-F | 셀럽 출생정보 신뢰도 라벨 | `discover_screen.dart` 셀럽 카드 widget + arb key `celebCardConfidenceLabel` | "공개 생일 기반의 가벼운 비교 (출생시간 미상)" 라벨 wire | discover_screen 셀럽 카드 + arb ko/en | **低** (라벨 추가만) | 셀럽 카드 라벨 widget mount + 한국어 본문 audit |
| P1-G | "사주 계산 기준" 설명 페이지 | `settings_screen.dart` 메뉴 추가 + 신규 `info_saju_calc_screen.dart` (또는 `info_screen.dart` 안의 새 섹션) | Settings → "사주 계산 기준" 항목 탭 시 진태양시 / 자시 학파 / 절기 / 음력 / 도시 경도 5 항목 평이 설명 페이지 | settings_screen 메뉴 + info_saju_calc_screen 신규 + arb ko/en | **低** (신규 페이지, widget tree 변경 X) | 페이지 mount + 5 항목 widget 존재 + 한자 jargon noun 단독 사용 0 + 사주 도메인 어휘 옆 1줄 풀이 wire |

→ 회귀 위험을 정리하면 低 (P1-F / P1-G), 中 (P1-B / P1-D / P1-E), 高 (P1-A / P1-C) 이에요. 회귀 위험이 낮은 순서로 sprint 를 진행해요 (사용자 신뢰도 느끼는 보강 빠르게 + algorithmic 보존 risk 마지막).

---

## 2. P1 항목별 진단 + fix 방향 상세

### #A — 만세력 algorithmic 깊은 fix (sprint 7)

- **추정 위치**:
  - `lib/services/solar_term_service.dart` — 입추 / 입춘 / 동지 ±5분 boundary 영역.
  - `lib/services/manseryeok_service.dart` — 야자시 / 조자시 학파 boundary (현재 정시 boundary 子 23:00~00:59 적용).
- **fix 방향**:
  1. 사용자 추가 정성 sample ≥10 (출생일·시·gender + unsin 또는 KASI 검증 일주 명시, R79 baseline 6 sample 와 별개 신규 sample) 먼저 받아야 함 mandate.
  2. 신규 sample ≥10 cross-check + R79 baseline 6 sample 의 잔존 mismatch #2/#4/#5 추적 → 절기 ±5분 + 자시 boundary 30분 학파 검증.
  3. 학파 boundary 차이 = `weightProfile` 옵션화 또는 절기 raw +/- ε offset 조정.
  4. 5행 골든 (1995-10-27 男 17시 16/21/17/41/4 + 일주 辛卯) 100% 보존 mandate (M4).
- **영향 범위**: solar_term_service / manseryeok_service / 5행 raw 분포. R69 lock matchCount 5/6 영향 가능.
- **회귀 위험**: 高. 5행 골든 보존 algorithmic 어려움. 사용자 추가 정성 sample 미수령 시 R84 위임 trigger condition 발동.
- **검증 plan**:
  - 사용자 추가 sample ≥10 의 일주 unsin (또는 KASI 검증) 100% 일치.
  - R79 baseline 6 sample 의 #2/#4/#5 잔존 mismatch 별도 추적 (R83 sprint 7 의 unsin 100% mandate 대상 X, 추적 audit 만).
  - 5행 골든 sample 보존 (1995-10-27 男 17시 16/21/17/41/4 + 일주 辛卯).
  - R69 lock 보존 또는 의도적 갱신 시 lock 갱신 commit 분리.
  - 신규 test: `test/round83_manseryeok_unsin_match_test.dart`.
- **Deferred trigger**: 사용자 추가 정성 sample < 10 이면 본 sprint 7 skip + R84 위임 (인수인계.md 명시).

### #B — 23시 자시 학파 입력 안내 (sprint 4)

- **추정 위치**:
  - `lib/screens/input_screen.dart` — 시간 picker 영역 (R76 hh:mm picker wire).
  - `lib/l10n/app_ko.arb` + `app_en.arb` — helper text key 신규.
- **fix 방향**:
  1. 23h 영역 helper text "자시 = 23:00~01:00 / 학파마다 30분 boundary 다름" 1줄 wire.
  2. 30분 boundary 시각화 (예: 23:00~23:29 = "오늘 일진 기준" / 23:30~00:59 = "내일 일진 기준" 학파 옵션 카드).
  3. 사용자가 모호하면 default = 정시 boundary (현재 앱 정책) 유지 + 학파 옵션 명시.
  4. 한자 어휘 "자시" 옆 1줄 평이 풀이 wire (예: "자시 (子時, 밤 11시부터 새벽 1시까지의 사주 시간대)").
- **영향 범위**: input_screen widget + arb ko/en 1쌍 + R76 picker 보존 가드.
- **회귀 위험**: 中. 시간 picker widget 변경, R76 hh:mm picker wire 보존 가드 필요.
- **검증 plan**:
  - 23h 영역 helper text mount widget test.
  - "자시" 어휘 옆 1줄 풀이 wire 검증.
  - R76 picker 회귀 가드.
  - 신규 test: `test/round83_jasi_helper_test.dart`.

### #C — H1 swap rootMiddleBonus ↔ rootTraceBonus (sprint 8)

- **추정 위치**:
  - `lib/services/manseryeok_service.dart:22~34` — `rootMiddleBonus` / `rootTraceBonus` 상수.
  - R81 deferred D4 + 외부 reviewer TOP 15 #7 (지장간 가중치 본기 > 중기 > 여기 vs 본기 > 여기 > 중기 학파 차이).
- **fix 방향**:
  1. 두 모드 분리 (`weightProfile`: `appCalibrated` / `traditionalHiddenStem`).
  2. `appCalibrated` = 현재 앱 baseline = 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존.
  3. `traditionalHiddenStem` = 본기 > 중기 > 여기 전통 학파 = 새 baseline (사용자 추가 정성 sample 비교 결과 audit 문서에서 본다).
  4. 사용자 설정 default = `appCalibrated` 유지, 옵션 활성 시 학파 선택.
- **영향 범위**: manseryeok_service 5행 raw 분포 algorithm + 5행 골든 mandate.
- **회귀 위험**: 高. 5행 골든 보존 algorithmic 어려움. M4 mandate 우선 — `appCalibrated` 모드 보존.
- **검증 plan**:
  - 두 모드 분리 test.
  - `appCalibrated` 모드 5행 골든 sample 보존.
  - `traditionalHiddenStem` 모드 새 baseline 명시.
  - 신규 test: `test/round83_root_bonus_swap_test.dart`.
- **Deferred trigger**: 사용자 추가 정성 sample 미수령 시 본 sprint 8 skip + R84 위임 (인수인계.md 명시).

### #D — 용신 억부/조후/격국 분리 표시 (sprint 6)

- **추정 위치**:
  - `lib/screens/result_screen.dart` — 용신 카드 영역.
  - `lib/services/yongsin_service.dart` — R80 sprint 6 D2 조후용신 wire 완료 base.
- **fix 방향**:
  1. 용신 카드 3 영역 분리 — 억부용신 (일간 강약 기준) / 조후용신 (계절 기운 기준) / 격국용신 (격국 보좌 기준).
  2. 각 영역 옆 1줄 평이 풀이 wire — 예: "억부용신 (일간 강약 기준의 용신)" / "조후용신 (계절 기운으로 본 용신, 추운 사주에 따뜻한 기운)" / "격국용신 (격국 보좌의 용신)".
  3. 카드 confidence = "강한 확신" / "두 줄기가 함께 보이는 복합 사주" 사용자 친근 어휘.
  4. 카드 default = 접힘 상태 mount (R82 sprint 7 first-fold 4 펼침 보존).
- **영향 범위**: result_screen 용신 카드 widget + yongsin_service 3 layer.
- **회귀 위험**: 中. R82 sprint 7 first-fold 4 펼침 와 conflict 가능 → 용신 카드 접힘 상태로 mount.
- **검증 plan**:
  - 용신 카드 3 영역 widget 존재 test.
  - 사주 도메인 어휘 1줄 풀이 wire 검증.
  - 5행 골든 보존.
  - 첫 fold 4 펼침 보존 (R82 sprint 7 회귀 가드).
  - 신규 test: `test/round83_yongsin_split_test.dart`.

### #E — 출생 시간 모름 처리 (sprint 5)

- **추정 위치**:
  - `lib/screens/input_screen.dart` — "시간 모름" 체크박스 신규.
  - `lib/models/saju_result.dart` — 시주 nullable 가드.
  - `lib/screens/result_screen.dart` — 대운/성향 카드 흐림 처리.
- **fix 방향**:
  1. Input "시간 모름" 옵션 (체크박스 또는 toggle).
  2. 체크 시 saju_result 의 시주 nullable + disclaimer "시주가 없어요 — 대운과 성향 영역은 정확도가 살짝 떨어져요" 1줄 wire.
  3. 시간 영향 큰 영역 (대운 / 성향 / 6각 radar 일부 axis) 흐림 처리 또는 보조 disclaimer.
  4. 시주 있음 case = 기존 5행 골든 보존 (M4 mandate).
  5. 시주 모름 case = 시주 영향 분리 (5행 raw / 일주 / 십신 / 대운 / 성향 중 시간 의존 영역 명시).
- **영향 범위**: input_screen + saju_result model nullable + result_screen 카드 흐림 처리.
- **회귀 위험**: 中. data model 변경 + R75 5행 calibration conflict 가능 → 시주 모름 case 와 시주 있음 case 분리 명시.
- **검증 plan**:
  - 시주 nullable 시 disclaimer mount.
  - 시주 있음 시 5행 골든 16/21/17/41/4 보존.
  - 시주 모름 시 시주 영향 분리 검증.
  - 신규 test: `test/round83_birthtime_unknown_test.dart`.

### #F — 셀럽 출생정보 신뢰도 라벨 (sprint 3)

- **추정 위치**:
  - `lib/screens/discover_screen.dart` — 셀럽 카드 widget.
  - `lib/l10n/app_ko.arb` + `app_en.arb` — `celebCardConfidenceLabel` 신규.
- **fix 방향**:
  1. 셀럽 카드 하단 또는 옆 라벨 wire — "공개 생일 기반의 가벼운 비교 (출생시간 미상)" 1줄.
  2. 출생시간 미상 셀럽 = 시주 미포함 = 정확도 caveat 사용자 transparent.
  3. 셀럽 카드 데이터 변경 X (celebrities.json 그대로).
- **영향 범위**: discover_screen 셀럽 카드 + arb ko/en 1쌍.
- **회귀 위험**: 低. 라벨 추가만.
- **검증 plan**:
  - 셀럽 카드 라벨 widget mount.
  - 한국어 본문 audit (한자 jargon X / AI 슬롭 X).
  - 신규 test: `test/round83_celeb_confidence_test.dart`.

### #G — "사주 계산 기준" 설명 페이지 (sprint 2)

- **추정 위치**:
  - `lib/screens/settings_screen.dart` — 메뉴 항목 추가.
  - 신규 `lib/screens/info_saju_calc_screen.dart` (또는 `info_screen.dart` 안의 새 섹션).
  - `lib/l10n/app_ko.arb` + `app_en.arb` — 5 섹션 key.
- **fix 방향**:
  1. Settings 메뉴 안에 "사주 계산 기준" 항목 추가.
  2. 탭 시 신규 페이지 mount — 5 섹션 평이 설명.
  3. 5 섹션 각각:
     - 진태양시 (서울 기준 약 -32분 보정, 천문 표준시).
     - 자시 학파 (子時 = 23:00~01:00, 학파별 30분 boundary 다름).
     - 절기 (입춘 / 입추 / 동지 등 24절기 기준 사주 월 boundary).
     - 음력 / 양력 (앱 입력 = 양력 default, 음력 변환 옵션).
     - 도시 경도 (서울 동경 127도 기준, 한국 mandate 단계 = 서울 보정).
  4. 각 섹션 1~2 줄 평이 풀이 + 사주 도메인 어휘 옆 1줄 풀이 wire.
  5. 글로벌 진출 (Co-Star) 단계 전 한국 mandate baseline.
- **영향 범위**: settings_screen 메뉴 + info_saju_calc_screen 신규 + arb ko/en.
- **회귀 위험**: 低. 신규 페이지, widget tree 변경 X.
- **검증 plan**:
  - 페이지 mount + 5 항목 widget 존재.
  - 한자 jargon noun 단독 사용 0.
  - 사주 도메인 어휘 옆 1줄 풀이 wire 검증.
  - 신규 test: `test/round83_info_saju_calc_test.dart`.

---

## 3. Sprint plan (10 sprint)

각 sprint 의 user story 는 testable 형식이에요. codex audit 9.9+ 못 받으면 해당 sprint 안에서 반복해요 (harness pattern, max 7 라운드 / 라운드마다 다른 audit file 사용).

| # | 의제 | user story (1줄 testable) | 산출물 | 회귀 위험 | 5행 골든 | R69 lock |
|---|---|---|---|---|---|---|
| 1 | spec (본 문서) | 사용자가 `docs/round83_spec.md` 1개 markdown 을 읽고 P1 7 항목 fix plan 을 이해할 수 있다. | `docs/round83_spec.md` | — | 보존 | 보존 |
| 2 | **P1-G** "사주 계산 기준" 설명 페이지 신규 | 사용자가 Settings 안의 "사주 계산 기준" 항목을 탭하면 진태양시 / 자시 학파 / 절기 / 음력 / 도시 경도 5 항목 평이 설명 페이지를 본다. | `settings_screen.dart` 메뉴 추가 + 신규 `info_saju_calc_screen.dart` + arb ko/en + test 신규 | **低** | 보존 | 보존 |
| 3 | **P1-F** 셀럽 출생정보 신뢰도 라벨 | 사용자가 Discover 화면 셀럽 카드에서 "공개 생일 기반의 가벼운 비교 (출생시간 미상)" 라벨을 본다. | `discover_screen.dart` 라벨 + arb ko/en + test 신규 | **低** | 보존 | 보존 |
| 4 | **P1-B** 23시 자시 학파 입력 안내 | 사용자가 Input 화면 23시 영역에서 30분 boundary 시각화 + 자시 학파 helper text 를 본다. | `input_screen.dart` helper text + arb ko/en + test 신규 | **中** | 보존 | 보존 |
| 5 | **P1-E** 출생 시간 모름 처리 | 사용자가 Input 화면 "시간 모름" 옵션을 선택하면 시주 미포함 결과 disclaimer + 시간 영향 큰 영역 (대운/성향) 흐림 처리를 본다. | `input_screen.dart` 옵션 + `saju_result.dart` nullable + `result_screen.dart` 흐림 처리 + test 신규 | **中** | 보존 (시주 있음 case) | 보존 |
| 6 | **P1-D** 용신 억부/조후/격국 분리 표시 | 사용자가 result_screen 용신 카드에서 억부용신 / 조후용신 / 격국용신 3 영역 분리 + 각 1줄 평이 설명을 본다. | `result_screen.dart` 용신 카드 분리 + `yongsin_service.dart` 3 layer + test 신규 | **中** | 보존 | 보존 |
| 7 | **P1-A** 만세력 algorithmic 깊은 fix (먼저 받아야 함: 사용자 추가 정성 sample ≥10) | 사용자가 추가로 받은 정성 sample ≥10 의 일주 unsin (또는 KASI 검증) 와 100% 일치한다 (R79 baseline 6 sample 와 별개의 신규 sample). | `solar_term_service.dart` + `manseryeok_service.dart` 보정 + test 신규 | **高** | 보존 (mandate) | 보존 또는 갱신 |
| 8 | **P1-C** H1 swap rootMiddleBonus ↔ rootTraceBonus (사용자 추가 정성 sample 비교 후) | 사용자가 weightProfile 두 모드 (appCalibrated / traditionalHiddenStem) 의 sample 비교 결과를 audit 문서에서 본다. | `manseryeok_service.dart:22~34` weightProfile + audit 문서 + test 신규 | **高** | 보존 (appCalibrated 모드) | 보존 또는 갱신 |
| 9 | 회귀 가드 + R69 lock + 5행 골든 통합 + R82+R83 분리 검증 | 사용자가 `flutter test` 전체 PASS 확인. 5행 골든 + R69 lock 보존. R82 fix + R83 fix 동시 보존. | `flutter analyze` 0 + `flutter test` 전체 PASS + 골든 test + R69 lock test + R82 시그니처 회귀 가드 | — | 보존 | 보존 또는 갱신 |
| 10 | memory R83 + 인수인계.md R83 섹션 + **(사용자 mandate 후만)** TestFlight 1.0.0+40 R82+R83 통합 외부 베타 ganzitester 제출 | 사용자가 본 memory (`project_pillarseer_round_83.md`) + 인수인계.md R83 섹션 commit 을 확인하고, 그 후 사용자가 "배포해" 라고 지시한 경우에만 1.0.0+40 외부 베타 제출 진행. | memory + 인수인계 commit + (사용자 mandate 후만) altool 업로드 | — | 보존 | 보존 |

### 작업 단계별 쉬운 한국어 풀이 (페르소나 적합 보강 — 5번 사용자 원칙)

위 표의 작업 단계 1줄 설명은 영문 약어가 섞여 있어요. 한국 MZ 중학생이 봐도 한 번에 이해하도록 다음과 같이 한국어로 다시 풀어요. 이 풀이는 작업하는 사람이 단계 시작할 때 의도를 다시 확인하는 용도예요 — 사용자에게 보이는 본문은 아니에요.

1. 1단계 — 이 문서 하나만 읽으면, 7가지 우선순위 항목 (사주 계산 기준 페이지, 유명인 신뢰도 표시, 자시 학파 안내, 시간 모름 처리, 용신 3종 분리, 사주 계산 정밀도, 숨은 글자 가중치) 각각의 고치는 방향과 위험을 한 번에 이해할 수 있어요.
2. 2단계 — 설정 메뉴 안에 "사주 계산 기준" 항목을 새로 만들어요. 사용자가 그 항목을 누르면 진태양시 / 자시 학파 / 절기 / 음력 / 도시 경도 5가지를 쉬운 한국어로 설명하는 페이지가 나와요.
3. 3단계 — 유명인 화면의 각 영역 옆에 "공개 생일 기반의 가벼운 비교 (출생시간 미상)" 표시 문구가 보이도록 추가해요.
4. 4단계 — 입력 화면의 23시 자리에서 자시 학파 안내 문구와 30분 경계 표시를 보여줘요. 새벽 0시 근처에 태어난 사용자가 학파마다 일주가 다를 수 있다는 점을 알게 해요.
5. 5단계 — 입력 화면에 "시간 모름" 선택지를 추가해요. 사용자가 그 선택지를 고르면, 결과 화면에서 시주가 없다는 안내 한 줄과, 시간에 영향을 많이 받는 영역 (대운·성향) 을 흐리게 처리해 보여줘요.
6. 6단계 — 결과 화면의 용신 영역을 억부용신 / 조후용신 / 격국용신 3개 영역으로 나눠요. 각 영역 옆에 어떤 용신인지 한 줄로 풀어 설명해요.
7. 7단계 — 사주 계산에서 절기 (입춘·입추·동지) 의 ±5분 부근과 자시 시작점을 더 정밀하게 맞춰요. 사용자가 추가로 보내준 정성 사례 (사용자가 직접 또는 외부 만세력으로 확인한 출생일·시간·일주 자료) 10건 이상 (이전 라운드의 기존 6 사례와 별개의 새 사례) 을 받은 다음에만 진행해요. **사례를 받기 전에는 사주 계산 로직 수정 절대 금지** (5행 골든 보존 우선).
8. 8단계 — 숨은 글자 가중치를 두 가지 방식 (지금 앱이 쓰는 기본값 / 전통 학파 기본값) 으로 나눠요. 사용자가 추가로 보내준 사례로 두 방식을 비교한 결과를 검토 문서 (작업자가 비교 결과를 정리해 두는 문서) 에 정리해요. 본 단계도 7단계와 같이 사례 10건 이상 먼저 받아야 함.
9. 9단계 — 모든 테스트가 통과하고, 1995-10-27 남 17시 사주의 5행 분포 16/21/17/41/4 + 일주 辛卯 가 그대로 유지되며, 이전 라운드에서 고친 부분도 같이 보존되는지 (원래대로 되돌아가지 않았는지) 확인해요.
10. 10단계 — 본 라운드 결과를 메모리 파일 + 인수인계 (다음 세션이 이어서 작업할 때 보는 문서) 에 정리해서 저장소에 올려요. 그 뒤에 사용자가 "배포해" 라고 직접 말한 경우에만 외부 시험판 (이전 라운드 + 이번 라운드 통합 1.0.0+40) 을 올려요.

### 단계 사이 의존 (쉬운 한국어 풀이)

- 2단계 / 3단계 (회귀 위험 낮음) 는 서로 독립이라 동시에 진행할 수도 있어요.
- 4단계 / 5단계 (회귀 위험 보통, 모두 입력 화면 영역) 는 4단계가 5단계보다 먼저예요. 자시 학파 안내가 "시간 모름" 선택지의 출발점이에요.
- 6단계 (회귀 위험 보통, 결과 화면 용신 카드) 는 이전 라운드의 조후용신 연결 작업이 끝난 위에서 진행해요. 2~5단계와 독립이에요.
- 7단계 / 8단계 (회귀 (원래대로 되돌아가는 일) 위험 높음, 사주 계산 정밀도 영역) 는 사용자 추가 정성 사례 10건 이상이 먼저예요. **사례를 못 받으면 7/8단계를 건너뛰고 다음 라운드로 넘겨요. 사례 받기 전에는 사주 계산 로직 수정 절대 금지.**
- 9단계 (회귀 가드, 예전 상태로 돌아가지 않게 막는 확인) 는 2~8단계의 모든 저장이 끝난 다음 마지막에 종합해요.
- 10단계 (배포) 는 사용자가 "배포해" 라고 말한 다음에만 진행해요 (2번 사용자 원칙).

### 7단계 / 8단계 건너뛰기 조건 (쉬운 한국어 풀이)

이번 라운드의 7단계 (사주 계산 정밀도) + 8단계 (숨은 글자 가중치 두 방식 (지금 앱 방식 / 전통 학파 방식) 으로 분리) 는 사용자가 추가로 보내준 정성 사례 (사용자가 직접 또는 외부 만세력으로 확인한 출생일·시간·일주 자료) 10건 이상 (이전 라운드의 기존 6 사례와 별개의 새 사례) + 학파 표준 비교 자료 (학파마다 다른 사주 계산 기준을 정리한 자료) 가 먼저예요.

**건너뛰기 조건**:
- 사용자가 추가로 보내준 정성 사례 (출생일·시간·성별 + 외부 만세력 또는 한국 천문연구원 (KASI) 검증 일주가 같이 명시된 자료, 이전 라운드의 기존 6 사례와 별개의 새 사례) 가 10건 미만이면 7/8단계를 건너뛰어요.
- 건너뛰면 다음 라운드로 넘겨요 (인수인계 문서의 이번 라운드 → 다음 라운드 연결에 같이 적어요).
- 건너뛰는 이유는 "사용자 추가 정성 사례 아직 못 받음 — 사주 계산을 바꾸는 일은 위험이 크고, 5행 골든 보존을 계산 방식만으로 지키기 어려워서, 4번 사용자 원칙 (5행 골든 보존) 을 우선" 이에요.
- **사례를 받기 전에는 사주 계산 로직 수정 절대 금지** — 4번 사용자 원칙 (5행 골든 보존) 의 가장 강한 보호선이에요.

**사례 받은 다음 진행 순서**:
1. 7단계 — 절기 ±5분 부근과 자시 시작점 더 정밀하게 보정 (계산 기준을 조금 더 정확하게 맞추는 일).
2. 8단계 — 숨은 글자 가중치 두 방식 (지금 앱이 쓰는 기본값 / 전통 학파 기본값) 으로 분리 (한쪽만 쓰지 않고 두 방식을 함께 보여주는 일).
3. 두 단계 모두 5행 골든 (1995-10-27 남 17시 16/21/17/41/4 + 일주 辛卯) 보존 확인이 필수예요.

### 단계별 사용자 노출 톤 체크리스트 (5번 사용자 원칙 적용 — 작업자가 매 단계 끝마다 확인)

각 단계의 작업자는 저장 직전에 다음 체크리스트로 사용자에게 보이는 본문 (문구 파일 / 문장 묶음 / 화면 글자 / 알림 문구 / 새 안내 페이지 본문) 만 점검해요. 이 명세 문서 본문 자체는 점검 범위 밖이에요 (작업자 검토용 문서).

- [ ] 어려운 한자 단어 단독 사용 0 — "본질" / "정수" / "결" / "운기" / "기운" / "결을 다듬는" / "벼린 칼" / "도검의 끝". 단 사주 도메인 허용 단어 목록 (§4 참고) 어휘는 옆에 1줄 풀이를 같이 보여주면 괜찮아요.
- [ ] 외국어 직역체 단어 단독 사용 0 — 사용자에게 어색한 직역 명사가 혼자 등장하지 않게 (이전 라운드 8단계의 어색 단어 목록 참고).
- [ ] 미안한 말투 0 — "죄송하지만" / "단정 짓기 어렵지만" / "확실하지는 않지만".
- [ ] 의료 단정 0 — "병이 나요" / "치료가 필요해요" / "의사 상담".
- [ ] 직장인 어휘 0 — "PT" / "리텐션" / "퍼포먼스" / "KPI" / "OKR".
- [ ] 작업 용어 단독 사용 0 — 영어 작업 약어 (연결 / 끼우기 / 첫 화면 / 깊은 연결 등 한국어로 다 풀어쓰기).
- [ ] 한글 동물 이름 (예: 금토끼·금원숭이) 단독 노출 0 — 이전 라운드 6단계 기준 (사용자 사주와의 관계 1줄을 같이 보여주기 필수).
- [ ] 긍정·중립·주의 비율 5:4:1 유지 — 이전 라운드 3 기준.
- [ ] 양면 단정 (한쪽 면만 보지 않고 두 면을 같이 말하는 표현) 30% 이상 — "강점이지만 ~ 주의" 같은 패턴.
- [ ] 행동 처방 (사용자가 오늘 무엇을 해보면 좋을지 알려주는 한 줄) 15% 이상 — "오늘 ~ 해봐요" 같은 패턴.
- [ ] (이번 라운드 특수) 사주 도메인 허용 단어 목록 (§4 참고) 어휘를 쓸 때 옆에 1줄 평이한 풀이를 같이 보여주기.

→ 위 체크리스트는 이 명세 문서 본문이 아니라 **2~8단계의 사용자에게 보이는 본문** 에 적용해요. 이 명세 문서 본문 자체는 작업자 검토용이에요.

---

## 4. 사용자 mandate 5개 + R70 (영구)

본 round 의 모든 sprint 가 다음 mandate 를 절대 룰로 지켜요. 위반 시 즉시 sprint 중단 + 사용자 보고예요.

### M1 — 자율 (사용자 mandate)

- 사용자 verbatim (CLAUDE.md / global.md): "자율 진행 — 묻기 전에 로컬 탐색·웹 검색 먼저. 진짜 사용자만 가능한 영역(Apple 2FA·신규 가입 등)만 사용자 대기 큐. 그 외 모두 자율."
- planner / generator / evaluator 패턴으로 사용자 손 0회 진행 (codex 9.9+ PASS 까지 반복, max 7 라운드).

### M2 — 자동 배포 X (사용자 mandate verbatim)

- 사용자 verbatim (R80 mandate, 2026-05-15): **"내가 배포하라고 할때만해"**.
- TestFlight 1.0.0+40 빌드·altool 업로드·외부 베타 제출 = 사용자 명시 후만.
- sprint 10 user story 의 IPA 자동 제출은 사용자 mandate 가 trigger.
- 1.0.0+39 (R79) 이미 외부 베타 ganzitester 제출 + 검증 완료 → R80 + R82 + R83 통합 빌드는 사용자 OK 후만 1.0.0+40 으로.

### M3 — 시뮬·에뮬레이터 새 부팅 X (사용자 mandate)

- 사용자 verbatim (global.md `⚠️ 7. 에뮬레이터/시뮬레이터 절대 금지`, 2026-05-11): "사용자 명시 허락 없이 안드로이드 에뮬레이터(AVD), iOS 시뮬레이터, 기타 가상 디바이스 절대 실행 금지."
- 이유: 이전 세션 에뮬레이터 부팅이 사용자 컴 멈춰 강제 종료까지 갔음.
- 본 round 의 UI 검증 = HTML mockup viewport / `flutter analyze` / `flutter test` / 사용자 실기기 USB 만 허용.
- 금지: `xcrun simctl boot ...` / `emulator -avd ...` / `flutter run` (디바이스 미연결 시).

### M4 — 5행 골든 보존 (R75 calibration)

- 1995-10-27 男 17:00 양력 → 木 16 / 火 21 / 土 17 / 金 41 / 水 4 + 일주 辛卯.
- 골든 test: `test/critical_regression_test.dart`, `test/celebrity_calibration_test.dart`, `test/round79_golden_test.dart`, `test/round80_*_test.dart`.
- R69 lock — matchCount 5 / matchedAxes [연애·일·돈·건강·평판] / 본성 78 / 연애 78 / 일 72 / 돈 74 / 건강 57 / 평판 71 (R80 갱신 baseline).
- 의도적 baseline 갱신 시 R69 lock test 동시 갱신 commit 분리 (sprint 9).
- **R83 특수**: sprint 7 (P1-A 만세력 algorithmic) + sprint 8 (P1-C H1 swap) 의 5행 골든 보존 algorithmic 어려움 → 사용자 추가 정성 sample ≥10 먼저 받아야 함 mandate. **사용자 추가 정성 sample (10건 이상, R79 baseline 6 sample 와 별개의 신규 sample, 외부 만세력 또는 KASI 검증 일주 명시) 을 받기 전에는 manseryeok_service / solar_term_service / weightProfile 의 사주 계산 로직 수정 절대 금지.** 이 mandate 위반 시 즉시 sprint 중단 + 사용자 보고.

### M5 — 한국 MZ 중학생 K-POP 팬 페르소나 (사용자 mandate)

- 페르소나 = Co-Star 글로벌 진출 전 한국 verification 페르소나. dorisurararara (Flutter 1인 개발자) + 여자친구 실 사용자.
- 사주 도메인 비전문가 — 한자 jargon · 영문 약어 · 개발자 용어 사용자 노출 본문에 0%.
- 톤 게이트 (사용자 노출 본문 — 후속 sprint 적용):
  - 직설 친근 해요체 (R74 baseline). 명령형·단정형 X.
  - 한자 jargon 0 — "본질" / "정수" / "결" / "운기" / "기운" / "결을 다듬는" / "벼린 칼" / "도검의 끝" (사용자가 의미 모를 한자어).
  - AI 슬롭 0.
  - MZ K-POP 친근 어휘 — "오늘 ~ 해봐요" / "당신 사주에서 ~ 가 강해요" / "~ 한 사람이에요" 자연.
  - 의료·법률·금융 단정 0.
  - Apologetic AI 어조 0.
  - 폴라리티 5:4:1 baseline (R73 lock).
  - 양면 단정 ≥30% / 행동 처방 ≥15% (R73 lock).
- **R83 특수 사주 도메인 어휘 화이트리스트**: 본 round 의 P1-A / P1-B / P1-C / P1-D / P1-G 는 사주 정확도 / transparency 영역. 다음 어휘는 사용자 노출 OK, 단 옆 또는 카드 안 1줄 평이 풀이 wire 필수:
  - "사주 / 일주 / 대운 / 용신 / 격국" — R83 P1-D / P1-G 핵심.
  - "진태양시 / 자시 / 절기 / 음력 / 양력 / 도시 경도" — R83 P1-G "사주 계산 기준" 설명 페이지 핵심.
  - "억부용신 / 조후용신 / 격국용신" — R83 P1-D 용신 분리 표시 핵심.
  - 예시 wire: "조후용신 (계절 기운으로 본 용신, 추운 사주에 따뜻한 기운)" / "진태양시 (서울 기준 약 -32분 보정, 천문 표준시)" / "자시 (子時 = 23:00~01:00 / 학파마다 30분 boundary 다름)".

### R70 — 자미두수 UI hidden (영구 마케팅 차별점)

- `kIsZiweiUiHidden=true` 플래그 보존 — 자미두수 12궁 별 이름 (자미성·천기성·태양성 등 nameKo) 사용자 노출 0.
- R82 sprint 5 의 12 결 풀이 라벨 보강 시에도 별 이름 nameKo noLeak 12×16 회귀 가드 wire 완료 — 본 R83 도 보존.
- R83 의 P1-D 용신 분리 표시 시 자미두수 별 이름 노출 0 가드 필수.

---

## 5. NON-GOAL (R83 X)

본 round 에서 안 하는 항목들이에요 (별도 라운드로 위임하거나, 사용자 mandate 받은 다음에만 진행해요):

1. **자미두수 UI 노출** — `kIsZiweiUiHidden=true` 보존 (R70 마케팅 차별점). 자미두수 UI 영역 신규 노출 0.
2. **새 기능** — 구독·결제·Firebase·RevenueCat·소셜·푸시 신규 채널·결제 wall. 별도 라운드 (R83 backlog P3-C).
3. **R82 sprint 8 잔여 본문** — saju_deep_slice 잔여 210 entry ko 본문 재작성. R83 backlog P4-C 위임.
4. **BottomNav 라벨 변경** — R83 backlog P2-A (한자 glyph 보조 장식). 별도 라운드.
5. **Home 단순화 (오늘 행동 중심)** — R83 backlog P2-B (first-fold 7 영역 순서). 별도 라운드.
6. **2026 신년운세 → 올해운 / Yearly Flow 라벨 갱신** — R83 backlog P2-C. 시즌감 영역 별도 라운드.
7. **Profile 공유 카드 템플릿 다양화** — R83 backlog P2-D (1080×1080 → 3~5 종). 별도 라운드.
8. **Reports K-pop 케미 진입 순서** — R83 backlog P2-E. 별도 라운드.
9. **글로벌 출생지/timezone 처리** — R83 backlog P3-A. **사용자 mandate 후만** (Co-Star 글로벌 진출 단계 trigger).
10. **모든 문구 l10n 정리** — R83 backlog P3-B (에러 / 스낵바 / placeholder / helper text 전체). 별도 라운드.
11. **영문 i18n 새 콘텐츠** — R83 backlog P3-D. 사용자 mandate 후만.
12. **폴라리티 캐릭터 영역 정정** — R83 backlog P4-A (`life_stage_pool.json` / `sipsin_persona.json` / `additional_life_pool.json` / `career_pool.json` / `wealth_detail.json` 5:4:1 폴라리티 본문 재작성). 별도 라운드.
13. **R78 hotspot H3 / H6 / H8 / H13 / H14** — R83 backlog P4-B. 별도 라운드.
14. **데일리 운세 Phase 2** — R83 backlog P4-D (12지 충/합/형/파/해 + 세운/월운/일진 + 신살 + 절기). 별도 라운드.
15. **코드 품질 P5 항목** — dart format / SajuProvider 영속 / SixAxisScore 타입 / DailyService clock 주입. 별도 라운드.
16. **디자인 톤 P6 항목** — README docs 동기화 / 접근성 글자 크기 / Reports accent. 별도 라운드.
17. **5행 raw 분포 변경** — R75 calibration (1995-10-27 男 17시 16/21/17/41/4) 보존 mandate (M4).
18. **R82 fix 변경** — sprint 2~12 fix (commit `2d19d57` ~ `10fc74e`) 의 변경 사항 보존, 회귀 0.
19. **자동 배포** — sprint 10 의 IPA 자동 제출은 **사용자 명시 후만** (M2 mandate).
20. **자미두수 12궁 별 이름 (nameKo) 사용자 노출** — R70 hidden mandate 보존.

---

## 6. R82 학습 명시 (codex moving goalpost 패턴)

R82 sprint 3 / sprint 8 의 codex audit 학습을 본 R83 spec 안에 같이 명시해요. R83 sprint 7/8 의 만세력 algorithmic 영역에서 같은 패턴이 다시 일어날 가능성도 함께 적어둬요.

### R82 sprint 3 / sprint 8 두 사례

**Sprint 3 (#6 oneLine 한자 jargon 일소)**:
- codex peak 9.32 — codex 매 라운드 새 dimension 추가 (해요체 wrap / 행동 처방 ≥15%).
- spec contract = 60일주 phrase 자체 = 형용사구라 wrap (해요체 "~ 해요" 마무리) 은 UI layer 작업 범위 외.
- 본질 충족: "벼린 칼" / "도검의 끝" / "정수" / "본질" / "결을 다듬는" 한자 jargon 60 entry 일소 완료.
- 사용자 결정으로 commit 진행 (`fadf704`, 532 test).

**Sprint 8 (#2 saju_deep_slice 30 entry 재작성)**:
- codex peak 9.20 — codex "수행평가 / 덕질" 류 학교 어휘 요구.
- spec contract = 사주 도메인 본질 어휘 ("사주 / 일주 / 대운") 와 conflict.
- 본질 충족: 30 entry × 7 field = 210 본문 재작성 + R74 어색 phrase blacklist 0 확인.
- 사용자 결정으로 commit 진행 (`69911e9`, 578 test).

### R83 sprint 7 / sprint 8 재발 가능성

R83 sprint 7 (P1-A 만세력 algorithmic) + sprint 8 (P1-C H1 swap) 는 **codex moving goalpost risk 高**:

- 5행 골든 보존 mandate (M4) 와 codex 의 새 dimension 요구 (절기 ε 보정 정밀도 / 학파 표준 100% 일치 등) 가 충돌 가능.
- 사용자 추가 정성 sample < 10 이면 algorithm 변경 자체가 risk → sample 먼저 받아야 함 mandate.
- codex peak 9.5+ 이면 supervisor 결정 (본질 충족 + 5행 골든 보존 + R69 lock 보존 confirm).
- peak 9.5- 이면 본질 충족 여부로 판단 + 5행 골든 보존 확인 후 사용자 보고.
- codex audit 4+ 라운드 oscillation 시 즉시 spec contract 와 codex 9.9 mandate 충돌 여부 판단 → 범위 밖이면 deferred 위임 후 다음 sprint.

### Generator 학습 적용 protocol

각 sprint 의 generator 가 다음 순서로 처리해요.

1. 첫 라운드 codex audit 결과에 새로 등장한 dimension 요구가 spec contract 범위 안인지 즉시 판단해요.
2. 범위 안 → 다음 라운드에 반영해요.
3. 범위 밖 → deferred 위임 (다음 sprint 또는 다음 라운드) + audit 문서에 명시해요.
4. 4+ 라운드 oscillation 인데 peak 9.5 미만이면, 본질 충족 여부 + 5행 골든 보존 확인 다음 supervisor 결정 dict 를 반환해요.
5. 4+ 라운드 oscillation 인데 peak 9.5+ 이면, 사용자 결정 또는 supervisor 결정 dict 를 반환해요.

---

## 7. Deferred list + 검증 plan

### Deferred list (R83 안 처리, 후속 라운드 위임)

본 round 에서 안 처리하지만 후속 라운드에서 처리할 항목이에요.

**R82 sprint 8 잔여**:
- saju_deep_slice 잔여 210 entry ko 본문 재작성 (R82 sprint 8 multi-sprint). R83 backlog P4-C 위임.

**R83 sprint 7 / 8 사용자 sample 미수령 시**:
- P1-A 만세력 algorithmic 깊은 fix → R84 위임.
- P1-C H1 swap rootMiddleBonus ↔ rootTraceBonus → R84 위임.

**R83 backlog P2 / P3 / P4 / P5 / P6 영역**:
- P2-A BottomNav 라벨 / P2-B Home 단순화 / P2-C 2026 신년운세 라벨 / P2-D Profile 공유 카드 / P2-E Reports IA — R84+ 위임.
- P3-A 글로벌 출생지 / P3-B l10n 정리 / P3-C 결제 paywall / P3-D 영문 i18n — 사용자 mandate 후만.
- P4-A polarity 캐릭터 영역 / P4-B R78 hotspot H3·H6·H8·H13·H14 / P4-C saju_deep_slice 잔여 210 / P4-D 데일리 Phase 2 — R84+ 위임.
- P5-A dart format / P5-B SajuProvider 영속 / P5-C SixAxisScore 타입 / P5-D DailyService clock — R84+ 위임.
- P6-A README docs 톤 동기화 / P6-B 접근성 글자 크기 / P6-C Reports accent — R84+ 위임.

### 검증 plan G1~G7 (sprint 9 회귀 가드 시점)

sprint 9 (회귀 가드) 시점에 다음 모두 PASS 를 확인해요 → R83 round close commit 진행이에요.

#### G1 — flutter analyze 0 issue

```bash
cd /Users/seunghyeon/seephone/pillarseer
flutter analyze
# 기대값: No issues found!
```

#### G2 — flutter test 전체 PASS

```bash
cd /Users/seunghyeon/seephone/pillarseer
flutter test
# 기대값: R82 종결 610 test baseline + R83 신규 (sprint 2~8 각 신규 test) → ≥ 620 test
```

신규 R83 test 후보:
- `test/round83_info_saju_calc_test.dart` (sprint 2)
- `test/round83_celeb_confidence_test.dart` (sprint 3)
- `test/round83_jasi_helper_test.dart` (sprint 4)
- `test/round83_birthtime_unknown_test.dart` (sprint 5)
- `test/round83_yongsin_split_test.dart` (sprint 6)
- `test/round83_manseryeok_unsin_match_test.dart` (sprint 7, sample 수령 시)
- `test/round83_root_bonus_swap_test.dart` (sprint 8, sample 수령 시)
- `test/round83_round_close_test.dart` (sprint 9)
- `test/round83_round_deploy_gate_test.dart` (sprint 10)

#### G3 — 5행 골든 1995-10-27 男 17시 (R75 calibration)

```
입력: 1995-10-27 / 男 / 17:00 (KST, 양력)
기대 출력:
  - 5행 raw: 木 16 / 火 21 / 土 17 / 金 41 / 水 4
  - 일주: 辛卯
  - 일간 element: 金 (辛)
```

검증 test (기존):
- `test/critical_regression_test.dart`
- `test/celebrity_calibration_test.dart`
- `test/round79_golden_test.dart`
- `test/round80_oneline_personalization_test.dart` (sample = 辛卯)

#### G4 — R69 lock (R80 갱신 baseline)

```
입력: 1995-10-27 男 17:00
기대 출력 (6각 점수):
  - 본성  78
  - 연애  78
  - 일    72
  - 돈    74
  - 건강  57
  - 평판  71
  - matchCount: 5 / 6
  - matchedAxes: [연애, 일, 돈, 건강, 평판]
```

검증 test: `test/round69_regression_test.dart`.

#### G5 — R71~R82 시그니처 보존

- 60일주 1440 phrase (R77).
- 자미두수 UI hidden (`kIsZiweiUiHidden=true` + 별 이름 nameKo 사용자 노출 0, R70 / R82 sprint 5 회귀 가드).
- 6각 radar widget 보존 + R82 sprint 4 `_MatchBadge` 라벨 "두 번 봐도 같이 잡힌 강점".
- 십신 음양 10분류 보존 (R75).
- SajuContext + DynamicTextResolver chain 보존 (R78 4단계).
- 알림 hh:mm picker 보존 (R76).
- `/today` route 보존 (R79 sprint 7 + R82 sprint 2 result_screen mount 제거).
- oneLine 60일주 wire 보존 + 폐기 5종 phrase 차단 (R80 sprint 2 + R82 sprint 3).
- radar 색상 재설계 보존 (R80 sprint 5).
- 조후용신 wire 보존 (R80 sprint 6).
- 신살 anchor 보존 (R80 sprint 4: 양인·괴강·백호·천을·문창).
- R82 sprint 5 palace_helper_anchor_service (12 결 라벨 1줄 설명).
- R82 sprint 6 animal_context_service (한글 동물 / 일진 / 알림 context).
- R82 sprint 7 `_CollapsibleSection` first-fold (펼침 4 / 접힘 14).
- R82 sprint 9 UserGender enum.
- R82 sprint 10 5행 "세력 분포 점수" 라벨.
- R82 sprint 11 Profile reset confirm 모달.
- R82 sprint 12 package_info_plus version 동적 로드.

#### G6 — R82+R83 분리 검증

- R82 fix 변경 0 가드 — sprint 2~12 commit 보존 grep.
- R83 신규 fix 추가만 — R82 시그니처 영역 변경 0.

#### G7 — 회귀 발견 시 protocol

- 5행 골든 sample 일치 X → 즉시 sprint 중단, 사용자 보고. M4 mandate 위반.
- R69 lock 일치 X → 의도적 변경이면 lock 갱신 commit 분리 (sprint 9). 의도 X 면 sprint 중단.
- flutter test 1개라도 FAIL → 즉시 sprint 중단.
- 시크릿 leak grep hit (.p8 / .env / .jks / AuthKey_ / private_key / sk- / ghp_) → 즉시 stash + 사용자 보고.

---

## 8. Round 73~82 reference (R83 입력 컨텍스트)

본 R83 가 reference 하는 직전 R73~R82 핵심을 한 줄로 정리해요.

| Round | 핵심 | 결과 | 배포 | commit hash |
|---|---|---|---|---|
| R73 | 운세의신 수준 + 17 섹션 + 8글자 십신 | 363/363 test | 1.0.0+34 외부 베타 | (memory hash) |
| R74 | 한국어 본문 어색 일소 + 12시간 흐름 first-fold | 363/363 test | 1.0.0+35 외부 베타 | (memory hash) |
| R75 | 1등 사이트 5행 골든 + 십신 음양 10분류 (가중치 calibration) | 368/368 test | 1.0.0+36 외부 베타 | (memory hash) |
| R76 | 알림 hh:mm picker + today_event 가능성 엔진 | 406/406 test | 미배포 (사용자 mandate) | (memory hash) |
| R77 | 4선수 부자연스러움 대결 115 fix + 60일주 1440 phrase | 433 test | 1.0.0+37 외부 베타 | (memory hash) |
| R78 | 하드코딩 13 hotspot 일소 + SajuContext 4단계 chain | 495 test | 미배포 (사용자 mandate) | (memory hash) |
| R79 | 만세력 cross-check (6 sample) + community 9 키워드 + /today route 분리 | 504 test | 1.0.0+39 외부 베타 | `0b08c59` |
| R80 | 개인화 broken fix (oneLine + todayHook + whyReason 60일주 wire) + radar 색상 + D2 조후용신 + 신살 anchor | 516 test | 미배포 (사용자 mandate) | `f259133` |
| R81 sprint 1 | 일주 unsin 일치율 99% mandate spec (algorithmic 변경 X 조건 도달 5/6 = 83%) | docs only | 미배포 (R82 우선 trigger) | `2ea7054` |
| R82 sprint 1~14a | 사용자 9문제 + 외부 reviewer 4 fix 통합 | 610 test / codex avg 9.83 / peak 10.0 sprint 9 | 미배포 (R82 sprint 14b 사용자 mandate 대기) | `d488b1a` |

→ R83 = R82 종결 직후 사용자 mandate "R82+R83 묶음 배포". R80 + R82 + R83 fix 가 모이면 (사용자 mandate 후) 1.0.0+40 통합 빌드.

### R82 → R83 → R84 chain boundary

| Round | 상태 | 핵심 |
|---|---|---|
| R80 | 미배포 (commit `f259133`) | 개인화 broken fix + 차트 색상 + D2 조후용신 wire |
| R81 sprint 1 | 미배포 (commit `2ea7054`, docs only) | 만세력 unsin 100% 측정 결과 (algorithmic 변경 X) |
| R82 sprint 1~14a | 미배포 (commit `d488b1a`) | 사용자 9문제 + 외부 reviewer 4 fix 통합 (610 test) |
| R82 sprint 14b | **사용자 mandate 대기** | 1.0.0+40 외부 베타 ganzitester (R80 + R82 통합) |
| **R83 sprint 1** | **본 spec 산출물** | P1 7 항목 통합 spec |
| R83 sprint 2~10 | 본 spec 후속 | P1-G / P1-F / P1-B / P1-E / P1-D / P1-A / P1-C fix + 회귀 가드 + (사용자 mandate 후) R80+R82+R83 통합 배포 |
| R84+ | R83 backlog 잔여 + R83 sprint 7/8 deferred (sample 부족 시) | P2 / P3 / P4 / P5 / P6 영역 + 만세력 algorithmic 후속 |

사용자 의도 = R82 + R83 한 번에 배포. R83 sprint 10 의 배포는 **R82 sprint 14b 와 묶음 = 1.0.0+40 단일 빌드**.

---

## 9. 결론 + 진행 boundary

- 본 spec = R83 ground truth. Sprint 2 부터 generator subagent 가 각 sprint 의 해당 # (P1-A~G) 정확히 구현.
- 매 sprint 끝 codex audit 9.9+ PASS 까지 generator 반복 (max 7 라운드, 매 라운드 다른 audit file).
- codex peak 9.5+ + 본질 충족 시 supervisor 결정 가능 (R82 sprint 3 / sprint 8 학습 적용).
- M2 mandate (자동 배포 X) 절대 — sprint 10 의 IPA 자동 제출은 사용자 명시 후만.
- M4 mandate (5행 골든 보존) 절대 — sprint 7 / sprint 8 manse algorithmic 영역의 5행 골든 변경 0.
- R70 mandate (자미두수 hidden) 절대 — 별 이름 nameKo 사용자 노출 0.
- 본 sprint 1 산출물 = `docs/round83_spec.md` 1개 markdown.
- Flutter 코드 변경 0 / test 변경 0 / 시뮬 새 부팅 0 / 시크릿 leak 0.

### 영문 약어 disclaimer

본 문서의 영문 약어 (P1-A~G · sprint 2~10 · G1~G7 · M1~M5 · weightProfile · boundary · wire · mount · first-fold · deep-link · spec · commit · blacklist · risk · fix · disclaimer) 와 한국어 도메인 단어 ("결" / "흐름" / "기운") 는 모두 개발자 audit · planner · generator · evaluator 간 communication 용. 사용자 노출 UI 본문 (sprint 2~8 의 phrase pool / arb / widget label / 신규 info 페이지 본문) 에는 영문 약어 0 노출.

단, R83 의 핵심 영역 = 사주 정확도 / transparency → **사주 도메인 명시 어휘 화이트리스트** ("사주 / 일주 / 대운 / 용신 / 격국 / 진태양시 / 자시 / 절기 / 음력 / 양력 / 도시 경도 / 억부용신 / 조후용신 / 격국용신") 는 사용자 노출 OK, 단 옆 또는 카드 안 1줄 평이 풀이 wire 필수.

사용자가 보는 모든 한국어 본문은 한국 MZ 중학생 K-POP 팬 친근 해요체 (M5 mandate) 만 사용.

---

> 본 문서 = `docs/round83_spec.md` v1. codex audit 9.9+ PASS 후 commit. R83 sprint 2 부터 본 spec 의 각 P1 # 차례로 진행 (회귀 위험 낮은 순서: P1-G → P1-F → P1-B → P1-E → P1-D → P1-A → P1-C).
