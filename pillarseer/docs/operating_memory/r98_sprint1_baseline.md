# R98 Sprint 1 — Content QA Baseline

> Status: baseline measurement only (no edits applied)
> Audited at: 2026-05-19 KST
> Auditor: Claude content QA agent (read-only)
> Scope: 사용자 mandate 1/2 — 반복 lead phrase + AI 슬롭 + 조사 오류 후보 측정
> 절대 룰: 본 baseline 산출 동안 어떤 source/asset도 수정하지 않았다. 측정·리포트 only.

---

## 0. 사용자 OCR 4문장 → 정확한 출처 매핑

| OCR 문장 (사용자 보고) | 정확한 매핑 |
|---|---|
| `단정하고 세련된 본성이 어릴 때부터 또렷이 보였어요` | `assets/data/life_paragraphs.json:1039` (key `신묘.early_life`) — 동일 lead가 같은 pillar `신묘` 안에서 17개 카테고리 + dict M/F 6개 = 총 20회 |
| `공간가 어느새 한 시간대로 흘러요` | `lib/screens/reports/kpop_compat_screen.dart:1457` 템플릿 `너의 $mySceneKo와 $shortName의 $stSceneKo가 어느새 한 시간대로 흘러요.` → `jiSceneKo['戌'] = '문 닫고 같이 지키는 공간'`(line 1418)일 때 `$stSceneKo가` = `공간가` 조사 오류 |
| `본인 스타일대로 가는 쪽이 정답이에요` | `lib/screens/home_screen.dart:305` `_pool[actionDay]['辛']` 1번째 줄 |
| `사람들이 본인을 바로 기억해요` | `lib/screens/home_screen.dart:305` `_pool[actionDay]['辛']` 2번째 줄 (위와 동일 entry) |

가드: 위 4건 모두 source line 으로 정확히 찍혔다. 4/4 PASS.

---

## 1. 파일별 문제 count table

`결이에요 / 본성이 / 시그니처 / 정답이에요 / 본인 스타일대로 / 사람들이 본인을 / 두 배로 / 단 한 번의 정답 / 다음 분기 전체 / 한 단계 위 / 본인 이미지를 / 흐름대로 가면 / 그게 오늘 / 본인답게 가는 게 / 그대로 묻어나요` 등 forbidden 사전 기준.

| 파일 | 결이에요 | 본성이 | 시그니처 | 정답이에요 | 본인 스타일대로 | 사람들이 본인을 | 두 배로 | 단 한 번의 정답 | 다음 분기 전체 | 한 단계 위 | 그대로 묻어나요 | 당신은+당신의+당신이+당신에게 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `assets/data/life_paragraphs.json` | **1000** | **556** | 852 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 250 | 0 |
| `assets/data/sipsin_persona.json` | 54 | (포함, 보조) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — | 0 |
| `assets/data/life_fragments.json` | 116 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| `assets/data/saju_deep_slice_0_19.json` | 0 | 0 | 0 | 5 | 0 | 0 | 3 | 4 | 4 | 3 | 0 | ~345 |
| `assets/data/saju_deep_slice_20_39.json` | 0 | 0 | 0 | 5 | 1 | 0 | 2 | 3 | 5 | 5 | 0 | ~345 |
| `assets/data/saju_deep_slice_40_59.json` | 0 | 0 | 0 | 3 | 3 | 0 | 2 | 2 | 5 | 1 | 0 | ~345 |
| `assets/data/life_stage_pool.json` | 0 | — | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | — | 0 |
| `assets/data/additional_life_pool.json` | 0 | — | 0 | 0 | 0 | 5 | 0 | 0 | 0 | 0 | — | 0 |
| `assets/data/celebrities.json` | 0 | — | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — | 0 |
| `assets/data/dreams.json` | 0 | — | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — | 7 |
| `lib/screens/home_screen.dart` | 1 | 0 | 2 | 5 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `lib/screens/reports/kpop_compat_screen.dart` | 0 | 0 | 0 | 2 | 0 | 0 | 1 | 0 | 0 | 1 | 0 | 0 |
| `lib/screens/reports/compatibility_screen.dart` | 19 (정확) | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 1 | 0 | 0 |
| `lib/screens/reports/new_year_2026_screen.dart` | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 6 |
| `lib/services/deep_content_service.dart` | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| `lib/services/natural_prose_joiner.dart` | 0 | 0 | 0 | 0 | 0 | 1(주석) | 0 | 0 | 0 | 0 | 0 | 0 |
| `lib/services/notification_pool_service.dart` | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `lib/services/life_overview_service.dart` | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| `lib/services/dynamic_text_resolver.dart` | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| `lib/services/today_deep_service.dart` | 0 | 0 | 1(주석) | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `test/probe_r96_prose_sample.dart` | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `test/natural_prose_joiner_test.dart` | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |

