# R104 Sprint 1 — 전생 화면/본문 개선 baseline (read-only 진단)

> 본 문서는 **수정 없이** 작성된 baseline. R104 mandate + 코드/데이터/테스트 ground truth.
>
> 사용자 verbatim mandate (codex 두뇌 전달):
> > "전생의 악연/인연 시나리오에서 다시뽑기가 있으면 안되고, 선택하면 밑에 목록은
> > 사라지고 결과가 나와야지 ... 내용도 너무 ai같고 재미가 없어 길이도 짧고"
> > "중요한건 내용에 기승전결이 있어야해"
>
> codex R104 방향 결정:
> 1. 본문 = keyword × storyArc 단위 "완결 story arc pack" (8 keyword × 6~8 arc, arc
>    하나가 원인→사건→전환→이번 생 punchline 통째).
> 2. 목표 길이 = 4문단 총 8~10문장.
> 3. 다시뽑기 완전 제거 + 셀럽 선택 시 picker/search hide + 결과 카드만 + 상단에
>    "선택한 최애: X" / "다른 최애 고르기" 버튼.
> 4. 셀럽별 bespoke story 안 함, kind 만 현대 punchline 분기.

---

## 0. 빌드 / commit / dirty 상태

| 항목 | 값 |
|---|---|
| 마지막 commit | `7755bf2` — R102 전생 자연화 + 음악 처방 데이터 정합성 |
| pubspec version | `1.0.0+63` (ASC VALID + ganzitester 외부 베타 제출 완료) |
| dirty files (untracked, 모두 R104 무관 — 보존) | `scripts/asc_check_prerelease.rb` / `scripts/check_b62.rb` / `scripts/expire_b61_and_v110.rb` / `test/probe_r103_sprint5b_qa.dart` |
| 본 baseline | `docs/operating_memory/r104_past_life_baseline.md` (신규 1개) |

> 주의: R103 sprint 0 baseline (`r103_sprint0_baseline.md`) 의 일부 수치는 stale.
> R103 sprint 1~5A 가 이미 코드/풀에 반영됨 (intros/tails 3→16, headers 10 신규,
> event_sub/bridge 8 신규, scroll fix, 10~14 sentence 등). 본 R104 baseline 은
> **현재 worktree의 실제 코드 상태**를 ground truth 로 한다.

### backup 안내
`.codex_backups/` 디렉토리는 이미 존재 (mkdir 불필요). 본 작업은 신규 문서 1개만
추가하므로 원본 백업 대상 없음 — backup 불필요.

---

## 1. Files inspected (read-only)

절대경로:
- `/Users/seunghyeon/seephone/pillarseer/new인수인계.md`
- `/Users/seunghyeon/seephone/pillarseer/docs/operating_memory/celebrity_db_playbook.md`
- `/Users/seunghyeon/seephone/pillarseer/docs/operating_memory/r103_sprint0_baseline.md`
- `/Users/seunghyeon/seephone/pillarseer/lib/screens/reports/past_life_screen.dart` (767 lines)
- `/Users/seunghyeon/seephone/pillarseer/lib/services/past_life_service.dart` (943 lines)
- `/Users/seunghyeon/seephone/pillarseer/assets/data/past_life_pool.json` (~647 lines)
- `test/r101_past_life_screen_smoke_test.dart`
- `test/r101_past_life_keyword_test.dart`
- `test/r102_past_life_headline_test.dart`
- `test/r102_past_life_repetition_test.dart`
- `test/r102_past_life_seed_determinism_test.dart`
- `test/r102_past_life_story_structure_test.dart`
- `test/r102_past_life_inject_do_ege_test.dart`
- `test/r103_past_life_scroll_test.dart`
- `test/r103_past_life_length_test.dart`
- `test/r103_past_life_dramatic_detail_test.dart`
- `test/r103_past_life_fingerprint_test.dart`
- `test/r103_past_life_phrase_cap_test.dart`
- `test/r103_past_life_resolution_motif_test.dart`
- `test/r103_past_life_inject_collision_test.dart`

