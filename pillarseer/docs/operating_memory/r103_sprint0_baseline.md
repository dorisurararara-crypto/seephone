# R103 Sprint 0 — User-Reported 4 Mandate 진단 (read-only baseline)

> 본 문서는 **수정 없이** 작성된 baseline. 사용자 verbatim 4 mandate + 코드/데이터 ground truth.
>
> 사용자 verbatim (1.0.0+63 실기기 검증 후):
> "전생에 악연 또는 인연 내용이 다 똑같네 몇개 반복한거 같은데 소설 내용도 별로야 처음에 예시로 줬던 느낌으로 해야돼 좀 더 길어야 되고 그리고 이 메뉴도 역시 스크롤이 이상하게 돼, 그리고 처음 사주입력할때 태어난 날짜치면 자동으로 시간으로 넘어가는데 시간치면 자동으로 태어난 지역으로 안넘어가 태어난지역 끝났으면 키보드가 닫혀야하고 사진 1,2 처럼 디지털 처방전 메뉴에는 없는 곡들이 너무 많아 이거 제대로 검증해서 올려야지"
>
> OCR suspect 곡:
> - 파리타 (베이비몬스터) — "두 라이크 댓"
> - 재이 (스테이씨) — "샵 아저씨"

---

## 0. 빌드 / commit 상태

| 항목 | 값 |
|---|---|
| 현재 빌드 | 1.0.0+63 ASC VALID + ganzitester 외부 베타 자동 제출 완료 |
| 마지막 commit | `7755bf2` — R102 전생 자연화 + 음악 처방 데이터 정합성 |
| pubspec version | `1.0.0+63` |
| dirty files | 3 untracked (모두 R102 무관 — 보존):<br>- `scripts/asc_check_prerelease.rb`<br>- `scripts/check_b62.rb`<br>- `scripts/expire_b61_and_v110.rb`<br>+ 본 baseline (신규) |

---

## 1. Files inspected

read-only 로 확인한 파일 (절대경로):

- `/Users/seunghyeon/seephone/pillarseer/new인수인계.md`
- `/Users/seunghyeon/seephone/pillarseer/docs/operating_memory/r102_sprint1_baseline.md`
- `/Users/seunghyeon/seephone/.claude-shared/memory/project_pillarseer_round_102.md`
- `/Users/seunghyeon/seephone/pillarseer/lib/services/past_life_service.dart` (763 lines)
- `/Users/seunghyeon/seephone/pillarseer/lib/services/music_pharmacy_service.dart` (493 lines)
- `/Users/seunghyeon/seephone/pillarseer/lib/screens/reports/past_life_screen.dart` (757 lines)
- `/Users/seunghyeon/seephone/pillarseer/lib/screens/input_screen.dart` (1391 lines)
- `/Users/seunghyeon/seephone/pillarseer/assets/data/past_life_pool.json` (647 lines)
- `/Users/seunghyeon/seephone/pillarseer/assets/data/celeb_songs.json` (1658 lines / 207 keys)
- `/Users/seunghyeon/seephone/pillarseer/assets/data/celebrities.json` (2678 lines / 223 entries)

핵심 카운트:
- `celebrities.json` entries = **223** (idol 203 / actor 17 / athlete 2 / icon 1)
- `celeb_songs.json` keys = **207** (R102 sprint 4 에서 16 drop 후)
- `past_life_pool.json` body_lines = 8 keyword × 4 phase × 12 variant = **384 raw lines**
- 5행 distribution (songs 있는 셀럽만): wood 56 / fire 35 / earth 37 / metal 41 / water 38

---

## 2. Mandate #1 — 전생 본문 "다 똑같다" repetition 진단

### 2-1. 50 sample fingerprint 측정

10 셀럽 × 5 seed × keyword rotation = 50 시나리오 generator 시뮬 결과:

| metric | 결과 | 해석 |
|---|---|---|
| First sentence unique | **44 / 50** (88%) | 5 duplicate group (셀럽명만 다른 동일 header) |
| First-3 sentence fingerprint unique | **50 / 50** (100%) | sentence pick 자체는 다양 |
| Full body fingerprint unique | **50 / 50** (100%) | 완전 동일 본문은 0 |
| Header pattern repeat | 5 case x2~x3 dup | 헤더 한 줄은 동일 시대 hit 시 완전 동일 |

→ **수치상 unique 100%** 인데 사용자는 "다 똑같다" 체감. 이유는 **structural repetition** (phrase-level / 구조 동일).

### 2-2. Structural repetition hotspot (사용자 체감 직접 원인)

50 sample 본문 phrase 빈도 (8 sentences × 50 stories = 400 sentences):

