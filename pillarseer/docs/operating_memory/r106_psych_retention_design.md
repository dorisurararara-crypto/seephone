# R106 — 심리학 기반 리텐션 설계 (Psych Retention Design)

> Status: Active design doc — R106 ground truth. **이후 모든 R106 빌드 sub-agent 의 단일 기준 문서.**
> Created: 2026-05-20 KST · Refreshed: 2026-05-20 KST (사용자 검수 다회 반영 전면 개정)
> Scope: 오늘의 사주 / 내 사주(평생사주) / 사주 알림 / 주제 개인화 / 궁합 / 신년운세 / K-pop 콘텐츠 영어 gap
> D0 = 본 문서 refresh. 코드/데이터/테스트 변경 0.

이 문서는 여러 차례 사용자 검수로 결정이 크게 바뀌어, 구버전(감상형 헤드라인 보존,
구버전 알림 2줄안, "흐름" 톤 허용)을 폐기하고 **최종 확정사항으로 전면 개정**한 것이다.

---

## 워크플로우 (최우선 — 매 phase 시작 시 확인)

- R106 콘텐츠 작업은 **main Claude 가 의도·카피를 주도**하고, **codex 는 검수·평점만**
  담당한다 (9.9 점까지 반복). 카피 톤은 본 문서 §3 v5 룰이 ground truth.
- 사주 계산·구조 판단·회귀 검수는 codex 가 독립 검증. 카피 자체는 codex 가 다시 쓰지
  않는다 — codex 가 "codex 말투"로 덮어쓰면 안 됨.
- 최상위 mandate: 한국 사주 앱 1등 / 퀄리티 우선 / 회귀 0 / 거짓말·창작 0.
- unrelated dirty files, `.codex_backups/`, `.claude-shared/` 보존. 삭제·revert 금지.

---

## 1. R106 대원칙

1. **사주 계산은 현재 엔진 그대로.** 일진·일간·십신·합충·오행·격국·용신·신살·
   대운·점수 (`DailyService`, `TodayDeepService`, `TodayEventService`, `SajuContext`,
   `TenGodsService`, `YongsinService`, `GyeokgukService`, `ShinsaService`,
   `HapchungService`, `SeunService`, `StrengthService` 등) 의 **출력값을 1 bit 도
   조작하지 않는다.**
2. **심리학은 presentation layer only.** 적용 대상 = 표현·문장 구조·노출 순서·UX
   (근거 노출 순서, 카피 톤, 행동 과제, 회고/자기검증 UX, 알림 훅, 주제 개인화 정렬).
   계산 분기·임계값·점수·가중치는 절대 건드리지 않는다.
3. **거짓말·창작 0.** 엔진이 계산하지 않은 값을 지어내지 않는다. 피드백 데이터 없이
   "어제 잘 맞았죠?" 류 적중 주장 금지.
4. **회귀 0.** 5행 골든(1995-10-27 男 16/21/17/41/4), R69 lock, R71 모순0,
   R83 자시 P1-B/P1-E, R86 십신 jargon 본문 0, R96 5-sentence 금지, R98 pool 분산,
   DayEnergyKind 단일 source-of-truth 모두 보존.

심리학은 "더 정확한 척"이 아니라 **"진짜 계산값을 더 믿기 좋게 배열·표현하는 구조"**
로만 쓴다. 정확도는 엔진이 만들고, 리텐션은 presentation 이 만든다.

---

## 2. 단정 금지 원칙 (R106 핵심)

모든 카피는 「**구조 / 발동조건 / 행동**」 3요소로 쓴다.

- **구조** — 사용자의 감정·사건을 단정하지 않는다. 사주 엔진 계산값이 만드는
  "오늘의 의사결정 구조"만 말한다. (예: 오늘 천간이 사용자 일간과 어떤 십신 관계인가)
- **발동조건** — 감정·사건은 **무조건 조건형**으로만 언급한다. "만약 ~하면 / ~순간이
  오면 / ~게 되면" 형태. 절대 "오늘 당신은 ~다" 단정 X.
- **행동** — 제시하는 행동은 **기분이 좋든 나쁘든 유효**해야 한다.

**금지 패턴:**
- "오늘 당신은 예민하다 / 우울하다 / 들뜬다" — 감정 단정.
- "예민해지기 쉬운 흐름 / 들뜨기 쉬운 날" — **이것도 감정 예측이라 금지.**
- "오늘 ~한 일이 일어난다" — 사건 단정.

