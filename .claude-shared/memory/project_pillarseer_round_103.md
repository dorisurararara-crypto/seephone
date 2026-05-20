---
name: pillarseer-round-98-to-104-ship-log
description: "pillarseer R98~R104 ship 로그. 현재 1.0.0+65 (R104). 새 세션 '이어서' 시 이 파일 + feedback_workflow_option_a 부터 read."
metadata:
  node_type: memory
  type: project
  originSessionId: b7388865-d3ed-4b0b-8946-5130910483e5
---

## 현재 빌드 (2026-05-20 기준)

- **1.0.0+65** (R104) — ASC VALID + Beta Review APPROVED, ganzitester 외부 베타 라이브 ✅
- pillarseer ASC App ID: **6768096855**
- Public link: https://testflight.apple.com/join/kRs36R3b
- Bundle ID: pillarseer 별도 (빡신 6764363757 와 다름)
- build 64 = R103 (VALID+APPROVED) / build 65 = R104 (VALID+APPROVED)

## Round 진행 (R98 → R104)

| Round | 내용 | build | 상태 |
|---|---|---|---|
| R98 | 한국어 본문 자연화 — life_paragraphs boilerplate 일소 / korean_josa helper | 1.0.0+58 | APPROVED |
| R99 | 영어 본문 자연화 — saju_deep_slice EN + celebrities blurbEn + l10n | 1.0.0+59 | APPROVED |
| R100 | 케미 본문 반복감 일소 — kpop_compat first-sentence unique 0.004→0.955 | 1.0.0+60 | APPROVED |
| R101 | 팬심 카테고리 재정의 — 전생 시나리오/처방전 신규 + 최애궁합 rename | ~~1.1.0+61~~ → 1.0.0+62 | +61 expired (minor bump 사고) |
| R102 | 전생 자연화 + 처방전 musicEligible 가드 + celeb_songs 16 drop | 1.0.0+63 | APPROVED |
| R103 | 전생 본문 재설계(10~14문장 4막) + 곡 73 정정 + 입력 focus + 스크롤 fix | 1.0.0+64 | APPROVED |
| R104 | 전생 story arc 재설계(기승전결) + 다시뽑기 제거 + picker hide + pre-existing 8건/조사/오염 일소 | 1.0.0+65 | APPROVED |

## R101 1.1.0 사고 (중요 — 반복 금지)

codex 가 R101 을 minor 기능 추가로 보고 1.1.0+61 결정 → 사용자가 1.0.0 numbering 원함. ASC marketing version 은 다운 못 하나 1.0.0 preReleaseVersion 이 이미 존재해서 build 62 를 1.0.0 stream 아래로 받아줌. build 61 expired. **version bump 는 사용자 결정.**

## ⚠️ build 번호 stale 트랩 (R104 세션 교훈)

`check_build_status.rb` 가 세션 시작 시 stale 데이터 반환한 적 있음 — build 64 가 ASC 에 VALID 인데 조회 결과 max 63 으로 나왔다. ship 직전 build 번호는 **재조회로 재확인**하고, "이미 있는 번호인지" 사용자에게도 확인. R104 는 64(R103 점유) 다음 **65** 로 ship.

## R104 상세 (직전 round)

사용자 mandate (1.0.0+64 = R103 실기기 검증 후):
1. 전생 다시뽑기 버튼 제거
2. 셀럽 선택하면 밑 목록 사라지고 결과만 (스크롤 없이)
3. 전생 본문 AI같고 재미없고 짧음 → 기승전결 + 더 이야기답게

