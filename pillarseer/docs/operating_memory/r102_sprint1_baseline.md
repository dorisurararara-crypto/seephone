# R102 Sprint 1 — Content Authenticity Recovery 진단 (read-only baseline)

> 본 문서는 **수정 없이** 작성된 baseline. 사용자 verbatim 불만 6건과 코드/데이터 ground truth 를 매핑함.
>
> 사용자 verbatim:
> "이게 뭐야?? 내용이 하나도 자연스럽지않고 툭툭 끊기는 느낌에 김채원도 인데 김채원 도 이렇게 되어있고 스토리가 하나도 없는데? 두번째사진은 한소희는 가수도 아니고 나의아저씨는 없는노랜데 ??"

---

## 1. Files inspected

read-only 로 확인한 파일 (절대경로):

- `/Users/seunghyeon/seephone/pillarseer/lib/services/past_life_service.dart`
- `/Users/seunghyeon/seephone/pillarseer/lib/services/music_pharmacy_service.dart`
- `/Users/seunghyeon/seephone/pillarseer/lib/services/korean_josa.dart`
- `/Users/seunghyeon/seephone/pillarseer/lib/screens/reports/past_life_screen.dart`
- `/Users/seunghyeon/seephone/pillarseer/lib/screens/reports/music_pharmacy_screen.dart`
- `/Users/seunghyeon/seephone/pillarseer/lib/router.dart`
- `/Users/seunghyeon/seephone/pillarseer/assets/data/past_life_pool.json`
- `/Users/seunghyeon/seephone/pillarseer/assets/data/celeb_songs.json`
- `/Users/seunghyeon/seephone/pillarseer/assets/data/celebrities.json`
- `/Users/seunghyeon/seephone/pillarseer/test/r101_past_life_keyword_test.dart`
- `/Users/seunghyeon/seephone/pillarseer/test/r101_past_life_screen_smoke_test.dart`
- `/Users/seunghyeon/seephone/pillarseer/test/r101_music_pharmacy_test.dart`
- `/Users/seunghyeon/seephone/pillarseer/docs/operating_memory/r101_sprint1_baseline.md`

핵심 카운트:
- `celebrities.json` entries = **223**
- `celeb_songs.json` keys = **223**
- `past_life_pool.json` body_lines key = **8** (wonjin / dohwa / yeokma / cheoneul / gongmang / hap / chung / hyeong)
- `celebrities.json` kind 분포: idol 203 / actor 17 / athlete 2 / icon 1

---

## 2. Current dirty files observed

`git status --short` 결과 (Sprint 1 시작 시점):

```
?? scripts/asc_check_prerelease.rb
?? scripts/check_b62.rb
?? scripts/expire_b61_and_v110.rb
```

→ 코드/asset 변경 없음. Untracked Ruby script 3개만 존재. R102 Sprint 1 은 **삭제·되돌리기 금지** — dirty file 보존.

---

## 3. Past life generator location

| 역할 | 절대경로 | 주요 라인 |
|---|---|---|
| 서비스 본체 | `/Users/seunghyeon/seephone/pillarseer/lib/services/past_life_service.dart` | enum L35, generateScenario L292, generate L318, **_composeFromPool L344**, inject closure L387, **headline L445**, hard fallback L495 |
| 데이터 풀 | `/Users/seunghyeon/seephone/pillarseer/assets/data/past_life_pool.json` | eras / relations / endings / templates / body_lines |
| 화면 | `/Users/seunghyeon/seephone/pillarseer/lib/screens/reports/past_life_screen.dart` | `_compose()` L103, `_ResultCard` L483, headlineKo 렌더 **L522-530**, scenarioKo 렌더 L560-568 |
| 라우터 | `/Users/seunghyeon/seephone/pillarseer/lib/router.dart` | `/reports/past-life` builder L113 |
| 조사 helper | `/Users/seunghyeon/seephone/pillarseer/lib/services/korean_josa.dart` | hasFinalConsonant L100, withSubj/withTop/withObj/withWith L126-135 |