| pattern | 빈도 / 400 | 사용자 체감 |
|---|---|---|
| `"사주상"` | **45** | 거의 모든 tail/event 첫 단어 "사주상 X결이..." 동일 시작 |
| `"이번 생"` | **77** | 결말 cluster 의 거의 모든 문장에 등장 |
| `"그 옛"` | **57** | ending + resolution 의 starter 어구 압도적 빈도 |
| `"두 사람은"` | **17** | R102 cap 2 적용 후에도 절대값 17 (8 키워드 setup 풀의 hard-coded) |
| `"결이 두 사람 사이에"` | **9** | tail 의 2/3 가 이 구조 ("X결이 두 사람 사이에 (옅게/부드럽게) 남아 있어요") |
| `"콘서트 / 앨범"` | 11 + 6 | resolution 의 "굿즈/앨범/콘서트" cluster — 모든 keyword 의 resolution 마지막에 등장 |

### 2-3. Algorithm-level repetition spot (`past_life_service.dart`)

`_composeFromPool` (L344-591) 합성 순서가 **항상 동일 8 sentence 슬롯**:

```dart
final sentences = <String>[
  headerSentence,    // L552 — "X와 Y는 [시대]에서 처음 마주쳤어요." 형 고정
  inject(intro),     // L399 — tpl['intros'] (3 variant per keyword)
  inject(setup),     // L401 — body['setup'] (12 variant per keyword)
  inject(event),     // L402 — body['event'] (12 variant per keyword)
  inject(turn),      // L403 — body['turn'] (12 variant per keyword)
  inject(resolution),// L404 — body['resolution'] (12 variant per keyword)
  inject(ending),    // L398 — endings (12 global variant)
  inject(tail),      // L400 — tpl['tails'] (3 variant per keyword)
];
```

| 슬롯 | variant count | 사용자 체감 위험도 |
|---|---|---|
| header | **시대 12 × 이름 매칭 = 12 base** | 같은 셀럽 reroll 시 12 진입 → 사용자가 reroll 4번 하면 같은 header hit 확률 30%+ |
| intro | **3 per keyword** | 같은 keyword 4 reroll = 같은 intro 100% repeat |
| tail | **3 per keyword** | 같은 keyword 4 reroll = 같은 tail 100% repeat |
| setup/event/turn/resolution | 12 per keyword | 4 reroll 안엔 unique 가능 |
| ending | 12 global | 4 reroll 안엔 unique 가능 |

→ **P0 root cause**: tpl["intros"] / tpl["tails"] 가 keyword 별 3 variant **밖에 안 됨**. 사용자가 같은 셀럽으로 4번 reroll 하면 intro + tail = 동일 페어 hit 거의 보장. + 같은 keyword 의 다른 셀럽 픽 시도 같은 페어 hit 가능. 이게 "다 똑같다" 체감의 hard cause.

→ **P0 두번째 root cause**: header 문장이 hard-coded format (`"$user{과/와} $celeb{은/는} $era에서 처음 마주쳤어요."`) — variation 0. 같은 시대 hit 시 header 완전 동일.

→ **P0 세번째 root cause**: resolution 의 "굿즈/앨범/콘서트/알고리즘" cluster 가 모든 keyword 의 resolution 12 variant **전부** 동일 motif 반복. 사용자가 본 5 sample 전부 "팬 활동 굿즈/앨범 청구" 류 결말. 자체는 유머 톤이나 5번째 보면 비슷한 농담.

### 2-4. 본문 "소설 내용도 별로야 / 좀 더 길어야 돼" — 사용자 verbatim 예시 톤과 비교

**사용자 verbatim 예시** (R101 mandate 원본):
> "1800년대 프랑스에서 몰락한 귀족이었던 당신과 당신을 감시하던 스파이였던 솔라가 만났습니다. 사주상 원진살 — 이번 생에서도 솔라에게 돈 뺏기지만 행복할 운명."

**현 generator 결과 (story 1, 김채원 wonjin seed=1)**:
> "승현과 김채원은 1920년대 경성의 다방 골목에서 처음 마주쳤어요. 둘은 같은 골목에 있었지만 한 박자씩 어긋났어요. 승현의 자리는 왕실 의원의 조수, 김채원의 자리는 병문안을 자주 오던 손님 — 절대 가까워질 일 없는 두 자리였어요. 사주상 '원진살'이 단단히 묶여 있어서, 두 사람은 서로 피하려 할수록 더 자주 부딪쳤어요. 그 다툼은 풀리지 않은 매듭으로 남아 사주의 결로 굳어졌어요. 그 옛 결이 이번 생엔 '나 이 정도면 손절각 아냐?' 라는 말과 함께 새 앨범을 결제하는 모순으로 변했어요. 그래서 이번 생에는 그 미안함을 다정함으로 갚아 가는 중이에요. 사주상 원진살의 여운이 이번 생까지 따라왔어요. 김채원 때문에 마음이 자주 흔들리지만, 그 흔들림 자체가 승현의 행복일지도 몰라요."

