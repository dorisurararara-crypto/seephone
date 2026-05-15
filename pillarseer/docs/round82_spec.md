# Round 82 — 사용자 실기기 발견 9문제 fix plan (1.0.0+39 검증 후)

> Sprint 1 산출물. **audit + spec only / Flutter 코드 변경 0 / test 변경 0**.
>
> **본 문서는 개발자 audit 전용 — 최종 사용자에게 절대 노출 안 됨.**
>
> 본 spec 안의 영문 단어 (overload / first-fold / wire / mount / deep-link / redirect / golden screenshot / risk / blacklist / disclaimer / commit / spec) 와 한국어 도메인 단어 ("기운" / "결" / "흐름") 는 모두 개발자 planner / generator / evaluator 가 코드 위치·동작·검증을 빠르게 공유하기 위한 작업 용어. 본 spec 안에서 사용된 단어가 사용자 UI 에 그대로 노출되는 것은 **금지**.
>
> 최종 사용자가 보는 한국어 본문 (sprint 2~8 에서 작성될 arb / phrase pool / widget label) 은 한국 MZ 중학생 K-POP 팬 직설 친근 해요체 만 사용. UI 본문에는 한자 jargon · 영문 약어 · 개발자 용어 전부 0 — 본 문서의 M5 mandate (§4) 가 사용자 노출 본문 톤 게이트.

## 0. Round Overview

| 항목 | 값 |
|---|---|
| Round | 82 |
| 시작일 | 2026-05-15 |
| 예정 sprint 수 | 10 |
| 직전 Round | 80 (개인화 broken fix + 차트 색상 + D2 조후용신, 미배포 / commit `f259133`) |
| 진행 중단 Round | 81 (만세력 일주 99% mandate, sprint 1 spec 까지 — `docs/round81_spec.md` / commit `2ea7054`) |
| 사용자 trigger 시점 | R81 sprint 1 spec 작성 직후, 사용자가 1.0.0+39 ganzitester 빌드를 본인 + 여자친구 + 본인 결과 다시 보다가 9 visible 문제 noticed → R81 중단 · R82 우선 진행 |
| 본 sprint 1 산출물 | `docs/round82_spec.md` (markdown 1개) |
| 본 sprint 1 코드 변경 | 0 (docs only) |
| 본 sprint 1 test 변경 | 0 (docs only) |
| 본 sprint 1 배포 | X (사용자 mandate "내가 배포하라고 할때만해" 준수) |

### 사용자 trigger verbatim (2026-05-15)

> 출처: `pillarseer/인수인계.md` 의 "사용자 발견 9문제 (verbatim)" 블록 한 줄 인용 (해당 파일 line 14, 본 문서 작성 시점 기준). 본 spec 안에서는 verbatim 변형 0.

> "여전히 앱에 문제가 많아 너무 뭐가 많아서 한눈에 들어오지도 않고 내용도 부자연스러운것도 많고 삶의 12가지 결 풀이도 이 결은 드러낸 흐름이약해서 연겱된기운으로 봐야해요 하면서 도와주는기운과 살짝걸리는기운이 나오는데 그게 뭔지도 안나오고 설명도 약하고 내 사주탭에 오늘 당신에게 생길수 있는일이 왜있는거며 (오늘탭에 있어야함) 깊게봐도 다시 잡힌 핵심 이것도 부자연스럽고 벼린칼 같은사람이에요 이 단어도 너무 어렵고 금토끼 금원숭이 이런거 나오는데 그게 뭔지 설명도 없고 조승현아 오늘은 금토끼에 날이야 이건 또 갑자기 뭐하는거며 설명도 없고 오늘의 일진은 토 쥐 이것만있는데 이것도 설명도 없고 왜 있어야하는건지 모르겠고"

→ 9 visible 문제 / 5 영역: (a) UI overload (b) 본문 부자연 (c) 라벨/설명 X (d) 잘못된 탭에 카드 mount (e) 어려운 어휘.

### Planner spec plan 7 섹션 ↔ 본 spec 매핑

본 spec 은 `/tmp/plan_pillarseer_r82_s1.md` planner spec plan 의 7 섹션을 다음 위치에 모두 반영.

| Planner 섹션 | 본 spec 위치 |
|---|---|
| 1. 제품 컨텍스트 (무엇 / 왜 / 누구) | §0 Round Overview + §0 사용자 trigger verbatim |
| 2. 높은 수준 기술 설계 (Sprint 1 schema) | §1 사용자 발견 9문제 표 + §2 9문제 진단 + §3 Sprint plan |
| 3. 결과 제약 (파일 / 형식 / 품질 / commit) | §0 Round Overview + §9 결론 + 영문 약어 disclaimer |
| 4. AI 기능 자연 녹임 기회 (sprint 2~8) | §2 #3 / #5 / #6 / §3 Sprint plan 의 fix 방향 |
| 5. 디자인 톤 (콘텐츠 작성 시) | §4 M5 mandate (페르소나 + 톤 게이트) |
| 6. NON-GOAL list | §5 NON-GOAL (12 항목) |
| 7. Sprint Outline (10 sprint user story) | §3 Sprint plan (10 sprint 표 + user story 1줄) |

---

## 1. 사용자 발견 9문제 (verbatim 표)

본 표는 인수인계.md (2026-05-15 R82 섹션) line 16~26 의 9 row 표 + 본 round 에서 영향 범위 / 회귀 위험 / 검증 plan 컬럼을 보강한 것.