`ls test/ | grep -i past_life` 결과 = 14 tracked + `probe_r103_sprint5b_qa.dart` (untracked).

---

## 2. 현재 화면 구조 ground truth — `past_life_screen.dart`

### 2-1. widget tree (정확 line)

```
Scaffold (L134)
├── appBar (L136~156) — "전생 · 緣" + 뒤로가기 → context.go('/reports')
└── body: SafeArea(top:false) (L157)
    └── _buildBody (L177~225)
        └── ListView  Key('past_life_primary_scroll')  (L180)   ◀ 단일 primary scroll
            ├── _Hero()                                 (L184)
            ├── _NameField(controller:_nameCtl)         (L185)   key past_life_name_field (L309)
            ├── _SearchBar(controller:_searchCtl)       (L186~189) key past_life_search_field (L356)
            ├── _StarPickerList(stars,selectedId,onPick)(L190~200)
            │   └── Container (border만, height 없음)   (L417~424)
            │       └── ListView.separated             (L425~487)
            │           key past_life_star_picker_list  (L426)
            │           shrinkWrap:true (L429) + NeverScrollableScrollPhysics (L430)
            │           item: InkWell key past_life_star_row_${id} (L441)
            ├── if (_selected != null) ...[             (L201~221)
            │     SizedBox(height:8)
            │     if (_composing) CircularProgressIndicator
            │     else if (_scenario != null)
            │         _ResultCard  key past_life_result_card (L214~220)
            │   ]
            └── SizedBox(height:28)                     (L222)
```

### 2-2. 셀럽 선택 후 picker/search 가 결과 위에 **남는다** (R104 핵심 제거 대상)

`_buildBody` (L177~225) 의 children 은 `_Hero / _NameField / _SearchBar /
_StarPickerList` 가 **무조건 mount**. `_selected != null` 일 때 `_ResultCard` 가 그
**뒤에 추가될 뿐**, picker/search/name field 는 사라지지 않는다.

- L184~189: `_Hero` / `_NameField` / `_SearchBar` 무조건 mount.
- L190~200: `_StarPickerList` 무조건 mount (셀럽 207 entries 전체가 picker 로 노출).
- L201~221: `_selected != null` 일 때만 `_ResultCard` 가 picker **아래** 추가.

→ 사용자 verbatim "선택하면 밑에 목록은 사라지고 결과가 나와야지" 와 정면 충돌.
현재는 결과 카드가 picker 아래로 append 되고 picker 가 그대로 위에 남아 있다.

### 2-3. "다시 뽑기" 버튼 — 정확 위치

| 항목 | 위치 |
|---|---|
| 버튼 위젯 | `_ResultCard` 안 `OutlinedButton` — `past_life_screen.dart` **L582~603** |
| 버튼 key | `Key('past_life_reroll_button')` — **L583** |
| 버튼 라벨 | `'다시 뽑기'` — **L595** |
| 버튼 callback | `onPressed: onReroll` — **L584** |
| callback 출처 | `_ResultCard` 의 `onReroll` 필드 (L496, L502) |
| callback 결선 | `_buildBody` L219: `onReroll: () => _compose(reroll: true)` |
| reroll 로직 | `_compose({bool reroll = false})` — L103~129. L109: `if (reroll) _seed = (_seed + 1) & 0x7fffffff;` |
| 클래스 상단 주석 | L12: `// 4) "다시 뽑기" 버튼 — seed 회전 ...` |

→ R104 에서 버튼/key/라벨/callback/`reroll` 파라미터/`_seed` 회전 전부 제거 대상.

### 2-4. 결과로 돌아가기 / 다른 최애 고르기 경로 — **존재 안 함**