비교:
- 사용자 예시: **소설 구체 디테일** (몰락한 귀족 — 신분/사회 배경 명확) + **사건성** (감시하던 스파이 — 갈등 driver) + **유머 결론** (돈 뺏기지만 행복)
- 현 결과: **추상 setup** ("자리는 X, 자리는 Y") + **추상 갈등** ("한 박자씩 어긋났어요") + 유머 결론은 OK
- 사용자 예시 = **5~6 문장 안에 영상 한 편**
- 현 결과 = **8 문장인데 사건이 약함** + 마지막 3 문장 (resolution + ending + tail) 이 톤이 비슷해서 마무리 cluster 가 늘어진 느낌

→ "더 길어야 돼" 의 진의는 **분량이 부족** 이 아니라 **사건이 부족** (8 문장이지만 사건 묘사는 setup + event 만, turn 은 항상 "헤어졌어요" 류 closure). Sprint 1 generator 손볼 때 **12~16 문장 expand** 가 아니라 **사건 strand 2~3 줄 추가** 가 정답일 가능성 높음.

### 2-5. Sprint 1 fix 우선순위 (전생 generator)

| 우선순위 | 대상 | 작업 | 위험 |
|---|---|---|---|
| P0 | `past_life_pool.json` templates[k].intros / tails | 3 → 8 variant 로 확장 (× 8 키워드) | 양 늘리면 sentence quality 검수 부담 |
| P0 | `past_life_pool.json` header sentence | hard-coded → templates[k].headers 5+ variant 풀로 빼고 `_composeFromPool` 가 rng 선택 | header header 자체 변종 검수 필요 |
| P0 | `past_life_pool.json` body_lines resolution | "굿즈/앨범/콘서트" motif 외 다른 cluster 추가 (꿈, 일상, 알람, SNS, 라이브 etc) — 8 키워드 × 6+ alt motif | 톤 mandate "팬 활동" 유지하면서 motif 확대 어려움 |
| P1 | `past_life_service.dart` `_composeFromPool` 합성 순서 | 사건 strand 2~3 줄 추가 (event sub-A, event sub-B), 또는 turn variant 를 2개 픽 | 8 → 10+ sentence 분량 |
| P1 | `past_life_service.dart` `_capRepetition` | "사주상" / "이번 생" / "그 옛" 도 cap 대상 추가 | cap 강하면 본문 의미 손상 |
| P2 | `past_life_pool.json` relations | 24 → 40+ 확장 (사용자 예시 의 "몰락한 귀족 + 스파이" 같은 구체 디테일 강한 페어) | 양 증가만으로는 본질 못 풀음 |

---

## 3. Mandate #2 — 전생 화면 "스크롤이 이상하게 돼" 진단

### 3-1. `past_life_screen.dart` widget tree

```dart
Scaffold (L134)
└── body: SafeArea (L157, top: false)
    └── ListView (L178)              ◀── parent scroll
        ├── _Hero                    (L181)
        ├── _NameField               (L182)
        ├── _SearchBar               (L183)
        ├── _StarPickerList          (L187)
        │   └── Container (height: 260, fixed)  ◀── L411-419
        │       └── ListView.separated         ◀── NESTED scroll inside parent ListView
        ├── (if _composing) CircularProgressIndicator
        ├── (else) _ResultCard       (L211)
        │   └── Padding → RepaintBoundary
        │       └── Container        ◀── decoration paper
        │           └── Column (cross-axis stretch)
        │               ├── Text — `전생 · 緣`
        │               ├── Text — scenario.headlineKo
        │               ├── Wrap — keyword chips
        │               ├── Text — scenario.scenarioKo  (full body)
        │               └── OutlinedButton — `다시 뽑기`
        └── SizedBox(height: 28)
```

### 3-2. 스크롤 broken 원인 — 정확한 line

**원인 1 (P0)** — `_StarPickerList` (L386-481):

```dart
return Container(
  height: 260,                   // L412 — 부모 ListView 안에서 자식 ListView 가 fixed height
  decoration: ...,
  child: ListView.separated(     // L420 — nested ListView!
    padding: EdgeInsets.zero,
    itemCount: stars.length,     // ~207
    ...
  ),
);
```

문제:
- 부모가 ListView (L178), 자식이 또 ListView (L420) — nested vertical scroll
- 자식의 `height: 260` 만으로는 gesture 가 부모와 자식 사이에서 hit-test fight
- 사용자가 셀럽 picker 영역에서 시작한 드래그가 picker 안에서 소비 → 외부 본문 스크롤 안 됨
- 반대로 picker 가장자리에서 드래그 시작하면 부모가 잡아 picker 가 안 움직임

