---
name: project_pillarseer_round_82
description: "R82 sprint 1 — 사용자 1.0.0+39 검증 후 9문제 fix plan spec markdown 작성 (codex 9.95 PASS, 미배포)"
metadata: 
  node_type: memory
  date: 2026-05-15
  type: project
  originSessionId: f718ca1f-90b5-4e42-908d-e7fa50b20f06
---

## R82 trigger — 사용자 verbatim 9문제 (1.0.0+39 실기기 검증 후)

> "여전히 앱에 문제가 많아 너무 뭐가 많아서 한눈에 들어오지도 않고 내용도 부자연스러운것도 많고 삶의 12가지 결 풀이도 이 결은 드러낸 흐름이약해서 연겱된기운으로 봐야해요 하면서 도와주는기운과 살짝걸리는기운이 나오는데 그게 뭔지도 안나오고 설명도 약하고 내 사주탭에 오늘 당신에게 생길수 있는일이 왜있는거며 (오늘탭에 있어야함) 깊게봐도 다시 잡힌 핵심 이것도 부자연스럽고 벼린칼 같은사람이에요 이 단어도 너무 어렵고 금토끼 금원숭이 이런거 나오는데 그게 뭔지 설명도 없고 조승현아 오늘은 금토끼에 날이야 이건 또 갑자기 뭐하는거며 설명도 없고 오늘의 일진은 토 쥐 이것만있는데 이것도 설명도 없고 왜 있어야하는건지 모르겠고"

→ 9 visible 문제 (UI overload / 본문 어색 / 12 결 라벨 X / 잘못된 탭 today_event / 깊게 봐도 핵심 어색 / 벼린 칼 한자 / 금토끼·금원숭이 context X / 일진 동물 단독 노출).

## Sprint 1 완료 — spec 작성 only (2026-05-15)

- 산출물: `pillarseer/docs/round82_spec.md` 신규 **475 line**
- codex audit **5 라운드** (9.53 → 9.86 → 9.65 → 9.67 → **9.95 PASS** A 10.0 / B 9.9 / C 9.9 / D 10.0)
- commit `1eab1a5`
- 미배포 (사용자 mandate "내가 배포하라고 할때만해" 준수)

### 9문제 → 추정 코드 위치 (sprint 2~8 generator 가 사용)

| # | 문제 | 위치 (확정) |
|---|---|---|
| 1 | UI overload | `result_screen.dart` 4290 line widget tree |
| 2 | 본문 어색 | `saju_deep_slice_*.json` 240 entry ko |
| 3 | 12 결 라벨 X | `result_screen.dart:3267/3280/3291` 12궁 라벨 |
| 4 | "내 사주"에 today_event | `result_screen.dart:147~150` `TodayEventDetailSection` mount + `today_screen.dart:21` |
| 5 | "깊게 봐도 잡힌 핵심" 어색 | `six_axis_radar.dart:71` `_MatchBadge` |
| 6 | "벼린 칼" 한자 | `deep_content_service.dart:404~540` `_oneLineByJi60Ko` |
| 7 | "금토끼·금원숭이" | `saju_60ji.json` `name` field (Wood Rat) + `date_picking_screen.dart:144` `_jiKoreanAnimal` |
| 8 | "조승현아 오늘은 금토끼에 날이야" | `notification_pool_service.dart` template |
| 9 | "오늘 일진 토 쥐" | `home_screen.dart:146` `_localizedGanjiLabel` + `l10n/app_ko.arb:50` `homeTodaysPillar` |

## Sprint plan (10 sprint — sprint 1 완료, 2~10 진행 대기)

