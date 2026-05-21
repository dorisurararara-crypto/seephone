---
name: pillarseer-round-107
description: "R107 사주 정확도 audit 라운드 — codex 전수감사 6.4→9.94 PASS(2026-05-21). 9개 사주 기능 중복·대충·잘못 일소. commit 3e525a7, 미배포 — 사용자 '출시' 대기, ship 시 1.0.0+72."
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
main HEAD `11ed260`, pubspec `1.0.0+71`(미bump). **미배포** — 사용자 "출시" 시 ship: 1.0.0+72, round82 version pin +72 동기화 필수, `submit_b72.rb` 작성, deploy_testflight.sh 72.

## 차기 후보
최애의 사주 셀럽 출생일 외부 1차 출처(공식 프로필/소속사) 다양화 — web research 데이터 라운드.
