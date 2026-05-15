# Seephone Codex Auto-Start Instructions

This monorepo uses Pillar Seer operating memory as the current canonical Codex+Claude workflow memory.

MUST at the start of every Codex session launched from `/Users/seunghyeon/seephone` or any child directory:

1. If the task touches `pillarseer` or is unclear, read `pillarseer/new인수인계.md` before planning or editing.
2. Follow `pillarseer/new인수인계.md` `SESSION_START Gate`.
3. If the task has an active playbook, read it before work.
4. Keep Codex as planner/reviewer and Claude CLI as code/data editor unless the user explicitly overrides or emergency recovery requires a minimal direct fix.
5. Do not delete or revert files unless the user explicitly approves. Preserve unrelated dirty files.
6. For monorepo-wide Claude/HANDOFF/Mac-Windows rules, also respect `CLAUDE.md` and `.claude-shared/`.

Current Pillar Seer operating memory:

- `pillarseer/new인수인계.md`
- `pillarseer/docs/operating_memory/celebrity_db_playbook.md`

If this file conflicts with newer user/system/developer instructions, follow the newer instruction. If it conflicts with `pillarseer/new인수인계.md` for a Pillar Seer task, `pillarseer/new인수인계.md` is the detailed source of truth.

