---
name: pillarseer-round-107
description: "R107 사주 정확도 audit 라운드 — codex 6.4→9.94 PASS + 영어 갭 보강. 1.0.0+72 배포 완료(2026-05-21, commit 19fb185), ganzitester Beta Review 제출. 1484/1484 test PASS."
metadata:
  node_type: memory
  type: project
---

# pillarseer Round 107 — 사주 정확도 audit

**"이어서" 복원 ground truth.** R106 후속. 사용자 mandate: "내 사주 카테고리들이 다 중복된다(계속 '단정하고 세련된 손길'). 각 운은 다르게 봐야 하는 거 아니냐. 앱 모든 사주 기능 중 대충 보거나 잘못 보는 데 있나 전수로 봐라. 1~9 다 자율로 codex 9.9까지."

## 결과
codex 전수 audit **6.4 → 9.94/10 PASS** (3차 재검수). 9개 기능 전부 9.9~10.0.
`flutter test` **1459/1459 PASS**, `flutter analyze lib/` 0. 5행 골든(1995-10-27 男 17시 辛卯 16/21/17/41/4) 보존. commit `3e525a7`.

## 9개 기능 수정 내역
1. **내 사주(평생) 4.0→9.9** — `life_paragraphs.json` 60일주×17카테고리 동일 frame 도입 scaffold 제거(1200본문) + `innate_tendency` 잔여 scaffold 59건 + 중반 boilerplate(54회→6회) 정리. 카테고리 실내용 보존.
2. **K-pop 궁합 5.5→9.95** — `kpop_compat_screen._starToSajuResult` 가짜 pillar copy 제거 → `CelebChartValidator` 로 셀럽 출생일→실제 年月日 3주 계산. 時柱 null.
3. **알림 6.0→9.95** — 사주 있으면 mystery/deep(실제 일진 계산) 기본, `pickFor` 기본풀 last-resort. 기본풀 200 entry 단정→조건형.
4. **오늘의 사주 7.5→9.95** — `today_v5_pool` 변주 3→6(240 fragment), `today_event_service` 월지(userMonthBranch) 합충 wire(signature 불변).
5. **궁합 6.5→9.9** — `compatibility_screen` 년·월·시주 합충 보조 anchor(`_secondaryPillarAnchor`). 시주는 양쪽 출생시 있을 때만.
6. **신년운세 6.5→9.95** — 고정 "정재보다 편재" 제거 → `wealthShape(ctx)` 정재/편재 5분기.
7. **음악 처방 6.5→9.95** — "100% 충전" 단정 제거 → 조건형 + 셀럽 일주 근거.
8. **최애의 사주 7.0→9.95** — 셀럽 30명 `chartValidation` 추가(validator 3시각 재계산 일치). 단 출생일 외부 1차 출처 다양화 = 별도 web research 라운드(미반영).
9. **전생/엔진 7.0→9.95/10.0** — 전생 keyword 0매칭 시 `hap` 가짜 fallback 제거 → `neutral` 경로. 음력 변환 실패 `SajuResult.lunarConversionFailed` 로 전파 + result 화면 경고 배너(한/영). 엔진 계산 알고리즘 불변.

## codex goalpost 주의
R106 과 달리 R107 은 정확도/중복 audit(codex 강점) — goalpost 없이 3차에 9.94 수렴. 신규 test: r107_life_paragraph_dedup / r107_kpop_celeb_pillar / r107_notification / r107_today_v5 / r107_compat_full_pillar / r107_newyear_music / r107_past_life_fallback / r107_lunar_fail_surface / r107_celeb_chart_validation.

## R107 영어 갭 보강 (2026-05-21, 사용자 "영어도해")
- 영어 My Saju: `kLifeCategoryBodyEn` 17 generic → `kLifeCategoryBodyEnByStem` 일간 10×17=170 개인화 본문. service `categoryBodyEnFor(saju)` 일간 lookup.
- 영어 today_v5: `today_v5_pool.json` 영어 변주(`*En` 키) + `TodayV5Service.build(useKo)` + 위젯 useKo 분기. today_v5 가 영어 모드에도 동작.
- 1484/1484 test PASS. commit `11ed260`.

## 현재 working tree
main HEAD `19fb185`(R107 ship 1.0.0+72), pubspec `1.0.0+72` committed. **배포 완료** — build 72 ASC VALID → ganzitester 외부 베타 Beta Review 제출. Public link testflight.apple.com/join/kRs36R3b. submit script `submit_b72.rb`.

## ⭐ 다음 세션 작업 큐 (2026-05-21 사용자 지정 — "이어서" 시 이것부터)

사용자가 실기기 스크린샷 보고 **4건** 지정. "다음 세션에서 작업할거야."

### ⚠️ 실행 워크플로 (사용자 mandate — 4건 전부 이 방식으로)
**"하나 할 때마다 완성된 예시를 먼저 보여주고, 사용자가 승인하면 그때 전체 진행."**
- 각 작업 항목(①②③④) 착수 시 → 먼저 **완성형 샘플 1개**(예: 카테고리 1개 재작성본, 알림 슬롯 1개, 스토리 arc 1개)를 사용자에게 보여준다.
- 사용자 승인 받기 전엔 전체(나머지 60일주/17카테고리/9 arc 등) 진행 X.
- 승인 후 그 검증된 형식으로 전체 확장.
- 자율로 다 만들어놓고 던지지 말 것 — 매 항목 샘플→승인→확장.

