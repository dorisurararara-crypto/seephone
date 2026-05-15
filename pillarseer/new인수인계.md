# 새 Codex 세션 인수인계 — 계속 발전하는 AI 운영 메모리

> version: 2.0  
> last_updated: 2026-05-16 KST  
> last_audited: 2026-05-16 KST by Claude Opus + Codex subagent  
> purpose: 특정 작업 인수인계가 아니라, 세션이 반복될수록 Codex+Claude 운영 방식 자체가 더 똑똑해지도록 만드는 장기 운영 메모리.

## 30초 Active Memory Index

| 항목 | 현재값 |
|---|---|
| 운영 원칙 | Codex = 판단/계획/검수/문서화, Claude = 실제 코드/데이터 편집 |
| 현재 active task | 셀럽 DB 확장 재개 대기, 2026-05-16 snapshot 기준 223명 |
| active playbook | `docs/operating_memory/memory_routing.md`, `docs/operating_memory/celebrity_db_playbook.md` |
| 마지막 안정 상태 | Playbook canonical. snapshot: `assets/data/celebrities.json` 223명, round83 celebrity test 30/30 pass |
| 안정 백업 | `.codex_backups/celebrities_223_stable.json` |
| 절대 주의 파일 | `ios/Podfile.lock`, 출처 불명 dirty files, `.codex_backups/*` |
| 시작 필수 확인 | `git status --short`, active playbook, 관련 test/count |
| 종료 필수 확인 | 의도 변경 파일, 통과 테스트, 남은 위험, 운영 메모리 갱신 |
| 최근 Claude 사고 | JSON truncate, heredoc hang, test update omission, forbidden blurb words |
| 다음 권장 행동 | 사용자가 재개하면 NCT/WayV 10명 후보를 source 재검증 후 진행. Playbook canonical |

## Rule Hierarchy

1. System/developer/current user instruction overrides this file.
2. Latest user instruction overrides older notes in this file.
3. Absolute safety rules override speed and convenience.
4. Active playbook details override stale task notes, but not this file's safety rules.
5. If two rules conflict, follow the safer rule or stop and ask the user.

## Command Legend

- `EXACT`: 그대로 실행해도 되는 명령.
- `TEMPLATE`: placeholder를 바꾼 뒤 실행.
- `TASK-SPECIFIC`: 해당 playbook/task에서만 실행.

명령 블록을 맹목적으로 실행하지 않는다. `<...>`가 있으면 반드시 치환한다.

## 최상위 목표

AI 모델 자체의 지능은 세션마다 고정되어 있다. 이 프로젝트에서는 MD 파일을 외부 장기기억, 운영 규칙, 실패 데이터베이스, 최적화 로그로 사용한다. 목표는 한 세션의 똑똑함이 아니라 **누적되는 운영 지능**이다.

MUST:

- 같은 실수를 반복하지 않는다.
- 사용자 취향과 금지사항을 규칙으로 누적한다.
- 실패한 프롬프트/명령/작업 방식은 기록하고 피한다.
- 성공한 패턴은 템플릿화한다.
- 파일이 많아져도 임의 삭제하지 않는다.
- 어떤 작업이 와도 이 문서를 먼저 읽고 더 좋은 방식으로 진행한다.

## 역할 헌법

사용자는 “코딩은 Claude Opus 4.7 / 판단과 명령은 Codex” 방식을 원한다.

Codex MUST:

- 목표 해석
- 계획 수립
- 작업 분해
- Claude에게 명령
- 독립 검수
- 테스트 실행
- 사용자 취향 반영
- 이 문서와 관련 playbook 갱신

Claude MUST:

- 실제 코드/데이터 편집
- 테스트 추가/수정
- 포맷
- 1차 실행 결과 보고

Codex MAY directly do:

- 읽기/조사: `rg`, `sed`, `jq`, `git status`
- 검증: 테스트 실행, 중복 검사, count 확인
- 프로세스 관리: 멈춘 Claude 종료
- 계산/분석: 사주값 계산, diff 해석, 품질 평가
- 문서화: 인수인계/운영 메모리 갱신

Codex MUST NOT directly do unless user explicitly approves or emergency recovery requires minimal repair:

- 앱 코드 대량 구현
- 데이터 대량 편집
- 테스트 대량 작성
- Claude에게 맡기기로 한 구현을 혼자 끝내는 것

If Claude CLI is unavailable:

- Codex MUST ask the user before direct implementation.
- Exception: tiny documentation edits or urgent data-loss prevention.
- If Claude corrupts files repeatedly, pause delegation and switch to recovery mode.

## SESSION_START Gate

