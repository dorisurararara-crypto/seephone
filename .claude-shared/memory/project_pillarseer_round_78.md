# pillarseer Round 78 — 하드코딩 일소 + 운세의신 2차 deep analysis (미배포)

> 2026-05-14 / 8 sprint harness × codex 9.93 avg / 495/495 test / 5행 골든 보존

## 핵심 한 줄
R71~R77 누적 위에 **Task A (사주 결과 13 hotspot 동적화)** + **Task B (운세의신 V1~V8 2차 deep analysis)** 추가. SajuContext 합성 → DynamicTextResolver 4단계 chain → today_deep/today_event/home/new_year body 모두 사주 derive. **사용자 mandate 준수 배포 X.**

## Sprint 결과 (8 sprint)
- Sprint 0: chore baseline (R77 잔류 정리 + gitignore 보강) — commit e8e74f3
- Sprint 1: SajuContext 합성 — PASS 9.95 (A 10.0/B 9.8/C 10.0/D 10.0) — commit 86cc6e9
- Sprint 2: 운세의신 V1~V8 deep analysis (297 lines docs) — PASS 9.95 — commit 0bc42fd
- Sprint 3: DynamicTextResolver + H1 _OracleHero — PASS 9.9 — commit 9a15efb
- Sprint 4: today_deep ctx 격국·용신 derive — PASS 9.9 — commit 86e94df
- Sprint 5: 용신 5축 행동 처방 (25 entry) — PASS 9.95 — commit 9f31100
- Sprint 6: 합/충/형/파/해 + 신살 24 + 공망 wire — PASS 9.92 — commit ad7af3c
- Sprint 7: 대운·신년 12달 동적화 — PASS 9.93 — commit 27af746
- Sprint 8: cleanup + 회귀 가드 + memory + 인수인계 — (본 commit)

평균 codex score: 9.93 / 7 codex 평가 sprint

## 변경 인프라

### Task A 하드코딩 일소
- **SajuContext** (`lib/services/saju_context.dart` 신규) — 사주 컨텍스트 1차 source-of-truth (일간/오행%/십신 freq/격국/용신/기신/신살/공망/대운/일진/관계)
- **DynamicTextResolver** (`lib/services/dynamic_text_resolver.dart` 신규) — 4단계 priority chain (정확 → 부분 → ctx suffix → static fallback) + requires whitelist (ArgumentError release 가드)
- **H1 _OracleHero** (home_screen) — ctx 주입 + _ctxEntries 2 entry (정관격 × 용신 木/火)
- **H2 _godPhraseKoByEnergy + H4 headline + H5 십신 본문** (today_deep_service) — ctx 기반 격국 anchor + 용신 5축 + 대운 십신 anchor body 합성
- **H7 _moodsKo/En** (new_year_2026_screen) — public moodFor 위임, 격국 anchor + 용신 suffix append
- **H9 _actionForGodKo / H10 _cautionKo** (today_deep_service) — ctx 5축 1줄 + 공망 caution wire

### Task B 운세의신 2차 분석 + 도입
- **V1 격국·십신·용신 결합** → DynamicTextResolver.gyeokgukAnchor (8 격국 ko/en) + today_deep body 합성
- **V2 용신 5축** → YongsinService.guideAxesKo/En (25 entry) + oneAxisLineKo/En + today_deep actions 5축 1줄
- **V3 대운 단계** → today_deep _daewoonAnchor (10 십신 ko/en) + ctx.currentDaewoonGod wire
- **V4 합·충·형·파·해** → today_event_pool.hapchung 36 key (5 지지 관계 × 6 카테고리 + 천간합 6 카테고리)
- **V5 신살 24 key** → today_event_pool.shinsa 8 → 24 (R76 8 + 12신살 6 + 별칭 2)
- **V6 신년 12달 격국·용신** → new_year_2026 절기 라벨 + 격국 anchor + 용신 suffix
- **V7 톤 가드** → 폐기 phrase 7종 명시 ("본인의 결" / "흐름이" 단독 / "센터처럼" / "K팝 센터처럼" / "리텐션" / "퍼포먼스" / "PT")
- **V8 공망 wire** → today_deep caution + gongMangAreas wire

