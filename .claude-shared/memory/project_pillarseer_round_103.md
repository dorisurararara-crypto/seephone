---
name: pillarseer-round-98-to-105-ship-log
description: "pillarseer R98~R105 ship 로그. 현재 1.0.0+66 (R105). 새 세션 '이어서' 시 이 파일 + feedback_workflow_option_a 부터 read."
metadata:
  node_type: memory
  type: project
  originSessionId: b7388865-d3ed-4b0b-8946-5130910483e5
---

## 현재 빌드 (2026-05-20 기준)

- **1.0.0+66** (R105) — ASC VALID + Beta Review APPROVED, ganzitester 외부 베타 라이브 ✅
- pillarseer ASC App ID: **6768096855**
- Public link: https://testflight.apple.com/join/kRs36R3b
- Bundle ID: pillarseer 별도 (빡신 6764363757 와 다름)
- build 64=R103 / 65=R104 / 66=R105 — 전부 VALID+APPROVED

## Round 진행 (R98 → R105)

| Round | 내용 | build | 상태 |
|---|---|---|---|
| R98 | 한국어 본문 자연화 — life_paragraphs boilerplate / korean_josa | 1.0.0+58 | APPROVED |
| R99 | 영어 본문 자연화 — saju_deep_slice EN + blurbEn + l10n | 1.0.0+59 | APPROVED |
| R100 | 케미 본문 반복감 일소 — kpop_compat unique 0.004→0.955 | 1.0.0+60 | APPROVED |
| R101 | 팬심 카테고리 재정의 — 전생/처방전 신규 + 최애궁합 rename | ~~1.1.0+61~~→62 | +61 expired |
| R102 | 전생 자연화 + 처방전 musicEligible + celeb_songs 16 drop | 1.0.0+63 | APPROVED |
| R103 | 전생 본문 재설계(4막) + 곡 73 정정 + 입력 focus + 스크롤 | 1.0.0+64 | APPROVED |
| R104 | 전생 story arc 재설계(기승전결) + 다시뽑기 제거 + pre-existing 8건/오염 일소 | 1.0.0+65 | APPROVED |
| R105 | 신규 메뉴 "최애의 사주" — 셀럽 Top 30 실제 사주 + 위키 검증 사실 침투 | 1.0.0+66 | APPROVED |

## R101 1.1.0 사고 (반복 금지)

codex 가 R101 을 minor 로 보고 1.1.0+61 → 사용자가 1.0.0 원함. build 61 expired, 62 로 재ship. **version bump 는 사용자 결정.**

## ⚠️ 트랩 (세션 교훈)

- **build 번호 stale**: check_build_status.rb 가 세션 시작 시 stale (build 64 VALID 인데 max 63 으로 조회됨). ship 직전 build 번호 재조회 + 사용자 확인. 빌드 번호는 R103=64 / R104=65 / R105=66 순.
- **round82 version pin**: test/round82_version_display_test.dart 가 pubspec 버전을 하드코딩 핀. 매 ship 마다 +N 동기화 필수 (R104 ship 때 누락 → full test -1 사고). ship sprint 가 pubspec bump 와 round82 핀을 같이 갱신.

## R104 상세 (전생 story arc)

전생 본문 slot 랜덤조립 → keyword×storyArc 완결 시나리오 (8 keyword × 8 arc = 64, 기/승/전/결 4문단 + modernPunchlineByKind). 다시뽑기 제거 + 셀럽 선택 시 picker hide + seed 미전달((user,celeb)별 arc). pre-existing 8건(late_life/관성 오탐/골든/본인 415건/anchor/version/호칭) + 조사 50건 + 오염 토큰 102건(톤정/톤제 등 "결" 일괄치환 잔해) 일소. codex 9.1/10. commit 277ac65 + 39d5d39.

## R105 상세 (직전 round — 최애의 사주)