새 세션은 작업 전 반드시 이 게이트를 통과한다.

EXACT:

```bash
uname -a
pwd
git status --short
```

MUST:

- `new인수인계.md`를 읽는다.
- 현재 요청의 작업 영역을 분류한다: app code, data, content, UI/UX, test/QA, deploy, docs/operation.
- 관련 playbook을 읽는다. 무엇을 읽을지 애매하면 `docs/operating_memory/memory_routing.md`를 먼저 사용한다.
- git sync 정책을 평가한다. 글로벌/상위 규칙이 pull을 요구하면, dirty risk를 먼저 확인하고 가능할 때만 `git pull --ff-only`를 사용한다. dirty worktree 때문에 pull을 건너뛰면 skip 이유를 SESSION_END에 기록한다.
- 이번 세션 운영 개선 가설 1개를 정한다.
- dirty file 중 현재 작업과 무관한 것은 건드리지 않는다.

TASK-SPECIFIC celebrity DB checks are in `docs/operating_memory/celebrity_db_playbook.md`.

## Memory Routing Protocol

새 세션은 “무엇을 읽을지”를 감으로 고르지 않는다.

MUST use `docs/operating_memory/memory_routing.md` when:

- 요청이 둘 이상의 도메인에 걸친다.
- 어떤 playbook을 읽을지 애매하다.
- 새 playbook 생성/skip을 판단해야 한다.
- 어디에 학습 로그나 partial state를 기록할지 불명확하다.
- 상위 `CLAUDE.md`, `HANDOFF.md`, `.claude-shared`까지 검색해야 할 수 있다.
- 작업 중 사용자 방향 전환이 발생해 partial state 기록 위치를 정해야 한다.

## SESSION_END Gate

최종 답변 전 반드시 확인한다.

MUST list:

- 완료한 작업
- 의도적으로 변경한 파일
- 실행한 테스트/검증과 pass/fail 결과
- unrelated dirty files를 보존했는지
- 데이터 변경 시 recovery point/backup
- 새로 발견한 실패 패턴
- 운영 메모리 또는 playbook 갱신 여부
- 이번 세션 운영 가설의 결과와 write-back 위치
- 세션 품질 점수: `quality: routing ?/10, safety ?/10, accuracy ?/10, tests ?/10, content ?/10, efficiency ?/10`
- git sync를 실행/skip한 결과와 이유
- 다음 세션 첫 행동

Task is NOT done until evidence is listed. “Claude가 통과했다고 말함”은 증거가 아니다. Codex가 독립 검수해야 한다.

## Doc Update Transaction

운영 메모리나 playbook을 갱신할 때는 아래 형식을 유지한다.

```text
### YYYY-MM-DD — title

- Before state:
- After state:
- Files intentionally changed:
- Commands proving state:
- New failure learned:
- Rule promoted/deprecated:
- Open risk:
- Next session first action:
```

이 형식이 없으면 문서가 일기처럼 불어나고, 다음 세션이 배울 수 없다.

## 자기최적화 루프

매 세션은 실제 작업과 운영 개선을 함께 수행한다.

1. 시작 진단
   - 현재 상태, active playbook, dirty files, 이전 실패를 확인.
2. 작은 가설 설정
   - 예: “데이터 추가와 테스트 추가를 분리하면 누락이 줄어드는가?”
3. 실행
   - Claude에게 구현을 시키고 Codex가 검수.
4. 사후 평가
   - Claude 멈춤, 누락, 품질 위반, 테스트 실패 여부를 기록.
5. 문서 갱신
   - 효과 있으면 권장 방식으로 승격.
   - 실패하면 피해야 할 방식으로 기록.
   - 결과는 반드시 `운영 학습 로그` 또는 해당 playbook의 known incidents / prompt templates / quality rules 중 하나에 write-back한다.

## 세션 품질 점수표

세션 종료 시 1줄로 남긴다.

```text
quality: routing ?/10, safety ?/10, accuracy ?/10, tests ?/10, content ?/10, efficiency ?/10
```

평가 기준:

- safety: 파일 count, 백업, dirty file 보존
- routing: 올바른 AGENTS / memory / playbook / docs를 찾고 기록했는지
- accuracy: 계산/사실/source 안정성
- tests: regression, format, relevant test pass
- content: 사용자 취향, 금지어, 자연스러움
- efficiency: Claude 재작업률, 프롬프트 명확성, 자동화 정도

점수가 낮은 항목은 다음 세션의 운영 개선 가설로 올린다.

## 파일 증가와 정리 정책

삭제는 최후 수단이다. 먼저 분류하고, 보존형 정리를 검토하고, 필요한 경우 사용자 승인을 받는다.