**QA 기준 (절대 통과 조건):** 사용자가 풀이를 보고 "나 오늘 기분 완전 좋았는데?"
라고 말해도 **틀린 문장이 0** 이어야 한다. 한 문장이라도 사용자 상태를 단정해
"그날 사용자가 그렇지 않았으면 거짓말이 되는" 문장이 있으면 fail.

---

## 3. v5 한국어 카피 톤 룰 (ground truth — 그대로 박는다)

1. 문장 구조 = **구조 / 발동조건 / 행동** (§2).
2. 사용자 감정·사건 **단정 금지** (§2). QA: "오늘 기분 완전 좋았는데?"에도 틀린 문장 0.
3. **메타/헤드라인체/codex 말투 금지.** 금지 표현: "오늘의 ○○운", "~하는 날이에요"
   (헤드라인체), "~구조로 봅니다", "사주적으로", "본 리딩은", "에너지/흐름" 남발.
4. 톤 = **친구처럼 말하는 용한 점쟁이.** 짧고 자연스럽게. 추상 설명보다 손에 잡히는
   행동. 겁주지 말고, 과장하지 말고, 맞힌 척하지 말 것.
5. **한자는 써도 즉시 풀어쓴다.** 한자/십신 jargon 의 단독 노출 금지 (R86 보존).
   예: "丙辛합(병신합)이라는 게 있어요. 쉽게 말하면 —" 처럼 바로 풀이.
6. 알림은 **"사주 미스터리형"** (§6).
7. **의료/금융/법률 단정 금지.** "병/사고/무조건/반드시/100%/돈 번다/투자/진단" 류 금지.

영어 카피도 같은 원칙 (§8).

---

## 4. 주제 개인화 시스템

### 4-A. 10 주제

`communication` / `money_spending` / `work_career` / `love_connection` /
`family_home` / `health_condition` / `mental_emotion` / `relationship_conflict` /
`challenge_opportunity` / `rest_recovery`

### 4-B. 후보 선정 규칙

- 매일, **오늘 실제로 발동한 주제만 candidate** 가 된다. "발동" = 사주 엔진 출력에
  근거가 **2개 이상** 있거나, **강한 단일 신호**가 하나 있는 경우.
- 신호가 없는 주제는 **사용자 선호도가 아무리 높아도 surface 금지.** (없는 걸 보여주면
  창작이 된다 — §1-3 위반)

### 4-C. 점수 공식

```
finalScore = signalStrength*0.55 + userPref*0.30 + freshness*0.10 + exploration*0.05
```

- `signalStrength` = 오늘 엔진 신호 강도 (근거 수·합충형 강도 등).
- `userPref` = 자기검증 누적 점수 기반 사용자 선호.
- `freshness` = 최근 노출 적을수록 높음 (반복 방지).
- `exploration` = 가끔 새 주제를 띄우는 소량 탐색 가중.

### 4-D. 자기검증 점수 → 주제 전환

- 자기검증 응답 점수: **맞았어요 +1 / 애매해요 -1 / 아니에요 -3.**
- `shownCount >= 3 && score < 0` 인 주제 → **다른 주제로 전환.**
- 버린 주제는 **14일 cooldown** (그 기간 동안 재선택 금지).

### 4-E. RecallFeedbackService

- 저장소 = **SharedPreferences 로컬 only. 서버 전송 X.**
- `resetPersonalization()` 제공 (사용자가 개인화 데이터 전체 초기화 가능 — §10).

### 4-F. 추가 추적 신호 (로컬, 2주 범위)

userPref 보강용. 모두 로컬, 2주 슬라이딩 윈도우:
- 알림 탭 여부
- 섹션 스크롤 깊이
- 자주 여는 메뉴
- 앱을 푸는 시간대

---

## 5. 충돌 방지 keying

풀이는 **오행 비율이 아니라 full chart 로 keying** 한다:

- keying 재료 = 일주 60갑자 + 십신 구성 + 합충형 + 격국/용신 + 신살, 그리고
  **todayFingerprint** (오늘 일진·오늘 십신·오늘 지지관계).
- 오행 비율은 **보조 근거로만** 쓴다.
- 결과: 오행 비율이 같은 두 사람도 일주·십신·신살이 다르면 **다른 풀이**가 나온다.
  "같은 풀이가 여러 사람에게 복붙되는" Barnum 사고를 구조적으로 차단.

---