| # | 문제 | 추정 위치 | fix 방향 | 영향 범위 | 회귀 위험 | 검증 plan |
|---|---|---|---|---|---|---|
| 1 | UI 정보 overload — 한눈에 안 들어옴 | `result_screen.dart` 전체 17 섹션 | 우선순위 정리 / 접기 강화 / 핵심만 first-fold | result_screen 전반 widget tree | 中 (golden screenshot 변동) | 첫 fold widget 갯수 cap test + golden screenshot |
| 2 | 본문 부자연스러움 (계속) | `assets/data/saju_deep_slice_*.json` ko 본문 240 entry | 운세의신 톤·구조 카피 (verbatim X) sample 30 entry 재작성 (sprint 8) | saju_deep_slice 3 file × 본문 ko 필드 | 中 (한국어 본문 어색 검사 회귀 가능) | tone audit blacklist grep test + 폴라리티 5:4:1 회귀 가드 |
| 3 | 12 결 풀이 "도와주는 기운" / "살짝 걸리는 기운" 라벨 = 무엇? 설명 X | `result_screen.dart:3267, 3280, 3291` (자미두수 12궁 `_ZiweiPalaceBlock`) + `assets/data/additional_life_pool.json` | 라벨 옆 "= X 십신 / Y 용신" + 1줄 설명 카드 wire | result_screen 자미두수 영역 + additional_life 카드 영역 | 中 (자미두수 hidden 영역 노출 mandate 위반 X 가드) | 카드 widget 추가 항목 test + 한국어 본문 audit |
| 4 | "내 사주" 탭에 "오늘 당신에게 생길 수 있는 일" 노출 | `result_screen.dart:147~150` `TodayEventDetailSection` mount | R79 sprint 7 의 `/today` route 분리 미완 — result_screen 에서 today_event 완전 제거 (anchor key 만 유지 또는 deprecate) | result_screen mount + deep-link redirect rule + alert anchor scroll | 中 (deep-link `/result?anchor=today_event` backward compat) | result_screen widget tree grep `TodayEventDetailSection` 0 + golden screenshot + deep-link redirect test |
| 5 | "깊게 봐도 다시 잡힌 핵심" 부자연스러움 | `lib/widgets/six_axis_radar.dart:71` `_MatchBadge` | 라벨 자체 재작성 ("두 번 봐도 같이 잡힌 강점" 류) 또는 badge 자체 제거 | six_axis_radar 위젯 1개 + R69 lock matchCount test | 低 (라벨 변경만 시 widget tree 동일) | widget tree audit + 문구 grep + R69 lock 재확인 |
| 6 | "벼린 칼 같은 사람" 단어 어려움 | `deep_content_service.dart:404~540` `_oneLineByJi60Ko` (R80 sprint 2 wire) | 60일주 phrase 자체 재작성 — 더 쉬운 MZ 단어 (폐기 5종 fallback 도 점검) | deep_content_service oneLine + 폐기 5종 차단 blacklist + tone audit | 中 (R80 sprint 2 wire 60 entry 전수 재작성) | 60 entry tone audit + grep blacklist test + 5행 골든 보존 |
| 7 | "금토끼" / "금원숭이" 갑자기 등장, 설명 X | `assets/data/saju_60ji.json` `name` field (예: "Wood Rat" 영문) + UI 노출 영역 | name field 노출 영역 grep + 1줄 설명 추가 또는 한글 name 자체 변경/삭제 (사용자 노출 영역에서 한글 동물 단독 노출 X) | saju_60ji.json + saju_content_service + UI 표시 영역 | 中 (60갑자 name 사용 영역 다수) | 한글 name 노출 영역 grep test + 카드 widget 설명 추가 test |
| 8 | "조승현아 오늘은 금토끼에 날이야" 갑자기 등장, context 없음, 무서워 보임 | 알림 / home / today 카드 — `notification_pool_service` + today_event 영역 | "오늘 일진" 카드의 한글 name 노출 영역 = 사용자 사주와 관계 1줄 wire ("오늘 일진은 X 일주 = 당신 일간 Y 와 Z 관계") | notification_pool_service template + home_screen today pillar widget | 中 (알림 template 회귀 가능) | 알림 phrase blacklist grep + context 1줄 wire test |
| 9 | "오늘의 일진은 토 쥐" 만 노출 (戊子의 한글 풀이?), 설명 X | `home_screen.dart` 일진 표시 카드 (`homeTodaysPillar` + `_localizedGanjiLabel`) | 일진 (오늘 60갑자) 의 의미 1줄 설명 + 사용자 사주와 관계 추가 ("오늘 일진 戊子 = 당신 일간 X 와 Z 관계") | home_screen 일진 카드 widget + l10n key | 低 (home_screen widget 한 곳 + arb key 1개) | 일진 카드 widget 추가 항목 test + 한국어 본문 audit |

→ 9문제 5 영역 정리: (a) UI overload = #1 / (b) 본문 부자연 = #2 / (c) 라벨·설명 X = #3 #5 #6 #7 #8 #9 / (d) 잘못된 탭 mount = #4 / (e) 어려운 어휘 = #5 #6 (overlap with c).

---

## 2. 9문제 진단 + fix 방향 상세

### #1 — UI 정보 overload (result_screen 17 섹션 한눈에 안 들어옴)

- **추정 위치**: `lib/screens/result_screen.dart` 전체 widget tree (현재 4290 line). 17+ 섹션 (60일주 한 줄 요약 / 5행 / 십신 / 격국 / 용신 / 신살 / 통근 / 합충 / 대운 / 연운 / 12 카드 (`삶의 12가지 결 풀이` 라벨 영역) / 자미두수 12궁 / 6각 radar / 오늘 한 줄 / 오늘 깊게 / 오늘 이벤트 / today_deep) 이 평면적으로 나열.
- **fix 방향**:
  1. 첫 fold (스크롤 0~1) = 핵심 3~4 섹션 (예: 60일주 한 줄 요약 / 5행 분포 / 십신 핵심 / 오늘 한 줄) 펼침 상태.
  2. 나머지 12+ 섹션 (격국 / 용신 / 신살 / 통근 / 합충 / 대운 / 연운 / 12 카드 / 자미두수 12궁) 은 `_AccordionRow` 접힘 상태로.
  3. today_event 는 #4 fix 로 result_screen 에서 아예 제거 → `/today` route 단독.
- **영향 범위**: result_screen widget tree 광범위. golden screenshot 변동 큼. 사용자 deep-link `/result?anchor=...` backward compat 가드 필요.
- **회귀 위험**: 中. R73 17 섹션 wire / R74 12시간 흐름 first-fold / R76 알림 anchor scroll / R79 /today route 분리 모두 영향. 단 5행 골든 sample 점수 자체에는 영향 0.
- **검증 plan**: golden screenshot 새 baseline + 첫 fold widget 갯수 cap test (예: ≤ 6 widget) + deep-link redirect smoke + R73~R79 시그니처 보존 grep test.

### #2 — 본문 부자연스러움 (saju_deep_slice 240 entry ko 본문)