삭제 금지:

- `assets/data/*.json`
- `test/*.dart`
- `.codex_backups/*`
- `ios/Podfile.lock`
- 기존 문서/인수인계/스펙 파일
- 출처가 불명확한 dirty file

정리 가능 후보:

- `/tmp`에 만든 임시 파일
- 현재 세션에서 만든 것이 확실한 `_tmp`, `_scratch`, `_draft`
- 비어 있고 사용되지 않는 scratch 파일

정리 절차:

1. `git status --short`
2. 파일을 핵심/테스트/백업/문서/임시/산출물로 분류
3. 임시 파일만 삭제 후보
4. 핵심/테스트/백업/문서는 삭제하지 않음
5. 삭제 필요 시 사용자 승인

## MD 비대화 방지 정책

이 메인 파일은 운영 헌법과 active index만 담는다.

MUST:

- top 100 lines는 30초 안에 읽을 수 있게 유지.
- 작업별 세부 절차는 `docs/operating_memory/*_playbook.md`로 분리.
- main file이 400 lines를 넘으면 압축 후보를 점검한다.
- main file이 450 lines를 넘으면 오래된 task detail이나 복구 세부 절차를 playbook/archive로 이동한다.
- incident는 삭제하지 않고 archive한다.
- stale fact에는 label을 붙인다: `Verified as of`, `Must re-check`, `Historical incident`, `Assumption`, `Current active state`.

Backups:

- `.codex_backups/`는 임의 삭제 금지.
- 정리가 필요하면 최근 5개 + 월말 1개 보존 같은 정책을 제안하고 사용자 승인 후 진행.

## Playbook Lifecycle

새 작업 도메인에 관련 playbook이 없으면 다음 기준을 따른다.

MUST create or update a playbook when:

- 같은 유형의 작업이 2회 이상 반복될 가능성이 있다.
- Claude에게 시킬 구현/데이터 편집 절차가 있다.
- 실패 복구 절차나 금지 파일이 있다.
- 사용자 취향/금지사항이 작업 품질에 직접 영향을 준다.

MAY skip playbook when:

- 1회성 설명/질문 답변이다.
- 파일 변경이 없는 간단한 조사다.

If creating a playbook:

- Use `docs/operating_memory/<task>_playbook.md`.
- Add it to `Active Playbooks` if current or recurring.
- Move old task detail out of this main file.

Archive rule:

- Completed or stale playbooks are not deleted.
- Mark status as `Archived`, `Superseded`, or `Needs verification`.
- Keep a one-line pointer in this file when still relevant.

## Failure Recovery Decision Trees

### Claude hangs

1. 60s no output: check whether files changed.
2. 120s no output and no file change: kill only matching `claude -p` process.
3. 2 failures: split the task into smaller prompts.
4. 4 failures: stop and report to user.

### Unexpected data shrink

1. Stop all edits.
2. Check current count and latest stable backup.
3. Do not run more Claude edits.
4. Restore only after confirming the correct backup.
5. Run relevant tests.
6. Record incident in playbook.

### Tests fail

1. Classify: data failure, test expectation failure, source code failure, environment failure.
2. Do not blindly edit multiple files.
3. Ask Claude for a narrow fix only after classification.
4. Codex reruns relevant tests.

### New dirty files appear

1. Identify whether current session touched them.
2. If unrelated, do not modify.
3. If related, inspect diff before any further edit.
4. Never revert user work without explicit request.

### Codex gives a bad instruction

1. Stop further Claude commands.
2. Identify which rule/playbook was violated.
3. Check whether files changed.
4. If no files changed, revise prompt and record the failure.
5. If files changed, inspect diff and classify damage before repair.
6. Use Claude for narrow repair unless emergency minimal recovery is required.
7. Add the bad instruction pattern to the relevant playbook.

### User changes direction mid-task

1. Stop current task queue.
2. Preserve current partial state with status: completed / partial / not started.
3. Do not delete partial files or backups.
4. Update Active Memory Index or active playbook status if the active task changes.
5. Re-run SESSION_START classification for the new direction.
6. Continue only with the newest user instruction.

## Rule Override / 이의제기

If a rule blocks real progress:

1. Do not silently ignore it.
2. Record why the rule is blocking.
3. Propose a safer exception.
4. Ask the user unless it is urgent data-loss prevention.

## 작업 도메인 Playbook Template

새 반복 작업이 생기면 `docs/operating_memory/<task>_playbook.md`를 만든다.

```text
# <Task> Playbook

> Status:
> Verified as of:
> Owner split:
> Current stable state:
> Forbidden files:
> Required startup checks:
> Required done checks:
> Known incidents:
> Recovery:
> Next recommended action:
> Prompt templates:
> Quality rules:
```