현재 코드에는 "다른 최애 고르기" 류 버튼/route/콜백이 **전무**. 셀럽을 바꾸려면
화면에 항상 떠 있는 picker 에서 다른 row 를 다시 tap 해야 한다 (`onPick` L193~199).
`onPick` 은 `_selected` 갱신 + `_scenario = null` 후 `_compose()` 재호출.

→ R104 mandate "상단에 '선택한 최애: X' / '다른 최애 고르기' 버튼" = 신규 추가 필요.
picker 를 hide 하므로, hide 된 picker 를 다시 부를 수 있는 명시적 경로가 새로 필요하다.

---

## 3. 현재 service 구조 ground truth — `past_life_service.dart`

### 3-1. slot별 랜덤 조립 구조 — `_composeFromPool` (L344~727)

현재 본문 = **10개 슬롯을 keyword별 풀에서 각각 독립 random pick** 후 join.

조립 순서 (`composedSentences` L690~701):

| # | 슬롯 | 풀 위치 (keyword `k` 기준) | 풀 크기 |
|---|---|---|---|
| 1 | headerSentence | `templates[k].headers` (L373~375) | **10** (없으면 L681 hard-coded fallback) |
| 2 | intro | `templates[k].intros` (L368) | **16** |
| 3 | setup | `body_lines[k].setup` (L388) | **12** |
| 4 | event | `body_lines[k].event` (L389) | **12** |
| 5 | event_sub (있을 때만) | `body_lines[k].event_sub` (L391~393) | **8** |
| 6 | bridge (있을 때만) | `body_lines[k].bridge` (L395~397) | **8** |
| 7 | turn | `body_lines[k].turn` (L398) | **12** |
| 8 | resolution | `body_lines[k].resolution` (L399) | **12** |
| 9 | ending | `pool.endings` (전역) | **12** |
| 10 | tail | `templates[k].tails` (L369) | **16** |

추가 전역 풀: `eras` 16, `relations` 48 (`rel.user`/`rel.celeb` placeholder).

각 슬롯은 `rng.nextInt(pool.length)` 로 **서로 독립** 선택 (L418~436). 즉 슬롯 간
인과 관계가 보장되지 않음 — header 가 "조선" 인데 event 가 다른 시대 motif 일 수
있고, setup 의 갈등과 turn 의 결말이 logically 연결 안 될 수 있다.

### 3-2. R103 에서 풀이 늘어났지만 causal arc 가 아니다

R103 sprint 1 이 headers(10 신규) + intros/tails(3→16) + event_sub/bridge(8 신규)
를 추가했고, `_meta.rule` 에 "4막 흐름" 을 명시했다. 그러나:

- 4막 흐름은 **슬롯 순서**일 뿐, **각 슬롯이 독립 random** 이라 한 시나리오 안에서
  원인(setup)→사건(event)→전환(turn)→결말(resolution) 이 **같은 사건 줄기**로
  이어진다는 보장이 없다.
- 예: setup 이 "감시하던 자리" 인데 event 가 무관한 다른 motif, turn 이 또 무관.
- 사용자 체감 "내용이 ai같고 재미없고 기승전결이 없다" 의 구조적 원인 = **slot
  단위 random 조립 자체**. 풀을 더 늘려도 random 조립이면 인과가 안 생긴다.

### 3-3. story arc 방식으로 바꿔야 하는 이유

codex 결정: keyword × **storyArc 단위 "완결 story arc pack"**.

- 한 arc = 원인→사건→전환→이번 생 punchline 이 **하나의 묶음(pack)** 으로 작성된
  완결 단편. arc 내부 문장들은 작성 시점에 서로 인과로 연결됨.
- 8 keyword × 6~8 arc → 한 keyword 당 6~8개의 완결 story 중 seed 로 하나 선택.
- 슬롯 단위 random 조립을 버리고 **arc 단위 단일 선택**으로 전환하면, 생성된
  본문이 항상 기승전결이 있는 완결 story 가 된다.