- **추정 위치**: `assets/data/saju_deep_slice_0_19.json` + `saju_deep_slice_20_39.json` + `saju_deep_slice_40_59.json` ko 필드 (60일주 × ~ 5 카테고리 × 본문 = 240 entry). R74 부분 재작성 통과 후에도 R77 generator 4선수 대결 단계에서 60 entry 가량 어색 phrase 잔존 확인.
- **fix 방향** (sprint 8 별도):
  1. 운세의신 사이트 톤·구조·키워드만 참고 (문장 자체 복제 X — 사용자 mandate "운세의신처럼 나오는 것" 의 의미 = 같은 정도의 짜임새, 문장 베끼기 X).
  2. 30 entry 부분 sample 우선 재작성 (sprint 8 1차).
  3. 폴라리티 5:4:1 (긍정·중립·주의) baseline 유지 — R73 lock.
  4. 양면 단정 ≥30% / 행동 처방 ≥15% 유지.
  5. 어색 phrase blacklist 갱신 (테스트 fixture `test/fixtures/r82_ai_slop_blacklist.txt` 신규 — "구조예요" 중복 5회+, AI 슬롭 직역체 noun 단독 패턴 등을 fixture 에 한 곳으로 모음. 본 spec 안에 직접 인용 X).
- **영향 범위**: saju_deep_slice 3 file. test 회귀 risk = ko_content_quality_test (R74 wire).
- **회귀 위험**: 中. 사용자 felt 정합 정도가 audit 으로만 검증 가능 (codex evaluator + 사용자 추가 본인 sample).
- **검증 plan**: tone audit blacklist grep test + 폴라리티 5:4:1 회귀 가드 + 어색 phrase 5회+ 반복 grep + codex audit 30 entry sample 9.9+ PASS.

### #3 — 12 결 풀이 라벨 "도와주는 흐름" / "살짝 걸리는 흐름" = 무엇? 설명 X

- **추정 위치**: 
  - `lib/screens/result_screen.dart:3267` "이 결은 직접 드러난 기운이 약해서, 연결된 흐름까지 같이 봐요." (사용자 verbatim 와 거의 일치 — 자미두수 12궁 `_ZiweiPalaceBlock` 영역).
  - `lib/screens/result_screen.dart:3280` "도와주는 흐름" `${palace.luckyStars.length}가지 기운이 받쳐줘요`.
  - `lib/screens/result_screen.dart:3291` "살짝 걸리는 흐름" `${palace.badStars.length}가지 기운이 살짝 걸려요`.
  - `assets/data/additional_life_pool.json` (12 카테고리 결 풀이 본문 영역 — 별도 wire 가능성 audit 필요).
- **fix 방향**:
  1. "도와주는 흐름" 라벨 옆 또는 카드 안 1줄 설명 추가 — "= X 십신 (예: 식신/정관) / Y 용신 (예: 木)" 근거 표기 + "이게 당신의 ~ 영역에 어떤 도움을 주는지" 사용자 친근 어휘로 1줄.
  2. "살짝 걸리는 흐름" 라벨 옆 1줄 설명 추가 — "= 충/공망/도화 등 사주 신살" 근거 표기 + "그래서 ~ 부분은 천천히 가요" 같이 행동 처방 1줄 (의료 단정 X / Apologetic AI 어조 X).
  3. luckyStars / badStars 정체 자체 (자미두수 별 이름) 는 사용자 노출 X mandate 유지 (Round 70 마케팅 차별점 보호 — 자미두수 UI 영역에서는 별 이름 hidden).
  4. 카드 confidence 표시 = "당신 사주 ~ 와 어떤 관계인지" 만 (1줄, 사용자 친근 어휘).
- **영향 범위**: result_screen 자미두수 12궁 widget 추가 항목 1줄. additional_life 카드 영역 (별도 confirm 필요). 라벨 자체는 유지.
- **회귀 위험**: 中. 자미두수 hidden mandate 위반 X 가드 (별 이름 nameKo 노출 0). Round 70 `kIsZiweiUiHidden=true` 회귀 X.
- **검증 plan**: 카드 widget 추가 항목 test (`_SupportSummaryRow` 가 추가 1줄 노출 검증) + 자미두수 별 이름 nameKo grep 0 회귀 가드 + 한국어 본문 audit (한자 jargon X / Apologetic AI X / 의료 단정 X).

### #4 — "내 사주" 탭에 "오늘 당신에게 생길 수 있는 일" 노출 (잘못된 탭 mount)

- **추정 위치**: `lib/screens/result_screen.dart:147~150` `TodayEventDetailSection` mount (anchor key `kTodayEventDetailAnchor` 유지). Round 79 sprint 7 의 `/today` route 분리 작업 시 `TodayEventDetailSection` 자체는 result_screen 에 유지 + `today_screen.dart` 가 result_screen import 해서 동일 widget 재사용 (line 21 `import 'result_screen.dart' show TodayEventDetailSection`).
- **fix 방향**:
  1. `TodayEventDetailSection` 을 result_screen 에서 detach → 별도 `widgets/today_event_detail_section.dart` 로 이동 + today_screen import path 변경.
  2. result_screen line 147~150 의 mount 자체 제거 (anchor key kTodayEventDetailAnchor 도 제거 또는 deprecated comment).
  3. deep-link `/result?anchor=today_event` → router rule 에서 `/today` 로 redirect (이미 R79 sprint 7 에서 부분 적용된 가능성, 본 sprint 에서 검증 + 보강).
- **영향 범위**: result_screen line 28 import / line 147~150 mount / line 51 anchor key declaration / line 67~84 anchor scroll logic / today_screen.dart line 21 import / app router rule.
- **회귀 위험**: 中. 사용자 알림 deep-link → /result 진입 → today_event 자동 스크롤 동작이 R76 sprint 6 에 wire 되어 있으므로, redirect rule 누락 시 알림 클릭 dead 가능. → router rule 보강 필수.
- **검증 plan**: 
  - `grep TodayEventDetailSection lib/screens/result_screen.dart` = 0 회귀 가드 test.
  - `grep TodayEventDetailSection lib/screens/today_screen.dart` ≥ 1 (today 단독 mount 보존).
  - deep-link smoke test: `/result?anchor=today_event` → `/today` redirect.
  - golden screenshot (result_screen first fold + today_screen first fold).