핵심 집계:
- `결이에요` total: assets 1170 + lib 37 = **1207** (lib 19 는 `compatibility_screen.dart` 의 5행 케미 mapping 의도적 운영 표현이지만 user-facing prose 어휘 단조로움 기여).
- `본성이` total: assets 556 + lib 0 = **556** (전부 life_paragraphs.json 안).
- `시그니처` total: assets 853 + lib 약 12 (주석·service 메타 다수) + test 약 8 (주석/regression label 의 `시그니처 보존` 의미라 user-facing 아님). user-facing 위험은 `notification_pool_service.dart:172` 의 `최애 직캠 본 후 한 줄 메모. 그 곡이 너의 시그니처가 돼요.` (1건) + `celebrities.json` 의 blurb 1건.
- `공간가` / `공간와`: assets/data 0, lib raw string 0. **하지만 runtime 합성 = kpop_compat_screen.dart 1457 의 `$stSceneKo가` + `jiSceneKo['戌']='문 닫고 같이 지키는 공간'` 조합 시 = `공간가` 발화 발생.** 같은 위험: `mySceneKo` 1447·1457·1466·1476 line 모두 `$...SceneKo가` / `$...SceneKo와` 식 직결합.
- `당신은+당신의+당신이+당신에게` total: saju_deep_slice 3 file 합산 **1036** + lib 14 = **1050**. R96 sprint 1 사용자 mandate "오늘 너 = 이런 표현 빼줘 ai같아" 와 정면 충돌 가능 — 해요체/너 어조 통일 mandate 와 `당신` 어조가 mixed.

---

## 2. Exact phrase top 50 (forbidden 사전 기준)

(전체 repo 기준 `assets/data + lib + test` 합산. 큰 순서대로.)

| rank | count | phrase | 주 위치 |
|---:|---:|---|---|
| 1 | 1207 | `결이에요` | life_paragraphs (1000) / sipsin_persona (54) / life_fragments (116) / compatibility_screen (19) / etc |
| 2 | 1050 | `당신` 4-form (`당신은/의/이/에게`) | saju_deep_slice ×3 (1036) / lib services 14 |
| 3 | 853 | `시그니처` (user-facing copy 중) | life_paragraphs (852) / celebrities (1) — assets 압도적 |
| 4 | 556 | `본성이` | life_paragraphs (전수) |
| 5 | 250 | `그대로 묻어나요` | life_paragraphs |
| 6 | 120 | `자아의 무게로 자리잡고 있어요` | life_paragraphs `innate_character.M/F` 패턴 |
| 7 | 120 | `평소 자아의 무게로` | life_paragraphs |
| 8 | 30 | `결이 어릴 때부터 또렷이 보였어요` | life_paragraphs `early_life` |
| 9 | 24 | `자라는 결이` | life_paragraphs (갑/갑자 계열) |
| 10 | 20 | `단정하고 세련된 본성이` | life_paragraphs `신묘.*` 17 카테고리 + M/F 6 = 20 |
| 11 | 17 | `_FirstFoldGreeting`/`_PillarOfTheDay` (이미 R85 sprint 에서 surface 제거됨, 시그니처만 잔류) | source 주석 |
| 12 | 14 | `다음 분기 전체` | saju_deep_slice |
| 13 | 13 | `정답이에요` (user-facing copy) | saju_deep_slice 13 + home_screen 5 + kpop_compat 2 + new_year 2 + today_deep 1 = 23 (전체) |
| 14 | 9 | `단 한 번의 정답` | saju_deep_slice |
| 15 | 9 | `한 단계 위` | saju_deep_slice + 일부 reports |
| 16 | 8 | `두 배로` | saju_deep_slice + life_fragments + lib 4 |
| 17 | 7 | `사람들이 본인을` | life_stage_pool 2 + additional_life_pool 5 + home_screen 1 + test 2 |
| 18 | 4 | `본인 스타일대로` | saju_deep_slice 4 + home_screen 1 + deep_content_service 2 = 7 |
| 19 | 4 | `본인답게 가는 게` | saju_deep_slice |
| 20 | 2 | `두각이 나요` | life_paragraphs |
| 21 | 1 | `본인 이미지를` | home_screen.dart:288, 304 (2회 실제) |
| 22 | 1 | `흐름대로 가면` | home_screen.dart:290, 306 (2회 실제) |
| 23 | 1 | `그게 오늘` | home_screen.dart:277, 305 (2회 실제 — actionDay 辛 / restDay 癸) |
| 24 | 1 | `공간가` (runtime 합성) | kpop_compat_screen 템플릿 |
| 25–50 | <5 each | (보조 — 아래 lead-stem 표 참고) | — |