- placeholder($userName/$celebName/$userRole/$celebRole/$era) inject 와 josa
  보정 로직(L443~669)은 그대로 재사용 가능 — arc 텍스트에 placeholder 만 박으면 됨.

---

## 4. 현재 tests conflict — R104 mandate 와 충돌하는 assertion (가장 중요)

R104 = (A) 다시뽑기 제거 + (B) 4문단 8~10문장 story arc + (C) picker hide.
아래는 이 셋과 충돌하는 **기존 회귀 가드 assertion 전수 목록**. 다음 sprint 에서
이 테스트들을 보고 "되돌리는" 실수를 하지 않도록 명확히 식별한다.

### 4-A. "다시 뽑기" 보존을 요구하는 테스트 (mandate A 와 충돌)

| 파일:line | assertion 텍스트 | 충돌 |
|---|---|---|
| `test/r101_past_life_screen_smoke_test.dart:53~58` | `test('다시 뽑기 버튼 + reroll seed 회전 진입점')` — L54 `expect(src.contains("'다시 뽑기'"), isTrue)` / L55~56 `expect(src.contains('past_life_reroll_button'), isTrue)` / L57~58 `expect(src.contains('reroll: true'), isTrue)` | R104 가 다시뽑기 버튼/key/`reroll:true` 진입점 전부 제거 → 이 test 가 fail. **테스트를 "다시뽑기 없음" 가드로 재작성해야 함 (삭제 아님).** |
| `test/r103_past_life_scroll_test.dart:192~196` | `test('R101 hero / 라벨 / "다시 뽑기" 보존')` — L195 `expect(src.contains("'다시 뽑기'"), isTrue)` | 동일. "다시 뽑기" 라벨 보존 요구 → R104 와 충돌. 해당 expect 만 제거/반전. |

> 참고: `r101_past_life_screen_smoke_test.dart:71~73` 의 `forbiddenInScreen` 에
> `"'reroll'"` 이 들어 있으나, 이건 영문 라벨 leak 가드라 R104 와 무관 (보존 OK).
> 단, R104 에서 `_compose(reroll:...)` 의 `reroll` 식별자를 코드에서 없애면
> `'reroll'` (따옴표 포함 문자열) 은 어차피 화면 텍스트가 아니라 무관.

### 4-B. 10~14 / 7~14 sentence 수를 요구하는 테스트 (mandate B "8~10문장" 과 충돌)

| 파일:line | assertion 텍스트 | 충돌 |
|---|---|---|
| `test/r103_past_life_length_test.dart:52~74` | `test('50 sample sentence count ∈ [10, 14]')` — L69 `expect(sentences.length, inInclusiveRange(10, 14))` | R104 목표는 **8~10문장**. 10~14 범위 lower bound 가 R104 상한(10)과 거의 겹치지만 **상한 14 가 너무 김**. R104 spec 으로 `inInclusiveRange(8, 10)` 재작성 필요. (threshold 낮추는 게 아니라 mandate 변경.) |
| `test/r102_past_life_story_structure_test.dart:90~115` | L106 `expect(sentences.length, inInclusiveRange(7, 14))` | 범위 7~14. R104 의 8~10 은 이 범위 안에 들어가므로 **이 test 는 기술적으로 통과 가능** — 단 의도가 R102 8~10 mandate 라서 R104 8~10 으로 좁히는 게 정합적. 충돌 위험은 낮으나 audit 대상. |
| `test/r103_past_life_fingerprint_test.dart:58~99, 101~120` | first/first3/body unique ratio + `같은 셀럽 5 seed 안 첫 문장 ≥ 3종` (L101~119) | arc 방식 = keyword당 6~8 arc. 같은 셀럽 5 seed → arc 6~8 중 선택이라 first sentence 종류 ≥ 3 은 **충족 가능**. body unique ratio 0.96 도 arc + 셀럽 inject 면 충족 가능. **단 같은 keyword 6~8 arc 만 있으면 5 seed 중 중복 arc hit 가능** → arc 수가 6 미만이면 fail 위험. arc pack 을 keyword당 ≥ 6 (가능하면 8) 로 보장해야 이 test 통과. |

