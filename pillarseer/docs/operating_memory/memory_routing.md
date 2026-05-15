# Memory Routing Playbook

> Status: Active operating playbook  
> Verified as of: 2026-05-16 KST  
> Purpose: 새 세션이 어떤 상황에서 무엇을 읽고, 어디를 검색하고, 어디에 기록할지 결정하는 라우팅 규칙.

## Source Roots

Use absolute roots so commands work from `/Users/seunghyeon`, `/Users/seunghyeon/seephone`, or `/Users/seunghyeon/seephone/pillarseer`.

| Scope | Root |
|---|---|
| home | `/Users/seunghyeon` |
| monorepo | `/Users/seunghyeon/seephone` |
| Pillar Seer | `/Users/seunghyeon/seephone/pillarseer` |
| operating memory | `/Users/seunghyeon/seephone/pillarseer/docs/operating_memory` |
| shared Claude memory | `/Users/seunghyeon/seephone/.claude-shared` |

## Required Memory Sources

Always consider these layers.

1. Current user/system/developer instructions.
2. Nearest `AGENTS.md`.
3. `/Users/seunghyeon/seephone/pillarseer/new인수인계.md`.
4. Relevant operating playbook under `docs/operating_memory`.
5. Monorepo rules: `/Users/seunghyeon/seephone/CLAUDE.md`, `/Users/seunghyeon/seephone/HANDOFF.md`.
6. Shared Claude rules/memory: `/Users/seunghyeon/seephone/.claude-shared/global*.md`, `/Users/seunghyeon/seephone/.claude-shared/memory/`.
7. Repo docs/source/tests.
8. Web, only when facts may be stale or source content is not local.

## Routing Table

| Situation | Read first | Search keywords | Write destination |
|---|---|---|---|
| operating protocol / Codex-Claude collaboration / session automation | `new인수인계.md`, `AGENTS.md`, this playbook | `Codex`, `Claude`, `SESSION_START`, `운영`, `자동`, `routing` | `new인수인계.md` operating log |
| monorepo / Mac-Windows handoff / shared Claude rules | `seephone/CLAUDE.md`, `HANDOFF.md`, `.claude-shared/global*.md` | `HANDOFF`, `Mac`, `Windows`, `global`, `memory` | `HANDOFF.md` for task handoff/status. `.claude-shared/memory/` only for cross-machine operating rules or durable lessons that both machines must inherit |
| repeated task procedure | relevant `*_playbook.md` | task name, file name, domain keywords | relevant playbook |
| celebrity DB / K-pop / actors | `celebrity_db_playbook.md` | `celebrity`, `셀럽`, `K-pop`, `birth`, `dayPillar` | `celebrity_db_playbook.md` |
| saju accuracy / manseryeok / calculation logic | existing docs/source, create playbook if recurring | `사주`, `만세력`, `Manseryeok`, `klc`, `dayPillar` | `saju_accuracy_playbook.md` if criteria pass |
| UI/UX / screen / design | design docs/source, create playbook if recurring | `UI`, `UX`, `screen`, `디자인`, `화면`, screen name | `ui_ux_playbook.md` if criteria pass |
| content tone / copy / forbidden words | tone docs, relevant playbook | `tone`, `금지어`, `blurb`, `문체`, `자연스러움` | `content_tone_playbook.md` if criteria pass |
| testing / QA / regression | test files, relevant playbook | `test`, `regression`, `flutter test`, `QA` | `testing_playbook.md` if criteria pass |
| deploy / TestFlight / ASC | `CLAUDE.md`, scripts, fastlane docs | `TestFlight`, `ASC`, `deploy`, `fastlane` | `deploy_playbook.md` if criteria pass |
| Claude incident / recovery | `new인수인계.md`, relevant playbook | `truncate`, `hang`, `recovery`, `dirty`, `kill` | relevant playbook Known Incidents |
| file growth / deletion / archive decision | `new인수인계.md`, this playbook | `archive`, `delete`, `backup`, `bloat`, `임시` | `new인수인계.md` or relevant playbook |

## No-Match Fallback

If no row matches:

1. Read nearest `AGENTS.md`.
2. Search `new인수인계.md` and `docs/operating_memory`.
3. Search `CLAUDE.md`, `HANDOFF.md`, `.claude-shared/global*.md`, `.claude-shared/memory/`.
4. Search repo docs/source/tests using user nouns and file names.
5. If still unclear, classify as `unknown-domain`.
6. For unknown-domain file changes, ask the user or create a short investigation note before editing.

## Multi-Match Priority

If multiple rows match:

1. Safety/recovery rules first.
2. Current user instruction.
3. Active task playbook.
4. Domain-specific playbook.
5. General operating memory.
6. Older docs/history.