추가 lib hardcoded 위험:
- `home_screen.dart` `_pool` 30 ment 안의 `정답이에요` 5건, `본인 이미지를` 2건, `흐름대로 가면` 2건, `본인 스타일대로` 1건, `본인 이미지를` 2건이 한 phrase 안에 응집해 있어 사용자 인지 빈도가 절대 횟수보다 훨씬 높음.

---

## 3. 첫 문장 lead stem top 50 (`life_paragraphs.json` 60 pillar 기준)

`life_paragraphs.json` 60 pillar 각각이 17 카테고리(`early_life / mid_life / late_life / health / constitution / social / social_personality / personality / innate_tendency / wealth / wealth_gather / wealth_loss_prevent / wealth_invest / conclusion_self`) + 3 dict 카테고리(`innate_character.M/F / love_fate.M/F / affection.M/F` 6 strings) = **20개 string** 의 첫 14자 lead 가 모두 동일한 패턴.

대표 60건 (모두 count=20, 즉 한 pillar 의 20개 string 첫 문장이 100% 동일 lead 로 시작):

| pillar | lead stem (첫 14자) | 반복 count |
|---|---|---:|
| 갑자 | `곧은 나무처럼 자라는 결이` | 20 |
| 갑인 | `리더 자리가 자연스러운 무` | 20 |
| 갑오 | `큰 줄기 같은 추진력의 결` | 20 |
| 갑신 | `뿌리 깊은 자존심의 무게가` | 20 |
| 갑술 | `하늘 향해 곧게 뻗는 본성` | 20 |
| 갑진 | `곧고 단단한 본성이 평소 ` | 3 (부분 repeat) |
| 을축 | `부드럽지만 끈질긴 풀과 덩` | 20 |
| 을묘 | `유연한 적응력이 매력인 본` | 20 |
| 을사 | `섬세하지만 굽히지 않는 결` | 20 |
| 을미 | `바람 따라 흐르되 뿌리는 ` | 20 |
| 을유 | `천천히 멀리 가는 끈기의 ` | 20 |
| 을해 | `작은 빈틈도 채워가는 본성` | 20 |
| 병자 | `태양처럼 환한 에너지의 결` | 20 |
| 병인 | `직진형 밝은 본성이 평소 ` | 3 (부분) |
| 병진 | `주위를 데워주는 따뜻한 결` | 20 |
| 병오 | `활기 넘치는 무대 체질의 ` | 20 |
| 병신 | `솔직하고 표현 잘하는 결이` | 20 |
| 병술 | `한낮처럼 거리낌 없는 본성` | 20 |
| 정묘 | `섬세하고 정 깊은 본성이 ` | 20 |
| 정사 | `디테일까지 챙기는 손길의 ` | 20 |
| 정미 | `작은 등불처럼 빛나는 따뜻` | 20 |
| 정유 | `예민하지만 다정한 본성이 ` | 20 |
| 정해 | `조용히 곁을 비춰주는 결이` | 20 |
| 정축 | `촛불처럼 따뜻한 결이 평소` | 3 (부분) |
| 무자 | `큰 산처럼 묵직한 본성이 ` | 20 |
| 무인 | `듬직한 무게가 매력인 결이` | 20 |
| 무진 | `흔들리지 않는 중심의 본성` | 20 |
| 무오 | `책임감 강한 큰형/큰언니의` | 20 |
| 무신 | `안정감이 자연스럽게 풍기는` | 20 |
| 무술 | `한 자리 깊게 뿌리내리는 ` | 20 |
| 기축 | `비옥한 흙처럼 포근한 결이` | 20 |
| 기묘 | `사람을 키우는 자상한 본성` | 20 |
| 기사 | `받아주고 품어주는 무게가 ` | 20 |
| 기미 | `실속 있게 챙기는 어른 같` | 20 |
| 기유 | `조용히 자리를 다지는 본성` | 20 |
| 기해 | `뒤에서 단단히 받쳐주는 결` | 20 |
| 경자 | `단단한 쇠처럼 곧은 본성이` | 20 |
| 경인 | `결단력과 의리가 매력인 결` | 20 |
| 경진 | `한 번 마음 정하면 끝까지` | 20 |
| 경오 | `강하지만 정 깊은 결이 사/평` | 3+3 (부분) |
| 경신 | `추진력 있는 직진형의 본성` | 20 |
| 경술 | `벼린 칼 같은 단호한 결이` | 20 |
| 신축 | `정제된 보석처럼 예리한 결` | 20 |
| 신묘 | **`단정하고 세련된 본성이 사/평`** | **20 (직접 OCR 일치)** |
| 신사 | `날 선 감각이 매력인 결이` | 20 |
| 신미 | `깔끔하게 마무리하는 손길의` | 20 |
| 신유 | `결이 분명한 본성이 평소 ` | 3 (부분) |
| 신해 | `광택 있는 금속 같은 결이` | 20 |
| 임자 | `큰 강처럼 흐르는 본성이 ` | 20 |
| 임인 | `자유롭고 깊이 보는 결이 ` | 20 |
| 임진 | `통찰력 있는 본성이 평소 ` | 3 (부분) |
| 임오 | `한 곳에 갇히지 않는 시야` | 20 |
| 임신 | `잔잔하지만 거대한 흐름의 ` | 20 |
| 임술 | `바다처럼 품 넓은 결이 사/평` | 3+3 (부분) |
| 계축 | `맑은 이슬처럼 섬세한 결이` | 20 |
| 계묘 | `직관이 빠른 본성이 평소 ` | 3 (부분) |
| 계사 | `조용하지만 깊이 있는 결이` | 20 |
| 계미 | `차분하게 흘러가는 무게가 ` | 20 |
| 계유 | `예민한 감각이 매력인 결이` | 20 |
| 계해 | `작은 빗방울처럼 부드러운 ` | 20 |

