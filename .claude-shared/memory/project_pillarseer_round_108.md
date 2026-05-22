---
name: pillarseer-round-108
description: "R108 — Today 영어갭 + 내사주/오늘탭 my_saju_v5 톤 + 알림 복수슬롯 + 전생 66편 장편화. ①②③④ 완료, 1543 test PASS. 1.0.0+73 배포 완료(2026-05-22) — ganzitester Beta Review 제출."
metadata: 
  node_type: memory
  type: project
  originSessionId: 69637c57-c2c9-491f-94d8-6abaa0cc02e9
---

# pillarseer Round 108 — v5 톤 확산 + 알림 슬롯 + 전생 팬픽

**"이어서" 복원 ground truth.** R107 작업 큐(`project_pillarseer_round_107.md`) 4건 + ③ 3분할 = 6 sub-item. 워크플로 mandate: **항목마다 완성 샘플 먼저 → 사용자 승인 → 전체 확장.**

## 진행 상태 (2026-05-22)

| | 항목 | 상태 |
|---|---|---|
| ① | Today 영어 한글누락 (lucky chips EN) | ✅ 완료 — **uncommitted** |
| ③-1 | 내 사주 큰그림 LIFE OVERVIEW my_saju_v5 톤 | ✅ 완료 — **uncommitted** |
| ③-2 | 17카테고리 1400+170 본문 v5 톤 | ✅ commit `aa07272`/`8eaaf5d` (codex 9.92) |
| ③-3 | today_deep_service v5 톤 | ✅ commit `9db0ff5` (codex 9.96) |
| ④ | 알림 복수 슬롯 (아침/오후/저녁) | ✅ commit `53a1053`/`06506a9` (codex 9.92) |
| ② | 전생 스토리 팬픽 장편화 | ✅ 완료 — KO 66편 + EN 66편 longform (commit 47a8753~c3cec70) |

`flutter test` **1543/1543 PASS**, `flutter analyze lib/` 0. 5행 골든 1995-10-27 男 辛卯 16/21/17/41/4 보존. **R108 ①②③④ 전 항목 완료.**

## ② 완료 내역 (2026-05-22)
전생 66 arc 전부 인터넷소설 장편으로 재작성 — KO 66편 + EN 66편, 각 `format:"longform"` + 5~7 챕터 + epilogue (편당 7,000~9,500자). harness 10 sprint (Sprint 0 인프라 → 1~8 관계별 KO 집필 → 9 EN 66편). 9관계(dohwa/wonjin/hap/chung/cheoneul/hyeong/yeokma/gongmang/neutral) 시대·장르 전부 unique. codex QA 각 sprint (goalpost drift 거부, TRUE hard violation 0 수렴). 구 slot 스키마(`paragraphs`/`_composeFromPool`)는 fallback 으로 보존(합성 test 로 검증) — Sprint 10 죽은코드 제거는 회귀 위험 대비 가치 낮아 미실행. 설계 = `docs/operating_memory/r108_past_life_design.md`. past_life commit: 47a8753(인프라) 3844f9a 9b3f02e 3741501 23120c0 fdc1e9a 2fc9d99 ad2f45f f36151b(KO) a101fcc 7aaf78d 8069065 6a07309 3fc79cd c3cec70(EN) + 회귀 test 마이그레이션.

### 미커밋 (사용자 "계속 두기" mandate)
`lib/screens/home_screen.dart`(① lucky chips useKo 분기), `lib/services/lucky_chips_service.dart`(① EN carrier), `lib/services/life_overview_service.dart`(③-1), `test/r108_lucky_chips_english_test.dart`(① 신규 test) — 4개 파일 uncommitted. ④ generator 가 home_screen 0 diff 로 처리해 ① 변경 안 섞임. ship/commit 시 함께.

## ① 완료 내역
`lucky_chips_service.dart` `LuckyChip` 에 `categoryEn`/`valueEn`/`reasonEn` 추가, 6칩 영어 carrier(`_stemEn`/`_elEn`, 음식명 영어 의역, 성씨 `surname Kim`). `home_screen.dart` `_LuckyChipsCard`/`_LuckyChipButton` useKo 분기 — `Today's Lucky Picks`/`Why is this lucky?`/`Close`, 점수 `53점→53`. test `r108_lucky_chips_english_test.dart` (한글 leak 가드).

## ③ 완료 내역 — my_saju_v5 메타포 톤 (gold standard = `my_saju_v5_pool.json`)
- ③-1 `life_overview_service.dart` anchor 맵 전수 재작성 (KO `_stemPersona` 등 + EN). "결" jargon·모순 padding·fragment-pad block 제거. 한자 leak 0 가드(B6b/B8b) 때문에 한글만(메타포). 골든 ess4 639자.
- ③-2 `life_paragraphs.json` 70키×17 = 1400 한국어 + `kLifeCategoryBodyEnByStem` 170 영어. harness 7 sprint. boilerplate("취향이 또렷해서" 12회 등) 0. 신묘 일주에 사용자 verbatim "단단한 대신 잘 안 구부러져서 힘들어도 티를 안 내고 혼자 너무 오래 버틴다" 반영.
- ③-3 `today_deep_service.dart` 본문 풀 전체 — headline 메타("총평")·"~날" 헤드라인체 제거, 일간 비유 anchor, 발동조건형. harness 1 sprint codex 9.96.