If the task spans two domains, read both. Record output in the domain whose files were changed. If files changed in both domains, record in both playbooks or create a cross-domain note.

## Search Commands

EXACT base search from any cwd:

```bash
rg -n "<user_keyword>|<domain_keyword>" \
  /Users/seunghyeon/AGENTS.md \
  /Users/seunghyeon/seephone/pillarseer/new인수인계.md \
  /Users/seunghyeon/seephone/pillarseer/docs/operating_memory \
  /Users/seunghyeon/seephone/pillarseer/AGENTS.md \
  /Users/seunghyeon/seephone/AGENTS.md \
  /Users/seunghyeon/seephone/CLAUDE.md \
  /Users/seunghyeon/seephone/HANDOFF.md \
  /Users/seunghyeon/seephone/.claude-shared
```

TEMPLATE examples:

```bash
rg -n "셀럽|celebrity|K-pop|birth|dayPillar" /Users/seunghyeon/seephone/pillarseer /Users/seunghyeon/seephone/.claude-shared
rg -n "사주|만세력|Manseryeok|klc|dayPillar" /Users/seunghyeon/seephone/pillarseer/docs /Users/seunghyeon/seephone/pillarseer/lib /Users/seunghyeon/seephone/pillarseer/test
rg -n "TestFlight|ASC|fastlane|deploy" /Users/seunghyeon/seephone/CLAUDE.md /Users/seunghyeon/seephone/pillarseer/scripts /Users/seunghyeon/seephone/pillarseer/fastlane
rg -n "UI|UX|screen|디자인|화면" /Users/seunghyeon/seephone/pillarseer/docs /Users/seunghyeon/seephone/pillarseer/lib/screens /Users/seunghyeon/seephone/pillarseer/lib/widgets
```

Keyword policy:

- Use both Korean and English terms when possible.
- Include file names, feature names, route names, class names, and user nouns.
- If first search misses, broaden from exact feature to domain terms.

## Write Routing

| What happened | Where to record |
|---|---|
| universal operating rule changed | `new인수인계.md` |
| routing rule changed | this file |
| task-specific procedure changed | relevant playbook |
| Claude incident | relevant playbook `Known Incidents` |
| mid-task direction change | relevant playbook `Partial State` section; if no playbook, `new인수인계.md` operating log |
| session quality score / operating hypothesis result | `new인수인계.md` operating log, and relevant playbook if domain-specific |
| stale active snapshot fixed | `new인수인계.md` Active Memory Index + relevant playbook |
| old detail archived | archive file + one-line pointer in source file |

## Playbook Creation Rule

Create or update a playbook when any MUST condition applies:

- Same work type is likely to repeat.
- Claude will receive reusable prompts/commands.
- Recovery procedure is needed.
- User preference/forbidden pattern affects quality.
- The detail would add 40+ lines to `new인수인계.md`.

Skip only when:

- It is a one-off answer with no file change.
- It naturally belongs in an existing playbook.

This replaces weaker “two or more criteria” thresholds.

## Direction Change Protocol

When the user changes direction mid-task:

1. Stop current task queue.
2. Write partial state using Doc Update Transaction format.
3. Destination:
   - relevant playbook `Partial State` section if one exists.
   - otherwise `new인수인계.md` operating log.
4. Mark status: `completed`, `partial`, `blocked`, or `not started`.
5. Do not delete partial files or backups.
6. Re-run routing classification for the new request.
7. Continue only with newest user instruction.

## Routing Quality Score

Session quality must include routing:

```text
quality: routing ?/10, safety ?/10, accuracy ?/10, tests ?/10, content ?/10, efficiency ?/10
```

Routing score asks:

- Did the session read the right AGENTS / memory / playbook?
- Did it search the right local/shared docs?
- Did it write learning to the right place?
- Did it create or skip playbooks correctly?

## Pointer Integrity Check

Before final answer when memory files changed:

EXACT:

```bash
test -f /Users/seunghyeon/seephone/pillarseer/new인수인계.md
test -d /Users/seunghyeon/seephone/pillarseer/docs/operating_memory
test -f /Users/seunghyeon/seephone/pillarseer/AGENTS.md
test -f /Users/seunghyeon/seephone/AGENTS.md
test -f /Users/seunghyeon/AGENTS.md
test -f /Users/seunghyeon/seephone/CLAUDE.md
test -f /Users/seunghyeon/seephone/HANDOFF.md
test -f /Users/seunghyeon/seephone/.claude-shared/global.md
test -d /Users/seunghyeon/seephone/.claude-shared/memory
```

If a referenced file is missing, fix the pointer or report the missing file.
