---
name: project_pillarseer_round_75
description: pillarseer Round 75 — 5행 가중치 calibration (金 41% 1등 사이트 골든) + 십신 음양 10분류 + TestFlight 1.0.0+36
metadata: 
  node_type: memory
  type: project
  date: 2026-05-14
  originSessionId: bd822aa5-cb36-4cc4-bc81-10bcead64b89
---

## Round 75 — 1등 만세력 사이트 골든 일치 + 십신 10분류

### 무엇 / 왜
사용자 1.0.0+35 실기기 테스트 중 한국 1등 만세력 사이트 비교 결과:
- "金이 압도적으로 높았어야 하는데 우리는 24/24/17/25/11 평탄" mandate
- 1995-10-27 15:43 男 (辛 일간) → 1등 사이트 = 木16 火21 土17 金41 水4 % (金 압도적)

codex 가 자체 수정 base 두고 implementer 가 review + 보완:
- 가중치 calibration (월령 ×3.0 / 통근 보너스 / 정록 보너스 / pillar 위치 가중)
- 십신 매핑 일간 기준 동적 (5분류)
- 의료 권고 톤 정리

implementer 가 추가:
- 십신 음양 분리 10분류 (비견/겁재/식신/상관/정재/편재/정관/편관/정인/편인)
- 한자 jargon 제거 (사용자 노출 比肩/劫財 류 0)
- exact lock 골든 + 과적합 방지 회귀 (IU/Karina)

### 검증 결과
- flutter analyze 0
- flutter test 368/368 PASS
- polarity audit hedge 0 / slop 0 / 43:32:8:16 / 행동 23% / 양면 56% (Round 74 baseline 유지)
- 1995-10-27 골든: 16/21/17/41/4 정확 일치 (mandate)
- codex audit:
  - sprint 1: 9.92 (A 9.95 / B 9.92 / C 9.9 / D 9.9)
  - sprint 2: 10.0 (전 dimension 만점)

### 핵심 파일
- `lib/services/manseryeok_service.dart` — 가중치 상수 + _calculateElements
- `lib/services/thong_geun_service.dart` — 지장간 ratio 0.7/0.2/0.1
- `lib/services/deep_content_service.dart` — _tenGodKey 음양 10분류 + 톤
- `lib/services/saju_service.dart` — allStems wiring
- `test/round72_zijang_monthboost_test.dart` — 골든 + 과적합 회귀
- `test/round75_ten_god_test.dart` — 10분류 mapping + 한자 leak 검증

### 다음
- 1.0.0+36 ASC 처리 polling → ganzitester 외부 베타 ko+en whatsNew 자동 제출
- 사용자 실기기 1995-10-27 사례 검증 (5행 16/21/17/41/4 노출 확인)
- 다음 라운드: 정관/편관 등 dominant 외 십신 멘트도 살릴지, 또는 lucky chip 톤 추가 정리

### Trap / 학습
- codex 자기 수정 self-audit 회피 — sprint 4 별도 codex audit 으로 객관 비판 (한자 jargon · range 느슨 · 십신 5분류 한정 등 6 issue 찾음)
- 지장간 ratio 0.6/0.3/0.1 → 0.7/0.2/0.1 변경 시 첫 sanity test (round72 line 33) 와 충돌. test 갱신 우선
- 본기 강화 = 1등 사이트 패턴 (金 본기 庚이 申 지지에서 더 또렷이 dominant 매김)
- 일간 음양 + 같은 5행 천간 음양 다수 비교 tie 규칙: 일간 자체 자동 포함 → sameYinYang 우세 자연스러움