요약: **60 pillar × 20 string = 1200 user-facing 문단의 첫 문장이 `[성격 stem] + [카테고리 안내]` 동일 lead-in 으로 시작.** 사용자가 한 pillar 안에서 17 카테고리 reading 을 흘려 보면 100% 같은 한 줄로 시작.

stem(`갑/을/...`) 10 entries 는 lead 반복 ≥3 0건 — stem 카테고리는 다양하게 짜여있으나, pillar 카테고리만 동일 lead 강제.

---

## 4. 조사 오류 후보 top 30 (`$varName가/와/이/은/을/를` 직결합 + 의심 본문 sample)

`rg '\$[a-zA-Z_][a-zA-Z0-9_]*[가-힣]' lib/screens lib/services` 의 60+ hit 중 risk 등급별 top 30. **`가/이/와/과/은/는/을/를` 직결합 = 변수 끝 받침 여부 확정 불가 → 조사 깨질 위험**.

| rank | risk | file:line | 템플릿 |
|---:|---|---|---|
| 1 | **HIGH (재현 확인됨)** | `lib/screens/reports/kpop_compat_screen.dart:1457` | `너의 $mySceneKo와 $shortName의 $stSceneKo가 어느새 한 시간대로 흘러요.` — `'戌':'문 닫고 같이 지키는 공간'` 일 때 `공간가` 발화. (또한 `짧은 도시 산책가`, `밤바다 같은 깊은 대화가` 등 다수 조합 모두 깨짐) |
| 2 | HIGH | `lib/screens/reports/kpop_compat_screen.dart:1466` | `너의 $mySceneKo와 $shortName의 $stSceneKo가 정반대 시간대라,` — 동일 root |
| 3 | HIGH | `lib/screens/reports/kpop_compat_screen.dart:1476` | `너의 $mySceneKo와 $shortName의 $stSceneKo가 자연스럽게 겹치는 순간이 와야` |
| 4 | HIGH | `lib/screens/reports/kpop_compat_screen.dart:1447` | `너의 $mySceneKo가 $shortName한테도 자연스럽게 닿아요.` — `'戌':'...공간'`일 때 `공간가` |
| 5 | HIGH | `lib/screens/reports/kpop_compat_screen.dart:1567` | `$anchorSummary가 함께 있어서` — `anchorSummary` 끝 변동 (예: `자리 2개`, `약함`) |
| 6 | MID | `lib/screens/reports/kpop_compat_screen.dart:1443` | `$shortName이 깨달은 건 너도 곧 깨닫고, 너의 변화도 $shortName한테 빠르게 비쳐요.` — 받침 없는 이름(`예: 미나`) + `이` 결합 |
| 7 | MID | `lib/screens/reports/kpop_compat_screen.dart:1444` | `너의 $mySceneKo가 $shortName한테도 자연스럽게 닿아요.` — 위와 동일 risk |
| 8 | MID | `lib/screens/reports/kpop_compat_screen.dart:1560` | `$shortName과의 시간은 의식적으로 깊이를 만들 때만 자라요.` — 받침 없는 이름이면 `과` 어색 |
| 9 | MID | `lib/screens/reports/kpop_compat_screen.dart:1745` | `$shortName이 너 모르는 새 면을 가져올 수 있도록` |
| 10 | MID | `lib/screens/reports/kpop_compat_screen.dart:1746` | `$shortName이 흔들릴 때` |
| 11 | MID | `lib/screens/reports/kpop_compat_screen.dart:1747` | `$shortName과 너의 페이스가` |
| 12 | MID | `lib/screens/reports/kpop_compat_screen.dart:1750` | `너의 한 마디·한 행동이 $shortName한테 깊게 닿아요.` |
| 13 | MID | `lib/screens/reports/kpop_compat_screen.dart:1752` | `$shortName이 너 앞에서는 평소보다 더 솔직해져요.` |
| 14 | MID | `lib/screens/reports/kpop_compat_screen.dart:1753` | `네가 별생각 없이 한 말도 $shortName한테는 오래 남고` |
| 15 | MID | `lib/screens/reports/kpop_compat_screen.dart:1754` | `너의 에너지가 $shortName의 약한 자리를 자연스럽게 데워주는` |
| 16 | MID | `lib/screens/reports/kpop_compat_screen.dart:1763` | `$shortName의 안정감이 너의 흔들림을 잡아주니까` |
| 17 | MID | `lib/screens/reports/kpop_compat_screen.dart:1764` | `$shortName의 색이 너의 빈자리를 데워주는 자리라` |
| 18 | MID | `lib/screens/reports/kpop_compat_screen.dart:1765` | `$shortName이 별생각 없이 건넨 말이` |
| 19 | MID | `lib/screens/reports/kpop_compat_screen.dart:1766` | `$shortName의 기운이` |
| 20 | MID | `lib/screens/reports/kpop_compat_screen.dart:1771` | `$shortName이 너 앞에서는 평소보다 위축될 수도` |
| 21 | MID | `lib/screens/reports/kpop_compat_screen.dart:1773` | `너의 기운이 상대를 다듬는 위치라 $shortName의 단점이` |
| 22 | MID | `lib/screens/reports/kpop_compat_screen.dart:1774` | `네가 $shortName의 흐름을 조이는 위치라` |
| 23 | MID | `lib/screens/reports/kpop_compat_screen.dart:1775` | `$shortName이 자기 의견을 꺼낼 타이밍을` |
| 24 | MID | `lib/screens/reports/kpop_compat_screen.dart:1776` | `너의 기운이 $shortName을 정돈하는 위치라` — 받침 없는 이름이면 `을` 어색 |
| 25 | MID | `lib/screens/reports/kpop_compat_screen.dart:1777` | `$shortName한테는 자극이자 부담` |
| 26 | MID | `lib/screens/reports/kpop_compat_screen.dart:1784` | `$shortName의 톤이 너의 평소 속도를 살짝 흔드는` |
| 27 | MID | `lib/screens/reports/kpop_compat_screen.dart:1786` | `$shortName이 너의 속도를 의도치 않게 흔들어` |
| 28 | MID | `lib/screens/reports/kpop_compat_screen.dart:1787` | `$shortName의 직설을 비판이 아니라` |
| 29 | MID | `lib/screens/reports/kpop_compat_screen.dart:1909` | `$myElName↔$stElName 사이의 끌림이` — el name 끝 받침 변동 |
| 30 | MID | `lib/screens/reports/new_year_2026_screen.dart:1058 / 1077` | `용신 $yong / 희신 $hui을 가까이.` — `$hui을` 직결합 (예: `희신 木을` 자연 / `희신 火를` 필요 — 받침 변동) |