**원인 2 (P0)** — `_ResultCard` 가 본문 영역 (L211-217):

`_ResultCard` 안의 본문 텍스트 (`scenario.scenarioKo`, L560-568) 가 8 문장이라 화면 1 fold 를 가뿐히 넘어감. 부모 `ListView` 의 자식으로 들어가 있어 본문은 잘 보이지만, **결과 카드 영역에서 본문을 읽으려고 천천히 드래그하면 다시 picker 영역으로 돌아가야 함**. 사용자가 "스크롤이 이상하게 돼" 라고 한 건 이 nested scroll + fixed-height picker 가 한 화면 안에 공존하는 것 자체의 ergonomic 문제.

**원인 3 (P1)** — `_NameField` + `_SearchBar` + `_StarPickerList` 가 모두 화면 상단에 stack 되어 있어, 결과 카드 보려고 picker 영역 통과 시 picker 가 매번 gesture 빼앗음.

### 3-3. Sprint 2 fix 방향

| 우선순위 | 변경 | 효과 |
|---|---|---|
| P0 | `ListView.separated` → `Column` + `for (final s in stars)` (직접 widget list) 로 교체 — picker 의 nested scroll 제거 | 부모 ListView 만 단일 scroll. 모든 picker entries 가 부모 scroll 안에서 흐름 |
| P0 alt | 또는 `_StarPickerList` 의 `Container(height: 260)` 제거 + `physics: NeverScrollableScrollPhysics()` + `shrinkWrap: true` | nested ListView 가 fixed height 없이 부모 ListView 안에서 본문처럼 동작 |
| P1 | 결과 카드 (`_ResultCard`) 가 mount 되면 picker 영역을 collapsible / 접기 옵션 | 결과 카드 보는 동안 picker 가 화면을 안 차지 |
| P2 | `RepaintBoundary` 가 결과 카드만 감쌈 (L501) — 공유 기능 대비 — 이건 유지 OK | (변경 X) |

→ **권장**: P0 alt 가 적은 코드 변경으로 가능. `shrinkWrap: true` + `NeverScrollableScrollPhysics()` 조합.

---

## 4. Mandate #3 — 사주 입력 focus chain "시간 → 지역 자동 이동 안 됨 + 키보드 안 닫힘"

### 4-1. 현 wire 현황 (`input_screen.dart`)

| 필드 | 컨트롤러 | FocusNode | maxLen | onLengthReached | textInputAction | 키보드 dismiss |
|---|---|---|---|---|---|---|
| 이름 | `_nameController` | `_nameFocus` | — | (TextFormField) | `next` (L264) | 자동 |
| YYYY | `_yearCtl` | `_yearFocus` | 4 | `_monthFocus.requestFocus()` (L279) | `next` (L896) | 자동 |
| MM | `_monthCtl` | `_monthFocus` | 2 | `_dayFocus.requestFocus()` (L291) | `next` | 자동 |
| DD | `_dayCtl` | `_dayFocus` | 2 | `if (!_unknownTime) _timeFocus.requestFocus()` (L303-305) | `next` | 자동 |
| HHMM | `_timeCtl` | `_timeFocus` | 4 | **`null`** (L331) | `next` (L896) | **수동/실패** |
| city | `_cityController` | **없음** | — | (TextFormField) | **없음** (L394-411) | **닫히지 않음** |

### 4-2. Broken locations — 정확 line

**Bug 1 (P0)** — `input_screen.dart` **L331**: time field 의 `onLengthReached: null`

```dart
_NumberField(
  controller: _timeCtl,
  focusNode: _timeFocus,
  hint: 'HHMM (예: 0830)',
  maxLen: 4,
  enabled: !_unknownTime,
  onChanged: (_) => _recomputeTime(),
  onLengthReached: null,            // ◀── P0 BUG: 사용자 mandate verbatim 그대로 직발
),
```

→ DD 는 `onLengthReached: () => _timeFocus.requestFocus()` 로 wire 되어 있는데, HHMM 은 null. HHMM 4자 도달 시 city field 로 자동 이동 wiring 누락.

**Bug 2 (P0)** — `input_screen.dart` **L394-411**: city TextFormField 가 FocusNode 없음 + `textInputAction` 없음 + `onSubmitted` 없음 + `onEditingComplete` 없음

