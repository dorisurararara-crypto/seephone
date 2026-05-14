---
name: pillarseer-round-74-12-first-fold-testflight-1-0-0-35
description: "Round 73 실기기 사용자 mandate \"한국어 본문 어색\" 직설 피드백 → 6 sprint 전수 sweep + 12시간 흐름 home 첫 fold 승격. TestFlight 1.0.0+35 외부 베타 ganzitester 제출 완료."
metadata: 
  node_type: memory
  type: project
  date: 2026-05-14
  originSessionId: bd822aa5-cb36-4cc4-bc81-10bcead64b89
---

# pillarseer Round 74

## 무엇

Round 73 에서 운세의신 정합 수준 + 17 섹션 + TestFlight 1.0.0+34 외부 베타 진입. 사용자가 실기기 캡쳐 3장 + 직설 mandate ("한국어 본문 어색"). Round 74 mandate:

1. `_OracleHero` 30 ko 멘트 일상톤 전수 재작성 ("깎이지 마라" 사람 X 동사 제거)
2. `today_deep_service` 6 어색 구문 + DayEnergyKind hook + restDay 분기 sweep (`일지` jargon 제거)
3. `personalization_engine` 14+ surface 합니다체+해요체 혼용 → 해요체 통일
4. `deep_content_service` 5 element 헷지 + fallback 합니다체 sweep
5. 12시간 흐름 (`_HourlyFlowSection`) `_DeepDiveSection` 안 → home first-fold 승격
6. 영문 hedging (fade quietly/stay far away/settle down/could be) 0
7. TestFlight 1.0.0+35 외부 베타 ganzitester 제출

## 왜

운세의신 정량 정합 통과 + Round 73 폴라리티 quantitative gate 통과 했어도 사용자가 실기기에서 사람 눈으로 읽었을 때 어색 표현 다수. 한국 MZ 중학생 K-POP 페르소나 codex 평가가 끝없이 spot fix 요구하는 패턴 — 모든 시적/추상 표현/AI tic/반복 phrase 제거 필요. 4 sprint × codex 평균 4 라운드 audit 누적.

## 검증결과 (6 sprint)

| Sprint | 점수 | A | B | C | D | commit |
|---|---|---|---|---|---|---|
| 1 (메타) | inventory | - | - | - | - | (코드 X) |
| 2 | 9.91 | 9.94 | 9.88 | 9.92 | 9.90 | 4f6d169 |
| 3 | 9.9+ | 9.9 | 9.8 | 10.0 | 10.0 | d7f4148 |
| 4 | 9.9+ | 9.9 | 9.9 | 9.8 | 9.7 | 75a892d |
| 5 | 9.98 | 10.0 | 10.0 | 9.9 | 10.0 | 42b5895 |
| 6 | 9.91 | 9.95 | 9.95 | 9.90 | 9.95 | e8509aa |
| 7 | TF 제출 | - | - | - | - | 8465dd8 |

avg codex 9.93.

4 gate (Sprint 6):
- `flutter analyze`: 0 error
- `flutter test`: 363/363 PASS
- `polarity_audit`: hedge 0 / slop 0 / 폴라리티 43:32:8 (Round 73 baseline 유지)
- spec testable user story U1~U12 모두 통과

TestFlight 상태:
- Build #35 id `dda2b960-897e-4215-b019-546a13f70d20` state=VALID
- 외부 그룹 ganzitester (3217ce1c-29ca-4946-a26a-0c55529172a3) 할당 HTTP 204
- Beta Review 자동 제출 HTTP 201 ✅
- Public link: https://testflight.apple.com/join/kRs36R3b

## 페르소나 codex 학습 결과

한국 MZ 중학생 K-POP 팬 페르소나 codex 는 첫 라운드부터 9.9+ 거의 안 나옴 (Sprint 2 = 10 라운드 걸려 PASS / Sprint 3 = 4 라운드 / Sprint 4 = 3 라운드). 점진 spot fix 패턴:

라운드별 typical 지적:
1. 명령형 `마라/해라/가라` → 평서체 `안 하는 게 낫다`
2. AI tic 반복 (`오늘 너는` 30회 / `한 줄` 25회 / `분기점` 12회) → 분산
3. 시적 표현 (`비춘다/스며든다/받친다/자기 색/머릿속에 박힌다`) → 일상어
4. 직장인 jargon (`결단/평판/책임`) → 친근어 (`결정/이미지/일`)
5. 영문 hedging (`might/maybe/perhaps/fade quietly/locks the day in`) → 단정 평이 영어
6. 한자 jargon (`일지/운기/결의 흐름/본질/정수`) → 일상어

## 다음

사용자가 TestFlight 1.0.0+35 실기기 테스트 후:
- 추가 어색 발견 → Round 75 spot fix
- 톤 PASS → Production 1.0.0 정식 출시 검토 (별도 라운드)

## NON-GOAL invariant 유지

- kIsZiweiUiHidden=true (자미두수 UI 숨김)
- result_screen 17 섹션 구조 (Round 73 lock)
- DayEnergyKind 로직 (Round 71 invariant)
- 사주 계산 코어 (만세력·지장간·십신·대운·합충·공망) 변경 0
- TenGodsService.tableFor 호출 변경 0

## 파일 변경 요약

- `lib/screens/home_screen.dart` (S2 _OracleHero ko/en + S5 _HourlyFlowSection 위치)
- `lib/services/today_deep_service.dart` (S3 전면 sweep)
- `lib/services/personalization_engine.dart` (S4 + S6 잔재 fix)
- `lib/services/deep_content_service.dart` (S4)
- `lib/l10n/app_ko.arb` + `lib/l10n/app_localizations_ko.dart` (S4 sync)
- `pubspec.yaml` (S7 1.0.0+35)
- `scripts/submit_b35.rb` (S7 신규)

총 8개 파일, 7 commits.
