---
name: pillarseer-round-92-to-97-ship-log
description: pillarseer R92~R97 진행 결과 + 1.0.0+57 외부 베타 ganzitester 자동 제출 상태. R95 부터 Option A workflow (codex 두뇌 + 서브 코딩) 적용.
metadata: 
  node_type: memory
  type: project
  originSessionId: b7388865-d3ed-4b0b-8946-5130910483e5
---

## 현재 빌드 (2026-05-19 기준)

- **1.0.0+57** ASC VALID + 외부 베타 ganzitester 자동 제출 ✅
- Public link: https://testflight.apple.com/join/kRs36R3b
- pillarseer ASC App ID: **6768096855**
- 마지막 commit: `3e49eb1` (R96 sprint 1 release)
- git status clean (모든 commit push 완료)

## Round 진행 (R92 → R97)

| Round | 내용 | ship build | codex score |
|---|---|---|---|
| R92 | entry 단위 quality 정제 (천간 modifier prepend / R88 artifact / MZ inject / deep enrich) | 1.0.0+50 | 8.4 (R91 7.87 → +0.5) |
| R93 | 사용자 4 mandate (K-POP 케미 진짜 연인 톤 + 궁합 UI 키보드 + 본문 ×2 + 신년운세 _AnnualSummary 1500자) | 1.0.0+52 | 9.95 SHIP |
| R94 | 셀럽별 차별화 (birth year stem score 변별) + gender chip + 본문 ×3 + 검색 IME debounce | 1.0.0+53 | 9.95 SHIP |
| R95 | input autofocus 이름 + kpop_compat _starIdentityLead + 4 영역 중복 패턴 fix (compatibility microcopy / new_year_2026 _TwelveAreas 동적화) | 1.0.0+54 | 9.95 SHIP (Option A workflow 시작) |
| R96 | NaturalProseJoiner connector inject → 실기기 보고 "AI 같다" → 자체 철회 3~4/10 | 1.0.0+55 | **잘못된 9.9** (surface metric 만 봤음) |
| R97 | connector 제거 + sentence 5→3~4 감축 + 4 broken fix + 4 variant pool (반복감 해소) | 1.0.0+56 | 9.55 GO |
| R96 sprint 1 | 최애 케미 복붙 fix (FNV-1a seed + relation pool 96 templates + anchor/결 jargon 제거) | **1.0.0+57** | 9.5 GO |

## 핵심 service (R95+ 변경)

- `lib/services/natural_prose_joiner.dart` — trim/공백/마침표/dedup 만 (R97 에서 connector inject 제거)
- `lib/screens/reports/kpop_compat_screen.dart` — _composeVerdict / _verdictSeed / _KpopAnchors.relationVariant (8×6×2=96 pool) / _starIdentityLead / _composeDailyBreathDetail / _composeScoreBandTexture (R97)
- `lib/screens/reports/compatibility_screen.dart` — _analyze + _relationshipAnchorProfile + element/branch/stem pair microcopy 25+12+5 (R95)
- `lib/screens/reports/new_year_2026_screen.dart` — _AnnualSummary 7 문단 + _yearBranchRelationToWu + _TwelveAreas._buildAreaReadings (R95)
- `lib/services/today_deep_service.dart` — variant pool 4종 (branch neutral 5 / geopjae 3 / mixedDay moodHook 3 / mixedDay opening 5) (R97)

## 회귀 가드 (모두 PASS, 871/871 test)

- R91 baseline (본인 3+ / 일간 prefix / anchor 5+ / fragment ≥200)
- R77 한자 jargon (마음의 결/본인의 결/본질이에요/본성이에요)
- R89 B1~B7 (60 일주 × 14 unisex)
- R78 sprint 7 moodFor 격국 변별력
- R82 sprint 9 Gender.other (UserGender.other 명시 분기)
- R82 sprint 12 version 동적 로드
- R93 _TwelveAreas 12 area 6+ diff (round93_new_year_dynamic_test)
- R71 → R93 → R95 → R96 가드 chain

## 사용자 실기기 검증 대기 (1.0.0+57)

- 최애 케미 같은 일주 7명 본문 unique (R96 sprint 1)
- 변형 풀 96 라인 + anchor/결 jargon 제거 (R96 sprint 1)
- 자연 prose connector 제거 + sentence 감축 + variant pool (R97)
- 신년운세 _TwelveAreas 다른 사주 다른 본문 (R95)
- 궁합 본문 1000~2000자 + 연애·결혼·자녀 섹션 (R94)
- K-POP 케미 점수 변별 (R94 birth year stem)
- gender chip + 검색 IME debounce (R94)
- 입력 autofocus 이름 (R95)

## 다음 세션 시작 protocol

1. `git pull` (clean 예상)
2. HANDOFF.md "## 최신" read
3. `ruby pillarseer/scripts/check_build_status.rb` 로 ship 상태 확인
4. 사용자 다음 mandate 받으면 **Option A workflow**: codex 에 verbatim 전달

## 관련

- [[feedback_workflow_option_a]] — Option A 운영 룰
- [[reference_testflight_pipeline]] — ship pipeline
- [[reference_seephone_ids]] — pillarseer APP_ID 6768096855