### Round 78 신규 신살 emit (today_event_service _activeShinsa 확장)
- _twelveShinsaFor — 9 살 정통 표 (겁살·재살·천살·지살·월살·망신·장성·반안·육해)
- _gongmangBranches — 60갑자 일주 → 공망 2 지지

### Anchor 우선순위 (composeBodyKoWithAnchor)
1. 핵심 9 신살 (천을귀인·도화·역마·문창귀인·양인·괴강·백호·화개·공망) only
2. 천간합 anchor (userDayStem + todayStem 매칭 시)
3. 지지 hapchung anchor (합/충/형/파/해 + 카테고리)
- 12 신살 (겁살·재살·월살 등) 은 항상 1 hit 이라 anchor 단계 1 에서 제외 → 천간합/지지 우선순위 안정

### Hot path
- home_screen `_OracleHero` + `_TodayEventCard` + `_TodayDeepReadingSection` 모두 SajuContext.from(saju, today: now) 주입
- result_screen `_TodayEventCard` (today_event_detail) composeBodyKoWithAnchor wire
- new_year_2026 _MonthlyFlow.build 1회 ctx 합성 → 12 row 재사용

## 검증
- flutter analyze: **0 issue**
- flutter test: **495/495 PASS** (R77 433 + R78 신규 62 = 495)
- polarity_audit 사건 영역 (R78 신규 pool): PASS — shinsa 24 / hapchung 36 / hedge 0 미스 / 단정 예언 0
- polarity_audit 캐릭터 영역 (R72-R77 baseline): hedge 98 / ai-slop 5 / polarity 흉 39% 길 26% — **R78 미터치 영역, 별도 라운드 정정 대상**
- 1995-10-27 男 5행 골든 **16/21/17/41/4 보존** (Sprint 1 회귀 test 가드)
- restDay 금칙어 ("도전·승부·발표·공식 자리·승진") 0 회귀 (sprint 3 invariant test)
- 폐기 phrase ("본인의 결", "센터처럼", "리텐션" 등) 0 회귀

## Deferred (다음 라운드)
- H3 `personalization_engine._atoms` deprecation 또는 SajuContext field 확장
- H6 자미두수 _coreReadKo/En (UI 숨김 영역, 후순위)
- H8 notification_pool_service adult 풀 retire (pickDeep 100% 전환)
- H11 / H12 false positive (i18n / 라벨 dictionary — 가드만)
- H13 career_recommend_service fallback hit rate 강화 (격국·용신 join)
- H14 sipsin_persona_service hardcoded fallback retire
- 5행 round 합 100 보정 (R75 calibration 우선)
- paywall* 28 ARB key 재활성
- compat / datePick 77 ARB key 재활성
- **polarity_audit 캐릭터 영역 정정** — life_stage / sipsin_persona / additional_life / career / wealth 폴라리티 비율 (흉 39%/길 26% → 50:40:10 ±1) + hedge 98 / ai-slop 5 정리. R72-R77 baseline 영역, R78 미터치.

## NON-GOAL 준수
- TestFlight 배포 X (사용자 mandate)
- 시뮬·에뮬 새 부팅 X (사용자 컴퓨터 freeze 위험)
- 시크릿 commit X (ASC API key path 노출 0)
- 자미두수 UI 노출 X (kIsZiweiUiHidden=true 유지)
- Android Play Store 작업 X
- 새 백엔드 / DB / API 추가 X
- OpenAI / Anthropic API 추가 결제 X (codex CLI ChatGPT 모드만 사용)
- Apple Developer 인증 / 신규 계정 가입 X

## TestFlight 상태
**1.0.0+37 (R77 외부 베타 ganzitester 제출 진행 중)** — 사용자 검증 대기. R78 변경은 **1.0.0+38 build 미생성 / 미배포** (사용자 명시 후만).

## 다음 라운드 트리거
- "테스트플라이트에 반영" / "출시" — 1.0.0+38 build + altool + 외부 베타 자동 제출
- "버그 있어" / "이거 이상해" — 사용자 실기기 발견 이슈 Round 79
- "다음 라운드" — Deferred 항목 (H3/H6/H8/H13/H14/paywall/compat/**polarity 캐릭터 영역 정정**) 선택

## ground truth
- spec: `/tmp/plan_pillarseer_round_78.md`
- docs: `pillarseer/docs/unsin_analysis_v2.md`
- 인수인계: `pillarseer/인수인계.md`
