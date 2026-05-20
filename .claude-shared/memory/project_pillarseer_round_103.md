---
name: pillarseer-round-98-to-103-ship-log
description: "pillarseer R98~R103 ship 로그. 현재 1.0.0+64 (R103). 새 세션 '이어서' 시 이 파일 + feedback_workflow_option_a 부터 read."
metadata:
  node_type: memory
  type: project
  originSessionId: b7388865-d3ed-4b0b-8946-5130910483e5
---

## 현재 빌드 (2026-05-20 기준)

- **1.0.0+64** (R103) — ship 진행 중 (사용자 "출시" 승인 후 sub-agent dispatch)
- pillarseer ASC App ID: **6768096855**
- Public link: https://testflight.apple.com/join/kRs36R3b
- Bundle ID: pillarseer 별도 (빡신 6764363757 와 다름)

## Round 진행 (R98 → R103)

| Round | 내용 | build | 상태 |
|---|---|---|---|
| R98 | 한국어 본문 자연화 — life_paragraphs 1400 entry boilerplate 일소 / 사용자 OCR 5문장 / korean_josa helper | 1.0.0+58 | APPROVED |
| R99 | 영어 본문 자연화 — saju_deep_slice EN 420 paragraph + celebrities blurbEn 223 + lib/l10n | 1.0.0+59 | APPROVED |
| R100 | 케미 본문 반복감 일소 — kpop_compat first-sentence unique 0.004→0.955 / compatibility 같은 element-relation 차별화 | 1.0.0+60 | APPROVED |
| R101 | 팬심 카테고리 재정의 — 전생 시나리오(신규) + 디지털 기운 처방전(신규) + 최애와의 궁합보기(rename) | ~~1.1.0+61~~ → 1.0.0+62 | +61 expired (minor bump 사고), +62 로 재ship |
| R102 | 전생 자연화(조사 띄어쓰기 + 4 phase) + 처방전 musicEligible 가드 + celeb_songs 16 drop | 1.0.0+63 | APPROVED |
| R103 | 전생 본문 재설계(10~14문장 4막) + 곡 73 정정 + 입력 focus + 스크롤 fix + josa hotfix | 1.0.0+64 | ship 진행 중 |

## R101 1.1.0 사고 (중요 — 반복 금지)

codex 가 R101 을 "minor 기능 추가"로 보고 1.1.0+61 결정 → 사용자가 1.0.0 numbering 원함. ASC marketing version 은 다운 못 하는 게 원칙이나, **1.0.0 preReleaseVersion 이 이미 존재해서** build 62 를 1.0.0 stream 아래로 받아줌. build 61 은 expired 처리. **이후 version bump 는 사용자 결정.**

## R103 상세 (현재 round)

사용자 mandate (1.0.0+63 실기기 검증 후):
1. 전생 본문 반복 + 내용 별로 → 처음 예시 톤 + 더 길게
2. 전생 메뉴 스크롤 이상
3. 사주 입력 focus — 시간→지역 자동 이동 + 지역 후 키보드 닫힘
4. 처방전 없는 곡 너무 많음 → 제대로 검증

R103 6 sprint 결과:
- Sprint 0 baseline / Sprint 1 전생 재설계 (headers 80 / intros 128 / tails 128 / relations 48 / event_sub 64 / bridge 64, 10~14문장 4막) / Sprint 2 스크롤 fix / Sprint 3 입력 focus chain / Sprint 4 곡 전수 audit (73 정정, 2-source verified) / Sprint 5A josa hotfix (카리나가름/선비가라는) + 5B QA 159 PASS + 5C 1.0.0+64 prep
- 사용자 verbatim spirit 복원 ("몰락한 귀족이었던 당신과 감시하던 스파이였던 X ... 알고리즘이 아니라 사주예요")
- celeb_songs P0 fix: pharita_bm "두 라이크 댓"→"포에버" / j_stayc "샵 아저씨"→"치키 아이시 탱"

## R104 deferred

- yeri_rv "치얼 업" (TWICE 곡 사칭)
- lee-junho "아 진짜요" (R102 lock 의존)
- jhope "아리랑" (unverified)
- group-song vs solo-song policy

## 핵심 service / 파일 (R101~R103)

- `lib/services/past_life_service.dart` — 전생 시나리오 generator (R101 신규, R102/R103 재설계)
- `assets/data/past_life_pool.json` — 전생 pool (8 keyword × headers/intros/tails/event_sub/bridge/relations/eras)
- `lib/screens/reports/past_life_screen.dart` — 전생 화면
- `lib/services/music_pharmacy_service.dart` — 기운 처방전 (musicEligible 가드)
- `lib/screens/reports/music_pharmacy_screen.dart` — 처방전 카드 UI
- `assets/data/celeb_songs.json` — 셀럽 곡 DB (R103 audit 후 207 keys)
- `lib/screens/reports/kpop_compat_screen.dart` — 최애와의 궁합보기 (thin wrapper, compatibility _analyze 재사용)
- `lib/screens/reports/compatibility_screen.dart` — 일반 궁합
- `lib/screens/reports/reports_home_screen.dart` — 메뉴 (팬심 1전생/2처방전/3최애궁합 + 일반궁합/신년운세/꿈풀이)
- `lib/screens/input_screen.dart` — 사주 입력 (focus chain)
- `lib/services/korean_josa.dart` — 조사 helper (R98 신규)

## 회귀 가드 (모두 유지 필수)

- R98 korean_josa / sprint7 content quality
- R99 english_quality_guard
- R100 compat_repetition_guard
- R101 past_life_keyword / music_pharmacy / korean_no_english_leak / celeb_compat_uses_analyze
- R102 josa_no_loose_spacing / past_life_story_structure / celeb_songs_audit / music_pharmacy_idol_only
- R103 past_life fingerprint/length/phrase_cap/dramatic_detail/resolution_motif / scroll / input_focus_chain / inject_collision

## 다음 세션 protocol

1. `git pull --rebase` (clean 예상)
2. HANDOFF.md "## 최신" read
3. `ruby pillarseer/scripts/check_build_status.rb` + `check_beta_review.rb` 로 1.0.0+64 상태 확인
4. [[feedback_workflow_option_a]] read — codex 호출법 + sprint 패턴 + ship 룰
5. 사용자 mandate 받으면 → codex 에 verbatim 전달 (1등 앱 / 퀄리티 우선 mandate prepend)

## 관련

- [[feedback_workflow_option_a]] — Option A workflow 운영 룰 (codex 호출법 포함)
- [[reference_testflight_pipeline]] — ship pipeline
- [[reference_seephone_ids]] — APP_ID 6768096855
- [[reference_xcodebuild_signing]] — xcodebuild ASC API key 패턴