## ④ 완료 내역 — 알림 복수 슬롯
하루 1회 → 아침/오후/저녁 **3 고정 슬롯** {enabled,hour,minute}. 마스터 토글 + 슬롯별. 마이그레이션(기존 daily.hour→아침). ID `_kDailyId+slotIdx*32+dayOffset` 96개. 슬롯별 `SlotFrame`(미리보기/변화/마무리) 카피. `_kMysteryAlgoVersion` v2→v3. settings `_NotifSlotsSection` 3행 UI. test `r108_notification_slots_test.dart`.

## ② 전생 스토리 — 진행 중 (다음 작업)
사용자 mandate: "지금 전생 스토리 유치하고 내용 없다. **긴 소설**로, **팬픽인데 장르 다양하게**, 최소 **20-30분** 분량(현재 10배+), **늑대의 유혹·그놈은 멋있었다** 식 인터넷소설 느낌." 워크플로 = "방향만 주면 Claude 가 초안, 사용자 검토."

### 승인된 것
- **샘플 톤 승인**: 「경성 1929 — 그해 겨울의 모던보이」(도화/로맨스, 경성 모던보이 인터넷소설 톤, $userName/$celebName 변수). 사용자 "승인 — 이 톤으로".
- **구조 결정 (사용자 최종)**: 처음엔 12~15편 압축 제안했으나 사용자가 번복 → **66편 전부** 장편화. "내가 생각해보니까 66편 만드는게 좋을거 같아." 현 66 arc(9관계×8, neutral 2) 슬롯을 각각 20-30분 인터넷소설 장편으로. 같은 관계 8편도 장르·배경 다양하게(사용자 "장르 다양하게").

### ② 완료 — 위 "## ② 완료 내역" 참조. KO 66 + EN 66 longform, 1543 test PASS.

## 배포 완료 — 1.0.0+73 (2026-05-22)
사용자 "출시" → ship 완료. ①+③-1 commit `b5b23b5`, release commit `5745535`(pubspec 1.0.0+73 + round82 pin). `scripts/deploy_testflight.sh 73` → IPA 25M altool UPLOAD SUCCEEDED → build #73 ASC **VALID** → `scripts/submit_b73.rb`: whatsNew ko/en PATCH 200 → 외부 그룹 ganzitester 할당 HTTP 204 → Beta Review 제출 완료. Public link `testflight.apple.com/join/kRs36R3b`.

## R109 — 사용자 버그픽스 2건 (2026-05-22) — 1.0.0+74 배포 완료
1.0.0+73 배포 후 사용자 지정 2건. **1.0.0+74 배포 완료** — build #74 ASC VALID → ganzitester 외부 베타 Beta Review 제출. release commit `5745535` 다음 → R109 release commit, `submit_b74.rb`.
- **FIX 1 알림 톤 제거** (commit `aca6145`): 설정의 "어른/중·고생 톤"(`NotificationTone` adult/mz)은 R106 미스터리 알림 도입 후 死기능 — settings UI·`notification_provider` tone state·`setTone`·`_kPrefsTone`·`notification_service`/`notification_pool_service` tone 분기·`_koPoolMz`/`_enPoolMz` 100 entry·l10n 4키 전수 제거.
- **FIX 2 탭 스크롤 보존** (commit `7f9bd8b` + 후속 `052c609`): 하단 4탭(홈/내사주/리포트/프로필) `context.go` 라우트 교체 → 탭 복귀 시 스크롤 리셋. `router.dart` 를 `StatefulShellRoute.indexedStack` 4 branch 로 전환 — IndexedStack 이 branch State 살려둬 탭 전환·복귀 시 스크롤·상태 보존. `bottom_nav.dart` `PillarBottomNav` 는 `StatefulNavigationShell`/`goBranch` 모델. 후속 052c609 = shell 밖 push 화면(리포트 상세 9 + discover)이 하단 탭 잃은 것 → `PillarBottomNavStatic`(context.go 기반 정적 탭) 추가해 복원.
- 1552/1552 test PASS, analyze 0. test `r109_tab_scroll_preserve_test.dart` 신규.

## 다음 세션 protocol
**R108 ①②③④ + R109 버그픽스 2건 전부 배포 완료. 현재 TestFlight = 1.0.0+74.** "이어서" → 새 작업 대기.
- ⚠️ round82 version pin: `test/round82_version_display_test.dart` L100 이 pubspec version 하드코딩(현 +74) — 다음 ship 마다 같이 수정.
- ship 패턴: pubspec bump → round82 pin → flutter test → release commit → `scripts/submit_b<N>.rb` 작성 → `bash scripts/deploy_testflight.sh <N>` → ASC VALID 폴링 → submit script 실행 → commit·push. ASC App ID `6768096855` / 외부 그룹 `3217ce1c-29ca-4946-a26a-0c55529172a3`.
- ⚠️ round82 version pin: `test/round82_version_display_test.dart` 가 pubspec version(현 +73) 하드코딩 핀 — 다음 ship 마다 같이 수정.
- pillarseer ASC App ID `6768096855` / 외부 그룹 ganzitester `3217ce1c-29ca-4946-a26a-0c55529172a3` / submit 패턴 `scripts/submit_b<N>.rb`.