```dart
TextFormField(
  controller: _cityController,
  // ⚠ FocusNode 없음
  // ⚠ textInputAction 없음 → keyboard return 키가 'next' 또는 'done' 명시 X
  style: GoogleFonts.notoSerifKr(...),
  cursorColor: AppColors.ink,
  decoration: _underlineDeco(hint: l.inputBirthCityHelper),
  onChanged: (v) { ... },
  // ⚠ onSubmitted / onEditingComplete 없음 → 사용자가 키보드 return 눌러도 dismiss X
),
```

→ 사용자가 city 입력 끝내고도 키보드가 떠 있는 root cause.

**Bug 3 (P1)** — `_CitySuggestionBar.onPick` (L423-431) 안에는 `FocusManager.instance.primaryFocus?.unfocus();` 가 있음 (L430). 즉, **chip tap** 으로 도시 고르면 키보드 닫힘. 사용자가 chip tap 없이 자유 텍스트 입력 후 키보드 닫고 싶을 때 (즉, autocomplete miss 케이스) dismiss 경로 없음.

### 4-3. Sprint 3 fix

| 우선순위 | 변경 | 위치 |
|---|---|---|
| P0 | time field 의 `onLengthReached: () => _cityFocus.requestFocus()` 로 변경 | L331 |
| P0 | `_cityFocus = FocusNode()` 추가 + `_cityController` 와 함께 dispose | L25-27 + L60-72 |
| P0 | city TextFormField 에 `focusNode: _cityFocus` + `textInputAction: TextInputAction.done` + `onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus()` 또는 `onEditingComplete: () => _cityFocus.unfocus()` | L394-411 |
| P1 | `_unknownTime == true` 시 DD onLengthReached 가 city 로 직접 이동 | L303-305 |

→ 사용자 mandate verbatim "시간치면 자동으로 태어난 지역으로 안넘어가 태어난지역 끝났으면 키보드가 닫혀야하고" 정확히 두 점 모두 위 fix 로 해결.

---

## 5. Mandate #4 — "없는 곡들이 너무 많아 / 제대로 검증해서 올려야지"

### 5-1. celeb_songs.json schema + 분포

- 파일: `/Users/seunghyeon/seephone/pillarseer/assets/data/celeb_songs.json`
- keys: **207** (R102 sprint 4 에서 16 drop 후)
- value schema: `Array<{ titleKo, artistKo, element, moodKo }>` (entry 평균 1곡)
- 5행 분포 (songs 있는 셀럽만): wood 56 / fire 35 / earth 37 / metal 41 / water 38
- 영문 leak 없음 (R102 KO 가드 통과)

### 5-2. OCR 두 사례 — 정확 위치 확인

| OCR 사용자 사진 | celeb id | nameKo | titleKo | artistKo | 의심 reason |
|---|---|---|---|---|---|
| 사진 1 | `pharita_bm` | 파리타 (베이비몬스터) | 두 라이크 댓 | 베이비몬스터 | "Do Like That" 한글 transliteration 추정. 베이비몬스터 데뷔곡은 BATTER UP / SHEESH / FOREVER. "두 라이크 댓" = **베이비몬스터 곡 아님 (미검증)** |
| 사진 2 | `j_stayc` | 재이 (스테이씨) | 샵 아저씨 | 스테이씨 | "샵 아저씨" 의미 불명. 스테이씨 정식 곡 (ASAP, SO BAD, RUN2U, BUBBLE) 아님. **존재 안 함 (미검증)** |

→ 사용자 OCR 두 사례 모두 **곡명이 실제 곡 아님 (의미 불명 transliteration 또는 fake)** — 위치는 본 baseline 의 §5-3 table 의 P0 그룹 (transliteration nonsense) 에 정확히 매핑.

### 5-3. 의심 entries 분류 + Top 30 priority

**heuristic** (Python audit script):
- (a) drama title 차용 (`나의 아저씨` `선재 업고 튀어` `더 글로리` `오징어 게임` `K2` `도깨비` `슬기로운` `시그널` 등)
- (b) English transliteration 의심 (`라이크` `댓` `디스` `미 라이크` `두 라이크` `쇼 미` `브레이크` `핫 핫` `러브 ` `오 마이` `아이 ` `굿 ` `샵` `아저씨` ...)
- (c) artist == 그룹명 + 멤버 솔로곡 척 (그룹곡 misattribution)
- (d) tribute / 응원곡 / Unknown / placeholder (R102 에서 dropped — re-occurrence 가드)

**flagged 총 160 entries**. priority 분류:

| priority | 정의 | 카운트 (예상) | Sprint 4 action |
|---|---|---|---|
| **P0** | (a) drama title 차용 또는 의미불명 transliteration 단어 단독 ("샵 아저씨" 류) — **존재하지 않는 곡** | ~12~15 | drop or replace with verified song |
| **P1** | (b) "X 라이크 Y" 류 한글 transliteration — 실곡 가능성 있으나 미검증 | ~25~30 | web audit per entry. 실제 곡이면 표기 자연화 (ex "두 라이크 댓" → 영문 곡명 → 한글 곡명 mapping 검수). 가짜이면 drop. |
| **P2** | (c) 그룹곡 misattribution (멤버 nameKo + artist=그룹명) — K-POP 통상이라 R102 까지는 retain 정책 | ~80~100 | 솔로곡 우선 정책 채택 시 멤버별 본인 활동곡 fetch / 솔로 없음이면 그룹곡 retain (label "그룹곡") |
| **P3** | (a/b) 매우 경계 (translit + group 둘 다) | ~20 | P1+P2 통합 처리 |

**Top 30 (highest user-facing risk)** — Sprint 4 에서 즉시 처리:

| # | celeb id | nameKo | titleKo | artistKo | priority | reason | action |
|---|---|---|---|---|---|---|---|
| 1 | `pharita_bm` | 파리타 (베이비몬스터) | 두 라이크 댓 | 베이비몬스터 | **P0** | 사용자 OCR 직발 + 베이비몬스터 곡 카탈로그 미확인 | drop/replace |
| 2 | `j_stayc` | 재이 (스테이씨) | 샵 아저씨 | 스테이씨 | **P0** | 사용자 OCR 직발 + 의미 불명 | drop/replace |
| 3 | `wonyoung_ive` | 장원영 (아이브) | 애프터 라이크 | 아이브 | **P1** | "After LIKE" 그룹곡 한글 표기. 솔로 X | retain (그룹곡 label) or replace 본인 활동곡 |
| 4 | `jimin` | 지민 (방탄소년단) | 라이크 크레이지 | 지민 | **P1** | "Like Crazy" 지민 솔로 실곡 OK — **표기만 검증 필요** | 표기 OK 가능. 검증 후 retain |
| 5 | `haewon_nmixx` | 해원 (엔믹스) | 러브 미 라이크 디스 | 엔믹스 | **P1** | "Love Me Like This" 그룹곡 한글 표기 | retain (그룹곡 label) |
| 6 | `kyujin_nmixx` | 규진 (엔믹스) | 러브 미 라이크 디스 | 엔믹스 | **P1** | 위와 동일 | 위와 동일 |
| 7 | `wendy_rv` | 웬디 (레드벨벳) | 라이크 워터 | 레드벨벳 | **P1** | "Like Water" 웬디 솔로 실곡 (artist 오류 — 그룹명으로 표기) | artist 를 "웬디" 로 수정 |
| 8 | `karina` | 카리나 (에스파) | 드라마 | 에스파 | **P1** | "Drama" 그룹곡 한글 표기 + drama 단어 자체 confusing | retain (그룹곡 label) — drama 단어는 단순 transliteration |
| 9 | `yujin_ive` | 안유진 (아이브) | 아이 엠 | 아이브 | **P1** | "I AM" 그룹곡. translit "아이 엠" | retain (그룹곡 label) |
| 10 | `gaeul_ive` | 가을 (아이브) | 러브 다이브 | 아이브 | **P1** | "LOVE DIVE" 그룹곡 | retain (그룹곡 label) |
| 11 | `vernon_svt` | 버논 (세븐틴) | 러브 콜 | 세븐틴 | **P1** | "Love Call" 의심 — 세븐틴 정식 곡 카탈로그 미확인 | verify; 가짜이면 drop |
| 12 | `taehyun_txt` | 태현 (투바투) | 러브 송 | 투바투 | **P1** | "Love Song" — TXT 정식 곡 카탈로그 미확인 | verify; 가짜이면 drop |
| 13 | `huening_txt` | 휴닝카이 (투바투) | 아이 노 아이 러브 유 | 투바투 | **P1** | "I Know I Love You" — TXT 정식 곡 미확인 | verify |
| 14 | `sullyoon_nmixx` | 설윤 (엔믹스) | 씨 댓 | 엔믹스 | **P1** | "See That" — NMIXX 정식 곡 미확인 | verify |
| 15 | `jeonghan_svt` | 정한 (세븐틴) | 러브 스리 러브 | 세븐틴 | **P1** | "Love 3 Love" 카탈로그 미확인 | verify |
| 16 | `shuhua_idle` | 슈화 ((여자)아이들) | 러브 콜 | 아이들 | **P1** | (여자)아이들 정식 곡 미확인 | verify |
| 17 | `kim_gyuvin_zb1` | 김규빈 (제로베이스원) | 러브 송 | 제로베이스원 | **P1** | ZB1 정식 곡 미확인 | verify |
| 18 | `park_gunwook_zb1` | 박건욱 (제로베이스원) | 러브 인 더 무드 | 제로베이스원 | **P1** | "Love in the Mood" 카탈로그 미확인 | verify |
| 19 | `leehan_bnd` | 이한 (보이넥스트도어) | 이프 아이 세이, 아이 러브 유 | 보이넥스트도어 | **P1** | "If I Say, I Love You" 카탈로그 미확인 | verify |
| 20 | `woonhak_bnd` | 운학 (보이넥스트도어) | 러브 송 | 보이넥스트도어 | **P1** | BND 정식 곡 미확인 | verify |
| 21 | `shinyu_tws` | 신유 (투어스) | 오 마이 갓 | 투어스 | **P1** | TWS 정식 곡 미확인 (Oh Mz! Plot Twist 등 실곡 존재) | verify; 표기 수정 |
| 22 | `youngjae_tws` | 영재 (투어스) | 이프 아이 머스트 | 투어스 | **P1** | TWS 정식 곡 미확인 | verify |
| 23 | `hanjin_tws` | 한진 (투어스) | 오 마이 갓 | 투어스 | **P1** | 위와 동일 | 위와 동일 |
| 24 | `jihoon_tws` | 지훈 (투어스) | 오 마이 갓 | 투어스 | **P1** | 위와 동일 — 멤버 4명이 같은 곡 (그룹곡 misattribution 정상) | retain or replace |
| 25 | `renjun_nct` | 런쥔 (NCT DREAM) | 브로큰 멜로디스 | 엔시티 드림 | **P1** | "Broken Melodies" NCT DREAM 실곡 | retain (그룹곡 label) |
| 26 | `jaemin_nct` | 재민 (NCT DREAM) | 러브 잼 | 엔시티 드림 | **P1** | "Love Jam" NCT DREAM 카탈로그 미확인 | verify |
| 27 | `daniela_katseye` | 다니엘라 (캣츠아이) | 부 아이 러브 유 | 캣츠아이 | **P1** | "Boo I Love You" KATSEYE 카탈로그 미확인 | verify |
| 28 | `yeri_rv` | 예리 (레드벨벳) | 러브 미 두 | 레드벨벳 | **P1** | "Love Me Do" 카탈로그 미확인 | verify |
| 29 | `asahi_trsr` | 아사히 (트레저) | 러브 송 | 트레저 | **P1** | TREASURE 정식 곡 미확인 | verify |
| 30 | `liz_ive` | 리즈 (아이브) | 일레븐 | 아이브 | **P2** | "ELEVEN" 그룹곡 (실곡 OK) | retain (그룹곡 label) |