### 4-C. slot 구조(event_sub/bridge/resolution motif/headers/intros/tails 풀 크기)에 의존하는 테스트 (mandate B "arc 방식" 과 충돌)

R104 가 slot 조립을 arc pack 으로 바꾸면, slot별 풀(`headers`/`intros`/`tails`/
`event_sub`/`bridge`/`setup`/`event`/`turn`/`resolution`)이 사라지거나 의미가
바뀐다. 아래 테스트는 그 slot 풀의 **존재/크기/내용**을 직접 검증하므로 충돌.

| 파일:line | assertion 텍스트 | 충돌 |
|---|---|---|
| `test/r103_past_life_resolution_motif_test.dart:40~55` | `test('각 keyword 의 tail+resolution 합쳐 motif 5개 이상 매칭')` — `tpl['tails']` + `body['resolution']` 풀을 직접 join 후 motif hit ≥ 5 | tails/resolution slot 풀에 의존. arc 방식이면 slot 풀 자체가 없어질 수 있음 → fail. arc pack 안의 punchline motif 검증으로 재작성 필요. |
| `test/r103_past_life_resolution_motif_test.dart:57~90` | `test('8 keyword 모두 event_sub variant ≥ 8 + dramatic detail markers')` — `m['event_sub']` length ≥ 8 + 각 sub 가 dramatic marker 포함 | event_sub slot 풀 직접 검증. arc 방식이면 event_sub 풀 제거 가능 → fail. |
| `test/r103_past_life_resolution_motif_test.dart:92~103` | `test('headers / intros / tails 풀 크기 R103 spec 충족')` — `headers` ≥ 8 / `intros` ≥ 16 / `tails` ≥ 16 | headers/intros/tails slot 풀 크기 직접 검증. arc 방식이면 이 풀들이 없어질 수 있음 → fail. |
| `test/r103_past_life_resolution_motif_test.dart:105~115` | `test('relations pool ≥ 48')` + `몰락한 귀족 + 스파이 pair` 존재 | `relations` 풀 검증. arc 방식이 relations placeholder 를 계속 쓰면 통과. arc 가 role 을 arc 텍스트에 직접 박으면 relations 풀이 줄거나 사라짐 → fail 위험. |
| `test/r102_past_life_story_structure_test.dart:46~70` | `test('8 키워드 모두 setup/event/turn/resolution 4 phase 존재')` — 각 phase List length ≥ 12 | body_lines 4 phase slot 풀 직접 검증. arc 방식이면 body_lines 구조 자체가 바뀜 → fail. |
| `test/r101_past_life_keyword_test.dart:84~115` | `test('8 keyword 각각 templates intros/tails ≥ 3, body_lines 4 phase ≥ 12')` — intros ≥ 3, tails ≥ 3, setup/event/turn/resolution ≥ 12 | 동일. slot 풀 크기 직접 검증 → arc 방식과 충돌. |
| `test/r101_past_life_keyword_test.dart:63~82` | `test('parse OK + 필수 키 존재')` (eras/relations/endings/templates/body_lines) + 시대 ≥ 12 / 관계 ≥ 24 / 결말 ≥ 12 | top-level 키 + 풀 크기 검증. arc 방식이 top-level schema 를 바꾸면 fail. arc pack 을 새 키(`story_arcs` 등)로 추가하고 기존 키 잔존 시키면 일부 통과 가능 — schema 결정에 따라 audit 필요. |