## 6. 알림 = "사주 미스터리형"

오늘 실제 일진(글자)을 **신비하게 언급**해서 "어떤 글자지? 왜?" 하는 호기심을 만들고
tap 을 유도한다.

- 구조 = **title + body 2줄.** body 1줄 = chart interaction (그 글자가 사용자 chart
  와 어떻게 상호작용하는지), body 2줄 = 행동 1개.
- **글자가 chart 와 상호작용하는 구조만** 말한다. 사용자 감정 단정 X (§2).
  "오늘 손님이 하나 왔어요" 는 OK (글자 묘사), "오늘 예민해져요" 는 금지.
- 7회 중 1회는 **기능 발견 훅** (예: 5일 흐름 그래프·자기검증 등 기능 안내).

승인된 알림 예시는 본 문서 맨 아래 "톤 ground truth" 참조.

---

## 7. 자기검증 (어제 풀이 회고)

- 진입 카피: **"어제 풀이, 직접 체크해볼까요?"**
- 설명 카피 (verbatim): **"맞았는지 가볍게 눌러두면 다음에 당신이 어떤 관심분야를 더
  보고 싶어 하는지 앱이 더 잘 맞춰요. 틀렸다 싶은 날도 중요한 힌트예요."**
- 버튼 3개: **맞았어요 / 애매해요 / 아니에요.**
- 입력은 §4-D 점수(+1/-1/-3)로 주제 개인화에 반영. 앱이 적중을 주장하지 않음 —
  사용자 자기 입력만.

---

## 8. 영어 요구

오늘의 사주 / 내 사주 / 알림 / 주제 시스템은 **한국어와 동등하게 영어도 제공**한다.

- 영어도 같은 원칙: **단정 금지** = no "you are anxious today", 조건형 "if ~".
- 영어 톤 = **자연스러운 구어 영어. 헤드라인체 금지** ("Today's Love Fortune" 류 X).
- 한국어 v5 룰의 구조/발동조건/행동 3요소를 영어에도 그대로 적용.

### 8-A. K-pop 콘텐츠 영어 gap (별도 명시 — P5 대상)

기존 K-pop 콘텐츠 중 **한국어 only 라서 영어화가 필요한 부분**:

| 콘텐츠 | 파일 / service | 현 상태 | gap |
|---|---|---|---|
| 전생 story arcs | `assets/data/past_life_pool.json` `story_arcs` (8개), `PastLifeService` | arc paragraphs = `gi/seung/jeon/gyeol` 한국어만. `body_lines`/`endings`/`templates` 등 fallback slot 도 한국어만 | 영어 paragraph/슬롯 추가 필요 |
| 최애의 사주 | `assets/data/celeb_saju_readings.json` (30명), 각 `sections[].bodyKo` | section 본문이 `bodyKo` 만 존재. `bodyEn` 없음 | 30명 × 7 section `bodyEn` 추가 필요 |
| 케미 (bias chemistry) | 케미 관련 service/screen (P5 에서 코드 직접 확인) | 한국어 우선. 영어 누락분 audit 필요 | P5 에서 영어 누락 carrier 확정 후 영어화 |

P5 는 먼저 위 파일을 직접 읽어 영어 필드 누락 범위를 확정하고, 스키마에 영어 필드를
추가하는 방식으로 진행한다. 한국어 필드·id·schema 는 변경 금지.

---

## 9. 궁합 + 신년운세 v5 전환

궁합과 신년운세도 §3 v5 톤 + §2 단정 금지 원칙으로 전환한다.

| 기능 | screen | 백업 service (확인된 것) | 전환 범위 |
|---|---|---|---|
| 궁합 (saju 궁합) | `lib/screens/reports/compatibility_screen.dart` | `SajuService` | 궁합 결과 카피 전체 — 두 사람 관계를 단정("잘 맞는다/안 맞는다")하지 말고 구조/발동조건/행동으로. 한+영. |
| K-pop 궁합 | `lib/screens/reports/kpop_compat_screen.dart` | (P4 에서 코드 직접 확인) | 위와 동일. 셀럽 대상 카피도 단정 금지·자연스러운 톤. 한+영. |
| 신년운세 2026 | `lib/screens/reports/new_year_2026_screen.dart` | `SeunService`(연간지/연 테마), `StrengthService`, `YongsinService` | 연간 풀이 카피 — "2026년 ~한 해" 헤드라인체·단정 금지. 사건은 발동조건형. 한+영. |