→ **Sprint 4 audit 작업 estimate**:
- web audit per entry: ~30s ~ 2min/entry (artist 카탈로그 검색 + 한글 표기 표준화)
- 30 P0+P1 entries × 1.5 min avg = **~45 min**
- 80 P2 (그룹곡) entries — retain 정책이면 0min, 솔로곡 fetch 정책이면 80 × 2min = **~2h 40min**
- token: 각 entry 검색당 ~2k token × 30 = ~60k token (P0+P1 only)
- source: K-POP wiki / Genie / Bugs / Melon / artist 공식 디스코그래피
- 누적 estimate: **P0+P1 fix only = 약 1시간 작업**, **P2 본인 솔로곡 우선 정책 = +3시간**

### 5-4. Sprint 4 fix 권장 정책

1. **P0 (2 entries — OCR 직발)**: 즉시 drop or replace with verified 본인 활동곡 (베이비몬스터 = "BATTER UP" 등 / 스테이씨 = "ASAP" 등)
2. **P1 (28 entries — 의미 불명 transliteration)**: web audit per entry. 실곡 확인되면 표기 자연화 (한글 곡명 표준 표기). 가짜이면 drop + 본인 활동곡으로 replace.
3. **P2 (80+ entries — 그룹곡 misattribution)**: R102 retain 정책 유지. 단 사용자 톨러런스 검증 후 R104 에서 멤버 솔로곡 우선 정책 검토. (현 sprint 0 baseline 에서는 결정 보류)
4. **회귀 가드**: R102 신규 test `r102_celeb_songs_audit_test.dart` 가 tribute/응원곡/placeholder 0 보장 — 유지 + R103 새 가드 (실곡 검증 list lock) 추가.

---

## 6. Sprint 1~5 file list + 작업 강도 estimate