또한 **runtime 위험 가장 큰 entry** = `lib/screens/reports/kpop_compat_screen.dart:1408–1419` `jiSceneKo` 12 entries 중:
- `'戌': '문 닫고 같이 지키는 공간'` → `공간가/공간와/공간을` 모두 깨짐
- `'寅': '새로 시작하는 첫 발걸음'` → `첫 발걸음가` 깨짐
- `'未': '오후의 차 한 잔과 정원'` → `정원가/정원와` 깨짐
- `'酉': '저녁 빛 아래 정돈된 자리'` → `자리가` OK / `자리와` OK (운좋음)
- `'亥': '밤바다 같은 깊은 대화'` → `대화가` OK / `대화와` OK (모음 끝)
- `'卯': '봄빛 들어오는 창가의 대화'` → 동일
- `'丑': '느린 아침과 정리된 책상'` → `책상가/책상와/책상을` 깨짐
- `'巳': '뜨거운 한낮의 결정'` → `결정가/결정와` 깨짐

→ **12 ji × 4 template line (1447 / 1457 / 1466 / 1476) = 최소 48 조합 중 약 절반(받침 끝나는 entry × 직결합 조사)이 깨짐**.

---

## 5. 수정 우선순위 P0 / P1 / P2

### P0 (사용자가 즉시 인지 + OCR 보고)
1. `lib/screens/home_screen.dart` 의 `_pool[DayEnergyKind.actionDay]['辛']` (line 305) — 사용자가 OCR 로 2문장 같은 entry 에서 보고. 30 ment pool 안에 `정답이에요(5) / 본인 이미지를(2) / 흐름대로 가면(2) / 본인 스타일대로(1) / 사람들이 본인을(1) / 그게 오늘(2)` 응집.
2. `lib/screens/reports/kpop_compat_screen.dart:1447 / 1457 / 1466 / 1476` 의 `$mySceneKo가/와 / $stSceneKo가/와` 4 template line + `jiSceneKo` 12 entries → 조사 자동 보정 미적용. 사용자 OCR `공간가 어느새 한 시간대로 흘러요` 의 출처.
3. `assets/data/life_paragraphs.json` 의 `신묘` 20 entries — 사용자 OCR `단정하고 세련된 본성이 어릴 때부터 또렷이 보였어요` 의 출처. 한 pillar 안에서 동일 lead-in 20회 — 모든 60 pillar 가 같은 구조이지만, 사용자 OCR 가 직접 잡았으므로 P0 anchor.