데이터 흐름:
1. `_PastLifeScreenState._compose()` → `PastLifeService.generate()` (async, primeCache 후 `_composeFromPool` 진입)
2. `_composeFromPool` 가 `keywords / pool / celebName / userName / seed` 받고 `intro + body_lines[k] + ending + tail` 문장 합성
3. 문장 inject 만 `inject(tmpl)` closure 통과. **헤더 문장과 headline 은 inject 우회**
4. 결과 `scenarioKo` 는 화면 L562 `Text(scenario.scenarioKo, key: past_life_result_body, ...)` 에 그대로 표시
5. `headlineKo` 는 화면 L522-530 `Text(scenario.headlineKo, ...)` 에 그대로 표시

---

## 4. Root cause: josa spacing

OCR 1 의 "당신 과 김채원 의" / "김채원 도" 정확한 원인 2 가지:

### 4-1. headline 합성이 inject() 를 우회 (P0)

`past_life_service.dart` **L444-445**:

```dart
final composed = sentences.where((s) => s.trim().isNotEmpty).join(' ');
final headline = '$userName 과 $celebName 의 전생 — ${primary.labelKo} 결';
```

`composed` 본문 문장들은 `inject()` 를 거치지만 **headline 은 placeholder 없이 raw 문자열로 작성**되어 있음. `$userName` 과 `$celebName` 사이에 공백 + "과" / "의" 가 hard-coded. 사용자 OCR 의 "당신 과 김채원 의 전생 — 합 결" 과 정확히 일치.

또한 L495 hard fallback 도 동일 패턴: `'$userName 과 $celebName 의 전생 이야기는...'`. 풀 미로드 edge case 진입 시 같은 오류 노출.

### 4-2. inject() 에 "도" / "에게" 패턴 빠짐 (P0)

`past_life_service.dart` `_composeFromPool.inject` (L387-428) 의 치환 대상은:

- `$userName 과 / 와 / 은 / 는 / 이 / 을 / 의`
- `$celebName 과 / 와 / 은 / 는 / 이 / 을 / 의`
- `$userRole 였 / 은`
- `$celebRole 였 / 은 / 이`
- 마지막 plain placeholder fallback (조사 없이) `$celebName` `$userName` `$userRole` `$celebRole`

그러나 풀(`past_life_pool.json`) 에는 **inject 가 처리하지 않는 placeholder + 공백 + 조사 패턴**이 3 종 존재:

```
line 204: "$celebName 도 그랬어요. ..."          (gongmang body)
line 209: "..., $celebName 도 $userName 의 ..." (hap body)
line 214: "..., $celebName 도 같았어요."        (chung body)
line  92: "... $userName 에게 유독 잘 닿는 ..." (dohwa ending)
```

처리 chain 이 끝까지 빠지면 L423 `s = s.replaceAll(r'$celebName', celebName)` plain fallback 에 걸려 placeholder 만 사라지고 **`celebName + " 도"` 가 그대로 남음** → 사용자 OCR 의 "김채원 도" 정확 일치.

→ R102 Sprint 2 fix: (a) headline 도 `josa.withWith` / `josa.withTop` 사용, (b) inject 에 `$userName 도` `$celebName 도` `$userName 에게` `$celebName 에게` 케이스 추가 (받침 무관, 공백만 strip).

---

## 5. Root cause: weak story structure

사용자 verbatim 3 가지 ("툭툭 끊김 / 스토리 없음 / 1막만 있음") 원인:

### 5-1. body_lines 가 "주제 명세 (1막)" 만 (P1)

`past_life_pool.json` 의 body_lines[k] 는 키워드별 **3 문장 고정 풀**. 모든 키워드의 첫 문장이 같은 구조:

```
"$userName 은 $userRole 였고, $celebName 은 $celebRole 였어요. <상황 묘사>"
```

→ "당신은 떠돌이 악사였고, 김채원은 장터 행상이었어요" 등. **1막(상황 setup) 만 반복**. 2막(갈등/사건) 3막(여운/결말) 없음.

### 5-2. 합성 순서가 [intro → body × 3 → ending → tail] 5 구간 — 사건 흐름 없음 (P1)

`_composeFromPool` L435-441:

```dart
final sentences = <String>[
  headerSentence,       // "당신과 X는 1800년대 ...에서 처음 마주쳤어요."
  inject(intro),        // 키워드 도입
  ...bodies.map(inject),// body 3 문장 (1막 묘사)
  inject(ending),       // 회고 1 문장
  inject(tail),         // 합/결 마무리
];
```

