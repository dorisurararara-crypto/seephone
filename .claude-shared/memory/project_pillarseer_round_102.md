---
name: pillarseer-round-102-ship-log
description: pillarseer R102 (Content Authenticity Recovery) 진행 결과 + 1.0.0+63 외부 베타 ganzitester 자동 제출 상태. 사용자 OCR 2 case 직발 root cause fix.
metadata:
  node_type: memory
  type: project
---

## 현재 빌드 (2026-05-19 23:25 KST)

- **1.0.0+63** ASC VALID + 외부 베타 ganzitester 자동 제출 ✅
- Public link: https://testflight.apple.com/join/kRs36R3b
- ASC App ID: 6768096855 / Delivery UUID: 382fb5cf-b335-497c-bfb3-cdc87fd2f967
- 마지막 commit: `7755bf2d43047b45a23d2caf30e0534f2a52d537`
- whatsNew ko PATCH HTTP 200 (173 chars) / en-US PATCH HTTP 200 (346 chars)
- 외부 그룹 ganzitester 할당 HTTP 204 / Beta Review 제출 ✅ 201

## R102 Mandate

사용자 OCR 2 case verbatim:
1. **전생 김채원 — "당신 과 김채원 의 ..."** — past life headline loose josa
2. **음악 처방 — "한소희 — 나의 아저씨 (헌정)"** — actor 셀럽 + 가짜 곡 (드라마 제목) + tribute 라벨

Root cause:
- past_life_service.dart L444-445 headline raw 문자열 (inject 우회) — `'$userName 과 $celebName 의'`
- past_life_service.dart inject() 가 `도/에게` placeholder 미처리
- past_life_pool.json body_lines `$celebName 도` 풀에 잔존
- music_pharmacy_service.dart 후보 filter kind 가드 0
- celeb_songs.json artistKo "헌정" 13건 + "응원곡" 1 + "김연아 헌정" 1 + 드라마 제목 차용 다수

## Sprint 별 결과

| Sprint | 작업 | 결과 |
|---|---|---|
| Sprint 1 | read-only 진단 baseline (docs/operating_memory/r102_sprint1_baseline.md) | 13 risk pattern + 15+ song entry P0/P1 분류 |
| Sprint 2 | past_life headline inject 통과 + inject 5건 add + 4 phase body_lines (setup/event/turn/resolution) + 384 raw line | 76 PASS (R101 50 + R102 신규 6) |
| Sprint 3 | music_pharmacy musicEligible 가드 (actor/icon/athlete 차단, idol+예외 4명 [cha-eunwoo/lee-junho/bae-suzy/gdragon] retain) | 5 PASS + R101 33 회귀 |
| Sprint 4 | celeb_songs.json 207 keys (16 drop = 헌정 13 + 김연아 헌정 + 손흥민 응원곡 + 지창욱) | 10 PASS |
| Sprint 5 | release QA + 1.0.0+63 ship 자동 제출 | 1082 PASS / 8 known unrelated FAIL |

## 핵심 변경 파일

| File | 변경 |
|---|---|
| `lib/services/past_life_service.dart` | 497 → 763 lines. headline inject 통과 + 도/에게 placeholder + 4 phase 합성 |
| `lib/services/music_pharmacy_service.dart` | musicEligible 가드 + 예외 4명 retain |
| `assets/data/past_life_pool.json` | 223 → 647 lines. 8 키워드 × 4 phase setup/event/turn/resolution |
| `assets/data/celeb_songs.json` | 223 → 207 keys (16 drop) |
| `test/r102_*.dart` | 8 신규 (josa / headline / inject_도_에게 / repetition / story_structure / seed_determinism / music_pharmacy_idol_only / celeb_songs_audit) |
| `test/r101_past_life_keyword_test.dart` | R102 4 phase 적응 (510 lines, 76 case sweep) |

## 회귀 결과

- flutter test: **1082 PASS / 8 FAIL** (8 FAIL 전부 R102 무관 — R88/R89/R91 deferred + R79 golden anchor + today_event_card 호칭 + R82 version display)
- flutter analyze: 2 info (pre-existing, R102 무관)
- R102 신규 test 27 (8 파일) 모두 PASS
- R101 past_life_keyword (76 case sweep) PASS — 4 phase 적응
- R101 music_pharmacy (33 case) + R101 past_life_screen_smoke (48 case) PASS
- R100 / R98 / R99 / R96 / R95 / R83 / R69 / 5행 골든 모두 보존

## 사용자 OCR 재발 검증 evidence

- R102 josa_no_loose_spacing: 150 시나리오 (3 case × 10 celeb × 5 seed) loose 조사 0
- R102 inject_도_에게: 150 시나리오 placeholder 잔존 0
- R102 music_pharmacy_idol_only: 50 prescribe (5 deficit × 10 seed) actor/athlete/icon 0 + 16 명 explicit block 150 seed sweep 0 + exception 4명 살아 있음 확인
- R102 celeb_songs_audit: 207 key 전수 artistKo 검수, tribute/응원곡/placeholder 0

→ 사용자 OCR 2 case "당신 과 김채원 의" / "한소희 — 나의 아저씨 (헌정)" 정확 재발 0 verified.

## Deployment evidence

1. flutter clean + pub get + pod install → 통과
2. flutter build ipa --release --build-number 63 → archive 성공 (export 단계 fail 정상)
3. xcodebuild exportArchive (-allowProvisioningUpdates + ASC API key) → EXPORT SUCCEEDED
4. xcrun altool --upload-app --apple-id 6768096855 → UPLOAD SUCCEEDED (24M, 25.6MB transferred)
5. altool --build-status: BUILD-STATUS: VALID + IMPORT-STATUS: VALID
6. ASC 폴링 1회 만에 build #63 VALID 진입
7. submit_b63.rb → whatsNew ko/en PATCH 200 + 외부 그룹 ganzitester HTTP 204 + Beta Review HTTP 201

## 1.0.0+63 사용자-facing 개선 요약

- 전생 결과의 조사 띄어쓰기 ("X 의" / "Y 도") 0건으로 강제
- 전생 시나리오 4막 구조 (배경 → 사건 → 전환 → 여운) 의무화 + 막장/판타지 톤 + 8 키워드 × 신규 384 line 풀
- 음악 처방에서 actor/athlete/icon 셀럽 (한소희/김연아/손흥민 등 16명) 절대 노출 X
- celeb_songs 헌정/응원곡/드라마 제목 차용 16건 drop
- 회귀 0 (R88~R101 기존 시그니처 모두 보존)

## 다음 세션 첫 행동

- 실기기 사용자 검증 보고 대기 — 1.0.0+63 ganzitester 외부 베타 (5~30분 후 install 가능)
- 새 mandate 진입 시: r102_sprint1_baseline.md 가 ground truth (read-only)
- 잔여 dirty file 3개 (scripts/asc_check_prerelease.rb / check_b62.rb / expire_b61_and_v110.rb) 는 R102 무관, 보존