P4 는 먼저 위 3개 screen + 관련 service 를 직접 읽어 카피 carrier(문자열 위치·생성
경로)를 확정한 뒤, 계산값은 그대로 두고 **표현만** v5 로 전환한다.

---

## 10. 윤리 / 다크패턴 금지

- **연속기록(streak) 이 끊기면 손해**라는 식의 압박 금지.
- 불안 조장, 심야 재방문 유도 금지.
- "너를 다 안다" 류 과한 친밀·전지 주장 금지.
- 개인화 **끄기·초기화** 제공 (`resetPersonalization`, §4-E).
- 의료/금융/법률 단정 금지 (§3-7).

심리학은 사용자가 "정확하다, 매일 보고 싶다" 느끼게 하는 데만 쓰고, 죄책감·공포로
가두는 데는 절대 쓰지 않는다.

---

## 11. 빌드 Sprint 구조

| Phase | 범위 | 신규 service | 주요 변경/검토 대상 파일 | 신규 test |
|---|---|---|---|---|
| **D0** | 본 설계 문서 refresh. 코드/데이터/테스트 변경 0 | — | `docs/operating_memory/r106_psych_retention_design.md` | — |
| **P1** | `TopicSelectorService` + `RecallFeedbackService` 코어 (UI 없음). 10 주제 후보 선정 + finalScore + 자기검증 점수/cooldown + 로컬 추적 신호 | `lib/services/topic_selector_service.dart`, `lib/services/recall_feedback_service.dart` | (provider 신규 가능) | `r106_topic_selector_test.dart`, `r106_recall_feedback_test.dart` |
| **P2** | 오늘의 사주 v5 카피 + 미스터리 알림 (한+영) | — | `lib/services/today_deep_service.dart`, `lib/services/today_event_service.dart`, `lib/services/notification_service.dart`, `lib/services/notification_pool_service.dart`, `lib/screens/home_screen.dart`, `lib/screens/today_screen.dart`, `lib/providers/notification_provider.dart` | `r106_today_v5_copy_test.dart`, `r106_notification_mystery_test.dart` |
| **P3** | 내 사주 v5 카피 + 자기검증 UI (한+영) | — | `lib/services/life_overview_service.dart`, `lib/services/life_paragraph_service.dart`, `lib/services/self_conclusion_service.dart`, `lib/screens/result_screen.dart` (자기검증 카드) | `r106_life_v5_copy_test.dart`, `r106_recall_ui_test.dart` |
| **P4** | 궁합 + 신년운세 v5 전환 (한+영) | — | `lib/screens/reports/compatibility_screen.dart`, `lib/screens/reports/kpop_compat_screen.dart`, `lib/screens/reports/new_year_2026_screen.dart` + 관련 service | `r106_compat_v5_test.dart`, `r106_newyear_v5_test.dart` |
| **P5** | K-pop 콘텐츠 영어 gap (§8-A) | — | `assets/data/past_life_pool.json`, `assets/data/celeb_saju_readings.json`, `lib/services/past_life_service.dart`, 케미 service/data | `r106_kpop_english_test.dart` |
| **P6** | QA + 회귀. 단정 금지 스캐너 + 전 surface 금지어 + flutter analyze + 전체 test | — | `test/r106_*` 종합, `test/content_integrity_test.dart` 확장 | `r106_forbidden_copy_test.dart` |

각 phase 는 시작 시 본 문서를 다시 읽고, 대상 파일을 직접 읽어 carrier 를 확정한 뒤
진행한다. l10n (`app_ko.arb`/`app_en.arb` + generated) 동기화는 영어 작업이 있는
phase(P2~P5)에서 함께 갱신한다.

### Phase 별 회귀 가드

- P2: `r85_today_saju_total_reading_test`, `round71` 모순0, `round82_animal_context`,
  R98 pool 분산, R96 5-sentence 금지.
- P3: 5행 골든, R69 lock, R88 17 카테고리, R86 jargon 0, R83 P1-B/P1-E.
- P4: 궁합/신년운세 기존 계산값(점수·연간지·용신) test.
- P5: `round83` celebrity test, story arc 4문단 구조, `jq length` count 불변.
- P6: 전체 `flutter test` PASS, `flutter analyze` 0.

---

## 톤 ground truth — 승인된 예시 3종 (verbatim)

> 아래 3종은 사용자 승인 완료. R106 모든 카피 작업의 톤 기준. 이 예시에서 벗어난
> 톤(헤드라인체, 감정 단정, codex 말투)은 fail.