### #5 — "깊게 봐도 다시 잡힌 핵심" 라벨 부자연

- **추정 위치**: `lib/widgets/six_axis_radar.dart:71` `_MatchBadge` 라벨 "깊게 봐도 다시 잡힌 핵심".
- **fix 방향**:
  1. 옵션 A — 라벨 재작성: "겉도 속도 같이 강한 곳" / "두 번 봐도 같이 잡힌 강점" / "안팎 모두 일치한 영역" 류 사용자 친근 어휘.
  2. 옵션 B — badge 자체 제거 (✨ ring 만 radar 에 유지, 라벨 카드 미노출).
  3. 옵션 C — 라벨 옆 (?) tap 시 1줄 helper text 표시.
  4. codex 평가 후 옵션 결정.
- **영향 범위**: six_axis_radar 위젯 1개 + R69 lock matchCount 값 자체에는 영향 0 (라벨만 변경).
- **회귀 위험**: 低. widget tree 미변경 + 라벨 string 만 변경 시 R69 lock 무영향.
- **검증 plan**: widget tree audit + 문구 grep ("깊게 봐도 다시 잡힌" 0 회귀 가드) + R69 lock 재확인 (본성 78 / 연애 78 / 일 72 / 돈 74 / 건강 57 / 평판 71).

### #6 — "벼린 칼 같은 사람" 단어 어려움

- **추정 위치**: `lib/services/deep_content_service.dart:404~540` `_oneLinerFor` + `_oneLineByJi60Ko` map (R80 sprint 2 wire — 60일주 unique phrase pool).
- **fix 방향**:
  1. 60 entry phrase 전수 audit — 어려운 한자 jargon 어휘 ("벼린 칼" / "도검의 끝" / "정수" / "본질" / "결을 다듬는" 류) 찾기 + 더 쉬운 MZ 어휘로 재작성.
  2. 폐기 5종 fallback (R80 sprint 2 차단 phrase) 도 grep 후 정리.
  3. 5행 dom fallback 5종 (`koMap`: 木·火·土·金·水 → 5 phrase) 도 audit.
  4. 사용자 직관 단어 (예: "단단한" / "다정한" / "꾸준한" / "재빠른" / "차분한") 만.
- **영향 범위**: deep_content_service oneLine + todayHook + whyReason 모두 같은 base map 참조 → 영향 cascade.
- **회귀 위험**: 中. R80 sprint 2 wire 60 entry 전수 재작성 → R80 oneline_personalization_test 회귀 risk. test sample (예: 辛卯 일주) 만 update 후 sample 외 entry 는 자유.
- **검증 plan**: 60 entry tone audit (한자 jargon blacklist) + grep blacklist test ("벼린 / 도검 / 정수 / 본질 / 결을") + 5행 골든 보존 + R80 oneline test sample 갱신 + codex 30 entry sample audit 9.9+.

### #7 — "금토끼" / "금원숭이" 한글 동물 단독 노출, 설명 X

- **추정 위치**: 
  - `assets/data/saju_60ji.json` `name` field 영문 ("Wood Rat" / "Metal Horse" 등) — UI 노출 형태 별도 확인.
  - 한글 변환 wire 추적 필요. `lib/services/saju_content_service.dart` (loader + cache) + `lib/services/saju_service.dart:86, 174` 60일주 콘텐츠 로드 영역.
  - `lib/screens/discover_screen.dart:365` `jiKo` map (지지 한글) 사용 영역.
  - `lib/screens/reports/date_picking_screen.dart:144` `_jiKoreanAnimal` 한글 동물 변환.
  - 한글 동물 단독 노출 발생점 audit (예: notification_pool_service template 의 한글 동물 interpolation).
- **fix 방향**:
  1. 한글 동물 단독 노출 영역 grep → 모두 1줄 설명 추가 ("금토끼 = 辛卯 일주 = 차분하게 단단해지는 사람" 류).
  2. 또는 한글 동물 자체를 사용자 노출 영역에서 제거 (예: 알림 template / today 카드).
  3. saju_60ji.json `name` 영문 field 는 i18n 영문 영역에서만 사용 (한국어 사용자 노출 X 가드).
- **영향 범위**: saju_60ji.json + saju_content_service + notification_pool_service + home_screen / today_screen 한글 동물 interpolation 영역.
- **회귀 위험**: 中. 한글 동물 noun interpolation 영역이 다수 → 누락 시 사용자 추가 발견 risk.
- **검증 plan**: 
  - `grep '금토끼\|금원숭이\|목쥐\|화범' lib/ assets/` 모든 hit 점에 설명 wire 검증 test.
  - 한글 동물 단독 phrase blacklist test (사용자 노출 영역).
  - i18n 영문 영역 분리 가드.

### #8 — "조승현아 오늘은 금토끼에 날이야" 알림/카드 갑자기 등장, context X, 무서워 보임

- **추정 위치**: `lib/services/notification_pool_service.dart` template + `lib/services/today_event_service.dart` + 알림 phrase pool. `notification_pool_service.dart:3` 주석 "사용자 사주 + 오늘 일진 기반 calibrate" + line 244 `pickDeep`.
- **fix 방향**:
  1. "조승현아 오늘은 ~ 날이야" 류 호명 + 한글 동물 nicname 호출 phrase 영역 grep.
  2. context 1줄 wire — "오늘은 ~ 한 날이에요 (= 당신 일간 X 와 Y 관계)" 형태.
  3. 호명 톤 audit — 너무 친근 (반말 + 이름 단독) → 무서움 risk → "{이름}님" 또는 호명 자체 제거 옵션.
  4. 알림 push 와 home today 카드 양쪽 wire 점검.
- **영향 범위**: notification_pool_service template / push 알림 / home today 카드 / today_event_service.
- **회귀 위험**: 中. 알림 template 회귀 risk (R76 sprint 6 wire 갱신).
- **검증 plan**: 알림 phrase blacklist grep + context 1줄 wire test + 호명 톤 audit codex 9.0+.

### #9 — "오늘의 일진은 토 쥐" 단독 노출, 설명 X