## Active Playbooks

| Playbook | Status | Verified as of | Purpose |
|---|---|---|---|
| `docs/operating_memory/memory_routing.md` | Active | 2026-05-16 | 상황별 메모리 검색/읽기/기록 위치 결정, no-match/multi-match 라우팅 |
| `docs/operating_memory/celebrity_db_playbook.md` | Active | 2026-05-16 | 셀럽 DB 300명 확장 절차, Claude 사고 대응, count/test/backup 규칙 |

## 다른 메모리와의 정합성

- Round history / product backlog가 기존 `인수인계.md`, `RESUME.md`, `docs/*.md`, Claude memory에 있을 수 있다.
- This file is canonical for **operating protocol**.
- Task-specific playbooks are canonical for **current task procedure**.
- If this file conflicts with current user instruction, current user instruction wins.
- If old project docs conflict with this file's safety rules, follow this file or ask.

## 운영 학습 로그

### 2026-05-16 — 운영 메모리 v2 재구성

- Before state: `new인수인계.md`가 운영 헌법과 셀럽 DB 세부 로그를 한 파일에 섞어 804 lines.
- After state: main file은 운영 헌법/게이트/복구/인덱스 중심으로 축소, 셀럽 DB는 playbook으로 분리.
- Files intentionally changed:
  - `new인수인계.md`
  - `docs/operating_memory/celebrity_db_playbook.md`
- Commands proving state:
  - `wc -l new인수인계.md`
  - `sed -n '1,220p' new인수인계.md`
- New failure learned: 특정 작업 메모리를 메인 운영 메모리에 섞으면 범용성이 떨어지고 다음 세션 진입 비용이 커진다.
- Rule promoted: task detail은 playbook으로 분리, main file은 active index와 mandatory gates 중심.
- Open risk: 향후 playbook이 많아지면 index maintenance가 필요.
- Next session first action: `SESSION_START Gate` 실행 후 active playbook 확인.

### 2026-05-16 — 앱 전반 품질 감사 quick repair

- Before state: user requested A-to-Z Pillar Seer audit. Worktree already had many dirty files. `flutter test` failed in `content_integrity_test.dart` because celebrity Korean blurbs still contained awkward/forbidden wording such as standalone `결.` and weapon imagery.
- After state: celebrity `blurbKo` problem entries were rewritten without changing ids/birth/dayPillar schema; user-facing Pro/Phase 2/coming-soon copy was softened; first-fold "오늘은 ...의 날이야" copy was changed to a contextual "분위기가 강해" line; l10n generated files refreshed.
- Files intentionally changed:
  - `assets/data/celebrities.json`
  - `lib/l10n/app_ko.arb`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_localizations.dart`
  - `lib/l10n/app_localizations_ko.dart`
  - `lib/l10n/app_localizations_en.dart`
  - `lib/screens/home_screen.dart`
  - `new인수인계.md`
- Commands proving state:
  - `flutter analyze` -> No issues found
  - `flutter test` -> All tests passed, 760 pass
  - `flutter test test/content_integrity_test.dart` -> All tests passed
  - `flutter test test/round82_match_badge_label_test.dart test/round84_crossmatch_copy_test.dart test/round84_today_screen_ctx_test.dart` -> All tests passed
  - `jq length assets/data/celebrities.json` -> 223
  - klc spot/full celebrity day-pillar script -> `checked=223 mismatches=0`
- New failure learned: Broad Claude prompt covering data + l10n + code can hang after partial edits and may drift into nearby dirty code. Split future prompts by file group and inspect diff after 60s no-output.
- Rule promoted/deprecated: Promote narrow Claude calls for audit repair: data hygiene first, then l10n copy, then widget copy. Do not combine all in one prompt when the worktree is already dirty.
- Open risk: This was a quick repair, not a true full product audit of every deep-slice/persona pool. Existing unrelated dirty files remain and may contain older work in progress.
- Next session first action: If continuing quality audit, start with source-level grep for user-facing `결|기운|Phase 2|Pro|coming soon|dummy|fallback`, then classify by data/code/l10n before edits.
- quality: routing 9/10, safety 8/10, accuracy 9/10, tests 10/10, content 8/10, efficiency 7/10

## 자가 감사 주기

Every 5 sessions or after a major failure:

- Run a meta-review of this file.
- Ask Claude and a Codex subagent for scores using the same rubric: routing, safety, accuracy, tests, content, efficiency.
- Target: both reviewers >= 9.9.
- If below 9.9, patch this file/playbooks and repeat.