→ "처음 마주쳤다 → 직업 묘사 → 묘사 → 묘사 → 잊혔다 → 합 결이 남는다" 흐름. 사건의 진행/반전이 없으니 **모든 문장이 동등한 톤** = "툭툭 끊기는 느낌".

### 5-3. 반복 어휘 hotspot (P2)

`past_life_pool.json` 본문 fragment grep:

- "두 사람은" — body_lines 전반에서 8 회
- "자연스럽게" — 5 회
- "결" 단독 어휘 (headlineKo 포함) — 9 회 이상
- "당신과 {celeb}" 헤더 — 1 문장 고정 (모든 시나리오 첫 줄)
- body 1 문장이 항상 `"$userName 은 $userRole 였고, $celebName 은 $celebRole 였어요"` 로 시작 — **8 키워드 × 동일 패턴**

→ R102 Sprint 2 fix: body_lines 를 [setup / event / turn / resolution] 4 구간 분리 + 시작 어구 다양화 + "두 사람은", "자연스럽게", "결" 어절 cap 추가.

---

## 6. Exact risky strings/patterns found

| pattern | 발생 위치 | 빈도 | 사용자에게 노출되는가 |
|---|---|---|---|
| `'$userName 과 $celebName 의 전생'` (headline raw) | `past_life_service.dart` L445 | 1 | YES (모든 시나리오의 카드 헤드라인) |
| `'$userName 과 $celebName 의 전생 이야기'` (hard fallback raw) | `past_life_service.dart` L495 | 1 | YES (풀 미로드 시) |
| `'$celebName 도 ...'` (gongmang body[0]) | `past_life_pool.json` L204 | 1 | YES |
| `', $celebName 도 ...'` (hap body[1]) | `past_life_pool.json` L209 | 1 | YES |
| `'. $celebName 도 같았어요.'` (chung body[1]) | `past_life_pool.json` L214 | 1 | YES |
| `'$userName 에게 ...'` (dohwa ending) | `past_life_pool.json` L92 | 1 | YES |
| `'$userName 은 $userRole 였고, $celebName 은 $celebRole 였어요'` | body_lines 8 키워드 첫 문장 | 8 | YES |
| `'두 사람은 같은 자리에...'` | body_lines 전반 | 8+ | YES |
| `'자연스럽게'` | body_lines + endings | 5+ | YES |

추가 — inject() 가 다루는 josa 패턴 (정상):
- ` 과 / 와 / 은 / 는 / 이 / 을 / 의` (받침 기준 자동) — userName / celebName 모두 처리
- ` 였` (copula) — userRole / celebRole 처리

inject() 가 **다루지 않는** josa 패턴 (버그):
- ` 도` (보조사, 받침 무관)
- ` 에게` (조사, 받침 무관)
- ` 에서` ` 에` ` 부터` ` 까지` ` 보다` ` 만` ` 처럼` — 현재 풀에는 placeholder 형으로 안 쓰임. **방어적 추가 권장**.

---

## 7. Music pharmacy selection path

`/Users/seunghyeon/seephone/pillarseer/lib/services/music_pharmacy_service.dart` 의 후보 선택 흐름:

```
prescribe(user) → _loadAll() → _prescribeSync(user)
   ↓
   deficitHanja = user.elements.deficit            (L142)
   element = _hanjaToEnKey(deficitHanja)            (L143)
   ↓
   candidates = celebs.where((c) {                  (L147-150)
     final chun = c.dayPillar[0];
     return _chunGanToEnKey(chun) == element;
   }).where((c) => songs.containsKey(c.id))
   ↓
   pool = candidates 비어 있으면 songs 있는 전체 셀럽 (L153-155)
   ↓
   celeb = pool[XorShift32(...).nextInt(pool.length)] (L161)
   song  = celebSongs[XorShift32(...).nextInt(...)]   (L163-165)
   ↓
   본문 합성 L183-191:
     "오늘 ${whoKo}의 사주에 '${elementKo}' 기운이 부족합니다."
     "'${barebone}'의 기운을 타고난 [${shortName}]을 데려왔어요."
     "처방곡은 [${song.titleKo}] (${song.artistKo})."
     ...
```