> 참고로 `r103_past_life_dramatic_detail_test.dart` (50 sample dramatic detail ≥ 2 +
> 사주살 명시 ≥ 1) 와 `r103_past_life_phrase_cap_test.dart` (반복 어구 cap) 는
> **생성 결과물(scenario string)** 만 검증하므로 arc 방식으로 바꿔도 arc 텍스트가
> dramatic detail / 사주살 명시를 포함하고 반복 어구가 cap 이하면 **통과 가능**.
> 직접 충돌은 아니지만, arc pack 작성 시 이 가드를 만족하도록 콘텐츠를 써야 한다
> (회귀 가드로 유지).

### 4-D. 충돌하지 않는 (보존) past_life 테스트

R104 변경 후에도 그대로 통과해야 하는 회귀 가드 (생성 결과/계산 로직만 검증):

- `r101_past_life_keyword_test.dart` 의 `hasWonjin` 6쌍 / `extractKeywords` / KO leak
  24 case / seed determinism — keyword 추출 + inject 로직은 R104 변경 대상 아님.
- `r102_past_life_headline_test.dart` — headline josa 보정 (변경 없음).
- `r102_past_life_repetition_test.dart` / `r103_past_life_phrase_cap_test.dart` — 반복
  어구 cap (arc 텍스트도 이 cap 통과해야 함, 회귀 가드 유지).
- `r102_past_life_seed_determinism_test.dart` — 같은 seed → 같은 결과 (arc 선택도
  seed deterministic 유지해야 함).
- `r102_past_life_inject_do_ege_test.dart` / `r103_past_life_inject_collision_test.dart`
  — placeholder + josa collision 0 (inject 로직 유지, 회귀 가드).
- `r101_past_life_screen_smoke_test.dart` 의 hero/route/RepaintBoundary/메뉴 순서 등
  (다시뽑기 test 외) — 보존.
- `r103_past_life_scroll_test.dart` 의 scroll fix 가드 (다시뽑기 expect 외) — 보존.
  단 R104 가 picker hide 를 추가하면 `_StarPickerList` 의 mount 조건이 바뀌므로
  scroll test 의 일부 source grep 이 영향받을 수 있음 (sprint 2 에서 audit).

---

## 5. 제안 구현 구조 (Sprint 2 / 3 / 4)

### Sprint 2 — 화면 UX 변경 (다시뽑기 제거 + picker hide)

| 대상 | 경로 | 변경 |
|---|---|---|
| 화면 | `lib/screens/reports/past_life_screen.dart` | (1) `_buildBody` L177~225: `_selected != null && _scenario != null` 일 때 `_NameField`/`_SearchBar`/`_StarPickerList` 를 mount 하지 않음. (2) `_ResultCard` 의 reroll 버튼(L582~603)/`onReroll` 필드 제거. (3) `_compose` 의 `reroll` 파라미터 + `_seed` 회전(L103~129) 제거 또는 단순화. (4) 결과 표시 시 상단에 "선택한 최애: X" + "다른 최애 고르기" 버튼 신규 추가 — 후자 tap 시 `_selected=null; _scenario=null` 로 picker 복귀. (5) 클래스 상단 주석 L12 갱신. |
| 테스트 (재작성) | `test/r101_past_life_screen_smoke_test.dart` | L53~58 `다시 뽑기 버튼` test → "다시뽑기 없음 + 다른 최애 고르기 버튼 존재" 가드로 재작성. |
| 테스트 (수정) | `test/r103_past_life_scroll_test.dart` | L195 `'다시 뽑기'` 보존 expect 제거/반전. picker hide 후 scroll 가드 영향 audit. |
| 테스트 (신규) | `test/r104_past_life_screen_ux_test.dart` (제안) | 셀럽 선택 후 picker/search hide / "다른 최애 고르기" 버튼 / 다시뽑기 부재 회귀 가드. |

### Sprint 3 — story arc engine 변경