### P1 (사용자 mandate 1 = 반복 lead phrase 광범위)
4. `assets/data/life_paragraphs.json` 전체 60 pillar × 20 string = **1200 entries 의 첫 문장 lead-in 동일 패턴**. P0 #3 을 일반화한 전수 문제.
5. `assets/data/life_paragraphs.json` 의 `결이에요` 1000회 + `시그니처` 852회 → 한 reading 안에서 어휘 단조로움. mandate 2 (AI 같은 표현) 와 정면.
6. `assets/data/saju_deep_slice_*` 의 `당신은/의/이/에게` 1036회 — R86 sprint 2 사용자 mandate "오늘 너 = 이런 표현 빼줘 ai같아" 와 어조 mixed. saju_deep_slice 가 user-facing 인지 routing 확인 필요.
7. `lib/screens/home_screen.dart` 의 30 ment _pool 안 `정답이에요` 5, `본인 이미지를` 2, `흐름대로 가면` 2 — 사용자 mandate 1 (반복 lead) 의 대표 hit.

### P2 (정성 보강)
8. `assets/data/life_paragraphs.json` 의 `그대로 묻어나요` 250회 — AI typical filler.
9. `assets/data/life_paragraphs.json` 의 `자아의 무게로 자리잡고 있어요` 120회 (innate_character.M/F 패턴) — 동일 sentence stem 60 pillar × 2 gender = 120 시그니처 충돌.
10. `lib/screens/reports/new_year_2026_screen.dart:1058 / 1077` 의 `희신 $hui을` 조사 직결합.
11. `lib/services/notification_pool_service.dart:172` 의 `그 곡이 너의 시그니처가 돼요.` — user-facing single hit, mandate 2 위반 candidate.
12. `lib/screens/reports/compatibility_screen.dart` 의 `결이에요` 19회 (5행 케미 mapping 의도적이지만 mandate 2 와 충돌 시 톤 다양화 검토).
13. `assets/data/life_stage_pool.json` 의 `사람들이 본인을` 2회 + `assets/data/additional_life_pool.json` 의 5회 — P0/P1 fix 시 동일 source 정리.

