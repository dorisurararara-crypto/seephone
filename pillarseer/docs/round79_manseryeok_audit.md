# Pillar Seer Round 79 — 만세력 일주 정확도 audit

> Round 79 Sprint 6 산출 docs. Sprint 2 의 Playwright unsin 6 sample 결과 vs 우리 앱 시뮬 비교 → 일주 일치율 50% (3 일치 / 3 불일치). 본 docs 는 **불일치 3 sample 의 원인 audit + Round 80 deferred fix 영역** 정리.

## 1. 일치 / 불일치 sample (재확인)

| # | 입력 | unsin 일간 | 우리 시뮬 일주 | 결과 |
|---|---|---|---|---|
| #1 | 1995-10-27 男 13:30 양력 | 辛 | 辛卯 | ✓ |
| #2 | 1988-07-15 男 10:15 양력 | 庚 (추정) | 辛未 | ✗ |
| #3 | 2001-02-04 女 00:30 양력 | 戊 | 戊戌 | ✓ |
| #4 | 1992-12-31 男 23:30 양력 | 壬 (추정) | 辛巳 | ✗ |
| #5 | 1990-08-08 男 12:00 양력 | 庚 (추정) | 乙巳 | ✗ |
| #6 | 1995-10-27 男 17:00 양력 | 辛 (golden) | 辛卯 | ✓ |

## 2. 불일치 원인 가설 (Sprint 2 / Sprint 3 결과 종합)

### 가설 A — KASI 만세력 vs unsin 만세력 시차 (sample #2)
- **샘플**: 1988-07-15 男 10:15.
- **차이**: unsin 일간 庚 ↔ 우리 辛 (일간 천간 +1 shift).
- **원인 후보**:
  1. unsin 가 입추 (8/7) 절기 처리 다를 가능성 (1988-07-15 → 음력 6/3 → 미월 본기, 7/15 양력은 소서~대서 절기).
  2. KASI 표준 (`klc` 패키지) vs unsin 자체 만세력 raw lookup table 차이.
- **검증 방법 (Round 80)**: KASI 공식 만세력 reference (한국천문연구원) cross-check.

### 가설 B — 자시 day-crossover 처리 (sample #4)
- **샘플**: 1992-12-31 男 23:30 (자시).
- **차이**: unsin 일간 壬 ↔ 우리 辛 (일간 천간 +1 shift, 일지 巳 ↔ 추정 일지 다름).
- **원인 후보**:
  1. unsin 가 **야자시 학파** (23:30 → 같은 날 12-31 일주 유지) 사용 가능성.
  2. 우리 앱 default `useLateNightZasi=false` (조자시 학파) → 23h 출생 시 다음 날 일주 (lib/services/manseryeok_service.dart:307).
  3. 사용자 입력 23:30 (자시 시작) 정확히 boundary → 학파 선택 결정적.
- **검증 방법 (Round 80)**: input_screen 에 야자시/조자시 선택 옵션 추가 + default 학파 결정.

### 가설 C — 절기 boundary (sample #5)
- **샘플**: 1990-08-08 男 12:00 (입추 8/7~8/8 boundary).
- **차이**: unsin 일간 庚 ↔ 우리 乙 (매우 큰 차이 — 천간 +5 shift).
- **원인 후보**:
  1. 입추 절기 boundary (양력 8/7~8/8 사이) 정확한 입력 시각 처리.
  2. 1990-08-08 의 정확한 입추 절입 시각 unsin vs 우리 앱 다름.
  3. KASI 입추 datetime ±5분 정확도 (`lib/services/solar_term_service.dart` 의 `seoulTrueSunOffsetForDate` 보정).
- **검증 방법 (Round 80)**: 1990-08-08 의 입추 절입 시각 cross-check + solar_term_service 입추 처리 audit.

## 3. Round 79 sprint 6 결정

### 본 sprint 변경 영역
- **만세력 algorithmic raw fix X** (5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존 mandate + sample #2/#4/#5 까지 정합 시 회귀 위험 매우 高).
- **본 sprint 산출 = audit docs only** (Round 80 deferred 입력).

### Round 80 deferred fix 영역
1. **`useLateNightZasi` 학파 선택** — input_screen 에 옵션 추가 + 사용자 입력 boundary 시각화.
2. **KASI 만세력 reference cross-check** — `klc` 패키지 vs 공식 만세력 비교 audit.
3. **`solar_term_service` 절기 boundary 정확도** — 입추·입춘 등 ±5분 정확도 검증.
4. **만세력 raw fix** — KASI 일주 reference 와 cross-check 후 algorithmic 조정 (5행 골든 보존 시에만 채택).

## 4. NON-GOAL 재확인
- **본 sprint 만세력 algorithmic 변경 X** (5행 골든 보존 mandate).
- TestFlight 배포 X (Sprint 10 trigger).
- 만세력 raw fix → Round 80 deferred.

## 5. 사용자 사용성 영향 (audit)
- **현재 50% 일주 일치율**: 사용자가 다른 만세력 사이트와 비교 시 50% sample 에서 일주 차이 felt.
- **단** sample #1 (1995-10-27 男 17시 골든) 은 일치 — 사용자 명시 baseline 보존.
- **Round 79 H3 본문 wire (sprint 5)** 이 이미 일치 sample 의 본문 깊이 ↑ — 일치 sample 의 사용자 만족도 ↑ 효과.
- 불일치 sample 의 사용자 felt 차이는 **Round 80 의 만세력 audit 후 완전 해소** 후보.

---

> 본 docs 는 audit 용 — 사용자 노출 X. UI 본문 sprint 5-7 의 별도 정제.