**핵심 버그**: line 147-155 후보 filter 가 **kind 기준 없음**. 셀럽 dayPillar 가 부족 5행과 일치하면 actor/athlete/icon 도 후보 진입. 한소희는 kind=`actor`, dayPillar 첫 글자가 `壬` 또는 `癸` 이면 deficit=water 사용자에게 prescribe 진입. 그 때 `celeb_songs.json["han-sohee"]` = `[{titleKo: "나의 아저씨", artistKo: "헌정", element: "water"}]` 인 1곡 풀에서 강제 pick → 그대로 처방.

추가로 `celeb_songs.json` 자체에 `kind=idol` 이 아닌 셀럽 키 20 개가 등록되어 있음 (다음 섹션).

---

## 8. celeb_songs.json count and schema

- 파일: `/Users/seunghyeon/seephone/pillarseer/assets/data/celeb_songs.json`
- 키 count: **223** (celebrities.json 과 1:1)
- 값 schema: `Array<{ titleKo: string, artistKo: string, element: 'wood'|'fire'|'earth'|'metal'|'water', moodKo: string }>`
- 곡 entry 평균: 1 (현 데이터는 모든 셀럽 1곡씩)
- 영문 leak 없음 (KO 가드 통과)

artist 분포 top 30 — "헌정" 13건 + "김연아 헌정" 1건 + "응원곡" 1건이 즉시 의심. 나머지는 idol 그룹명/본인명.

---

## 9. High-risk song entries table

총 **15 P0 + 4 P1 + idol→그룹곡 다수** = 사용자에게 직접 위험한 entry 20+ 건.

| celebId / nameKo | kind | songTitle | artist / label | risk reason | recommended action |
|---|---|---|---|---|---|
| `han-sohee` / 한소희 | actor | 나의 아저씨 | 헌정 | 한소희는 가수 아님 + "나의 아저씨" 는 2018 tvN 드라마, 노래 X. 사용자 OCR verbatim 직접 직발. | drop entry. actor 는 music pharmacy 후보 제외. |
| `song-hyekyo` / 송혜교 | actor | 오로라 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `park-seojoon` / 박서준 | actor | 좋은 날 | 헌정 | actor, 곡명도 IU "좋은 날" 차용 의심 | drop entry |
| `jin-seyeon` / 진세연 | actor | 러브 시그널 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `squidgame-lee` / 이정재 | actor | 롤리팝 | 헌정 | actor, "롤리팝" 은 BIGBANG·2NE1 곡 | drop entry |
| `kim-soohyun` / 김수현 | actor | 드림 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `lee-minho` / 이민호 | actor | 스트레인저 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `song-kang` / 송강 | actor | 러브 인 더 무드 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `byeon-wooseok` / 변우석 | actor | 선재 업고 튀어 | 헌정 | actor, "선재 업고 튀어" 는 2024 tvN 드라마 (작품명 = 곡명 사칭) | drop entry |
| `hwang-inyoup` / 황인엽 | actor | 선풀 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `kim-seonho` / 김선호 | actor | 스타트 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `kim-jiwon` / 김지원 | actor | 러브 송 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `kim-hyeyoon` / 김혜윤 | actor | 청춘 | 헌정 | actor, 본인 곡 없음 | drop entry |
| `kim-yuna` / 김연아 | athlete | 아디오스 | 김연아 헌정 | athlete, "아디오스" 는 EVERGLOW 곡 (헌정 라벨이지만 사용자 혼동) | drop entry |
| `son-heungmin` / 손흥민 | athlete | 챔피언 | 응원곡 | athlete, "응원곡" 라벨 자체가 본인 곡 부정 | drop entry |
| `bae-suzy` / 배수지 | actor | 행복한 척 | 수지 | actor(=수지) 본인 곡 — 실존 (Miss A 활동 후 솔로). artist 표기는 OK | retain (검수 필요, 수지 본명/예명 일치) |
| `cha-eunwoo` / 차은우 | actor | 기적 같은 이야기 | 차은우 | actor(=아스트로 멤버) 본인 곡 — idol 이 actor 로 잘못 분류된 케이스. 곡 자체는 ASTRO 차은우 mini sing 가능 | retain (단 kind 를 idol 로 재분류 검토) |
| `ji-changwook` / 지창욱 | actor | 멜로디 | 지창욱 | actor 본인 곡 — 지창욱 OST 'Melody' (2014) 또는 K2 OST 존재 가능. 검증 필요 | verify externally; 의심 시 drop |
| `lee-junho` / 이준호 | actor | 아 진짜요 | 이준호 | actor(=2PM 준호) — idol 출신. 곡명 "아 진짜요" 는 2PM 곡 의심 | retain (단 kind 재분류 검토) |
| `gdragon` / 지드래곤 | icon | 무제 | 지드래곤 | kind=icon (gray zone). 곡 자체는 본인 곡. icon 도 music pharmacy 제외 정책이면 drop. | retain song; icon kind 처방 정책 결정 |

