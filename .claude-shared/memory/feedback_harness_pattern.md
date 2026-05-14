---
name: feedback_harness_pattern
description: /harness 스킬 — GAN-style 3-agent harness (planner+generator+evaluator). codex 9.9+ 까지 반복. 사용자 mandate + Anthropic 인사이트 융합.
metadata: 
  node_type: memory
  type: feedback
  date: 2026-05-13
  originSessionId: e9a0d5c1-e1f8-4ac5-9f3b-48e9d78571e1
---

# /harness 스킬 — GAN-style 3-agent harness

## 무엇
사용자가 지난 몇 달 동안 진화시킨 협업 방식 (pillarseer Round 60~70 의 codex audit 8.4 → 9.9 PASS 패턴) 을 글로벌 슬래시 커맨드로 코드화. 사용자 한 줄 → planner Opus → generator Opus → codex evaluator 9.9+ 까지 자율 반복 → 최종 정리만 사용자에게 보고.

## 왜
- 사용자 mandate: **코딩 X / 배분만 / 서브에이전트 / codex 감독**. 메인 에이전트가 코드 직접 짜는 게 아니라, Opus 서브에이전트 spawn → codex 감독 패턴이 검증됨.
- Anthropic 의 GAN-style 하네스 글 (3 agent 구조 + 스프린트 계약 + 파일 communication + 단순화 원칙) 과 우리 mandate 일치 → 융합 가치 高.
- 매번 같은 부트스트랩 룰 (mandate / 환경 / 페르소나 / codex stdin pipe / TestFlight 금지) 를 prompt 에 다시 박는 비용 절약.

## 위치 (양쪽 sync)
- `/Users/seunghyeon/.claude/commands/harness.md` (글로벌 — 모든 프로젝트에서 `/harness` 호출 가능)
- `/Users/seunghyeon/seephone/.claude-shared/commands/harness.md` (Mac↔Windows ground truth — git sync)

508 lines. `diff` clean (identical).

## 통합 요소
- **사용자 mandate 5 절대 룰**: 사용자=결정 / 메인=배분 / 서브=구현 / codex=감독 / TestFlight 금지
- **Anthropic GAN 패턴**: planner (spec 만, 경로는 generator) / generator (한 번에 일관 세션, sprint 단위) / evaluator (codex CLI 회의적 튜닝, few-shot 보정, AI 슬롭 페널티)
- **스프린트 계약 (Sprint Contract)**: 코드 전 generator + codex 가 "완료 정의" 합의 — testable user story, `/tmp/sprint_<n>_contract.md` 저장
- **파일 communication**: planner → `/tmp/plan_<slug>.md` → generator → `/tmp/sprint_log.md` → evaluator → `/tmp/audit_<round>.txt`
- **codex stdin pipe 검증된 방식**: `python3 << 'PY' > /tmp/audit.txt; print("...")` PY 후 `cat | codex exec -` (큰 prompt `$(cat ...)` X — hang)
- **사용자 환경**: Mac Darwin / Flutter / `~/devapp/{name}` / `~/seephone/...` / ASC Team Q6H9HCTK6W / Apple ID zkxmel@naver.com
- **페르소나**: 한국 MZ 중학생 K-POP 팬, 직설 친근 해요체, jargon X, "본인의 결은"·"흐름이"·"K팝 센터처럼" 금지

## 채점 기준 3 template
- **[A] 풀스택 앱**: 디자인 품질 (高) / 독창성 (高) / 기술 완성도 (中) / 기능성 (中) — hard threshold 9.0 + AI 슬롭 페널티
- **[B] 콘텐츠 정제**: 직설 친근 톤 (≥9.5) / AI 어색 없음 (≥9.5) / 페르소나 적합 (≥9.0) / 종합 (≥9.0) — pillarseer phrase 변주 패턴
- **[C] 기능 추가**: 차별화 (≥9.0) / 깊은 데이터 + UI 압축 (≥9.0) / 9.9+ 톤 (≥9.5) / 검증 (≥9.0)

## 실패 처리 경계
- codex `auth_mode = apikey` → STOP + 사용자 한 줄 (Pro 구독 추가 결제 위험)
- 1 sprint × 7 evaluator 라운드 모두 FAIL → STOP + 남은 FIX 보고
- 5 sprint 이상 진행 중 새 디렉션 → STOP + 사용자 confirm
- spaceauth cookie 만료 (TestFlight 단계만) → 사용자 1회 명령

## 트레이드오프
- 풀스택 앱: 1-4시간 / 콘텐츠 정제: 30분-1.5시간 / 기능 추가: 45분-2시간
- 비용: Pro 구독 한도 안에서 무료 (codex audit 1 라운드 5-15k token)
- 부적합: 단순 버그 / 1줄 변경 / 직접 빌드 명령 (이건 직접 처리가 빠름)

## 다음 검증
- codex audit 자체 호출 (스킬 사용성 / 완성도 / mandate 통합 / Anthropic 인사이트) — 9.9+ PASS 까지 반복
- 실제 사용 라운드 1-2회 후 feedback 누적 → 스킬 prompt 다듬기

## codex audit 결과 (작성 직후)

7 라운드 만에 PASS 9.9+ 달성 (사용자 mandate "최대 7 라운드" 안에서):
- R1: FAIL 9.56 (가중평균 공식·시뮬 launch 충돌·git diff 패턴 등 5개 FIX)
- R2: FAIL 9.72 (dict schema 정합·실행 순서·secret guard 등 5개 FIX)
- R3: FAIL 9.47 (mandate 정밀화·secret guard 2단·halt schema·사용법 한 줄 등 5개 FIX)
- R4: FAIL 9.78 (few-shot 9.7 PASS 충돌·main/generator halt 분리·중단 조건 분리·placeholder 등 5개 FIX)
- R5: FAIL 9.84 (commit-audit 순서·planner_spec_invalid 3 군데 일치·staged audit 등 5개 FIX)
- R6: FAIL 9.78 (HEAD~1 잔존 제거·contract self-binding·검증 주체 분리 등 4개 FIX)
- **R7: PASS 9.93** (A 9.90 / B 9.95 / C 9.95 / D 9.90)

최종 lines: 737. 위치 sync OK (글로벌 + .claude-shared).

## 핵심 학습 (스킬 작성 회고)
- codex 가 round 마다 다른 dimension 잡음 (정합성 → 동작 흐름 → schema 일치 → 예시 충돌 → commit 순서 → 검증 주체 분리). 한 라운드에 5개 FIX 적용해도 다음 라운드에 새 issue 발견 → 회의적 튜닝 필요.
- replace_all 은 정확 일치만 잡아 옛 표현 누락 위험 (R3 의 [A] template 누락 사례). grep 으로 모든 occurrence 먼저 확인 후 개별 Edit 안전.
- "FAIL → FIX → 재호출" 패턴이 누적 → 결과적으로 mandate 와 Anthropic 인사이트 정합성 高.