R104 sprint 결과 (Option A workflow, codex 두뇌):
- Sprint 1 baseline / S2 화면 UX(다시뽑기 제거·picker hide·"다른 최애 고르기" 바) / S2-followup seed fix(화면이 seed 안 넘김 → (user,celeb)별 arc) / S3 arc engine(slot 조립 → story_arcs 단일 선택, slot fallback 보존) / S4 content 64 arc 작성 / S5·5b·5c codex 본문 검수(7.2→8.4→9.1) / S6·6b·6c pre-existing 8건+조사 50건+오염 토큰 102건
- 본문 근본 해법: keyword × storyArc 완결 시나리오 (8 keyword × 8 arc = 64). 각 arc 가 기/승/전/결 4문단 + modernPunchlineByKind(idol/actor/athlete/icon). 기존 slot 키는 fallback 보존.
- pre-existing 8건 = R98~R101 누적 (late_life 80자 / 한자 "관성"=일관성 오탐 / round79 골든 stale / "본인" 415건 / anchor 5+ / round82 version stale / 호칭 "너에게" 회귀). +63·+64 도 안고 출시됐던 부채.
- 오염 토큰 = 과거 "결" 일괄치환이 결정/결제 깨먹어 톤정/톤제/쪽제/느낌제/톤로 102건 → 복원. life_paragraphs.json 한정, 타 자산 클린.
- codex 최종 GO 9.1/10. full test +1177 -0.

## R104 deferred / R105 후보

- yeri_rv "치얼 업" / lee-junho "아 진짜요" / jhope "아리랑" — celeb_songs 미검증 곡
- group-song vs solo-song policy
- hyeong punchline "약속" 의미축 편중 (acceptable, polish 후보)

## 핵심 service / 파일

- `lib/services/past_life_service.dart` — 전생 generator. R104: _selectStoryArc/_composeFromStoryArc(story_arcs 경로) + slot fallback + _PlaceholderInjector
- `assets/data/past_life_pool.json` — story_arcs 64 arc (R104) + 기존 slot 키(fallback)
- `lib/screens/reports/past_life_screen.dart` — 전생 화면. R104: 다시뽑기 제거, picker hide, seed 미전달
- `assets/data/life_paragraphs.json` — 평생사주 본문 corpus
- `lib/services/music_pharmacy_service.dart` / `music_pharmacy_screen.dart` — 기운 처방전
- `assets/data/celeb_songs.json` — 셀럽 곡 DB (207 keys)
- `lib/screens/reports/kpop_compat_screen.dart` / `compatibility_screen.dart` — 궁합
- `lib/screens/input_screen.dart` — 사주 입력 (focus chain)
- `lib/services/korean_josa.dart` — 조사 helper

## 회귀 가드 (모두 유지 필수)

- R98 korean_josa / R99 english_quality / R100 compat_repetition
- R101 past_life_keyword / music_pharmacy / korean_no_english_leak / celeb_compat_uses_analyze
- R102 josa_no_loose_spacing / past_life_story_structure / celeb_songs_audit / music_pharmacy_idol_only
- R103 past_life fingerprint/length/phrase_cap/dramatic_detail/resolution_motif / scroll / input_focus_chain / inject_collision
- R104 past_life_screen_ux(다시뽑기 부재) / past_life_arc / josa_consistency(자기을·오염토큰 0)

## 다음 세션 protocol

1. `git pull --rebase` (clean 예상)
2. HANDOFF.md "## 최신" read
3. `ruby pillarseer/scripts/check_build_status.rb` + `check_beta_review.rb` 로 1.0.0+65 상태 확인 — build 번호 재확인 (stale 트랩 주의)
4. [[feedback_workflow_option_a]] read — codex 호출법 + sprint 패턴 + ship 룰
5. 사용자 mandate 받으면 → codex 에 verbatim 전달 (1등 앱 / 퀄리티 우선 / 회귀 0 mandate prepend)

## 관련

- [[feedback_workflow_option_a]] — Option A workflow 운영 룰 (codex 호출법 포함)
- [[reference_testflight_pipeline]] — ship pipeline
- [[reference_seephone_ids]] — APP_ID 6768096855
- [[reference_xcodebuild_signing]] — xcodebuild ASC API key 패턴
