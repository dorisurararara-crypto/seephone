# Round 81 — 일주(4기둥) unsin 일치율 99% mandate (5행 골든 보존)

> Sprint 1 산출물. 사용자 mandate (2026-05-15): "Unsin이 짱이야" + "5행 골든 1995-10-27 男 17시 16/21/17/41/4 = 金 압도적" felt 일치 = 보존 OK.

## 0. 사용자 verbatim (2026-05-15)
> Q. 5행 골든 (16/21/17/41/4) vs unsin (25/8/8/38/21) — 어느 게 맞을까?
> A. "Unsin이 짱이야 그리고 골고루 아니던데 금이 압도적으로 높았어 내사주는"

→ unsin 도 金 압도적 보여줌 + 사용자 felt 도 金 압도적 = **5행 골든 보존 OK**.
→ 단 일주(4기둥 천간·지지) 자체 정확도는 unsin 과 일치 mandate.

## 1. mandate 분리

### 1.1 99% 일치 mandate (R81 강제)
- **일주(4기둥)** = unsin 와 일치율 99%.
- 검증 sample = R79 sprint 2 의 6 sample + R81 추가 ≥10 sample.

### 1.2 보존 mandate (R81 절대 룰)
- **5행 raw 분포** = 1995-10-27 男 17시 16/21/17/41/4 보존 (사용자 felt 정합).
- **R69 lock** = 6각 점수 (본성 78 / 연애 78 / 일 72 / 돈 74 / 건강 57 / 평판 71).
- **R71-R80 시그니처** = 60일주 1440 phrase / 자미두수 / 6각 radar / 십신 음양 10분류 / SajuContext + DynamicTextResolver / 알림 hh:mm picker / /today route / oneLine 60일주 wire / radar 색상 재설계 / chowhuYongsin.

## 2. R79 sprint 2 6 sample 결과 재확인

| # | 입력 | unsin 일주 (관측) | 우리 시뮬 일주 | 일치 | 원인 가설 |
|---|---|---|---|---|---|
| 1 | 1995-10-27 男 13:30 | 辛卯 | 辛卯 | ✓ | — |
| 2 | 1988-07-15 男 10:15 | 庚??? | 辛未 | ✗ | KASI vs unsin lookup +1 shift |
| 3 | 2001-02-04 女 00:30 | 戊戌 | 戊戌 | ✓ | — |
| 4 | 1992-12-31 男 23:30 | 壬??? | 辛巳 | ✗ | 자시 야자시/조자시 학파 |
| 5 | 1990-08-08 男 12:00 | 庚??? | 乙巳 | ✗ | 입추 절기 boundary |
| 6 | 1995-10-27 男 17:00 | 辛卯 | 辛卯 | ✓ | 골든 baseline |

**현재 일치율: 3/6 = 50%**.

## 3. fix candidate

### 3.1 D-A 야자시 default swap (가장 안전)
- **현재**: `useLateNightZasi=false` (조자시 학파, 23h~01h = 다음 날 일주).
- **변경**: `useLateNightZasi=true` (야자시 학파, 23h~01h = 같은 날 일주 유지).
- **영향 범위**: 23h~00h59m 출생자만. 다른 시간대 0 영향.
- **5행 골든 sample (17:00) 영향**: 0 (17시 ≠ 자시).
- **R69 lock 영향**: 0 (1995-10-27 男 15:43 ≠ 자시).
- **sample #4 (1992-12-31 23:30) 영향**: 일주 12-31 → 1-1 변경 (조자시 → 야자시 swap).

### 3.2 D-B 절기 boundary 정확도 audit
- `lib/services/solar_term_service.dart` — 입추(8/7~8/8), 입춘(2/4~2/5) 등 boundary 정확도 ±5분.
- `seoulTrueSunOffsetForDate` 보정 검증.
- **위험도**: 中 — 1995-10-27 (한로~상강 사이) 영향 X 가드 필수.

### 3.3 D-C 만세력 raw lookup audit
- KASI (klc 패키지) vs unsin 자체 lookup.
- sample #2 (+1 shift) / sample #5 (+5 shift) 원인.
- **위험도**: 매우 高 — 만세력 raw 변경 시 모든 sample 의 일주 영향 → 5행 골든 사주 영향 가능성. **algorithmic 변경 X mandate 유지**.

## 4. Sprint plan (8 sprint)

| # | 의제 | 산출물 | 5행 골든 | R69 lock |
|---|---|---|---|---|
| 1 | spec (본 문서) | `docs/round81_spec.md` | 보존 | 보존 |
| 2 | D-A 야자시 default swap + 5행 골든 회귀 가드 + R79 sample #4 fix 검증 | `manseryeok_service.dart` + 신규 test | 보존 | 보존 |
| 3 | D-B 절기 boundary audit (입추·입춘·동지 등) + sample #5 fix 시도 | `solar_term_service.dart` audit | 보존 | 보존 |
| 4 | Playwright 추가 unsin sample 5개 자동 수집 (총 11 sample) | `docs/round81_unsin_samples.md` | 보존 | 보존 |
| 5 | 우리 앱 vs unsin 일치율 측정 + 추가 fix candidate | docs | 보존 | 보존 |
| 6 | 9.9+ codex audit + fix 적용 | code + test | 보존 | 보존 |
| 7 | memory R81 + 인수인계 R81 섹션 | memory + 인수인계 | 보존 | 보존 |
| 8 | (옵션) TestFlight 1.0.0+40 = R80 + R81 통합 (사용자 mandate 후만) | IPA + altool | 보존 | 보존 |

## 5. NON-GOAL (R81 X)
- 5행 raw 분포 변경 (사용자 felt 와 정합).
- R69 lock 변경 (6각 점수 보존).
- 만세력 raw lookup algorithmic 변경 (KASI 표준 보존).
- 사용자 가시 UI 변경 (R80 4 critical 이미 fix).
- TestFlight 자동 배포 (사용자 mandate 후만).

## 6. 일치율 99% 도달 가능성 audit
- 야자시 swap → sample #4 fix 가능 → 4/6 = 67%.
- 절기 boundary fix → sample #5 fix 가능 → 5/6 = 83%.
- sample #2 (+1 shift) = KASI vs unsin lookup 차이 → algorithmic 변경 X 면 fix 불가능.
- **현실적 도달치**: 5/6 = 83% (algorithmic 변경 X 조건). 99% 도달은 만세력 raw lookup 변경 시만 가능.
- 사용자 mandate 99% 와 algorithmic mandate 보존 충돌 시 → 사용자 보고 후 결정.

---

> 본 spec = R81 ground truth. Sprint 2 부터 generator 진행. 매 sprint 끝 5행 골든 16/21/17/41/4 + R69 lock 회귀 0 가드.