| Sprint | Mandate | 파일 list | 변경 line estimate | token estimate |
|---|---|---|---|---|
| Sprint 0 (본 작업) | baseline | docs/operating_memory/r103_sprint0_baseline.md (신규) | +500 lines | ~10k |
| Sprint 1 | mandate #1 (전생 본문) | `lib/services/past_life_service.dart` (header → pool / cap 패턴 추가) + `assets/data/past_life_pool.json` (intros 3→8, tails 3→8, header 5+ variant, resolution motif 6+ alt, body 보강) + 신규 test `r103_past_life_diversity_test.dart` | service +30 / pool +400 / test +200 | ~80k |
| Sprint 2 | mandate #2 (전생 스크롤) | `lib/screens/reports/past_life_screen.dart` (`_StarPickerList` shrinkWrap + NeverScroll 또는 nested 제거) + 신규 test `r103_past_life_screen_scroll_test.dart` | screen ~10 / test +60 | ~5k |
| Sprint 3 | mandate #3 (focus chain) | `lib/screens/input_screen.dart` (_cityFocus + time onLengthReached + city onSubmitted) + 신규 test `r103_input_focus_chain_test.dart` | screen ~20 / test +120 | ~10k |
| Sprint 4 | mandate #4 (곡 audit) | `assets/data/celeb_songs.json` (30+ entries fix/replace) + 신규 test `r103_celeb_songs_verified_real_test.dart` + audit ledger doc (선택) | songs ~60 / test +100 | ~60k (P0+P1) / +180k (P2 솔로곡 fetch) |
| Sprint 5 | release QA | flutter test + 1.0.0+64 외부 베타 자동 제출 (사용자 mandate 후) | (테스트 + ship script) | ~15k |

→ **총 token estimate**: P0+P1 only = **~180k token**, P2 솔로곡 풀 audit 포함 = **~360k token**

---

## 7. R103 위험 5개 + 완화책

| # | risk | impact | 완화 |
|---|---|---|---|
| 1 | 곡 audit 시간 — P2 그룹곡 80건 모두 본인 솔로곡 검증 시 3h+ + token 폭발 | Sprint 4 가 R102 와 비슷한 1 round 안에 못 끝남 | Sprint 4 를 **2 phase** 로 분리: 4a (P0+P1 30 entries fix) → ship → 4b (P2 솔로곡 정책 사용자 컨펌 후 별 round) |
| 2 | 전생 본문 12~16 문장 expand 시 사용자 톨러런스 — 너무 길면 "스크롤 더 길어졌어" 새 불만 가능 | Mandate #1 fix 가 mandate #2 (스크롤) 와 충돌 | sentence 개수 늘리는 대신 **사건 strand 추가 (8→9 sentence 안에 압축)** + 화면 폰트 / leading 조정으로 시각 분량 < 1.3x 유지 |
| 3 | 사용자 verbatim 예시 톤 ("몰락한 귀족 + 스파이 + 돈 뺏기지만 행복") 정확 복원 어려움 — Sprint 1 generator 가 사건 묘사 강화해도 셀럽 specific 디테일 부족 | "처음에 예시로 줬던 느낌으로 해야돼" 의 user 톨러런스 충족 X | relations pool 24 → 40+ 확장 시 **사용자 verbatim 예시 (몰락 귀족/스파이) 를 첫 entry 로 고정** + sample 검증 시 사용자 예시와 톤 비교 |
| 4 | `_StarPickerList` shrinkWrap 변경 시 207 entries 가 부모 ListView 안에 풀로 mount → 첫 paint 비용 증가 + iOS 저사양 디바이스 lag | 사용자 체감 "스크롤 끊김" 신규 불만 | `ListView.builder` 유지 + `physics: NeverScrollableScrollPhysics()` + `shrinkWrap: true` 조합으로 lazy build 보존 |
| 5 | OCR 직발 2 entries (P0) 제외 의 P1 28 entries 의심도가 generator 의 5행 매칭에서 hit 안 되는 entries 일 가능성 — 즉 사용자가 실제 처방받은 적 없을 수도 | Sprint 4 가 hit 안 될 entries 만 fix 하느라 user-facing impact 없음 | Sprint 4 시작 시 **5행 distribution 별 hit 확률** 측정 → P0+P1 entries 의 element 분포 확인. hit 확률 0% entries 는 P2 로 강등 |

---

## 8. Sprint 0 do-not-edit confirmation

R103 Sprint 0 (본 작업) 은 **진단 baseline 작성만 수행**. 다음을 절대 수행하지 않음:

- 코드 파일 수정 (lib/**, test/**) — **변경 0**
- asset 파일 수정 (assets/data/**) — **변경 0**
- dirty file 삭제·되돌리기 — `scripts/asc_check_prerelease.rb`, `scripts/check_b62.rb`, `scripts/expire_b61_and_v110.rb` 보존
- 자동 배포 / git commit — 수행 X

본 baseline 은 `/Users/seunghyeon/seephone/pillarseer/docs/operating_memory/r103_sprint0_baseline.md` 한 파일만 신규 추가. Sprint 1~5 진입 시 본 문서를 ground truth 로 참고.
