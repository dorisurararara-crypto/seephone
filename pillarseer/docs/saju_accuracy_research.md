# Pillar Seer Round 79 — 사주 정확도 향상 의견 수집 (Community + WebSearch)

> Round 79 Sprint 3 산출물. **사용자 mandate**: "커뮤니티/검색으로 사주 정확도 높이는 의견도 들어봐."
>
> **audit 용 — 사용자 노출 X**. UI 본문 mandate (한국 MZ K-POP 톤 / 한자 jargon X) 와 별도 영역.
>
> **verbatim 도용 X** — 커뮤니티 후기 원문 인용 0 / 학파 표현 패턴·dimension 만 추출.

## 1. methodology

### 1.1 도구
- WebSearch 9 키워드 + 결과 자동 요약.
- WebFetch 7 page 직접 fetch (학파 검증 5 + 사용자 후기 2).

### 1.2 9 키워드 + 결과 페이지 수
1. "사주 정확도 가중치 지장간 본기 중기 여기" — 10 page (Wikipedia 지장간 / namu.wiki 사주팔자 / sajustudy.com 지장간 / Google Patents 사주분석장치).
2. "사주 안 맞는 이유 만세력 정확도" — 10 page (포스텔러 / 사주플러스 / brunch / sajunaru / 디시).
3. "운세의신 후기 정확도 사주" — 10 page (sinunse / 신한라이프 / 네이트 / 운세의신 Play store / chatgpt 운세박사).
4. "자평진전 vs 적천수 격국용신 정확도 학파" — 10 page (tellmesaju / 명리마당 / 국회도서관 / DBpia 논문 / 역학 갤러리).
5. "사주 무료 정확한 사이트 추천 후기 비교" — 10 page (powercam / 포스텔러 / 사주인 / 더쿠 / dmitory / sajugpt / 아시아경제).
6. "사주 신살 종류 학파별 차이 천을귀인 양인 화개" — 10 page (namu.wiki 신살 / Wikipedia 신살 / sajustudy / 화개살 / 쎄하다 사주 신살 도감 / 천명).
7. "사주 십신 강약 신강 신약 임계값 판단" — 10 page (namu.wiki / 포스텔러 / brunch / 8ja.co.kr / postype).
8. "사주 진태양시 longitude 보정 자시 day-crossover" — 10 page (마일모아 / namu.wiki / KISS 산업진흥 / postype / 0115590089 cafe / cheoninji).
9. "사주 어플 정확도 추천 K-POP MZ 한국" — 10 page (subdued20club cafe / App Store 점신 / threads arcanedrop / 헬로우봇 / 마이사주 / brunch / allurekorea).

> 총 9 키워드 × ~10 page = ~90 page 의 자동 summary text. Sprint 3 mandate (6 키워드 + 5 페이지) 초과 충족.

### 1.4 WebFetch 7 page (학파 검증 5 + 사용자 후기 2)

