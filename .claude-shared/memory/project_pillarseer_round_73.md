---
name: project_pillarseer_round_73
description: pillarseer Round 73 — 운세의신 수준 정확도 + 영문 leak fix + TestFlight 1.0.0+34
metadata: 
  node_type: memory
  date: 2026-05-14
  type: project
  originSessionId: 1fe486a1-9e39-46e8-93d7-a481cdd102ae
---

## 무엇
사용자가 운세의신 (한국 1위 사주 사이트, unsin.co.kr, 스포츠조선 운영) 보고 "되게 잘 맞는다" — 우리 앱은 "성격 잘 안 맞는다" 했음. 정확도 차이의 본질 분석 후 흡수.

## 왜
운세의신 정확도 비결 = **8글자 십신 풀이** + 라이프스테이지 분리 + 양면 단정 + 17 세분 섹션 + 폴라리티 5:4:1 + 행동 처방 20%. 우리 앱은 60갑자 일주만 사용, TenGodsService 콘텐츠 사용 빈도 2회, DaewoonService wire 0 = 라이프스테이지 갭 80%, 영문 모드 6 source 한글 leak.

## 검증 결과
- /harness 패턴: planner (Opus) → 진단 sub-agent (codex 9.6, 4 dim hard 통과) → 운세의신 deep analysis (codex 9.97 PASS) → generator (Opus, 76분) → codex 9.9+
- generator: 6 sprint × 평균 codex **9.93** (Sprint 1 9.97 / 2 9.90 / 3 9.90 / 4 9.96 / 5 9.97 / 6 9.90)
- 17 audit rounds, avg 2.83 round/sprint
- flutter analyze: 0 error
- flutter test: **363/363 PASS** (신규 20 + 기존 343)
- polarity_audit: 264 entry — hedge 0 / slop 0 / 폴라리티 43:32:8 (target 5:4:1 ±1) / 행동 23% / 양면 56%

## 핵심 산출물
- `lib/services/life_stage_service.dart` 신규 — DaewoonService wire (0 → 1)
- `lib/services/sipsin_persona_service.dart` 신규 — 8글자 십신 풀이
- `lib/services/career_recommend_service.dart` 신규 — 직업 추천
- `lib/services/wealth_strategy_service.dart` 신규 — 재테크 3 phase
- `lib/services/additional_life_service.dart` 신규 — 사회/체질/성격 등 보조
- `assets/data/life_stage_pool.json` 60 entry
- `assets/data/sipsin_persona.json` 120 entry
- `assets/data/career_pool.json` 30 entry
- `assets/data/wealth_detail.json` 8×3 entry
- `assets/data/additional_life_pool.json` 30 entry
- `tool/tone/polarity_audit.py` 신규
- `lib/screens/result_screen.dart` 17 섹션 재구성
- 영문 leak 6 source fix: `_SixAxisCard / _FiveDayTrendCard / _MatchBadge / SixAxisScore.axes / FiveDayTrend.labels / CrossMatch+_CrossmatchSection` (CrossMatch 14 case × 4 필드 = 56 string)

## Commits (6개, Round 73)
`b78ec49` → `05fff66` → `ec49856` → `63baa3c` → `4990bed` → `566d08c`

## TestFlight
- **1.0.0+34** 배포 완료 (사용자 명시: "이미 승인된 marketing 1.0.0 위에 build bump → 심사 빠름")
- Public link: https://testflight.apple.com/join/kRs36R3b
- 외부 그룹: ganzitester
- Beta Review 제출 ✅
- whatsNew ko/en-US 등록 (538/591 chars)
- ASC 상태 확인: marketing 1.0.0 = production 출시 / 1.0.1 build 30 / 1.0.2 builds 31~33 심사 중

## 트랩 / 교훈
- ASC `betaBuildLocalizations` whatsNew PATCH: 1009~1205자 → HTTP 409. ~500자 안에서 200 OK. 다음 빌드부터 release note 길이 한도 둘 것.
- `flutter build ipa` export 단계 fail 정상 — script `|| true` 처리, `xcodebuild -exportArchive` 가 ASC API key 로 cert 즉석 발급 (reference_xcodebuild_signing.md 패턴)
- altool 의 Delivery UUID 가 ASC build id 와 같은 경우도 있음 (`889ff91e-dbbf-...`)

## 1995-10-27 신묘 일주 검증
- 운세의신 본문: 정관×2 (명예/도덕) + 편재 (외부 재물) + 정인+상관 (박식/입담) → "언론인·기고가·영화인 적합"
- 우리 앱 Round 73 결과: 정인+상관 → 언론인/기고가/작가/방송 PD 매칭 ✅

## 차별점 유지 (운세의신 X — 우리 우위)
- 자미두수 (Round 70 숨김 유지, kIsZiweiUiHidden=true)
- 60갑자 (운세의신은 12 띠 cohort 4구간만)
- 무료 사주 today (운세의신은 무료에 띠별 only)
- 6각 radar 카테고리 라벨
- _OracleHero first-fold (Round 71)
- 지장간 비율 + 월령 ×2.5 (Round 72)

## 다음
- 사용자 실기기 테스트 (TestFlight 심사 통과 후, 보통 1.0.0 marketing 이라 24h 내)
- 결과 보고 후 결정 — 더 정확도 ↑ 시도 / 출시 production

[[project_pillarseer_round_72]] 다음 라운드. [[feedback_harness_pattern]] 5번째 검증 사례.
