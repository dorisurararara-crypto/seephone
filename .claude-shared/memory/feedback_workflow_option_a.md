---
name: workflow-option-a-codex-brain
description: "pillarseer R95+ 작업 방식 — codex(GPT5.5) 두뇌, 서브에이전트(Opus) 코딩, main Claude 메신저. 새 세션 '이어서' 한마디로 이 방식 100% 복원. codex 호출법·sprint 패턴·ship 룰 전부 포함."
metadata:
  node_type: memory
  type: feedback
  originSessionId: b7388865-d3ed-4b0b-8946-5130910483e5
---

사용자 mandate (2026-05-18 + 2026-05-20 강화):
- "codex가 머리 + Claude(메신저) + 서브에이전트가 코딩"
- "1등앱이 목표 / 퀄리티 우선" (2026-05-20)
- "다음 세션에서 이어서 한마디면 전부 지금이랑 완전 똑같이 되도록" (2026-05-20)

## 역할 분담 (절대 룰)

- **사용자**: mandate 만
- **codex (GPT-5.5)**: 두뇌 — 모든 의사결정, sprint 구조, dispatch spec, 검수
- **main Claude (Opus 4.7, 나)**: 메신저 — codex 호출 + 답변 paste + 서브 dispatch + 보고. **직접 코딩·결정 X**
- **서브에이전트 (general-purpose, model: opus)**: 실제 코딩

예외 — main Claude 가 직접 해도 되는 것: codex 가 명시 위임한 1줄 fix / 메모리 파일 작성 / git 상태 확인 / TaskCreate 추적.

## ⭐ R106+ 콘텐츠 작업 조정 (2026-05-20 사용자 mandate)

사용자 verbatim: "너가 내 의도를 가장 잘 아니까 너가 직접하고 이번엔 codex한테 검수만 받고 평점 9.9 나올때까지 반복하자."

콘텐츠·카피 중심 작업(본문 톤, 사용자 체감 문장)은 위 절대 룰을 **역전**:
- **main Claude = 의도 주도 + 카피 작성 책임** (codex 가 아니라 Claude 가 결정·문장 톤)
- **codex = 검수·평점만**. 9.9 나올 때까지 반복.
- 이유: codex(GPT-5.5) 강점 = 규칙·구조·로직 / 약점 = 자연스러운 한국어 카피 (R96 + R106 예시 반복 검수에서 codex 카피가 계속 "메타·헤드라인체·번역체"로 어색 → 사용자 다수 반려). 자연어 톤은 Claude 가 더 정확.
- 규칙·구조·계산 로직 결정은 여전히 codex 와 상의 가능. 단 최종 카피·톤·의도는 Claude.
- 적용 범위: 콘텐츠/카피 라운드. 순수 엔진·인프라 작업은 기존 Option A 유지 가능.

## 최상위 mandate (모든 codex 호출에 prepend)

**"한국 사주 앱 1등 목표 / 퀄리티 우선 / 회귀 0"**
- 속도·토큰 절약보다 사용자 체감 quality
- threshold 절대 낮추지 X (scope creep 사유 reject)
- 사용자가 한 번 본 fix 회귀 X (R98~R103 모든 가드 유지)

## codex 호출법 (정확히 — 안 그러면 hang)

heredoc 인자 방식은 stdin 대기로 **hang 됨**. 반드시:

1. prompt 를 `/tmp/codex_xxx.txt` 에 Write 로 작성
2. `codex exec --skip-git-repo-check --sandbox read-only --cd /Users/seunghyeon/seephone/pillarseer < /tmp/codex_xxx.txt > /tmp/codex_out.txt 2>&1` 를 **run_in_background: true** 로 실행
3. 완료 알림 받으면 `grep -n "^codex$\|tokens used" /tmp/codex_out.txt` 로 섹션 마커 찾기
4. 마지막 `codex` 마커 ~ `tokens used` 사이를 Read (offset/limit) — 그게 최종 답변
5. codex auth = ChatGPT 구독 모드 (`~/.codex/auth.json` auth_mode "chatgpt"). apikey 모드면 사용자에게 알림.

codex 에 보내는 prompt 구조: 사용자 verbatim + 현 상태 요약 + `=== 결정 요청 ===` Q1~QN + "paste-ready dispatch prompt 작성해줘".

## Round 진행 패턴 (R98~R103 검증된 흐름)

1. 사용자 mandate → codex 에 verbatim 전달 (Q1~QN 결정 요청 + dispatch prompt 요청)
2. codex 답변 그대로 사용자에게 paste (요약·sale 금지)
3. codex 가 sprint 구조 + 각 sprint paste-ready dispatch prompt 제공
4. Sprint 1 = baseline 진단 (보통 read-only, docs/operating_memory/rNNN_sprintN_baseline.md 산출)
5. baseline 결과 codex 에 보고 → codex 가 Sprint 2+ dispatch spec
6. sprint 별 sub-agent (general-purpose, model opus, run_in_background) dispatch — 파일 소유권 분리되면 병렬
7. 각 sub-agent 결과 codex 에 보고 → 다음 sprint
8. 마지막 sprint = 통합 QA + ship
9. TaskCreate 로 sprint 추적

## sub-agent dispatch 룰

codex 가 준 prompt 그대로 + 추가:
- 파일 소유권 명시 (수정 허용 / 수정 금지 — 병렬 sub-agent 충돌 방지)
- `.codex_backups/` 에 backup 먼저
- 신규 test 작성 + flutter test + flutter analyze
- 보고 형식 명시 (<= N words)
- model: opus, run_in_background: true

## ship 룰 (R103 부터 — 사용자 승인 필수)

- **자동 ship 금지. 사용자 "출시" 한마디 받고 ship.** (R98~R102 는 자동 ship 했으나 R103 codex 결정으로 사용자 승인 필수 전환)
- **version bump 는 사용자 결정** (R101 에서 codex 가 1.1.0 minor bump 했다가 사용자가 1.0.0 원함 → 사고. ASC 는 marketing version 다운 못 함. 단 기존 preReleaseVersion 살아있으면 가능했음)
- ship sub-agent: flutter clean → pub get → pod install → flutter build ipa → altool upload (`--apple-id 6768096855` 명시, Xcode 26 silent fail 회피) → build VALID 폴링 → submit_b{N}.rb → 외부 그룹 ganzitester + Beta Review → git commit + push
- ship sub-agent 가 polling 단계에서 일찍 종료하면 main 이 상태 확인 후 continuation sub-agent dispatch

## 교훈

- R96: codex 가 surface metric 만 보고 9.9 줌 → 실기기 "AI 같다" → 자체 철회 3~4/10. **codex 는 실제 본문 sample 한국어 native read 해야 함**
- codex 답변 sale 금지 — 사용자가 raw 그대로 봐야 함

## 이어서 할 때 (새 세션 "이어서" 한마디)

1. 머신 식별 (`uname` Darwin = Mac) + `git pull --rebase`
2. HANDOFF.md "## 최신" block read
3. `ruby pillarseer/scripts/check_build_status.rb` + `check_beta_review.rb` 로 ship 상태
4. 이 메모리 ([[feedback_workflow_option_a]]) + [[project_pillarseer_round_103]] read
5. 사용자 다음 mandate 대기 → codex 에 verbatim 전달 (1등 앱 mandate prepend)

## 관련

- [[project_pillarseer_round_103]] — R98~R103 ship 로그 + 현재 빌드
- [[reference_testflight_pipeline]] — ship pipeline
- [[reference_seephone_ids]] — pillarseer APP_ID 6768096855
- [[reference_xcodebuild_signing]] — xcodebuild ASC API key 패턴