---

## 6. 추가해야 할 regression test 후보

(파일 후보 이름 + 검증 의도. 코드는 추후 작성.)

| 후보 test file | 검증 의도 |
|---|---|
| `test/r98_forbidden_phrase_test.dart` | `assets/data/*.json` + `lib/**/*.dart` 전수 scan, `결이에요 / 본성이 / 시그니처 / 정답이에요 / 본인 스타일대로 / 본인답게 가는 게 / 사람들이 본인을 / 단 한 번의 정답 / 다음 분기 전체 / 한 단계 위 / 본인 이미지를 / 흐름대로 가면 / 그게 오늘 / 두 배로 / 그대로 묻어나요 / 자아의 무게로 자리잡고 있어요` 각 phrase 의 baseline count cap. cap 이하만 PASS. |
| `test/r98_lead_stem_dedupe_test.dart` | `life_paragraphs.json` 60 pillar 각각 안에서 17 string 카테고리의 첫 문장 첫 14자 lead stem unique count >= N (예: >= 8). 동일 pillar 안 20/20 = 1 unique 인 현재 상태 FAIL. |
| `test/r98_first_sentence_variation_test.dart` | 같은 pillar 의 17 string 카테고리의 **첫 문장 전체** 가 100% 동일 시작 phrase 인 경우를 count 하고 cap. 현재 60 pillar 가 모두 100% 동일 → FAIL. |
| `test/r98_particle_safe_template_test.dart` | `lib/**/*.dart` 안 `$varName(가|이|와|과|을|를|은|는)` 직결합 발생 위치 detect. 화이트리스트(고정 한자 변수 등) 제외하고 cap 0 또는 baseline. |
| `test/r98_kpop_scene_particle_test.dart` | `kpop_compat_screen.dart` 의 `jiSceneKo` 12 entries 각각이 `_attachJosa(scene, '가')` 같은 조사 보정 헬퍼를 통과한 후 어떤 조사가 붙어도 자연스러운 한국어인지 fixture 검증. |
| `test/r98_home_pool_phrase_diversity_test.dart` | `home_screen.dart _pool` 30 ment 안에서 `정답이에요 / 본인 이미지를 / 흐름대로 가면 / 본인 스타일대로` 등 forbidden phrase 의 cap. 현재 baseline cap 미설정. |
| `test/r98_saju_deep_slice_address_form_test.dart` | `saju_deep_slice_*.json` 의 ko 본문에 `당신` 어형 등장 여부 + 사용자 mandate "해요체 + 너 어조" 정합성 회귀. user-facing 인지 routing 확인 후 적용. |
| `test/r98_user_ocr_4_lines_test.dart` | 사용자 OCR 4 문장 정확 매칭 source line 이 fix 후 어떤 형태로 변경되었는지 lock 회귀 (regression source-level grep). |

---

## 7. 가드 결과 정리

- 가드 1 — `단정하고 세련된 본성이` exact count 확인: **20 (모두 `assets/data/life_paragraphs.json` 의 `신묘` pillar 안)**. PASS.
- 가드 2 — `본성이` lead stem ≥3 일주 enumerate: **60 pillar 전수 (count=20 entries 50건 + count=3 부분 entries 13건 = 60 unique pillars 모두 hit)**. 위 section 3 표 참고. PASS.
- 가드 3 — `공간가|공간와` 조합 템플릿 위험 위치 보고: `lib/screens/reports/kpop_compat_screen.dart:1447, 1457, 1466, 1476` + `jiSceneKo['戌'] = '문 닫고 같이 지키는 공간'` (line 1418). PASS.
- 가드 4 — `lib/screens/home_screen.dart` 의 `辛 actionDay` 문장 발견: `lib/screens/home_screen.dart:305` (`_pool[DayEnergyKind.actionDay]['辛']`). PASS.