| 대상 | 경로 | 변경 |
|---|---|---|
| 서비스 | `lib/services/past_life_service.dart` | `_composeFromPool` (L344~727) 의 slot 단위 random 조립을 **arc 단위 단일 선택**으로 교체. keyword `k` → `story_arcs[k]` 에서 seed 로 arc 1개 선택 → arc 의 paragraph 4개를 placeholder inject. inject/josa 보정(L443~669) + cap(L784~) + headline 로직은 재사용. `kind` 별 punchline 분기 hook 추가. |
| 테스트 (재작성) | `test/r103_past_life_length_test.dart` | `inInclusiveRange(10,14)` → `inInclusiveRange(8,10)` (R104 mandate 4문단 8~10문장). |
| 테스트 (audit) | `test/r103_past_life_fingerprint_test.dart` | arc 수가 keyword당 ≥ 6 보장되면 통과. arc < 6 이면 fail → arc pack 크기 검증 test 추가 권장. |
| 테스트 (보존, 회귀 가드) | `r102/r103 phrase_cap`, `dramatic_detail`, `inject_collision`, `seed_determinism`, `r102_repetition`, `r102_headline`, `r101_keyword` (계산부) | arc 텍스트가 이 가드들을 통과하도록 작성. |
| 테스트 (신규) | `test/r104_past_life_arc_test.dart` (제안) | keyword당 arc ≥ 6, 각 arc 4문단 구조, arc 내 기승전결 marker, seed→arc deterministic. |

### Sprint 4 — content pool 변경 범위 (`assets/data/past_life_pool.json`)

- 신규 키 `story_arcs` 추가: `{ keyword: [ {arc 4문단 + placeholder + punchline by kind}, ... ] }`. 8 keyword × 6~8 arc = **48~64 완결 arc**.
- 각 arc = 4문단(기/승/전/결), 총 8~10문장, 사주살 명시 1+, dramatic detail 2+,
  사용자 verbatim 예시 톤("몰락한 귀족 + 스파이 + 돈 뺏기지만 행복") 유지.
- 기존 slot 키(`templates.headers/intros/tails`, `body_lines.setup/event/event_sub/
  bridge/turn/resolution`) 처리 결정 필요:
  - **삭제 금지 mandate** 준수 → 기존 키는 **잔존시키되 미사용**으로 두거나, slot
    의존 테스트(§4-C)를 arc 검증으로 재작성한 뒤 schema 정리.
  - 권장: R104 sprint 3/4 에서는 `story_arcs` 키를 **추가**하고 service 가 그것을
    우선 사용, 기존 slot 키는 일단 보존(하위호환 fallback). schema 완전 정리는
    별도 round 로 미룸 (회귀 0 안전).
- `eras` / `relations` / `endings` 는 arc 가 placeholder($era/$userRole/$celebRole)
  를 계속 쓰면 보존. arc 가 role 을 텍스트에 직접 박으면 relations 의존 test
  (§4-C `r103_resolution_motif:105`) audit 필요.
- `_meta` 갱신 (version `r104-sprint*` + arc 방식 rule 기술).

---

## 6. Sprint 1 do-not-edit confirmation

R104 Sprint 1 (본 작업) 은 **진단 baseline 작성만** 수행. 다음 절대 수행 안 함:

- `lib/**` 수정 — **변경 0**
- `test/**` 수정 — **변경 0**
- `assets/**` 수정 — **변경 0**
- dirty file 삭제/되돌리기 — `scripts/asc_check_prerelease.rb` / `scripts/check_b62.rb`
  / `scripts/expire_b61_and_v110.rb` / `test/probe_r103_sprint5b_qa.dart` 보존.
- git commit / 자동 배포 — 수행 X.

본 baseline 은 `docs/operating_memory/r104_past_life_baseline.md` 한 파일만 신규 추가.
Sprint 2~ 진입 시 본 문서 §4 (충돌 테스트 목록) 를 ground truth 로 참고하여,
R104 mandate 구현 중 기존 회귀 가드를 잘못 되돌리지 않도록 한다.