→ 즉시 drop 권고: 15 건 (artist == "헌정" 13 + "응원곡" 1 + "김연아 헌정" 1).
→ kind 재분류 검토: 3 건 (차은우 / 이준호 / 지창욱은 actor 분류이나 idol 활동 이력).
→ 1 건 retain + verify: 배수지.
→ 1 건 정책 결정: 지드래곤(icon).

추가 audit: idol 203 명 중 본인 곡이 아닌 **그룹 곡** 으로 표기된 entry 다수 (예: 카리나 → 에스파 곡, 뉴진스 5 인 → 뉴진스 곡, 르세라핌 5 인 → 르세라핌 곡, 아이브 6 인 → 아이브 곡). 이 패턴은 K-POP 그룹 멤버 통상 표기이므로 R102 에서는 OK 로 보되, "솔로 활동 곡 우선" 정책을 R103 이후 검토.

---

## 10. Recommended Sprint 2 edits (전생 generator)

수정 대상 파일 — Sprint 2 가 직접 편집할 곳만 명시 (Sprint 1 은 손대지 않음):

1. `/Users/seunghyeon/seephone/pillarseer/lib/services/past_life_service.dart`
   - **L445 headline** — `'$userName 과 $celebName 의 전생'` → `'${userName}${josa.withWith(userName)} ${celebName}${josa.withSubj(celebName)/withTop(celebName)} 의 전생'`. "X 의" 도 `${X}의` (받침 무관, 공백 strip).
   - **L495 hard fallback** — 동일 패턴 적용.
   - **L387 inject()** — 다음 replace 5건 추가:
     ```dart
     s = s.replaceAll(r'$userName 도', '$userName도');
     s = s.replaceAll(r'$celebName 도', '$celebName도');
     s = s.replaceAll(r'$userName 에게', '$userName에게');
     s = s.replaceAll(r'$celebName 에게', '$celebName에게');
     ```
     ("도", "에게" 는 받침 무관 — 공백 strip 만으로 충분)
   - 방어적: `$userName 에서` `$celebName 에서` 등 향후 풀 확장 대비 추가 권장.
2. `/Users/seunghyeon/seephone/pillarseer/assets/data/past_life_pool.json`
   - body_lines 8 키워드 전부를 **2막 + 3막** 구조로 확장 (setup → event → turn → resolution).
   - 8 키워드 첫 문장 동일 패턴 (`$userName 은 $userRole 였고...`) 의 다양화.
   - 반복 어휘 cap: "두 사람은" 8회 → 2회 / "자연스럽게" 5회 → 1회 / "결" 단독 9회 → 3회.

---

## 11. Recommended Sprint 3 edits (music pharmacy containment)

수정 대상:

1. `/Users/seunghyeon/seephone/pillarseer/lib/services/music_pharmacy_service.dart`
   - **L147-155 candidates filter 에 kind 가드 추가**:
     ```dart
     final candidates = celebs.where((c) {
       if (c.kind != 'idol') return false; // music pharmacy 는 가수만
       final chun = c.dayPillar.isNotEmpty ? c.dayPillar[0] : '';
       return _chunGanToEnKey(chun) == element;
     }).where((c) => songs.containsKey(c.id)).toList();
     ```
   - `_Celeb` class (L421) 에 `kind` 필드 추가 + `fromJson` 에서 읽기.
   - fallback pool (L153-155) 도 동일하게 idol 만 허용.
