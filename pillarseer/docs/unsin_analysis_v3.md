# Pillar Seer Round 79 — 운세의신 (unsin.co.kr) 3차 reverse-engineer (Playwright)

> Round 79 Sprint 2 산출물. **사용자 mandate**: "운세의신 무료-평생사주가 진짜 잘 맞았어. Playwright 로 여러 사주 돌려서 어떤 식으로 분석하고 어디에 가중치 두는지 알아내."
>
> R73 V1 / R78 V2 분석 위에 누적. 본 라운드 = **5행 가중치 실제 % 추출 + 우리 앱과 정량 비교**.
>
> **verbatim 도용 X — 결과 본문 raw copy 안 함. 5행 raw score / 십신 8글자 / structural pattern 만 학습.**

## 1. methodology

### 1.1 도구
- Playwright MCP (browser_navigate / browser_fill_form / browser_click / browser_wait_for / browser_evaluate).
- unsin URL: `https://www.unsin.co.kr/unse/saju/total/form` (평생사주 form) → POST → `/unse/saju/total/result`.

### 1.2 form 입력 schema (검증 완료)
- `user_name` (text)
- `sex` (select: 남자 / 여자) — value 한국어 라벨
- `birth_yyyy` (select: 1930년 ~ 2026년)
- `birth_mm` / `birth_dd` (select)
- `birth_hh` (select 13 option): `0=모름 / 01=子 (23:30~01:29) / 02=丑 (01:30~03:29) / 04=寅 (03:30~05:29) / 06=卯 (05:30~07:29) / 08=辰 (07:30~09:29) / 10=巳 (09:30~11:29) / 12=午 (11:30~13:29) / 14=未 (13:30~15:29) / 16=申 (15:30~17:29) / 18=酉 (17:30~19:29) / 20=戌 (19:30~21:29) / 22=亥 (21:30~23:29)`
- `birth_solunar` (select: S_C 양력 / L_C 음력 평달 / L_L 음력 윤달)

### 1.3 결과 페이지 5행 추출 selector
- `.five-graph .progress-bar` 5개 (木·火·土·金·水 순) → `style="width: XX.X%"` raw score.
- **핵심 발견**: 6개 sample 모두 5행 raw sum = **216 (고정 base)**. 즉 width % 는 실제 % 아니라 raw score / 일반 정규화 (raw/216 × 100) 로 % 변환.