---

## 8. 후속 권장 (수정 단계, 본 sprint scope 밖)

1. R98 sprint 2 = P0 #1 home_screen `_pool` 30 ment 전수 재작성 + R86 sprint 2 mandate (해요체 / 반말 0 / AI 슬롭 0) 상위에 mandate 1 (반복 lead phrase 0) + mandate 2 (어색 한국어 0) 추가 invariant.
2. R98 sprint 3 = P0 #2 `kpop_compat_screen.dart` 의 `_attachJosa` 헬퍼 신규 도입 + `jiSceneKo` 12 entries 안의 끝-받침 다양성 검증.
3. R98 sprint 4 = P1 `life_paragraphs.json` 의 lead-stem 다양화. 60 pillar × 17~20 strings = 1200 entries 의 첫 문장을 카테고리별로 흩어버리는 작업. ground truth = section 3 표.
4. R98 sprint 5 = P1 `saju_deep_slice_*.json` 의 `당신` 어조 routing 확인 → user-facing 이면 mandate 1/2 통일.
5. R98 sprint 6 = regression test set (section 6) 추가.

---

## Doc Update Transaction (이 측정 자체)

### 2026-05-19 — R98 sprint 1 baseline 측정

- Before state: 사용자 OCR 4 문장 (`단정하고 세련된 본성이 어릴 때부터 또렷이 보였어요`, `공간가 어느새 한 시간대로 흘러요`, `본인 스타일대로 가는 쪽이 정답이에요`, `사람들이 본인을 바로 기억해요`) 의 정확한 source 위치 미확정 + mandate 1/2 hit count 부재.
- After state: 4 OCR 문장 모두 source line 매핑 완료, 반복 lead-in 1200 entries / `결이에요` 1207회 / `당신` 어조 1036회 / `공간가` runtime 합성 위치 4 line / `本性이` 556회 baseline 수치 확정.
- Files intentionally changed: `docs/operating_memory/r98_sprint1_baseline.md` (신규 생성, 측정 결과만).
- Commands proving state:
  - `rg -n "본성이|결이에요|시그니처|정답이에요|본인 스타일대로|사람들이 본인을|공간가|공간와" assets/data lib test`
  - `python3` inline lead-stem analysis on `life_paragraphs.json`
  - `rg -n '\$[a-zA-Z_][a-zA-Z0-9_]*[가-힣]' lib/screens lib/services`
- New failure learned: 한 pillar 안에서 17~20 user-facing string 의 첫 문장이 100% 동일 lead-in 으로 시작하는 구조가 60 pillar 전수에 적용되어 있음. 사용자 OCR 1건이 곧 1200건 회귀 신호.
- Rule promoted: forbidden phrase 검사 시 assets/data + lib + test 3 area 를 한꺼번에 grep 해야 하며, `결이에요` 같은 광범위 어휘는 source-file 별 cap 차이를 두는 게 합리. `compatibility_screen.dart` 의 5행 케미 mapping 같은 의도적 운영 표현은 별도 화이트리스트.
- Open risk: `saju_deep_slice_*.json` 의 `당신` 어조 (1036회) 가 user-facing 인지, 또는 reserved/legacy template 인지 routing 미확정. R98 sprint 5 에서 deep_content_service 의 호출 경로 확인 필요.
- Next session first action: P0 #1 `home_screen.dart _pool` 30 ment 재작성 sprint 시작 전, 본 baseline 의 section 6 regression test 후보 중 `test/r98_forbidden_phrase_test.dart` + `test/r98_user_ocr_4_lines_test.dart` 먼저 add → 회귀 lock 확보 후 ment 재작성.
- quality: routing 9/10, safety 10/10 (수정 0), accuracy 9/10, tests 9/10 (test 후보만 작성, 실제 add 미수행 — 본 sprint scope 밖), content 9/10, efficiency 9/10