### 작은 거 — Today 영어 모드 한글 누락 (오늘의 행운 / 점)
영어 모드 Today 화면인데 아직 한글이 샌다:
- `lib/screens/home_screen.dart:2149` `'오늘의 행운'` 섹션 제목 — hardcoded 한국어, useKo 분기 없음 → `"Today's Fortune"` 류.
- `home_screen.dart:2159` `'하나 눌러 봐 — 왜 너한테 행운인지 알려줄게'` 부제 — hardcoded 한국어 → 영어.
- `home_screen.dart:~668` 점수 `"53점 / 100"` 의 `점` — 영어 모드엔 `점` 빼고 `"53 / 100"` 류.
- `lib/services/lucky_chips_service.dart` — 6칩(색/숫자/방향/음식/사람띠/물건) **라벨·값·"왜 행운인지" popup 본문 전부 한국어 only**. 영어 carrier 추가 + useKo 분기 필요. (R106 P5 가 home Today 라벨 일부만, 이 LuckyChips 블록 누락.)
→ 캡처 증거: 칩이 `색·검정색 / 숫자·1 / 방향·북쪽 / 음식·생선 미역국 / 사람띠·돼지띠 또는 최씨 / 물건·물병` 전부 한글.

### 큰 거 — 전생 악연/인연 스토리 재작성 (사용자 직접 주도)
사용자: "전생에 악연 인연 스토리가 너무 재미없어서 직접 하나하나 다 스토리를 만들거야."
- 현재 `assets/data/past_life_pool.json` `story_arcs` **9개**(+ `story_arcs_en` 9개) — R104 keyword×storyArc. 사용자가 재미없다고 판단.
- 다음 세션 = 사용자가 스토리를 하나씩 직접 만든다. main Claude 는 현재 9 arc 를 보여주고, 사용자 구술/지시를 받아 `past_life_pool.json` 에 반영 + `past_life_service` 정합 + 영어판. **사용자 주도 — Claude 가 멋대로 창작 X, 사용자 스토리를 받아 적고 다듬는 역할.**

### ⭐ 큰 거 ③ — 내 사주 큰그림+17카테고리+오늘탭 전부 my_saju_v5 hero 스타일로 재작성 (KO+EN)
사용자 verbatim: "이 부분처럼 나머지 내 사주도 고쳐줘. 내 사주 큰그림, 초년운~재테크비법까지 나랑 잘 안 맞는 느낌. 사진처럼 — 신금은 잘 안 구부러져서 힘들어도 티를 안 낸다 — 이렇게 알기 쉽게 해석한 것처럼 바꿔줘. 오늘 탭도 전부 그런 식으로. 영어 한글 둘 다."
- **스타일 기준(레퍼런스) = `my_saju_v5` hero** (R106 P3, `lib/services/my_saju_v5_service.dart` + `assets/data/my_saju_v5_pool.json` + `widgets/my_saju_v5_section.dart`). 스크린샷의 "당신을 한 글자로 보면 辛金 — 잘 벼려진 칼이나 보석... 무른 쇳덩이가 아니라 이미 모양이 잡힌 금속이라 기준이 뚜렷하고... 잘 안 휘는 대신 잘 안 구부러져서 힘들어도 티를 안 내고 혼자 너무 오래 버티다 확 터진다" — **실제 사주(일간 오행·일지·십신·격국·용신)를 구체적·비유적·알기 쉬운 말로 풀이.** 추상어 X.
- **재작성 대상**:
  - 내 사주 큰그림(LIFE OVERVIEW) = `life_overview_service.dart` `compose`/`composeEn` — anchor 6 조합 essay 를 my_saju_v5 톤으로.
  - 초년운~재테크 17 카테고리 = `life_paragraph_service.dart` + `assets/data/life_paragraphs.json`(KO 70키) + `kLifeCategoryBodyEnByStem`(EN 일간10×17, R107 신규) — 전부 my_saju_v5 톤으로. R107 #1 이 중복 scaffold 만 제거했고 톤 업그레이드는 아직.
  - 오늘 탭 전부 = `today_v5_service`/`today_v5_pool.json` + `today_deep_service` + 관련. 오늘 풀이도 같은 톤.
- KO + EN 둘 다. 거짓말·창작 0(엔진 계산값 기반), v5 voice(단정 금지) 유지하되 **비유·구체성으로 알기 쉽게**. 회귀 가드(5행 골든·R69·R88·R107) 보존.
- 규모 큼 — my_saju_v5 pool 구조를 다른 영역에도 확장하거나, 각 service 의 anchor 카피를 my_saju_v5 수준으로 재작성. codex QA.

### ⭐ 큰 거 ④ — 알림 하루 여러 번 (오전 사주 / 오후 사주) + vivid 톤
사용자: "알림 시간을 한 번이 아니라 하루 중 몇 번 할 수 있게. 오전 사주 / 오후 사주 이런 느낌으로. 알림 내용도 ③처럼 알기 쉽게 해석."
- 현재 `notification_service` = R76 hh:mm picker, **하루 1회**. → 하루 복수 슬롯(오전/오후/저녁 등) 설정 + 각 슬롯별 다른 사주 풀이.
- 알림 카피도 ③의 my_saju_v5 vivid·accessible 톤 (현재 R106 P2b 미스터리형 + R107 deep — 톤 점검).
- settings 알림 UI(시간 picker)를 복수 슬롯 지원으로 확장. KO+EN.

## 차기 후보
최애의 사주 셀럽 출생일 외부 1차 출처(공식 프로필/소속사) 다양화 — web research 데이터 라운드.