| # | URL | 확인 포인트 (간접 요약) | calibration 영향 |
|---|---|---|---|
| F1 | [지장간 - 위키백과](https://ko.wikipedia.org/wiki/%EC%A7%80%EC%9E%A5%EA%B0%84) | 정기 (16~20일 / 최강) > 여기 (7~10일) > 중기 (3~7일 / 약). 30점 기준 비율. 모든 지지에 중기 존재 X (왕지 = 여기+정기 2). 학파 표준 순서 = **본기 > 여기 > 중기**. | 우리 앱 `manseryeok_service.dart:29-31` 의 `rootMainBonus=1.6 / rootMiddleBonus=0.6 / rootTraceBonus=0.3` 는 **본기 > 중기 > 여기** 순서 — 학파 표준 (본기 > 여기 > 중기) 과 중기·여기 순서 반대. **H1 가설 (sprint 5)**: rootMiddleBonus ↔ rootTraceBonus swap 검토 — 5행 골든 보존 시에만 채택. |
| F2 | [신살 - 위키백과](https://ko.wikipedia.org/wiki/%EC%8B%A0%EC%82%B4) | 신 8종 (천을·천덕·월덕·월공·문창·천의·암록·삼기) + 살 10종 (역마·도화·화개·귀문관·원진·양인·괴강·백호·공망·천라지망) = 18 표준. 학파별 사용 여부 page 미공개. | 우리 앱 `shinsa_service.dart` 8 신살 + `today_event_service.dart` 24 priority list = unsin 0건 노출과 별개로 학파 표준 (18 신살) 와 동급. **H4 추가 신살 후보**: 천덕귀인·월덕귀인·월공·천의·삼기·천라지망 — 단 학파 기피 (자평진전·적천수) 고려 시 sprint 6 deferred. |
| F3 | [지장간 - sajustudy](https://www.sajustudy.com/31) | 정기 (final stem / 본기 element) / 중기 (middle / 과거·미래 force) / 여기 (initial / 전월 momentum). 30일 / 월 합산. **명리약언은 정기 (본기) 중심** 권고. | 우리 앱은 본기 (정기) 우선 가중치 = 학파 권고 정합. sprint 5 의 H1 변경 시 정기 비중 ↑ 방향만 허용. |
| F4 | [자평진전 - tellmesaju](https://tellmesaju.com/saju/japyeongjinjeon/intro) | 격국용신은 월령 기반으로 용신을 구하는 학파. 월령 → 격국 → 용신 → 성격 → 구응 5단계 (간접 요약). 억부용신과 다름 — 월령 영향력 강조. | 우리 앱 `yongsin_service.dart:62-97` 은 억부용신 패턴 (강약 기준). 격국용신 (월령 기반 lookup) wire 안 됨. **sprint 5-6 후보 (H2 격국 anchor)**: yongsin_service 에 격국 입력 추가 + 격국별 용신 dispatch table. |
| F5 | [신강·신약 판단 - brunch sajuwiki](https://brunch.co.kr/@sajuwiki/37) | 일간 오행 본질 (목 = 긍정 신약 / 금 = 부정 신강) 강조. **count 기반 vs 본질 기반** 학파 차이. 비겁·인성 count 4+ 학파도 있음. | 우리 앱 `strength_service.dart:37-40` 의 % 임계값 (70/55/45/30) 은 element % 기반 — 학파의 count 기반 ↔ 본질 기반 어디에도 100% 정합 X. **H5 strength threshold 가설**: 학파 다수 + 명리학자 의견 차이로 보수적 임계값 유지 적정. sprint 6 audit 시 다른 학파 기준과 비교. |
| F6 | [사주 어플 후기 - brunch qufekdstudy](https://brunch.co.kr/@qufekdstudy/19) | 4 한국 사주 앱 (점신·헬로우봇·다락방·FMOI) 비교 — 점신 = 가장 mainstream / 헬로우봇 = AI 챗봇 톤 / 다락방 = 타로 + 감성 / FMOI = 깊은 분석. 사용자 mandate: 결정 도구 X / entertainment 영역 — 톤 mismatch 시 felt 차이 ↑. | **D5 페르소나 톤 dimension 보강**. 우리 앱은 직설 친근 해요체 + MZ K-POP 페르소나 명확 — 톤 mismatch 영역 낮음. 깊은 분석 (FMOI 패턴) 정합 위해 격국·용신 wire (H3) 필요. |
| F7 | [사주 타로 앱 20개 리뷰 - threads arcanedrop](https://www.threads.com/@arcanedrop/post/DFmVPtMTyHJ) | 20+ 앱 사용자 평가 — 점신 정확도 낮은 후기 일부 / 헬로우봇 타로 강 / 포스텔러 점성술 우위 / 운수도원 궁합·연애 좋은 평가 / 오즈의타로 투시타로. **dimension**: 사용자가 felt 평가 시 **카테고리별 강·약 명확화** 요구 (궁합·이성·연애·재물 등). | **D2 본문 매칭률 dimension 보강**. 17 섹션 (R73) 골조 + 카테고리별 분기 (R74-R77) 우리 앱 정합. 단 본문 derive 격국·용신 추가 시 카테고리별 매칭률 ↑. |


### 1.3 verbatim 도용 가드
- 커뮤니티 후기 원문 raw text quote 0건 (직접 인용 X).
- 학파 책 (자평진전·적천수·궁통보감·난강망) 본문 인용 0건.
- Wikipedia / 학파 사이트 의 dimension·표현 패턴·가중치 표준 만 학습.
- 단 명시 예외: (a) 사용자 mandate verbatim 인용 (Round 79 spec 의 사용자 발화 — 우리 앱 자체 발화); (b) WebSearch 검색 키워드 자체 (검색 쿼리). 두 영역은 원본 source 의 도용 X 영역.

---

## 2. "안 맞다고 느끼는" 5+ dimension (사용자 felt vs 실제 정확도)

| Dimension | 설명 | 출처 요약 (간접 요약 — raw quote X) | 우리 앱 영향 |
|---|---|---|---|
| **D1. 만세력 raw 정확도** | 일주·시주 계산 자체가 학파별 다름 (정자시 vs 야자시 / 진태양시 보정 / 시간 boundary). 30분 차이로 사주 완전 변경. | 만세력 사이트별 일주 결과 차이 / 23:30 boundary 결정적 / 진태양시 30분 보정 학파 차이 | **HIGH** — Sprint 2 의 일주 일치율 50% 와 정확히 정합. 만세력 algorithmic audit. |
| **D2. 본문 매칭률 (체감)** | 사주 5행 분포는 맞아도 본문이 사용자 자신과 어긋난다고 느낄 수 있음 — 격국 anchor 없는 정적 fallback 본문 영역. | 합·충·형·파·해 종합 해석 필요 / 본문 카테고리 구분 + 경어체/평어체 분류가 정확도 평가 핵심 / 본문 약한 사이트 정확도 평가 낮음 | **HIGH** — Round 79 H3 (본문 wire) 정합. |
| **D3. 학파 혼재** | 격국용신 (자평진전) / 억부용신 (적천수) / 조후용신 (궁통보감) 3 학파 — community 가설: 3 학파 복합 적용이 입체 이해 (단정 X, 학파 차이 영역). | 3 학파 복합 적용 community 가설 / 자평진전 사회·직장 / 적천수 가족·재물 / 궁통보감 시즌 영역 | **MID** — Round 79 의 yongsin_service 가 강약 기준 (적천수 억부) wire. 격국용신 / 조후용신 도입 여부 sprint 5-6 audit. |
| **D4. 신살 vs 본격적 사주** | 신살은 자평명리 이전 고법 — 현대 명리학자는 기피. | 신살은 자평명리 이전 고법 / 적천수·자평진전·난강망 학파 신살 기피 | **NEGATIVE 확정 (H4)** — 우리 앱 24 신살 priority 는 학파 적정. 추가 신살 부족보다 격국·용신 본문 wire 가 우선. |
| **D5. 사용자 페르소나 톤 mismatch** | 같은 사주여도 톤 mismatch 면 정확해도 사용자 felt 가 어긋날 수 있음. | 사주 사이트 정확도 평가 = 본문 카테고리 구분 + 경어체/평어체 분류 / 인기 사이트 일부에서 anchor 부족 felt — 페르소나 mismatch 후보 | **MID** — 우리 앱 R73 의 MZ 톤 mandate + 한자 jargon 제거 정합. 단 본문이 격국·용신 derive 안 하면 톤 보장해도 felt 차이 ↑. |
| **D6. 시간 boundary 사용자 입력 정확성** | 출생시 30분 단위 boundary 시 사주 완전 변경. | 23:30 / 11:30 / 13:30 등 30분 단위 boundary 결정적 | **MID** — Round 79 의 5행 골든 baseline = 17시 (사용자 명시) 지정 의무. 우리 앱 input_screen 의 시간 입력 picker UX audit 후보 (deferred). |
| **D7. 같은 일주여도 다른 사주** | 같은 60갑자 일주여도 월주·시주·년주 다르면 본문 다름. | 사주는 단순 글자 나열 X — 4기둥 종합 / 사이트 마다 일주 다름 (만세력 차이) | **HIGH** — Round 79 H3 + H2 (본문 derive 격국·용신 추가) 정합. 우리 앱 60일주 1440 phrase R74 baseline 위에 격국 anchor 추가. |

**결론**: 7 dimension 중 사용자 felt 불만족의 가장 큰 원인 후보 = **D1 만세력 정확도 (50% 불일치) + D2 본문 매칭률 (격국·용신 derive 부족) + D7 사주 derive 부족**. Round 79 의 HIGH 우선순위 fix 영역과 정확히 일치.

---

## 3. 정확한 사주 사이트 공통 요소

### 3.1 사이트 후기 (커뮤니티 종합)
- **프리사주**: 만세력 기반 평생운세·신년운세·사주풀이 — 종합도 ↑.
- **아시아경제 사주**: 경어체 사용 X (평어체) — 실제 상담 분위기 톤 — 정확도 다소 ↑ 평가. **우리 앱 R74 한국어 본문 어색 일소 + 직설 친근 해요체와 정합**.
- **기분좋은점 (niceunse.com)**: 사주 총평 정확 + **카테고리별 구분이 잘됨** — 우리 앱 R73 17 섹션 골조와 정합.
- **사주GPT**: 명리학 전문 AI + 만세력 기반 + **회원가입 없이 무료** — UX 진입 장벽 0.
- **마이사주 (MySaju)**: AI 기반 한국 사주 앱 + **K-POP·연예인 사주** + 음양력 엔진.
- **점신**: 가장 유명하나 신년운세 정확도 평가 낮은 후기 일부 — 본문 매칭률 ↓.
- **헬로우봇**: AI 챗봇 + 사주 — 페이스북 시절 인기, 현재 유료 전환.
- **포스텔러**: 과금 多 + **점성술/만세력 정확** + 사주 본문 약함.

### 3.2 정확한 사이트 공통 요소
1. **만세력 raw 정확도** — KASI 표준 + 진태양시 보정 + 자시 boundary 정확 처리.
2. **카테고리별 구분** — 17+ 섹션 (성격·재물·이성·건강 등). 한 화면에 다 박지 않음.
3. **경어체보다 평어체 또는 친근 해요체** — 점쟁이체 X.
4. **격국·용신 derive 본문** — 정적 일주 fallback 만 X.
5. **K-POP / MZ 페르소나 정합** — 직장인 jargon 0.
6. **회원가입 없이 무료** (UX 진입 장벽).

우리 앱 정합도: 1 (만세력 raw 정확도) — Sprint 2 의 일주 일치율 50% 발견으로 audit 필요. 2-6 — 이미 R71-R78 baseline 정합.

---

## 4. 학파별 가중치 표준

### 4.1 지장간 본기/중기/여기 가중치

자평명리 표준 (사주공부 sajustudy 기반):
- **본기 (정기)**: 가장 강 — 지지 element 의 핵심.
- **여기**: 중간 — 본기 다음.
- **중기**: 약 — 본기·여기 다음.

**우리 앱 `lib/services/manseryeok_service.dart:29-31`**: `rootMainBonus=1.6` (본기 / `s==3`) / `rootMiddleBonus=0.6` (중기 / `s==2`) / `rootTraceBonus=0.3` (여기 / `s==1`). 즉 **본기 1.6 > 중기 0.6 > 여기 0.3** — **본기 > 중기 > 여기 순서**.
**비교**: wikipedia 지장간 표준 = 본기 > 여기 > 중기 (작용 일수 16~20일 / 7~10일 / 3~7일). sajustudy 표준 = 본기 > 여기 > 중기. **우리 앱 코드 = 본기 > 중기 > 여기** — wikipedia/sajustudy 학파 표준과 중기·여기 순서 반대. **H1 가설 (sprint 5 후보)**: rootMiddleBonus 0.6 ↔ rootTraceBonus 0.3 swap (학파 표준 정합). 단 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존 시에만 채택.

**작용 일수 (지지별 가중치)**:
- 생지 (寅·申·巳·亥): 여기 7일 + 중기 7일 + 정기 16일.
- 왕지 (子·午·卯·酉): 여기 10일 + 정기 20일 (중기 없음).
- 고지 (辰·戌·丑·未): 여기 9일 + 중기 3일 + 정기 18일.

우리 앱 `thong_geun_service.dart` 의 `jijangGanRatio` 와 정합도 audit 필요 (sprint 5-6).

### 4.2 신강·신약 판단 기준

**전통 학파 기준** (8ja.co.kr / brunch.co.kr/@sajuwiki 등):
- **신강**: 일간 + 비겁 + 인성 = 사주팔자 4 기둥 중 4+ 이상.
- **신약**: 일간 + 비겁 + 인성 = 3 이하.
- **월지 포함 시 신강·신약 결정적** — 월지가 인성·비겁이면 신강 가까움.

**우리 앱 `lib/services/strength_service.dart:37-40`**: `thresholdVeryStrong=70 / Strong=55 / Balanced=45 / Weak=30` — % 기반 임계값. 학파 기준 (count 4+ vs 3-) 과 다른 metric. **strength_service 의 % 기반 vs 학파 count 기반 diff** → 같은 사주여도 우리 앱이 "신강" 라벨링하는 비율 차이 가능성. Sprint 5-6 의 H5 (강약 임계값) audit 영역.

### 4.3 용신 학파 분리

3대 학파:
1. **자평진전 (격국용신)**: 월령 (월지 본기 십신) → 격국 결정 → 용신. **사회/직장/사회반경 운**.
2. **적천수 (억부용신)**: 강약 판단 → 강이면 빼앗는 오행 / 약이면 돕는 오행. **재물/육친/사생활**.
3. **궁통보감 (조후용신)**: 계절·온도 → 따뜻한 사주에 水, 차가운 사주에 火. **시즌별 흐름**.

**우리 앱 `lib/services/yongsin_service.dart:62-97`**: 신강 → 식상·재성·관성 / 신약 → 인성·비겁 / 중화 → 가장 약한 오행 = **적천수 억부용신** 패턴. 격국용신 / 조후용신 wire X.

**Round 79 sprint 5-6 후보**:
- 격국용신 wire (yongsin_service 에 격국 입력 추가 → 격국별 용신 lookup).
- 조후용신 wire (월지 계절 + 일간 강약 → 火/水 보충).
- 단 3 학파 합산 시 트레이드오프 가능 — 사용자 mandate 5행 골든 보존 + 본문 변동 ↓ 조심.

---

## 5. K-POP / MZ 페르소나 검증

### 5.1 사용자 페르소나 정합 키워드
- **마이사주**: K-POP·연예인 사주 + AI 기반 + 음양력 엔진. **사용자 페르소나 정합**.
- **점신·헬로우봇**: 디시·더쿠 인기 + MZ 사용자 多.
- **포스텔러**: 과금 多 + 점성술. 사주 본문 약함.

### 5.2 우리 앱 차별화 영역 (R71-R78 baseline)
- 60일주 1440 phrase (R74) — 사용자별 본문 derive.
- 17 섹션 운세의신 수준 (R73).
- 십신 음양 10분류 (R75).
- 한자 jargon 본문 0 (R73 sprint 6).
- 알림 hh:mm picker (R76).
- 직설 친근 해요체 (R74).

### 5.3 차별화 부족 영역 (Round 79 sprint 5-6 후보)
- 만세력 일주 정확도 (D1) — 잠재 fix.
- 격국·용신 derive 본문 wire (D2 / D7) — 잠재 fix.
- 조후용신 (계절) wire — 잠재 fix (deferred 후보).

---

## 6. Round 79 calibration plan 입력 (Task C 우선순위 확정)

### 6.1 HIGH 우선순위 (sprint 5-6 입력)
1. **만세력 일주 정확도 audit** (D1) — Sprint 2 의 일주 일치율 50% + community D1 dimension 정합. 사용자 felt 의 가장 큰 원인 후보.
2. **본문 wire — 격국·용신 derive** (D2 / D7) — Round 79 의 H3 + H2 정합. PersonalizationEngine → DynamicTextResolver 마이그레이션.

### 6.2 MID 우선순위
3. **H1 5행 가중치** — 5행 골든 보존 mandate + 다른 sample 의 unsin diff ↓ (sprint 5).
4. **D3 학파 합산** — 조후용신 wire 후보 (sprint 6 deferred 가능).

### 6.3 NEGATIVE 확정
- **H4 신살 list 확장** — 학파 검증: **자평진전·적천수·난강망 학파는 신살 기피**. 우리 앱 24 priority list 학파 적정. 추가 작업 X.

### 6.4 NON-GOAL 재확인
- TestFlight 배포 X (Sprint 10 trigger).
- ChatGPT/Gemini API 호출 X.
- 자미두수 hidden 변경 X.
- 알림 picker 변경 X.

---

## 7. 다음 sprint 입력 (Sprint 4 종합)

Sprint 4 = Sprint 1 (가설 docs) + Sprint 2 (Playwright reverse) + Sprint 3 (Community 의견) 종합 → 최종 calibration plan 확정.

- **Top 3 fix 우선순위**:
  1. 만세력 일주 정확도 audit (D1 + Playwright 50% 불일치).
  2. H3 본문 wire (PersonalizationEngine deprecation + DynamicTextResolver 격국·용신 anchor).
  3. H1 5행 가중치 (골든 보존 + 다른 sample 정합).
- **NEGATIVE**: H4 신살 list (학파 기피).
- **Deferred**: D3 조후용신 (sprint 6 후보).

---

## 8. verbatim 도용 가드 (재확인)
- 커뮤니티 후기 원문 0건.
- 학파 책 본문 0건.
- 우리 앱 docs 안 학파 dimension·가중치 표준·페르소나 keyword 만 추출.

> **본 docs 는 audit 용 — 사용자 노출 X**. UI 본문 sprint 5-7 의 별도 정제.

---

## Sources (WebSearch 9 키워드 = 90 page summary 기반)

- [지장간 - 위키백과](https://ko.wikipedia.org/wiki/%EC%A7%80%EC%9E%A5%EA%B0%84)
- [사주명리 입문 - 지장간(地藏干)](https://www.sajustudy.com/31)
- [사주팔자 - 나무위키](https://namu.wiki/w/%EC%82%AC%EC%A3%BC%ED%8C%94%EC%9E%90)
- [자평진전 - tellmesaju](https://tellmesaju.com/saju/japyeongjinjeon/intro)
- [명리학의 적천수, 자평진전, 궁통보감 용신론 비교 연구 — 국회도서관](https://dl.nanet.go.kr/detail/KDMT1201822063)
- [신살 - 위키백과](https://ko.wikipedia.org/wiki/%EC%8B%A0%EC%82%B4)
- [사주팔자/신살 - 나무위키](https://namu.wiki/w/%EC%82%AC%EC%A3%BC%ED%8C%94%EC%9E%90/%EC%8B%A0%EC%82%B4)
- [신강 신약 판단 기준 - 8ja.co.kr](http://8ja.co.kr/sub1_08_3.html)
- [동서양 각국의 진태양시 보정에 관한 연구 - KISS](https://kiss.kstudy.com/Detail/Ar?key=4037051)
- [사주타로앱 20개 이상 사용자의 찐 리뷰 — subdued20club](https://m.cafe.daum.net/subdued20club/LxCT/307823)
- [마이사주 - K-POP·연예인 사주 — Google Play](https://play.google.com/store/apps/details?id=com.mysaju.app)
- [당장 깔아! 박성훈·프리지아 사주 어플 — Allure Korea](https://www.allurekorea.com/2024/05/14/)
- [사주 어플 후기 — brunch qufekdstudy](https://brunch.co.kr/@qufekdstudy/19) (F6 직접 fetch)
- [사주 타로 앱 20개 리뷰 — threads arcanedrop](https://www.threads.com/@arcanedrop/post/DFmVPtMTyHJ) (F7 직접 fetch)
- [지장간 - 위키백과](https://ko.wikipedia.org/wiki/%EC%A7%80%EC%9E%A5%EA%B0%84) (F1 직접 fetch)
- [신살 - 위키백과](https://ko.wikipedia.org/wiki/%EC%8B%A0%EC%82%B4) (F2 직접 fetch)
- [사주명리 입문 - sajustudy 지장간](https://www.sajustudy.com/31) (F3 직접 fetch)
- [자평진전 - tellmesaju](https://tellmesaju.com/saju/japyeongjinjeon/intro) (F4 직접 fetch)
- [사주 신강신약 - brunch sajuwiki](https://brunch.co.kr/@sajuwiki/37) (F5 직접 fetch)