2. `/Users/seunghyeon/seephone/pillarseer/lib/screens/reports/music_pharmacy_screen.dart`
   - 처방 결과에 actor/athlete/icon 셀럽이 노출되지 않도록 가드 — 이미 service layer 에서 차단되면 화면 변경 X.

---

## 12. Recommended Sprint 4 edits (song audit)

수정 대상:

1. `/Users/seunghyeon/seephone/pillarseer/assets/data/celeb_songs.json`
   - **15 건 entry drop** — 헌정 13 + 응원곡 1 + 김연아 헌정 1.
   - 또는 entry 유지하되 `"isOriginalArtist": false` flag 추가 후 prescribe 단에서 필터링.
   - idol 본인 외 그룹곡 entry 는 R102 에서는 retain (사용자 톨러런스 검증 후 R103+).
2. `/Users/seunghyeon/seephone/pillarseer/assets/data/celebrities.json`
   - 차은우 / 이준호 — kind 를 actor → idol 로 재분류 검토 (둘 다 K-POP 그룹 멤버 활동).
   - 지드래곤 — icon 분류 유지하되 music pharmacy 후보 제외 (idol-only 정책으로 자동 제외).

---

## 13. Tests that must be added

R102 Sprint 2-4 PR 에 반드시 포함:

| test | 검증 |
|---|---|
| `r102_josa_no_loose_spacing_test.dart` | `PastLifeService.generate` 의 `scenarioKo` + `headlineKo` 에 `RegExp(r'\s(과|와|은|는|이|가|을|를|의|도|에게|에서|에|부터|까지)(\s|$)')` 매칭 0회. 셀럽 30명 × 사용자 5명 = 150 시나리오 전수. |
| `r102_past_life_headline_test.dart` | headline 이 inject 통과 — `XXX의 전생` 의 "X의" 받침 무관 + "XXX과/와 YYY" 받침 맞춤. |
| `r102_past_life_repetition_test.dart` | 150 시나리오 전수에서 "두 사람은" 빈도 ≤ 30% / "자연스럽게" 빈도 ≤ 10% / "결" 단어 sentence 끝 ≤ 1회. |
| `r102_past_life_story_structure_test.dart` | 시나리오 sentence 수 ≥ 6, body_lines 가 setup·event·turn·resolution 4 phase 분리 (pool 구조 lock). |
| `r102_music_pharmacy_idol_only_test.dart` | 5행 5종 × 사용자 10 fixture = 50 prescribe call. 결과 celeb 의 `kind` 가 모두 `idol`. |
| `r102_celeb_songs_audit_test.dart` | `celeb_songs.json` 의 모든 entry artistKo 가 `["헌정", "응원곡", "tribute", "Unknown", "placeholder"]` 와 일치하지 않음. |
| `r102_celeb_songs_no_drama_title_test.dart` | titleKo 가 ["나의 아저씨", "선재 업고 튀어", "K2", "더 글로리", ...] 드라마 stopword 리스트와 매칭 0. |
| `r102_past_life_inject_도_에게_test.dart` | `'$celebName 도'` `'$userName 에게'` placeholder 가 정상 치환 (단위 테스트). |
| `r102_korean_no_english_leak_regression.dart` | R101 가드 유지 — 본문 영문 어절 0. |
| `r102_past_life_seed_determinism.dart` | 같은 seed → 같은 본문 (회귀 가드). |

---

## 14. Do not edit confirmation

R102 Sprint 1 (본 작업) 은 **진단 baseline 작성만 수행**. 다음을 절대 수행하지 않음:

- 코드 파일 수정 (lib/**, test/**) — **변경 0**.
- asset 파일 수정 (assets/data/**) — **변경 0**.
- dirty file 삭제·되돌리기 — `scripts/asc_check_prerelease.rb`, `scripts/check_b62.rb`, `scripts/expire_b61_and_v110.rb` 보존.
- 자동 배포 / git commit — 수행 X.

본 baseline 은 `/Users/seunghyeon/seephone/pillarseer/docs/operating_memory/r102_sprint1_baseline.md` 한 파일만 추가. Sprint 2 (전생 generator fix) / Sprint 3 (music pharmacy kind 가드) / Sprint 4 (songs audit) 진입 시 본 문서를 ground truth 로 참고.