- **추정 위치**: 
  - `lib/l10n/app_ko.arb:50` `homeTodaysPillar`: "오늘의 일진".
  - `lib/screens/home_screen.dart:146` `_localizedGanjiLabel(context, fortune.dayPillar)` — 일진 label 표시 영역.
  - `lib/models/saju_result.dart:110` `jiKo` map (지지 한글 변환) + `lib/screens/discover_screen.dart:365` `jiKo` map.
  - 한글 동물 변환 = `lib/screens/reports/date_picking_screen.dart:144` `_jiKoreanAnimal` (별도 위치 가능성).
- **fix 방향**:
  1. 일진 label "토 쥐" / "戊子" 단독 표시 X — 1줄 의미 설명 wire.
  2. 사용자 사주와 관계 1줄 — "오늘 일진 戊子 = 당신 일간 X 와 Z 관계 (예: 정관 / 충 / 합)".
  3. 친근 어휘 — "오늘은 ~ 한 분위기" 보조 phrase 1줄.
  4. `homeTodaysPillar` arb key 단독 라벨에 sub-label arb key 추가 (예: `homeTodaysPillarHelper`).
- **영향 범위**: home_screen 일진 카드 widget 1곳 + arb ko / en key 추가 1쌍.
- **회귀 위험**: 低. widget 한 곳 + l10n 1 쌍 추가.
- **검증 plan**: 일진 카드 widget 추가 항목 test + 한국어 본문 audit + l10n compat test.

---

## 3. Sprint plan (10 sprint)

각 sprint 의 user story 는 testable. codex 9.9+ 못 받으면 그 sprint 안에서 반복 (harness pattern, max 7 라운드 / 라운드 마다 다른 audit file).

| # | 의제 | user story (1줄 testable) | 산출물 | 5행 골든 | R69 lock |
|---|---|---|---|---|---|
| 1 | spec (본 문서) | 사용자가 `docs/round82_spec.md` 1개 markdown 을 읽고 9문제 fix plan 을 이해할 수 있다. | `docs/round82_spec.md` | 보존 | 보존 |
| 2 | #4 fix — `/today` route 분리 완료 | 사용자가 "내 사주" 탭 (`result_screen.dart`) 에서 "오늘 당신에게 생길 수 있는 일" 카드를 보지 않고, `/today` 탭에만 노출된다. | `result_screen.dart` mount 제거 + `widgets/today_event_detail_section.dart` 분리 + router redirect + test 신규 | 보존 | 보존 |
| 3 | #6 fix — `_oneLineByJi60Ko` 60 entry 더 쉬운 단어로 재작성 | 사용자가 `_oneLineByJi60Ko` 60 entry phrase 를 보고 "벼린 칼" / "도검의 끝" / "한자 jargon" 류 어휘 0. 폐기 5종 fallback (R77 차단) 도 정리된 상태. | `deep_content_service.dart` 변경 + blacklist test + R80 oneline test sample 갱신 | 보존 | 보존 |
| 4 | #5 fix — "깊게 봐도 다시 잡힌 핵심" 라벨 재작성 또는 제거 | 사용자가 `six_axis_radar.dart` `_MatchBadge` 영역을 보고 부자연 어휘 0, 또는 badge 자체 제거된 상태. | `six_axis_radar.dart` 변경 + widget test | 보존 | 보존 |
| 5 | #3 fix — 12 결 풀이 라벨 명시 + 1줄 설명 | 사용자가 12 결 풀이 카드 (`_ZiweiPalaceBlock`) 에서 각 "도와주는 흐름" / "살짝 걸리는 흐름" 옆에 "= 십신 X / 용신 Y" 라벨 + 1줄 설명을 본다. | `result_screen.dart` widget 변경 + `additional_life_service` 옵션 + 한국어 본문 audit | 보존 | 보존 |
| 6 | #7+#8+#9 fix — 한글 동물 name / 일진 / 알림 context | 사용자가 "금토끼" / "금원숭이" / "조승현아 오늘은 금토끼에 날이야" / "오늘 일진 토 쥐" 문구를 보고 옆에 1줄 의미 설명 (사주와 관계 명시) 을 본다. | `notification_pool_service.dart` / `home_screen.dart` / arb / 한글 동물 노출 영역 grep + 카드 widget 추가 test | 보존 | 보존 |
| 7 | #1 fix — UI 정보 우선순위 정리 (first-fold 핵심만) | 사용자가 `result_screen.dart` 첫 fold 에서 핵심 3~4 섹션 만 펼침 상태, 나머지 12+ 섹션은 접힘 상태로 본다. | `result_screen.dart` widget tree 재구성 + 첫 fold cap test + golden screenshot | 보존 | 보존 |
| 8 | #2 fix — 본문 부자연스러움 (saju_deep_slice 30 entry sample 재작성) | 사용자가 `saju_deep_slice_*.json` sample 30 entry ko 본문에서 R74 어색 phrase blacklist 0 (운세의신 톤 참고하되 문장 복제 X). | `assets/data/saju_deep_slice_*.json` 30 entry update + tone audit + blacklist grep test | 보존 | 보존 |
| 9 | 회귀 가드 + R69 lock 검증 + 5행 골든 보존 | 사용자가 `flutter test` 전체 PASS 확인. 1995-10-27 男 17시 5행 골든 16/21/17/41/4 + 일주 辛卯 보존. R69 lock (본성 78 / 연애 78 / 일 72 / 돈 74 / 건강 57 / 평판 71) 보존 또는 갱신 commit. | `flutter analyze` 0 + `flutter test` 전체 PASS + 골든 test + R69 lock test | 보존 | 보존 또는 갱신 |
| 10 | memory R82 + 인수인계.md R82 섹션 + (사용자가 배포 지시 시 그때만) 1.0.0+40 외부 베타 ganzitester 제출 | 사용자가 본 memory (`project_pillarseer_round_82.md`) + 인수인계.md R82 섹션 commit 을 확인하고, 그 후 사용자가 "배포해" 라고 지시한 경우에만 1.0.0+40 외부 베타 제출 진행. | memory + 인수인계 commit + (사용자가 배포 지시 시 그때만) altool 업로드 | 보존 | 보존 |

### Sprint user story 평이한 한국어 풀이 (페르소나 적합 보강 — M5 mandate)