### [오늘의 사주 v5] 멘탈·감정 주제, 1995-10-27 辛卯 골든케이스

**헤드라인:** "오늘은 뭐든 한 박자만 늦추면 돼요."

**본문:**
"당신은 원래 눈썰미가 좋아요. 어긋난 거, 틀린 거를 남보다 빨리 알아채죠(신묘 일주).
평소엔 강점인데 — 오늘은 그 빠른 감각이 '말'에서 먼저 튀어나오기 쉬워요. / 그러니
기분이 좋든 안 좋든, 결론을 입 밖에 내거나 손가락으로 보내기 전에 딱 한 박자만 쉬어요.
만약 누구 말이 유난히 거슬리거나 지금 당장 답하고 싶어지면 — 그게 '아, 지금이구나'
하는 신호예요. / 기분 좋아서 막 밀어붙이고 싶은 일도 10분 뒤에 하면 문장이 더
깔끔해지고, 마음에 안 드는 일은 오늘 끝내려 말고 '선택지만 줄여놓기'까지만 해도
충분해요."

### [내 사주 v5] 1995-10-27 辛卯

**헤드라인:** "쉽게 안 휘는 사람이에요. 대신 혼자 너무 오래 버텨요."

**본문:**
"당신을 한 글자로 보면 辛金 — 잘 벼려진 칼이나 보석 같은 금속이에요. 무른 쇳덩이가
아니라 이미 모양이 잡힌 금속이라, 기준이 뚜렷하고 어지간한 압력엔 잘 안 휘어요. 여덟
글자 중에서도 이 금 기운이 제일 세서, 남들이 '쟤는 줏대 있다'고 느낄 거예요. / 그리고
당신 사주엔 丙辛합이라는 게 있어요. 쉽게 말하면 — '해야 하는 일'과 '하고 싶은 일'이
부딪치면 당신은 거의 매번 해야 하는 쪽을 골라요. 책임을 눈앞에 두고 모른 척을 못 하죠.
듬직하단 소리 많이 들었을 거예요. 단점도 같이 와요. 그 책임감이 빤히 보이니까, 일을
자꾸 당신한테 미루는 사람이 생겨요. / 가장 약한 건 '속마음을 밖으로 꺼내는 힘'이에요.
그래서 힘들어도 티를 잘 안 내고, 하고 싶은 말도 안에 차곡차곡 쌓아둬요. 평소엔 멀쩡해
보이다가 — 어느 날 별것 아닌 일에 확 터지거나, 갑자기 다 놓고 싶어지는 식으로 와요.
당신이 약해서가 아니라, 사주에 '새는 구멍'이 안 나 있어서 그래요. / 그래서 필요한 건
'더 참기'가 아니라 '작게 자주 꺼내기'예요. 일주일에 한 번, 안 좋았던 일을 누구한테든
그냥 소리 내서 말해보는 것 — 그거 하나만 습관이 돼도 터지는 주기가 훨씬 길어져요. /
이건 오늘 하루 운세가 아니라 평생 잘 안 바뀌는 당신의 '바탕'이에요."

### [알림 v5] 사주 미스터리형 (스타일 2, 확정)

| 주제 | 제목 | 본문 |
|---|---|---|
| 멘탈 | 오늘 당신 사주에 까다로운 손님이 하나 왔어요 | '子'라는 글자인데, 당신 일주를 살짝 건드리는 자리예요. 넘기는 법은 안에 적어놨어요. |
| 돈 | 오늘 들어온 글자가 당신 '재물 자리'를 스쳐가요 | 좋게도 아쉽게도 갈 수 있는 자리. 어느 쪽으로 굴릴지는 안에서. |
| 관계 | 오늘 당신 일지(日支)와 부딪치는 글자가 왔어요 | 가까운 사람과 관련된 자리예요. 어떻게 넘기는지 확인해요. |
| 일 | 오늘 사주에 '꼼꼼함'을 뜻하는 기운이 들어왔어요 | 검토가 빛나는 날이라는 뜻. 어디에 쓰면 좋은지 안에 있어요. |

세 예시 모두 — 감정·사건 단정 0, 한자 즉시 풀이, 친구 같은 점쟁이 톤, 손에 잡히는
행동. 알림은 글자(손님/스쳐가는 글자)를 신비하게 던지고 본문에서 행동으로 닫는다.