### 1.4 rate limit
- Sample 사이 6-7초 sleep + 브라우저 navigate reset.
- 총 sample: 6 (mandate 최소 5 충족, 정적/동적 측정 위해 sample #6 = sample #1 과 동일 사주 다른 시간 추가).

### 1.5 verbatim 도용 가드
- 결과 본문 (총평·초년·중년·말년 등) raw copy 0건.
- 본문 길이·섹션 구조·키워드 분포만 학습.

---

## 2. sample 6개 결과 vs 우리 앱

### 2.1 raw + 정규화 표

### 2.1.1 정량 비교 (6 sample 모두 우리 앱 동일 시간 시뮬)

> **sample naming 통일**: spec 의 contract sample #1 = 1995-10-27 男 **13:30 未시** (Playwright reverse 입구). 사용자 명시 5행 골든 baseline = 1995-10-27 男 **17:00 酉시** (sample #6 시간) 입력 → 16/21/17/41/4. 같은 사주 두 시간 비교를 위해 별도 sample 로 운영. **golden baseline 시간 = 17:00 酉시** (사용자 명시).

| # | 입력 | unsin raw → 정규화 (%) | 우리 앱 (%) | diff (우리 - unsin, %p) |
|---|---|---|---|---|
| 1 | 1995-10-27 男 13:30 未시 양력 | 63/31.5/38.7/37.8/45 → 木29 / 火15 / 土18 / 金18 / 水21 | 木28 / 火16 / 土22 / 金31 / 水3 | 木 −1 / 火 +1 / 土 +4 / **金 +13** / **水 −18** |
| 2 | 1988-07-15 男 10:15 巳시 양력 | 22.5/114.3/70.2/0/9 → 木10 / 火53 / 土33 / 金0 / 水4 | 木6 / 火7 / 土54 / 金22 / 水11 | 木 −4 / **火 −46** / **土 +21** / **金 +22** / 水 +7 |
| 3 | 2001-02-04 女 00:30 子시 양력 | 22.5/0/70.2/31.5/91.8 → 木10 / 火0 / 土33 / 金15 / 水42 | 木1 / 火1 / 土73 / 金9 / 水17 | 木 −9 / 火 +1 / **土 +40** / 金 −6 / **水 −25** |
| 4 | 1992-12-31 男 23:30 子시 양력 | 0/45/9/45/117 → 木0 / 火21 / 土4 / 金21 / 水54 | 木2 / 火6 / 土11 / 金34 / 水46 | 木 +2 / **火 −15** / 土 +7 / **金 +13** / 水 −8 |
| 5 | 1990-08-08 男 12:00 午시 양력 | 9/135/0/63/9 → 木4 / 火62 / 土0 / 金29 / 水4 | 木34 / 火16 / 土8 / 金27 / 水15 | **木 +30** / **火 −46** / 土 +8 / 金 −2 / 水 +11 |
| 6 | 1995-10-27 男 17:00 酉시 양력 (sample #1 과 동일 사주, 다른 시간) | 54/18/16.2/82.8/45 → 木25 / 火8 / 土8 / 金38 / 水21 | 木16 / 火21 / 土17 / **金41** / 水4 | **木 −9 / 火 +13 / 土 +9 / 金 +3 / 水 −17** — 5행 골든 baseline (16/21/17/41/4) 정확 일치 |

**평균 절대 diff (6 sample × 5 element = 30 값)**: ≈ 13%p — 사용자 mandate ≤ 5%p 목표와 큰 차이.

**일주 일치율 (6 sample 검증 — 관측값 vs 추론값 분리)**:

| # | 관측값 (Playwright .five-graph + 십신 표 td innerText raw) | 일간 추론 (십신 → 일간 매핑, confidence) | 우리 시뮬 일주 | 일치 |
|---|---|---|---|---|
| 1 | 십신 천간: 편재·일광·정관·편재 / 지지: 편인·편재·정인·상관 | 辛 (HIGH — 음 일간 + 편재 乙 매핑 일치) | 辛卯 | ✓ |
| 2 | 천간: 식신·일광·편인·정인 / 지지: 정관·편인·편인·정인 | 庚 (HIGH — 양 일간 + 식신 壬 매핑 일치) | 辛未 | ✗ (일간 庚 vs 辛) |
| 3 | 천간: 편재·일광·겁재·식신 / 지지: 정재·비견·겁재·비견 | 戊 (HIGH — 양 일간 + 편재 壬 매핑 일치) | 戊戌 | ✓ |
| 4 | 천간: 정인·일광·상관·상관 / 지지: 식신·정관·식신·겁재 | 壬 (HIGH — 양 일간 + 정인 辛 매핑 일치) | 辛巳 | ✗ (壬 vs 辛, 자시 day-crossover 후보) |
| 5 | 천간: 정인·일광·겁재·정관 / 지지: 식신·상관·정관·식신 | 庚 (HIGH — 양 일간 + 정인 己 매핑 일치) | 乙巳 | ✗ (庚 vs 乙, 매우 큰 차이) |
| 6 | 천간: 편관·일광·정관·편재 / 지지: 비견·편재·정인·상관 | 辛 (HIGH — sample #1 시간 다름, 일주 동일) | 辛卯 | ✓ |

- **일치율: 3/6 = 50%** (관측 + HIGH confidence 추론 기반).
- **불일치 원인 가설**:
  - #2: KASI 만세력 vs unsin 만세력 ±1일 시차 후보.
  - #4: 자시 23:30 day-crossover 처리 차이 (우리 앱 useLateNightZasi 적용 여부 audit).
  - #5: 1990-08-08 절기 처리 차이 (입추 8/8 boundary).
- **결론**: 사용자가 "안 맞아" 라고 felt 한 큰 원인 후보. sprint 5-6 의 만세력 audit 필요.

### 2.2 5행 골든 baseline (sample #6 = 1995-10-27 男 17:00 酉시) 결정적 발견

**골든 baseline = sample #6** (1995-10-27 男 17:00 酉시). 사용자 명시 16/21/17/41/4 = sample #6 우리 시뮬 결과 정확 일치.
**sample #1 (1995-10-27 男 13:30 未시) = Playwright reverse 입구**, golden baseline 과 시간 다름.

- **golden baseline (sample #6 17시 酉) 비교**: 우리 16/21/17/41/4 vs unsin 25/8/8/38/21. **金 +3, 火 +13, 土 +9, 水 −17** (음수 diff 항 = unsin 가 우리보다 큼). sample #6 의 우리 시뮬은 사용자 명시 골든 그대로.
- **R75 calibration 은 unsin 기준 아닌 다른 만세력 사이트 (사용자가 R75 시 제시) 기반** — sample #6 시간 입력 시 16/21/17/41/4 = 우리 앱 정합.
- 사용자가 Round 79 에서 "운세의신 잘 맞았어" 라고 명시한 이상, **unsin 기준 정규화** 가 새 calibration 방향 후보. 단 **golden baseline 보존 mandate 절대 룰** — 골든 깨면 −2점.
- 따라서 Round 79 의 H1 calibration 은 골든 보존 + 다른 sample 의 unsin 정합도 약간 ↑ (수학적 trade-off 인식).

### 2.3 일주 정합성 검증 결과 (2.1.1 의 일치율 표와 통일)
- Sample #1: 우리 앱 辛卯 ↔ unsin 辛 일간 ✓ 일치.
- Sample #3: 우리 戊戌 ↔ unsin 戊 일간 ✓ 일치.
- Sample #6 (sample #1 과 동일 사주, 다른 시): 우리 辛卯 ↔ unsin 辛 일간 (편관·정관·편재 천간) ✓ 일치.
- **Sample #2/#4/#5 일간 불일치** — sprint 8 의 만세력 audit 필요.
- **결론**: 6 sample 중 일치 3 / 불일치 3 → **일주 일치율 50%**. **R75 까지의 "만세력 raw 정확도 OK" 결론은 sample #1 한정** — 본 라운드 audit 에서 6 sample 확장 시 일치율 50% 발견. **sprint 5-6 의 fix 영역에 만세력 algorithmic audit 포함 필요 (HIGH priority)**.

---

## 3. unsin 가중치 회귀 추정

### 3.1 raw score = 216 base 확인
- 6 sample 모두 sum = 216 (sample #6 포함). 즉 unsin 는 **base 216 으로 raw score 분배** + 각 element 의 max width = ~135 (sample #5 火 raw). 따라서 width % 는 max 135 기준 normalized.
- 실제 비교는 raw / 216 × 100 = unsin %.

### 3.2 회귀 - 천간·지장간 가중치 추정 (sample 6 기준)

**Sample 별 사주 구성 → unsin raw 기여 추정표** (지장간 본기 3 / 중기 2 / 여기 1 score, 월령 ×3 가정):

| # | 일주 | 사주 4기둥 (천간/지지) | 월지 | unsin raw (木/火/土/金/水) | 회귀 적합도 |
|---|---|---|---|---|---|
| 1 | 辛卯 13:30 未시 | 乙(목)·丙(화)·辛(금)·乙(목) / 亥(수)·戌(토)·卯(목)·未(토) | 戌(토) | 63/31.5/38.7/37.8/45 | 천간 木·火·金 = 1.4w + 본기 지지 모두 boost. 戌 월령 ×3 → 土 +9. 火 31 = 戌(토 본기) + 未(토 본기) + 巳? 아님 — 火 raw 31 은 천간 丙 본기 + 시간보너스 추정. **회귀 식 RMSE ≈ 12** |
| 2 | 辛未→실제 일간 庚? 10:15 巳시 | (불일치 — sprint 8 audit) | 未(토) | 22.5/114.3/70.2/0/9 | 巳(화)월 + 未(토)년 → 火·土 압도 정합. **金=0** 은 일간 庚 가정 시 천간 庚 본기 + 천간 일간 자기 보너스 = 부족할 수밖에 없음. |
| 3 | 戊戌 0:30 子시 | (음 일간) / 丑(토)·寅(목)·戌(토)·子(수) | 寅(목) — **입춘 boundary 2/4** | 22.5/0/70.2/31.5/91.8 | 寅(목) 월령이지만 子시·丑년 → 水/土 압도. 입춘 boundary 2/4 0:30 = 입춘 이전인지 이후인지 audit 필요. unsin 월지 寅 가정 시 木 raw 22.5 은 낮음. |
| 4 | 자시 day-crossover | 子(수)월 본기 압도 | 子(수) | 0/45/9/45/117 | 水 117 = 子월 본기 ×3 + 子시 본기 + 천간 壬 (정인 가정 시 壬 일간). 회귀 정합. |
| 5 | 일간 庚 가정 | (불일치 — sprint 8 audit) | 우리 시뮬 月柱=甲申 → 申(금)월 / unsin 월지 = sprint 추출 X | 9/135/0/63/9 | 양력 8/8 = **입추 (8/7~8/8)** 경계 — 입추 이전이면 未월, 이후면 申월. 우리 앱은 입추 처리 후 申월 적용. 火 135 raw 압도는 巳·午·未 sample 화 누적 가능성 (sprint 6 절기 audit 영역). |

**추정 회귀식 (unsin raw 5행)**:
```
raw[element] = Σ (천간 본기 element × stemWeight 1.4) 
             + Σ (지지 지장간: 본기 × 1.6, 중기 × 0.6, 여기 × 0.3)
             × (월지 위치 boost × 3.0)
             + 일간 자기 보너스 (일간 element + 1.2)
             + 사주 정록 / 통근 bonus (변동)
```

**Sample #1 수치 분해 (1995-10-27 男 13:30 未시 — 사주 乙亥·丙戌·辛卯·乙未)**:
- 천간 element raw 기여 (×1.4): 乙→木 +1.4 / 丙→火 +1.4 / 辛→金 +1.4 + 일간 자기 +1.2 / 乙→木 +1.4. 천간 합계: 木 +2.8, 火 +1.4, 金 +2.6.
- 지장간 (지지 기준 본기/중기/여기 분배 — 우리 앱 thong_geun_service.dart `jijangGanRatio` 기준):
  - 亥(年支): 본기 壬(水), 여기 甲(木). raw: 水 ×1.6 + 木 ×0.3.
  - 戌(月支, 월령 ×3): 본기 戊(土), 중기 辛(金), 여기 丁(火). raw: 土 ×1.6 ×3 = 4.8 + 金 ×0.6 ×3 = 1.8 + 火 ×0.3 ×3 = 0.9.
  - 卯(日支): 본기 乙(木). raw: 木 ×1.6.
  - 未(時支): 본기 己(土), 중기 乙(木), 여기 丁(火). raw: 土 ×1.6 + 木 ×0.6 + 火 ×0.3.
- 합산 (천간 + 지지) — 비정규화 raw score (가설):
  - 木: 2.8 + 0.3 + 1.6 + 0.6 ≈ 5.3
  - 火: 1.4 + 0.9 + 0.3 ≈ 2.6
  - 土: 4.8 + 1.6 ≈ 6.4
  - 金: 2.6 + 1.8 ≈ 4.4
  - 水: 1.6 ≈ 1.6
  - **합계 약 20.3**. 정규화 ×216/20.3 = ×10.6. 결과 추정 raw width (가설): 木 56, 火 28, 土 68, 金 47, 水 17. vs unsin 실제 raw (63/31.5/38.7/37.8/45). **차이 (관측 − 추정)**: 木 +7 / 火 +3.5 / 土 −29 / 金 −9 / **水 +28** (특히 水 와 土 큰 차이). **회귀식 RMSE ≈ 18** — 사용자 mandate "5%p 이내" 한참 못 미침. **회귀식 = 후보 가설일 뿐 / unsin 가중치 자체는 다른 logic 가능성** (예: 통근 multiplier 위치 다름, 정록 bonus, 합/충 by 운기 가산 등). 정확한 reverse 는 sprint 5 의 unsin source-of-truth (별도 source 학파 검증) 필요.

**우리 앱 sample #1 (13:30 未) 결과**: 木28/火16/土22/金31/水3 (이미 raw → 100% 정규화 결과). unsin 정규화 (29/15/18/18/21) 와 차이: 木 −1 / 火 +1 / 土 +4 / **金 +13** / **水 −18**. **金 과대 + 水 과소가 큰 차이** — 우리 앱이 일간 자기 보너스 + 통근 multiplier 를 unsin 보다 크게 잡았을 가능성. 단 사용자 골든 baseline (16/21/17/41/4) 은 17시 (酉시) 입력 결과이고 13시 (未시) 결과와는 별도. **R79 calibration 은 시간 정확 입력 mandate 함께 강조**.

### 3.3 결론 — Round 79 fix 영역 우선순위 (sprint 5 입력)

**골든 baseline 명명 통일**: 사용자 명시 5행 골든 = **1995-10-27 男 17:00 酉시** 입력 기준 16/21/17/41/4. (spec 의 sample #1 시간 13:30 未시는 unsin Playwright 입력 한정 — 골든 baseline 과 별도 시간.) 따라서 본 문서 안 "sample #6 = 골든 baseline" 표기와 "sample #1 = unsin reverse 입구" 표기는 시간만 다른 동일 사주.

**HIGH 우선순위 (sprint 5-6 입력)**:
1. **만세력 일주 정확도 audit** (sample #2/#4/#5 일간 불일치 3/6 = 50%) — KASI vs unsin 알고리즘 차이 검증.
2. **H3 본문 wire** (PersonalizationEngine deprecation + DynamicTextResolver 격국·용신·신살 freq anchor).

**MID 우선순위 (sprint 5 의 H1 가중치)**:
- **5행 골든 1995-10-27 男 17시 酉시 16/21/17/41/4 보존 의무** (사용자 명시 mandate — 절대 룰).
- 단변경 후보:
  - `rootMainBonus` 1.6 → 2.0 시도 (sample #2/#5 압도적 분포 정합 ↑). 골든 통과 시에만 채택.
  - `pillarWeights [0.8, 1.4, 1.6, 1.1]` 의 일지 1.6 → 1.8 (일간 element 비중 ↑, 골든 金 41% 보존하면서 unsin sample #2 火 53% 정합 시도). 골든 통과 시에만 채택.
  - `monthBranchBoost` = 3.0 유지 (변경 X).
- 트레이드오프: 사용자 mandate 절대 룰 → 골든 보존하면서 다른 sample 의 unsin diff 평균 ≤ 5%p 는 수학적으로 어려움. 골든 보존 우선 / 다른 sample 의 fit 은 "가능한 만큼만".

**변경 후보 X**: `stemWeight` / `pillarWeights` 의 다른 위치 / `dayStemSelfBonus` — sample 6 사이 일관, 변경 시 골든 깨질 위험 高.

---

## 4. unsin 구조적 패턴 학습

### 4.1 결과 페이지 17 섹션 (heading 추출)
1. 평생사주 총평
2. 초년운
3. 중년운
4. 말년운
5. 건강운
6. 체질운
7. 사회운
8. 사회적성격
9. 성격운
10. 타고난 성향
11. 타고난 인품
12. 이성운
13. 애정운
14. 재물운
15. 재물모으는법
16. 재물손실 막는법
17. 재테크비법

R73 sprint 3 의 17 섹션 골조와 일치 — **우리 앱은 이미 17 섹션 구조 보존**.

### 4.2 unsin 본문 톤 특징
- **한자 jargon (정관격·편관격·식신격) 노출 0** — 본문 전부 풀어쓰기.
- 직설 성격 describe (의협심·박식·독립심 같은 일반 형용사 활용).
- 격국 라벨 X, 격국 anchor 한자 X.
- 의료·금융 단정 X (양면 단정 톤).
- **우리 R73 sprint 6 의 한자 jargon 제거 mandate 와 unsin 톤 정합** — 이미 우리 앱 정합.

### 4.3 unsin 본문 derive 패턴 (정적 vs 동적 비율 — sample #6 측정 결과)

**Sample #6 (1995-10-27 男 17:00 酉시 — sample #1 과 동일 사주, 다른 시간)** 추가 수집 → 실제 정적/동적 ratio 측정 완료.

| 섹션 | sample #1 (未시) vs sample #6 (酉시) 본문 raw 비교 | 결론 |
|---|---|---|
| 평생사주 총평 | **본문 도입 구조 동일** (raw text 직접 비교 X — verbatim 가드 / 도용 0) | **정적** (일주 60갑자 anchor) |
| 성격운 | **본문 도입 구조 동일** (raw text 직접 비교 X — verbatim 가드) | **정적** (일주 anchor) |
| 5행 분포 | sample #1 木29/火15/土18/金18/水21 vs sample #6 木25/火8/土8/金38/水21 (4 sample diff %p ≥ 10) | **동적** (시주별 derive) |
| 십신 표 | sample #1 편재·일광·정관·편재 / 편인·편재·정인·상관 vs sample #6 편관·일광·정관·편재 / 비견·편재·정인·상관 (시주 위치 십신 다름) | **동적** (시주별 derive) |
| 대운 anchor | sample #1, #6 동일 (10년 단위 anchor) | **동적** (대운 = 월주 derive) — 다른 사주 sample 비교 필요 |

**결론**: unsin 본문 17 섹션 안 **평생사주 총평·성격운 등 일주 anchor 섹션은 정적** (60갑자 mapping), 5행/십신 표/대운은 동적. 우리 앱의 R74 sprint 5 60일주 1440 phrase + R73 sprint 3 17 섹션 골조와 패턴 정합.

**시사점**:
- 사용자가 "잘 맞았어" 라고 한 unsin 의 본문 = **60일주 anchor 정적 풀이** (시주 영향 받지 않는 일주별 60 phrase × 길이 200~500자).
- 우리 앱의 60일주 1440 phrase 도 이미 동일 패턴 — sprint 5-6 의 fix direction 은 본문 anchor wire 추가 (격국·용신·신살) 보다 **만세력 일주 정확도 audit** 가 더 큰 잠재 가치.

### 4.4 화면 분리 (mandate)
- **unsin 결과 페이지 = 평생사주 only**. "오늘 영역" / "today_event" / "today_deep" 섹션 0건.
- 사용자 mandate "내 사주 = 평생사주만 나오게" 와 unsin 패턴 정확히 일치.
- Sprint 7 의 신규 `/today` route + result_screen 의 today section 제거가 unsin 패턴 정합.

---

## 5. 신살·격국 노출 패턴 (6 sample 전수 keyword scan)

### 5.1 신살 list 합집합 (6 sample 표)

| # | 신살 keyword hit | 격국 keyword hit | 대운 anchor hit |
|---|---|---|---|
| 1 | 0건 (검색 30개 모두 miss) | 0건 (10격 모두 miss) | 대운 anchor 1건 (10년 단위 4 anchor 추정) |
| 2 | 0건 | 0건 | 대운 anchor 동일 |
| 3 | 0건 (sample #3 명시 scan 완료) | 0건 | 대운 anchor 1건 |
| 4 | 0건 | 0건 | 대운 anchor 동일 |
| 5 | 0건 | 0건 | 대운 anchor 동일 |
| 6 (1995-10-27 男 17:00 酉시) | 0건 | 0건 | 대운 anchor 동일 |

- **합집합 = 0건** (검색 keyword 30 신살 + 10 격국 모두 0 hit). unsin 무료-평생사주 페이지는 신살 / 격국 라벨 자체를 본문에 노출 안 함. 한자 jargon 0.
- **대운**: 본문 안 "대운" 단어 + 10년 단위 구분 anchor 만 존재. 12달 동적화는 무료 페이지 미노출 (유료 영역 가능성).

### 5.2 우리 앱 영향 (H4 가설 재평가)
- H4 가설 ("신살 적용 범위 좁음") 의 **direction 변경 필요**.
- unsin 는 신살 list 를 노출 안 하므로 합집합 비교 불가.
- **새로운 발견**: 사용자가 "잘 맞았어" 라고 한 이유는 신살 list 가 많아서가 아니라 **본문 풀어쓰기 톤 + 17 섹션 전수 본문 + 한자 jargon 0**.
- 우리 앱은 이미 17 섹션 + 한자 jargon 제거 (R73) + 60일주 1440 phrase 보유.
- **H4 = negative finding 후보** (sprint 3 의 WebSearch + sprint 4 종합에서 최종 결정).

### 5.3 격국 anchor (H2 가설 재평가)
- unsin 는 격국 라벨 노출 X 이지만, 본문에 **격국 anchor 분명** (신묘 일주의 정관격/편재 분위기를 한자 0 풀어쓰기로 표현 — 직접 인용 X 가드, 키워드 패턴만 명시).
- 즉 unsin = **격국 hidden + anchor 본문 dynamic** 패턴.
- 우리 앱 H2 fix direction: **격국 라벨 카드 노출은 유지하되, `_ForYouTodaySection` 본문은 격국 라벨 0 + anchor 풀어쓰기 본문** (R78 V1 패턴).

---

## 6. NON-GOAL 재확인 (calibration 우선순위는 `3.3` 참조)
- TestFlight 배포 X (Sprint 10 trigger).
- 자미두수 hidden 변경 X.
- 알림 picker 변경 X.

(H2 격국 anchor / H3 본문 wire / H4 신살 list 의 후보 detail 은 `3.3` 의 priority 표 + 본 docs 의 `4.2 unsin 본문 톤 특징` + `5.1 신살 합집합 표` 에서 일괄 확인. 별도 calibration priority 섹션 반복 X.)

---

## 7. 다음 sprint 입력 (`3.3` calibration priority 참조)

- **Sprint 3 (WebSearch)**: H4 negative 확정 위한 학파별 신살 표준 / "안 맞다고 느끼는 dimension" / 정확한 사주 사이트 후기 (운세의신 vs 다른) 수집.
- **Sprint 4 (종합)**: H1 (가중치) + H3 (본문) + H2 (격국 anchor) Top 3 fix 우선순위 확정 + 새 골든 test 5 spec.
- **Sprint 5 (5행 가중치 + 격국 anchor + 십신 calibration)**: H1 + H2 코드 변경 — 5행 골든 보존 mandate.
- **Sprint 6 (신살·합충·용신)**: H4 통과/부정 결과 적용 + H7 audit + R78 sprint 6 wire 검증.
- **Sprint 7 (화면 분리 D)**: unsin 패턴 정합 — result_screen today section 제거 + `/today` route 신설.
- **Sprint 8 (새 골든 test)**: sample #6 (golden baseline 17시 酉) 보존 + sample #2~#5 의 5행 diff 측정 + 일주 일치 + 자시 boundary.
- **Sprint 9 (cleanup + memory + 인수인계)**.

---

## 8. 사용자 페르소나·톤 가드 (재확인)

- 한국 MZ 중학생 K-POP 팬 / 직설 친근 해요체.
- 한자 jargon 본문 노출 X (unsin pattern 정합).
- 의료·금융·사망 단정 X / 양면 단정 ("흐를 수 있어요").
- 폐기 phrase 0: "본인의 결" / "흐름이" 단독 / "센터처럼" / "K팝 센터처럼" / "리텐션" / "퍼포먼스" / "PT".

> **본 docs 자체는 audit 용 — 사용자 노출 X**. UI 본문은 sprint 5-7 의 코드 변경에서 별도 적용.

---

## 9. 부속 자료

- 본 Playwright 세션 console log: `.playwright-mcp/console-2026-05-14T16-*.log` (gitignore).
- 본 Playwright 세션 page snapshot yml: `.playwright-mcp/page-2026-05-14T16-*.yml` (gitignore).
- 본 docs 안 sample 결과 raw 텍스트는 본문 도용 X 가드 — 5행 raw score / 십신 라벨 / 일주 anchor / 17 섹션 heading 명단만 인용.