본 표의 sprint user story 가 영문 noun 이 섞여 있어 페르소나 (한국 MZ 중학생) 가 즉시 이해하기 어려울 수 있어 다음과 같이 한국어로 한 번 더 풀어둠. 본 풀이는 spec 안에서 generator 가 sprint 시작 시 의도를 재확인하는 용도 — 사용자 노출 본문은 아님.

1. Sprint 1 — 이 문서 (R82 spec) 하나를 읽으면 사용자가 발견한 9가지 문제와 각 fix 방향을 한 번에 이해할 수 있어야 한다.
2. Sprint 2 — "내 사주" 탭에서 "오늘 당신에게 생길 수 있는 일" 카드가 더 이상 보이지 않고, 오늘 탭에서만 보이도록 자리를 바꾼다.
3. Sprint 3 — "벼린 칼 같은 사람" 같은 어려운 표현을 60일주별로 더 쉬운 한국어 표현으로 다시 쓴다.
4. Sprint 4 — "깊게 봐도 다시 잡힌 핵심" 라벨 문구를 사용자가 한 번에 이해할 수 있는 자연스러운 표현으로 바꾸거나 라벨을 없앤다.
5. Sprint 5 — 12가지 카드 안의 "도와주는 흐름" / "살짝 걸리는 흐름" 라벨 옆에 그게 무엇인지 1줄 설명을 붙인다.
6. Sprint 6 — "금토끼" / "오늘 일진은 토 쥐" 같은 단어가 단독으로 뜨지 않게, 옆에 짧은 설명과 사용자 사주와의 관계 1줄을 같이 보여준다.
7. Sprint 7 — "내 사주" 탭에서 처음 화면에 17가지 섹션이 동시에 펼쳐지지 않고, 핵심 3~4개만 펼쳐진 채 나머지는 접혀 있도록 화면을 정리한다.
8. Sprint 8 — 사주 본문 (saju_deep_slice 안의 한국어 본문 240개 중 30개) 의 어색한 문장을 더 자연스러운 표현으로 다시 쓴다.
9. Sprint 9 — 모든 테스트가 통과하고, 1995-10-27 남자 17시 사주의 5행 16/21/17/41/4 + 일주 辛卯 가 그대로 유지되는지 확인한다.
10. Sprint 10 — 본 라운드 결과를 메모리 + 인수인계 문서에 남기고, 사용자가 "배포해" 라고 명시했을 때에만 외부 베타 빌드 제출.

