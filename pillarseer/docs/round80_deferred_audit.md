# Round 80 — D1/D3/D4 deferred audit (R81 위임)

> Round 80 sprint 7 산출. 사용자 verbatim 4 critical (C1~C4) 모두 sprint 2~5 fix 완료
> + D2 sprint 6 wire 완료. 남은 D1/D3/D4 는 위험도 vs 가치 audit 결과 R81 위임.

## 0. 사용자 verbatim 처리 결과 (sprint 2~5)

| # | 사용자 단언 | sprint | 위치 | 결과 |
|---|---|---|---|---|
| 1 | "벼린 칼 같은 사람이에요 이건 항상 나오는거야?" | Sprint 2 | `lib/services/deep_content_service.dart:404-540` | ✓ 60일주별 unique phrase wire |
| 2 | "여자친구도 똑같이 나오던데" | Sprint 2~3 | 위 + 60일주 todayHook + whyReason | ✓ 60일주 base + dom suffix 합성, 변별력 가드 test |
| 3 | "사진1에서 왜 더 적은데 점에 색깔이 달라?" | Sprint 5 | `lib/widgets/six_axis_radar.dart:254-280` | ✓ 점 색·크기 = 값 비례 / matched = ring 보조 |
| 4 | "이것도 여자친구랑 점수가 다 똑같아 우연이야?" | Sprint 4 | `lib/services/six_axis_score_service.dart:413-487` | ✓ jitter ±2→±4 + 신살 anchor (양인/괴강/백호/천을/문창) |

→ **사용자 직발 4 critical 모두 fix.**

## 1. D2 조후용신 (sprint 6 처리)

- `yongsin_service.judge()` 가 `monthBranch` optional 받으면 `chowhuYongsin` getter 노출.
- 봄(寅卯辰)=火 / 여름(巳午未)=水 / 가을(申酉戌)=木 / 겨울(亥子丑)=火.
- reason 끝 계절 보정 한 줄 추가.
- yongsin/huisin 자체 backward compat (R69 회귀 0).

## 2. D1 만세력 algorithmic — R81 위임 (위험도 高 / 5행 골든 보존 mandate)

### Round 79 audit 결론 재확인
- Sample #2 (1988-07-15 男 10:15) — 일간 庚 vs 우리 辛 (+1 shift).
- Sample #4 (1992-12-31 男 23:30) — 일간 壬 vs 우리 辛 (야자시 학파 X).
- Sample #5 (1990-08-08 男 12:00) — 일간 庚 vs 우리 乙 (+5 shift, 입추 boundary).
- 일치율 50% (3/6) — sample #1, #3, #6 모두 일치.
- **5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존 mandate** — algorithmic raw 변경 시 회귀 위험 매우 高.

### Round 80 결정
- **algorithmic raw 변경 0** (Round 79 결정 유지).
- **R81 위임**: KASI 만세력 reference cross-check + `solar_term_service` 입추·입춘 ±5분 정확도 + `useLateNightZasi` 학파 boundary.
- **Round 80 sprint 6** 의 조후용신 (D2) wire 가 같은 일주 내에서도 본문 변동 ↑ — D1 보완 효과 일부.

## 3. D3 시간 입력 picker UX — R81 위임 (widget 큰 변경 / 회귀 위험)

### 현재 상태 (sprint 7 audit)
- `lib/screens/input_screen.dart` — 시간 입력 hour/minute 숫자 input (R71 sprint 1 picker dialog 제거 결정).
- 야자시/조자시 학파 선택은 `lib/screens/settings_screen.dart:734` 에 이미 노출.
- input_screen 직접 학파 선택 없음 — 23h 입력 사용자가 settings 가야 함.

### Round 80 결정
- **input_screen widget 큰 변경 0** (R71 picker dialog 제거 mandate 보존 / widget render 회귀 위험).
- **R81 위임**: input_screen 의 23h 입력 시 helper text 1줄 ("23시 출생자는 설정에서 학파 선택 가능") + 30분 boundary 시각화.
- **현재 사용자 사용성 영향**: 23h 출생자만 영향, 그 외 사용자는 영향 없음. sample #4 (1992-12-31 23:30) 만 영향.

## 4. D4 H1 가중치 조건부 swap — R81 위임 (5행 골든 보존 algorithmic 어려움)

### Round 79 결과
- Sprint 5 sprint 시도: `rootMiddleBonus 0.6` ↔ `rootTraceBonus 0.3` swap → 1995-10-27 男 17시 5행 변경 → 골든 깨짐 → revert.

### Round 80 audit
- 조건부 swap algorithmic 해법 = 매우 복잡 + 다른 sample 의 5행 회귀 위험.
- 5행 골든 보존 algorithmic 해법 후보:
  1. monthBranch 별 다른 가중치 (계절 따라 분기) — 회귀 위험.
  2. 일주 sample 별 가중치 (개별 hardcode) — overfitting.
  3. 학파 표준 (본기 > 여기 > 중기) 적용 후 5행 골든 분포 새 baseline 으로 lock 갱신 — R75 calibration 무효화 → 사용자 명시 baseline 깨짐.

### Round 80 결정
- **algorithmic 변경 0**.
- **R81 위임**: 사용자 추가 sample (≥10) 정성 수집 후 학파 표준 가중치 vs 사용자 정성 비교 후 결정.

## 5. R81 입력 (Round 80 deferred queue)

| ID | 영역 | 위험도 | 가치 | 우선순위 |
|---|---|---|---|---|
| D1 | 만세력 algorithmic | 매우 高 | 中 | R81 sprint 1-2 (audit + cross-check) |
| D3 | 시간 picker UX | 中 | 中 | R81 sprint 3 (input_screen helper text) |
| D4 | H1 swap | 매우 高 | 中 | R81 sprint 4-5 (algorithmic 후보 비교) |

→ 모두 사용자 추가 정성 수집 + 학파 표준 cross-check 가 선결 조건.

## 6. Round 80 종료 시점 시그니처

- **사용자 4 critical fix** — oneLine 60일주 / todayHook + whyReason / 6각 점수 변별 / 차트 색상.
- **D2 조후용신 wire** — yongsin_service 시그니처 확장 + 회귀 0.
- **5행 골든 보존** — 1995-10-27 男 17시 16/21/17/41/4 + 일주 辛卯.
- **R69 lock 갱신** — 6각 점수 신묘 (본성 78 / 연애 78 / 일 72 / 돈 74 / 건강 57 / 평판 71).
- **테스트** — 515/515 PASS (R79 504 + R80 sprint 2~6 신규 11).
- **TestFlight** — 사용자 mandate 후만 1.0.0+40 배포 후보.

---

> 본 docs = R80 종료 시점 audit 결과 ground truth. R81 sprint 1 진입 시 본 docs 의 D1/D3/D4 deferred queue 부터.