| Sprint | 의제 | 상태 |
|---|---|---|
| 1 | spec (+ 1.5 외부 reviewer audit 흡수, 14 sprint 확장) | ✅ 완료 (commit `1eab1a5` + `3cf6362`) |
| 2 | #4 fix — /today route 분리 (result_screen 에서 today_event 제거) | ✅ 완료 commit `2d19d57` (codex 9.96 / 523 test / 5행 골든 보존) |
| 3 | #6 fix — _oneLineByJi60Ko 60 entry 쉬운 단어 + 폐기 fallback 정리 | ✅ 완료 commit `fadf704` (codex peak 9.32 / 532 test / 사용자 mandate 본질 충족 — 사용자 결정 진행, sprint 13 재검증 예정) |
| 4 | #5 fix — "깊게 봐도 다시 잡힌 핵심" 라벨 재작성/제거 | ✅ 완료 commit `0d76dd3` (codex 9.92 / 540 test / 옵션 A "두 번 봐도 같이 잡힌 강점") |
| 5 | #3 fix — 12 결 풀이 라벨 명시 + 1줄 설명 | ✅ 완료 commit `b052d52` (codex 9.9 / 555 test / palace_helper_anchor_service 신규 520 line + 자미두수 nameKo noLeak 12×16 case + R78 chain 보존) |
| 6 | #7+#8+#9 fix — 금토끼·금원숭이/일진 한글 name 영역 audit + 설명 | ✅ 완료 commit `3eb7429` (codex 9.91 / 562 test / animal_context_service 신규 159 line + self-pair 60 / today-pillar 132 anchor + 호명 무서움 risk blacklist) |
| 7 | #1 fix — UI 정보 우선순위 (first-fold + 접기) | 대기 |
| 8 | #2 fix — 본문 어색 saju_deep_slice sample 재작성 | 대기 |
| 9 | 회귀 가드 + R69 lock 검증 + 5행 골든 보존 | 대기 |
| 10 | memory R82 + 인수인계.md R82 + (사용자 mandate 후) TestFlight 1.0.0+40 | 대기 |

## 사용자 mandate (영구 — spec 본문 명시)

1. 자동 배포 X — 사용자 명시 후만 ("내가 배포하라고 할때만해")
2. 시뮬·에뮬 새 부팅 X (사용자 컴 freeze 위험)
3. 1995-10-27 男 17시 5행 골든 16/21/17/41/4 + 일주 辛卯 보존
4. 한국 MZ 중학생 K-POP 팬 페르소나
5. 자미두수 UI 노출 X (kIsZiweiUiHidden=true)

## NON-GOAL (이 라운드 안 하는 것 — 12)

- 자미두수 UI 노출
- 새 기능 (구독/결제/Firebase/RevenueCat)
- TestFlight 배포 (sprint 10 사용자 mandate 후만)
- R72~R77 캐릭터 영역 폴라리티 정정 (life_stage/sipsin_persona/additional_life/career/wealth — 별도 라운드)
- 만세력 algorithmic 깊은 fix (R81 D1/D3/D4)
- paywall 28 ARB / compat/datePick 77 ARB 재활성
- R78 잔여 hotspot H3/H6/H8/H13/H14

## Deferred (사용자 mandate 후만 재개)

- R81 D1/D3/D4 (만세력 KASI cross-check / 시간 picker UX / H1 swap)
- R77 paywall 28 ARB / compat·datePick 77 ARB
- R78 polarity_audit 캐릭터 영역 (hedge 98 / ai-slop 5 / 흉 39 % / 길 26 %)

## 다음 세션 trigger

- "이어서" / "체크해줘" → git pull + memory R82 read + sprint 2 시작 (#4 fix)
- "Sprint 2" / "다음 sprint" → R82 sprint 2 진행
- "테스트플라이트에 반영" / "배포해" → **sprint 10 사용자 mandate** = 9 sprint 완료 후만. 현재 sprint 1 만 끝났으므로 안내 후 STOP.

## 참고

- [`docs/round82_spec.md`](../../seephone/pillarseer/docs/round82_spec.md) — 신규 475 line
- [`인수인계.md`](../../seephone/pillarseer/인수인계.md) line 8~70 R82 섹션
- [[project_pillarseer_round_80]] / [[project_pillarseer_round_79]] / [[feedback_harness_pattern]]
