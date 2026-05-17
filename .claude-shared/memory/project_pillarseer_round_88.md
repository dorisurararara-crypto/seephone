---
name: project_pillarseer_round_88
description: "R88 운세의신 17 카테고리 대전환 — deep myeongli 삭제 + LifeParagraph/Overview/SelfConclusion 3 service + 220 paragraph fixture + 회귀 9 baseline (sprint 1-5, 8-10 / sprint 6-7 R89 deferred)"
metadata: 
  node_type: memory
  date: 2026-05-18
  type: project
  originSessionId: 99ccaae2-c5aa-4b6e-84ea-20f3c131a423
---

## 무엇

pillarseer Round 88 = **운세의신(unsin.co.kr) 17 카테고리 인생 분류 구조 도입**. R71~R86 까지 쌓은 명리학 deep 구조 (격국 / 용신 3종 / 강약 / 공망 / 신살 / 12운성 / 합·충 / _OracleHero / _DayMasterHero / _SipsinPersonaSection / VERIFICATION / 자미두수 _CrossmatchSection) 전부 삭제하고 사용자 친밀 어휘로 갈아엎음.

내 사주 탭 (`/result`) 새 순서:
1. 세력 분포 점수 (5행 차트, R75 골든 16/21/17/41/4 보존)
2. 내 사주 큰 그림 (LifeOverviewService — 평생 총평 600~900자 essay)
3~19. 17 카테고리 (초년/중년/말년/건강/체질/사회/사회적성격/성격/타고난 성향/타고난 인품/이성/애정/재물/재물 모으는 법/재물 손실 막는 법/재테크 비법) + "나는 어떤 사람?" 결론 (SelfConclusionService 80~200자)

오늘 탭 순서 재배치 (한 줄 → 사주 총평 → 이렇게 해 봐). 설정 탭에서 "이 풀이는 어떻게 계산되나요" + "사주 계산 기준 안내" 항목 제거 (info_saju_calc_screen.dart 파일 본체는 R89 deferred dead code).

## 왜

사용자 verbatim "정확도가 운세의신이 훨씬 높은 것 같다 — 나랑 여친 기준으로". R80 sprint 1 의 "본인+여친 동일" 회귀 신호 + 명리학 jargon (격국/용신/12운성) 진입장벽 + 평탄 어휘 leak 가능성이 합쳐진 결과로 판단. 운세의신 사상 (일간 + 월지 + 십성 + 5행 가중) 은 우리와 거의 동일하나 **카테고리 frame** 이 인생 어휘 (재물/이성/사회) vs 명리학 어휘 (격국/용신) 로 갈라짐. 사용자 ROI 측면에서 인생 카테고리 frame 채택.

## 작업 결과

- **7 commits** (Sprint 1, 2, 3, 4, 5, 8, 9+10)
- **codex audit 16 라운드 / 평균 PASS 9.92** (S1: 1 / S2: 1 / S3: 2 / S4: 3 / S5: 2 / S8: 4 / S9+10: 4)
- **flutter analyze 0 issues / flutter test 825/825 pass** (R83 698 + R87 87 신규 + R88 신규 — 일부 deep myeongli test 폐기 + R88 baseline 신규)

### 신규 service 3종
- `lib/services/life_paragraph_service.dart` — instance method signature, 일주 60 → 일간 fallback chain, gender 분기
- `lib/services/life_overview_service.dart` — "내 사주 큰 그림" anchor 10 조합 essay (600~900자)
- `lib/services/self_conclusion_service.dart` — "나는 어떤 사람?" 결론 (80~200자, 일간 + 5행 anchor)

### 신규 data
- `assets/data/life_paragraphs.json` — 220 paragraph fixture (갑자 sprint 4 + 일간 10 base × 17 카테고리 sprint 5). 모두 ≥80자 / 평탄 어휘 0 / 단정조 0 / AI 슬롭 0 / 한자 jargon 0 / 의료 단정 0 / 직장인 jargon 0.

### 변경 file
- `lib/screens/home_screen.dart` — 오늘 탭 순서 재배치
- `lib/screens/result_screen.dart` — 17 카테고리 skeleton + deep myeongli 8종 mount 제거
- `lib/screens/settings_screen.dart` — 안내 row 2 제거
- `lib/router.dart` — info_saju_calc route 제거
- `lib/services/life_paragraph_service.dart` (신규)
- `lib/services/life_overview_service.dart` (신규)
- `lib/services/self_conclusion_service.dart` (신규)
- `assets/data/life_paragraphs.json` (신규)
- `test/r88_*.dart` × 6 + R83/R82 test 갱신·폐기

## 회귀 가드 baseline 9 항목 모두 보존

1. 5행 골든 1995-10-27 男 17시 → 16/21/17/41/4 (R75 calibration)
2. R69 lock (본성 78 / 연애 78 / 일 72 / 돈 74 / 건강 57 / 평판 71)
3. R83 P1-B 자시 학파 picker (23:00 + 조자시/야자시)
4. R83 P1-E 시간 모름 차단 (자미두수 ziwei=null)
5. R87 해외 출생지 IANA tz (~150 도시)
6. K-POP 케미 _score 18~99 range
7. 60 일주 paragraph ≥80자 (220 fixture 검증)
8. 평탄 어휘 ("균형/조화/골고루") 0회
9. 운세의신 본문 그대로 차용 0회 (저작권)

## R89 deferred (남은 작업)

- **Sprint 6**: 일주 60 × 카테고리 14 = 840 paragraph variant 확장 (현재 일간 10 base 만 — 같은 일간 사용자 동일 본문 문제 잔존)
- **Sprint 7**: 성별 분기 일주 60 × 3 카테고리 × M/F = 360 paragraph (타고난 인품 / 이성운 / 애정운)
- **Sprint 11**: chip nav UI 다듬기 (17 카테고리 navigation)
- **info_saju_calc_screen.dart** 파일 본체 정리 (route 제거됐지만 파일 dead code 잔존)

R88 deferred 핵심: 외부 codex/gemini server batch 인프라 필요. Main session 안에서 1020 paragraph 생성은 token cost ↑↑. R89 별도 batch sprint 권장.

## 배포 상태

**미배포** (사용자 명시 mandate "다 자동배포하지마 내가 배포하라고 할때만해"). 현재 commit f513023 까지 origin 에 push. 사용자가 "TestFlight 올려" / "출시" 한 마디 시 R87 + R88 통합 1.0.0+46 배포 단계 진입.

## commits

- `64e6841` R88 S1 — 오늘 탭 widget 순서 재배치
- `ffbb78a` R88 S2 — 설정 탭 항목 2 개 제거
- `99cd462` R88 S3 — result_screen 17 카테고리 skeleton + deep myeongli 8종 mount 제거
- `a5f265b` R88 S4 — LifeParagraphService + DB schema + 갑자 fixture
- `a8c4d7e` R88 S5 — 일간 10 base × 17 카테고리 paragraph + fallback wire
- `dd82913` R88 S8 — LifeOverviewService + result_screen wire
- `f513023` R88 S9+S10 — SelfConclusionService + 17 카테고리 service wire + 회귀 baseline

## 다음 결정 (사용자)

1. R88 결과 실기기 검증 (TestFlight 자동 배포 시 R87 + R88 통합 1.0.0+46)
2. R89 sprint 6/7 (1020 paragraph full batch) 시작 시점
3. R89 sprint 11 (chip nav UI 다듬기)