사용자 mandate: "셀럽 사주를 진짜 사주에 알려진 사실을 티 안 나게 넣어서. 위키백과 잘 안 알려진 사실로 딱. 거짓말 없이."
- IU·RM 예시로 톤 검증 → Top 30 확장 결정.
- Sprint 1 스키마/검증기/route skeleton / S2 Top12 / S2b 손흥민·제니 정확도 / S3A·3B Top13~30 / S3C·3D codex QA(8.1→8.6) / S4 UX polish.
- 데이터: `celeb_facts.json`(사실+출처 URL+confidence+publicness) + `celeb_saju_readings.json`(chart 3주+usedFactIds+7섹션 본문) 분리.
- 사주 = 셀럽 birth date 로 年月日 3주만 (時 미상 → hourPillar null, 시주 단정 금지). dayPillar 는 celebrities.json 과 대조 검증. 절기 경계 7명 = boundary_ambiguous (Top 30 제외).
- 거짓말 0: 모든 fact 위키백과(ko/en) WebFetch 검증, 출처 URL 기록, 충돌 시 폐기. usedFactId→facts 매핑 가드 테스트 = launch blocker.
- Top 30 = iu·rm·jungkook·jennie·karina·wonyoung_ive·taeyeon·gdragon·송혜교·이정재·김연아·손흥민 + 뷔·지민·진·지수·로제·리사·윈터·안유진·김수현·이민호·차은우·박서준·이준호·배수지·한소희·김지원·변우석·김혜윤. 나머지 193명 "준비 중".
- codex 8.6/10 GO. full test 1204/1204. commit 526ba99.

## R106 후보 / deferred

- 최애의 사주 셀럽 확장 (Top 30 → 50/100/223 단계). boundary_ambiguous 7명은 日柱 중심 + confidence badge 정책.
- 30명 reading 잔존 반복("팬 입장에서는" 25 / "무늬" 47) — per-celeb 라 acceptable 판정됐으나 polish 후보.
- celeb_songs 미검증 곡 (yeri_rv/lee-junho/jhope) / group-song vs solo-song policy.

## 회귀 가드 (모두 유지 필수)

- R98 korean_josa / R99 english_quality / R100 compat_repetition
- R101 past_life_keyword / music_pharmacy / korean_no_english_leak / celeb_compat_uses_analyze
- R102 josa_no_loose_spacing / past_life_story_structure / celeb_songs_audit / music_pharmacy_idol_only
- R103 past_life fingerprint/length/phrase_cap/dramatic_detail/resolution_motif / scroll / input_focus_chain
- R104 past_life_screen_ux / past_life_arc / josa_consistency(자기을·오염토큰 0)
- R105 r105_celeb_chart_audit(dayPillar 대조·시주 금지) / r105_celeb_facts_guard(usedFactId 매핑·출처 allowlist) / r105_celebrity_saju_screen

## 핵심 service / 파일

- `lib/services/past_life_service.dart` + `assets/data/past_life_pool.json` — 전생 (story_arcs 64 + slot fallback)
- `lib/screens/reports/past_life_screen.dart` — 전생 화면
- `assets/data/life_paragraphs.json` — 평생사주 본문 corpus
- `lib/services/celeb_chart_validator.dart` — R105 셀럽 3주 계산·검증
- `lib/screens/reports/celebrity_saju_screen.dart` — R105 최애의 사주 화면
- `assets/data/celeb_facts.json` / `celeb_saju_readings.json` — R105 사실 DB + 사주 본문
- `lib/screens/reports/reports_home_screen.dart` — 메뉴 (팬심 1전생/2처방전/3최애궁합/4최애사주)
- `lib/services/music_pharmacy_service.dart` / `assets/data/celeb_songs.json` — 처방전
- `lib/screens/input_screen.dart` / `lib/services/korean_josa.dart`

## 다음 세션 protocol

1. `git pull --rebase` (clean 예상)
2. HANDOFF.md "## 최신" read
3. `ruby pillarseer/scripts/check_build_status.rb` + `check_beta_review.rb` 로 1.0.0+66 상태 확인 (build 번호 재확인 — stale 트랩)
4. [[feedback_workflow_option_a]] read — codex 호출법 + sprint 패턴 + ship 룰
5. 사용자 mandate 받으면 → codex 에 verbatim 전달 (1등 앱 / 퀄리티 우선 / 회귀 0 prepend)

## 관련

- [[feedback_workflow_option_a]] — Option A workflow 운영 룰 (codex 호출법 포함)
- [[reference_testflight_pipeline]] — ship pipeline
- [[reference_seephone_ids]] — APP_ID 6768096855
- [[reference_xcodebuild_signing]] — xcodebuild ASC API key 패턴