### Sprint 간 의존
- Sprint 2 (#4) 가 sprint 7 (#1 UI 정리) 보다 먼저 — today_event 제거 후에 first-fold 정의가 깨끗.
- Sprint 5 (#3) 가 sprint 7 (#1) 보다 먼저 — 12 카드 라벨 보강 후 접기 순서 정리.
- Sprint 8 (#2) 은 multi-sprint 가능 — 240 entry 중 30 sample 우선, 나머지는 후속 라운드.
- Sprint 9 (회귀 가드) 가 sprint 2~8 모든 commit 후 마지막 종합.
- Sprint 10 = 배포 = 사용자 명시 후만.

### Sprint 별 사용자 노출 톤 체크리스트 (M5 mandate 적용 — generator 가 매 sprint 끝 확인)

각 sprint 의 generator 가 commit 직전 다음 체크리스트로 사용자 노출 본문 (arb / phrase pool / widget label / 알림 template) 만 audit. 본 spec 본문 자체는 audit 범위 밖 (개발자 audit 문서).

- [ ] 한자 jargon noun 단독 사용 0 — "본질" / "정수" / "결" / "운기" / "기운" / "결을 다듬는" / "벼린 칼" / "도검의 끝".
- [ ] AI 슬롭 0 — 사용자 verbatim 안에 등장한 직역체 noun 단독 패턴 (사용자 trigger §0 의 verbatim 안 단어 그대로 단독 사용 X). 상세 fixture: `test/fixtures/r82_ai_slop_blacklist.txt` (sprint 8 generator 가 신규 작성).
- [ ] Apologetic AI 어조 0 — "죄송하지만" / "단정 짓기 어렵지만" / "확실하지는 않지만".
- [ ] 의료 단정 0 — "병이 나요" / "치료가 필요해요" / "의사 상담".
- [ ] 직장인 jargon 0 — "PT" / "리텐션" / "퍼포먼스" / "KPI" / "OKR".
- [ ] 영문 약어 0 — "wire" / "mount" / "first-fold" / "deep-link" / "golden screenshot" / "risk" / "spec" / "commit" / "blacklist".
- [ ] 한글 동물 단독 노출 0 — "금토끼" / "금원숭이" / "토 쥐" / "목호랑이" 단독 phrase X (사용자 사주와 관계 1줄 wire 필수).
- [ ] 폴라리티 5:4:1 (긍정·중립·주의) baseline — R73 lock.
- [ ] 양면 단정 ≥30% — "강점이지만 ~ 주의" 패턴.
- [ ] 행동 처방 ≥15% — "오늘 ~ 해봐요" 패턴.

→ 위 체크리스트는 본 spec 의 본문이 아니라 **sprint 2~8 의 사용자 노출 본문** 에 적용. 본 spec 본문은 개발자 audit 용 (M5 mandate 의 사용자 노출 본문 톤 게이트 적용 대상 X).

---

## 4. 사용자 mandate 5개 (영구)

본 round 의 모든 sprint 가 다음 5개 mandate 를 절대 룰로 준수. 위반 시 즉시 sprint 중단 + 사용자 보고.

### M1 — 자율 (사용자 mandate)

- 사용자 verbatim (CLAUDE.md / global.md): "자율 진행 — 묻기 전에 로컬 탐색·웹 검색 먼저. 진짜 사용자만 가능한 영역(Apple 2FA·신규 가입 등)만 사용자 대기 큐. 그 외 모두 자율."
- planner / generator / evaluator 패턴으로 사용자 손 0회 진행 (codex 9.9+ PASS 까지 반복).

### M2 — 자동 배포 X (사용자 mandate verbatim)

- 사용자 verbatim (R80 mandate, 2026-05-15): **"내가 배포하라고 할때만해"**
- TestFlight 1.0.0+40 빌드·altool 업로드·외부 베타 제출 = 사용자 명시 후만.
- sprint 10 user story 의 IPA 자동 제출은 사용자 mandate 가 trigger.
- 1.0.0+39 (R79) 이미 외부 베타 ganzitester 제출 + 검증 완료 → R80 + R81 + R82 통합 빌드는 사용자 OK 후만.

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

### M5 — 한국 MZ 중학생 K-POP 팬 페르소나 (사용자 mandate)

- 페르소나 = Co-Star 글로벌 진출 전 한국 verification 페르소나. dorisurararara (Flutter 1인 개발자) + 여자친구 실 사용자.
- 사주 도메인 비전문가 — 한자 jargon · 영문 약어 · 개발자 용어 사용자 노출 본문에 0%.
- 톤 게이트 (사용자 노출 본문 — 후속 sprint 적용):
  - 직설 친근 해요체 (R74 baseline). 명령형·단정형 X.
  - 한자 jargon 0 — "본질" / "정수" / "결" / "운기" / "기운" / "결을 다듬는" / "벼린 칼" / "도검의 끝" (사용자가 의미 모를 한자어). 단 "사주" / "오늘 일진" 같이 자주 듣는 단어 OK.
  - AI 슬롭 0 — Co-Star 영문 직역 흔적 noun 단독 패턴 (직접 단어 인용은 sprint 8 fixture `test/fixtures/r82_ai_slop_blacklist.txt` 한 곳에만 보관, 본 spec 본문에는 직접 인용 X).
  - MZ K-POP 친근 어휘 — "오늘 ~ 해봐요" / "당신 사주에서 ~ 가 강해요" / "~ 한 사람이에요" 자연. 강요 X.
  - 의료·법률·금융 단정 0.
  - Apologetic AI 어조 0 ("죄송하지만" / "단정 짓기 어렵지만" 류).
  - 폴라리티 5:4:1 baseline (R73 lock).
  - 양면 단정 ≥30% / 행동 처방 ≥15% (R73 lock).

---

## 5. NON-GOAL (R82 X)

본 round 에서 안 하는 것 (별도 라운드 또는 사용자 mandate 후만):

1. **자미두수 UI 노출** — `kIsZiweiUiHidden=true` 보존 (R70 마케팅 차별점 보호). 12 결 풀이 라벨 보강 (#3 fix) 시 별 이름 nameKo (자미성·천기성·태양성 등) 사용자 노출 0 가드.
2. **새 기능** (구독·결제·Firebase·RevenueCat·소셜·푸시 신규 채널·결제 wall) — 별도 라운드.
3. **TestFlight 1.0.0+40 자동 배포** — 사용자 명시 후만 (sprint 10 user mandate 후만, M2 mandate).
4. **R72~R77 캐릭터 영역 폴라리티 정정** — `life_stage_pool.json` / `sipsin_persona.json` / `additional_life_pool.json` (오늘 12 결 풀이 본문 영역) / `career_pool.json` / `wealth_detail.json` 의 5:4:1 폴라리티 본문 재작성 (별도 라운드, R78 polarity 캐릭터 영역 deferred).
5. **만세력 algorithmic 깊은 fix** — R81 deferred D1 (KASI cross-check + 입추 ±5분) / D3 (시간 picker UX 30분 boundary 시각화) / D4 (H1 swap `rootMiddleBonus` ↔ `rootTraceBonus`). 회귀 위험 高 + 5행 골든 보존 algorithmic 어려움. R81 별도 라운드에서 처리.
6. **paywall 28 ARB 재활성** — `lib/l10n/app_ko.arb` 의 paywall_* 28 key 재활성 = 구독·결제 wire 별도 라운드 (R77 deferred).
7. **compat / datePick 77 ARB 재활성** — 궁합·날짜 선택 신규 기능 별도 라운드.
8. **5행 raw 분포 변경** — R75 calibration (1995-10-27 男 17시 16/21/17/41/4) 보존 mandate (사용자 felt 정합 확인 완료).
9. **R78 hotspot H3 / H6 / H8 / H13 / H14 미완료 영역 algorithmic fix** — R78 sprint 5 deferred (별도 라운드).
10. **자미두수 12궁 별 이름 (nameKo) 사용자 노출** — Round 70 hidden mandate 보존, `_ZiweiPalaceBlock` 영역의 "도와주는 흐름" / "살짝 걸리는 흐름" 라벨 보강 (#3 fix) 시에도 별 이름 노출 0.
11. **자동 이메일·SMS·알림 일정 채널 추가** — 알림 hh:mm picker R76 wire 만 유지, 신규 채널 X.
12. **영문 i18n 새 콘텐츠** — 영문 leak fix (R73 회귀 가드) 만, 신규 영문 콘텐츠 작성 X.

---

## 6. Deferred list (R82 안 처리, 후속 라운드 위임)

본 round 에서 안 처리하지만 후속 라운드에서 처리 예정인 항목:

### R81 deferred (만세력 영역)

- **D1 만세력 algorithmic** — KASI cross-check + `solar_term_service.dart` 입추 / 입춘 / 동지 ±5분 + 야자시 / 조자시 학파 boundary (5행 골든 보존 mandate, 회귀 위험 高). R79 sprint 2 의 6 sample 중 #2 / #4 / #5 일주 unsin mismatch 원인 추적.
- **D3 시간 picker UX** — `input_screen.dart` 23h 사용자 helper text + 30분 boundary 시각화 (widget 큰 변경 회귀 위험).
- **D4 H1 swap** — `manseryeok_service.dart:22~34` `rootMiddleBonus` ↔ `rootTraceBonus` 조건부 (5행 골든 보존 algorithmic 어려움).

→ R81 의 D1 / D3 / D4 모두 사용자 추가 정성 sample (≥10) + 학파 표준 cross-check 가 선결. 본 R82 와 동시 진행 X (사용자 mandate "R82 우선" 준수).

### R77 deferred

- **paywall 28 ARB 재활성** — `lib/l10n/app_ko.arb` 의 paywall_* 28 key + `compat` / `datePick` 77 ARB. 구독·결제 wire 별도 라운드.

### R78 deferred

- **hotspot H3 / H6 / H8 / H13 / H14 algorithmic fix** — R78 sprint 5 deferred. SajuContext + DynamicTextResolver 4단계 chain 의 완전 활용 영역.
- **polarity 캐릭터 영역 정정** — `life_stage` / `sipsin_persona` / `additional_life` (오늘 결 풀이 12종) / `career` / `wealth` 의 5:4:1 폴라리티 본문 재작성.

### R76 deferred

- **자미두수 마케팅 노출 옵션** — `kIsZiweiUiHidden=true` 보존 mandate 유지, 옵션 활성 시 별도 라운드.

---

## 7. 검증 plan (round 종료 시점 회귀 가드)

sprint 9 (회귀 가드) 시점에 다음 모두 PASS 확인 → R82 round close commit.

### G1 — flutter analyze 0 issue

```bash
cd /Users/seunghyeon/seephone/pillarseer
flutter analyze
# 기대값: No issues found!
```

### G2 — flutter test 전체 PASS (≥ 516)

```bash
cd /Users/seunghyeon/seephone/pillarseer
flutter test
# 기대값: 516+ tests passed (R80 종료 시점 baseline = 516, R82 신규 test 추가 후 ≥ 516 + 신규)
```

### G3 — 5행 골든 1995-10-27 男 17시 (R75 calibration)

```
입력: 1995-10-27 / 男 / 17:00 (KST, 양력)
기대 출력:
  - 5행 raw: 木 16 / 火 21 / 土 17 / 金 41 / 水 4
  - 일주: 辛卯
  - 일간 element: 金 (辛)
```

검증 test:
- `test/critical_regression_test.dart`
- `test/celebrity_calibration_test.dart`
- `test/round79_golden_test.dart`
- `test/round80_oneline_personalization_test.dart` (sample = 辛卯)

### G4 — R69 lock (R80 갱신 baseline)

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

### G5 — R71~R80 시그니처 보존

- 60일주 1440 phrase (today_event_service / notification_pool_service) 유지.
- 자미두수 UI hidden (`kIsZiweiUiHidden=true` + 별 이름 nameKo 사용자 노출 0).
- 6각 radar widget 보존 (라벨만 #5 fix 로 재작성 시 widget tree 동일).
- 십신 음양 10분류 보존.
- SajuContext + DynamicTextResolver chain 보존 (R78 4단계).
- 알림 hh:mm picker (R76) 보존.
- `/today` route 보존 (R79 sprint 7) + sprint 2 (#4 fix) 에서 result_screen 의 today_event mount 제거 → /today 단독.
- oneLine 60일주 wire (R80 sprint 2) + 폐기 5종 phrase 차단 보존.
- radar 색상 재설계 (R80 sprint 5) 보존.
- 조후용신 wire (R80 sprint 6) 보존.
- 신살 anchor (R80 sprint 4: 양인·괴강·백호·천을·문창) 보존.

### G6 — 신규 R82 회귀 test list

각 sprint generator 가 신규 test 추가 (sprint 끝 codex audit 입력):

| sprint | 신규 test 후보 |
|---|---|
| 2 | `test/round82_today_route_split_test.dart` — TodayEventDetailSection result_screen mount 0 회귀 가드 |
| 3 | `test/round82_oneline_jargon_test.dart` — 60 entry 한자 jargon blacklist + 폐기 5종 fallback grep |
| 4 | `test/round82_match_badge_label_test.dart` — `_MatchBadge` 라벨 문구 + R69 lock matchCount 보존 |
| 5 | `test/round82_palace_helper_label_test.dart` — 12 결 풀이 카드 1줄 설명 + 자미두수 별 이름 noLeak |
| 6 | `test/round82_animal_context_test.dart` — 한글 동물 단독 노출 영역 grep + context 1줄 wire |
| 7 | `test/round82_result_first_fold_test.dart` — 첫 fold widget cap + 접힘 상태 사전 검증 |
| 8 | `test/round82_deep_slice_tone_test.dart` — saju_deep_slice 30 entry tone audit blacklist |
| 9 | `test/round82_round_close_test.dart` — flutter analyze 0 + flutter test count + 5행 골든 + R69 lock 통합 |

### G7 — 회귀 발견 시 protocol

- 5행 골든 sample 일치 X → 즉시 sprint 중단, 사용자 보고. M4 mandate 위반.
- R69 lock 일치 X → 의도적 변경이면 lock 갱신 commit 분리 (sprint 9). 의도 X 면 sprint 중단.
- flutter test 1개라도 FAIL → 즉시 sprint 중단.
- 시크릿 leak grep hit (.p8 / .env / .jks / AuthKey_ / private_key / sk- / ghp_) → 즉시 stash + 사용자 보고.

---

## 8. Round 73~80 reference (R82 입력 컨텍스트)

본 R82 가 reference 하는 직전 R73~R80 핵심.

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

→ R82 = 1.0.0+39 (R79) 실기기 검증 후 사용자 발견 9 visible 문제 fix round. R80 + R82 fix 가 모이면 (사용자 mandate 후) 1.0.0+40 통합 빌드 후보.

---

## 9. 결론 + 진행 boundary

- 본 spec = R82 ground truth. Sprint 2 부터 generator subagent 가 각 sprint 의 해당 # (#1~#9) 정확히 구현.
- 매 sprint 끝 codex audit 9.9+ PASS 까지 generator 반복 (max 7 라운드, 매 라운드 다른 audit file).
- M2 mandate (자동 배포 X) 절대 — sprint 10 의 IPA 자동 제출은 사용자 명시 후만.
- 본 sprint 1 산출물 = `docs/round82_spec.md` 1개 markdown + (필요 시) 인수인계.md 의 "R82 진행 중" micro update.
- Flutter 코드 변경 0 / test 변경 0 / 시뮬 새 부팅 0 / 시크릿 leak 0.

### 영문 약어 disclaimer

본 문서의 영문 약어 (C1·C2·D1·D2·G1~G7·H1·M1~M5·#1~#9) 는 개발자 audit · planner · generator · evaluator 간 communication 용. 사용자 노출 UI 본문 (sprint 2~8 의 phrase pool / arb / widget label) 에는 영문 약어 0 노출. 사용자가 보는 모든 한국어 본문은 한국 MZ 중학생 K-POP 팬 친근 해요체 (M5 mandate) 만 사용.

---

> 본 문서 = `docs/round82_spec.md` v1. codex audit 9.9+ PASS 후 commit. R82 sprint 2 부터 본 spec 의 각 # 차례로 진행.
