---
name: project_pillarseer_round_76
description: pillarseer Round 76 — 알림 시간 사용자 설정 + 오늘 사건 가능성 엔진 + 콘텐츠 풀 + UI + 사주 wire (배포 X)
type: project
date: 2026-05-14
---

# pillarseer Round 76 — "오늘 너에게 생길 수 있는 일" + 알림 시간 자율 설정

## 무엇

Round 71-75 운세의신 수준 위에 **최종 출시 hook 두 개** 추가 (7 sprint × codex 9.9+ PASS):

1. **알림 시간 사용자 설정** — 매일 8시 고정 → 사용자가 hh:mm 선택. settings_screen 에 `_NotifTimePicker` (showTimePicker) 신규. SharedPreferences `app.notif.daily.hour/minute` 영속.
2. **오늘 사건 가능성 엔진** — 사용자 일간 × 오늘 일진 → 십신 그룹 + 신살 + 합/충/형/파/해 → 6 카테고리 (relationship/money/work/love/health/luck) 점수 + dominant/sub + 별점 4. home_screen first-fold 카드 + result_screen detail 섹션 (18번째).
3. **사주 기반 매일 calibrate 알림** — 30일 schedule loop 안에서 각 일자별 다른 일진 → today_event_service 본문. signature 에 saju derived key (`deep:dayPillar:monthBranch:dayMaster` 또는 `nosaju`) 포함 → fallback↔deep 전환 시 자동 reschedule.

## 왜

- 기존 `NotificationPoolService` 는 50문구 deterministic 회전 — 사주와 약하게 결합. 사용자 verbatim: "정확한 사건 예측 앱으로 만들면 허술해지고, 사주 기반 오늘의 사건 가능성 + 행동 가이드 앱으로 만들면 꽤 그럴듯하고 상품성 있어." → 사건 예측 X / **가능성 + 행동 조언 O** 정체성 확립.
- 알림 8시 고정 = 한국 사용자 일과 미스매치 (학생 6시 등교, 직장인 9시, 야간조). 사용자별 customize 가 retention 직결.
- Sprint 4 콘텐츠 풀은 사용자 verbatim 6 예시 ("장바구니에만 담아두세요" / "피로가 쌓이기 쉬워요" / "정리부터 하면 좋아요" 등) 그대로 reference 1번 entry 로 채택. 톤 정체성: "오늘 반드시 ~" X, "오늘 ~ 생기기 쉬워요" O.

## 검증 결과

| 메트릭 | 결과 |
|---|---|
| flutter analyze | **0 issue** |
| flutter test | **406/406 PASS** (393 baseline → 13 신규: notification_time 6 + today_event_service 16 + today_event_pool_lint 4 + today_event_card 9 + notification_pool_deep 3, 일부 중복) |
| polarity_audit 캐릭터 영역 | **PASS** (Round 73 baseline 264 entries / 흉 43% 길 32% 양면 8% 중립 16% / 행동 23% / 양면 anchor 56%) |
| polarity_audit 사건 영역 | **PASS** (today_event_pool.json — 90 entries / body hedge 누락 0 / 단정 예언 0 / 120자 초과 0 / shinsa 8 key) |
| codex 최저 점수 | **9.92** (Sprint 2 + Sprint 6) |
| codex 최고 점수 | **9.93** (Sprint 3 + 4 + 5) |
| codex 평균 | **9.926** |
| 사용자 mandate 침범 | 0 (배포 0, 사주 코어 변경 0, 자미두수 노출 X, 17 섹션 본체 X, _OracleHero 단정조 유지) |

## Sprint 별 요약

| # | 주제 | codex | commit | 파일 |
|---|---|---|---|---|
| 1 | inventory + spec 확정 | (audit skip — 코드 변경 0) | — | /tmp/r76_inventory.md |
| 2 | 알림 시간 설정 (scheduleDaily(hour, minute) + _NotifTimePicker) | 9.92 (A 9.9 / B 9.9 / C 9.8 / D 10.0) | 4d31c1a | 10 |
| 3 | today_event_service 엔진 (TodayEventReading + 5 그룹 × 6 카테고리 + 신살 + 합/충/형/파/해) | 9.93 (A 10.0 / B 9.8 / C 10.0 / D 9.9) | 0ee590a | 2 |
| 4 | today_event_pool.json (30 key × 3 set + shinsa 8) | 9.93 (A 9.95 / B 9.90 / C 9.90 / D 9.95) | e360437 | 2 |
| 5 | home/result UI + anchor scroll | 9.93 (A 9.95 / B 9.90 / C 9.95 / D 9.90) | 836c2d2 | 9 |
| 6 | 알림 사주 wire + signature 전환 보장 | 9.92 (A 9.9 / B 9.9 / C 9.95 / D 9.95) | c7f2013 | 7 |
| 7 | polarity_audit 영역 분리 + memory | (사용자 환경 PASS — sprint 7 commit 1) | (pending) | 3 |

## 핵심 차별점 보존

- **60일주 / 자미두수 숨김** — `kIsZiweiUiHidden=true` 유지
- **6각 radar / _OracleHero** — 첫 fold 단정 평서 유지 (사건 영역 헷지와 분리)
- **17 섹션 result_screen** — 본체 변경 0. `_TodayEventDetailSection` 은 7.5 슬롯 (FiveElementsSection 직후) append
- **Round 71 DayEnergyKind** — 단일 source-of-truth restDay/mixedDay/actionDay 호출만 (변경 X)

## 다음 작업 — 배포 (사용자 명시 후만)

사용자 명시 "TestFlight 올려" 받으면:
1. pubspec.yaml 1.0.0+36 → 1.0.0+37 bump
2. `bbaksin/scripts/deploy_testflight.sh` 패턴 — APP_ID `6764363757` (pillarseer ASC App ID — `.claude-shared/memory/reference_seephone_ids.md` 참고)
3. submit 메타 3종 — `betaAppLocalizations` + `betaAppReviewDetails` + `betaBuildLocalizations` (whatsNew: "Round 76 — 알림 시간 자율 설정 + 오늘 사건 가능성")
4. 외부 그룹 `ganzitester` 자동 할당 + Beta Review 자동 제출

**현재 = 코드만 commit, 배포 X.** 사용자 mandate "다 자동배포하지마 내가 배포하라고 할때만해" 준수.

## NON-GOAL (다음 라운드)

- `shinsa_service` 에 겁살·망신살 신규 추가 (사용자 verbatim 에 언급은 있지만 본 라운드 scope 밖)
- 알림 카테고리 다중 채널 / 시간대별 (현재 매일 1회)
- 위치 / 외부 API
- 광고 / IAP 변경
- i18n 추가 locale (ko + en 유지)
- 자미두수 UI 노출
