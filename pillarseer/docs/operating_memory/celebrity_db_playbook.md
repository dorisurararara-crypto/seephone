# Celebrity DB Playbook — 300명 확장

> Status: Current active task memory  
> Verified as of: 2026-05-16 KST  
> Canonical source for 셀럽 DB 확장 세부 절차. `new인수인계.md`는 운영 헌법과 인덱스만 유지한다.

## Current Stable State

- `assets/data/celebrities.json`: 223 entries
- Last completed batches:
  - TREASURE +10: 207 -> 217
  - P1Harmony +6: 217 -> 223
- Test: `flutter test test/round83_celebrity_disclosure_test.dart` passed 30/30
- Duplicate id check: no output
- Stable backups:
  - `.codex_backups/celebrities_217_stable.json`
  - `.codex_backups/celebrities_223_stable.json`
- Forbidden unrelated file: `ios/Podfile.lock`

## Operating Rule For This Task

- Codex plans, calculates, verifies, and updates memory.
- Claude CLI edits `assets/data/celebrities.json` and `test/round83_celebrity_disclosure_test.dart`.
- Codex does not directly perform bulk JSON/test edits unless user explicitly overrides or emergency recovery requires minimal repair.
- Prefer separate Claude calls:
  - Call 1: data append only.
  - Codex verifies data.
  - Call 2: regression test update only.
  - Codex runs final checks.

## Mandatory Checks

Before editing.

EXACT:

```bash
git status --short
jq length assets/data/celebrities.json
ls -1 .codex_backups | tail
```

After each data edit.

TEMPLATE: replace `<new_id>`, `<GROUP>`, `<new_count>`, and `<new_pattern>` before running.

```bash
jq length assets/data/celebrities.json
jq -r '.[].id' assets/data/celebrities.json | sort | uniq -d
rg -n "<new_id>|<GROUP>|<new_count>" assets/data/celebrities.json test/round83_celebrity_disclosure_test.dart
jq -r '.[] | select(.id|test("<new_pattern>")) | [.id,.dayPillar,.dayPillarName,.blurbKo,.blurbEn] | @tsv' assets/data/celebrities.json
flutter test test/round83_celebrity_disclosure_test.dart
```

After stable pass.

TEMPLATE: replace `<count>` before running.

```bash
cp assets/data/celebrities.json .codex_backups/celebrities_<count>_stable.json
```

## Entry Schema

Key order:

```json
{
  "id": "...",
  "nameEn": "...",
  "nameKo": "...",
  "kind": "idol",
  "birth": "YYYY-MM-DD",
  "dayPillar": "癸卯",
  "dayPillarName": "Water Rabbit",
  "blurbEn": "...",
  "blurbKo": "...",
  "gender": "M"
}
```

Allowed `kind`:

- `idol`
- `actor`
- `icon`

## Blurb Rules

MUST:

- `blurbKo` mentions group/job naturally.
- Blurb reflects `dayPillarName` imagery.
- Same group entries should not read like repeated templates.

MUST NOT:

- raw hanja in blurb
- `일주`
- `결`
- weapon wording
- birth hour/time certainty
- medical, fatalistic, or romantic claim
- English `day master`

## Day Pillar Calculation

Use app dependency `klc`, not external calculators.

Template:

```bash
tmp=$(mktemp /tmp/pillars_XXXX.dart)
printf '%s\n' \
"import 'package:klc/klc.dart';" \
"void main(){" \
"final dates=[(2001,9,27,'keeho_p1h')];" \
"for(final d in dates){setSolarDate(d.\$1,d.\$2,d.\$3); print('\${d.\$4}=\${getChineseGapJaString()}');}" \
"}" > "$tmp"
dart --packages=.dart_tool/package_config.json "$tmp"
rm "$tmp"
```

Use only the day part, e.g. `癸巳日` -> `癸巳`.

Mapping:

- 甲/乙 Wood
- 丙/丁 Fire
- 戊/己 Earth
- 庚/辛 Metal
- 壬/癸 Water
- 子 Rat, 丑 Ox, 寅 Tiger, 卯 Rabbit, 辰 Dragon, 巳 Snake, 午 Horse, 未 Goat, 申 Monkey, 酉 Rooster, 戌 Dog, 亥 Pig

## Completed New Batches

### TREASURE 10

- `hyunsuk_trsr` — 1999-04-21 — `癸卯` — Water Rabbit
- `jihoon_trsr` — 2000-03-14 — `辛未` — Metal Goat
- `yoshi_trsr` — 2000-05-15 — `癸酉` — Water Rooster
- `junkyu_trsr` — 2000-09-09 — `庚午` — Metal Horse
- `jaehyuk_trsr` — 2001-07-23 — `丁亥` — Fire Pig
- `asahi_trsr` — 2001-08-20 — `乙卯` — Wood Rabbit
- `doyoung_trsr` — 2003-12-04 — `辛亥` — Metal Pig
- `haruto_trsr` — 2004-04-05 — `甲申` — Wood Monkey
- `jeongwoo_trsr` — 2004-09-28 — `庚戌` — Metal Dog
- `junghwan_trsr` — 2005-02-18 — `癸酉` — Water Rooster

### P1Harmony 6

- `keeho_p1h` — 2001-09-27 — `癸巳` — Water Snake
- `theo_p1h` — 2001-07-01 — `乙丑` — Wood Ox
- `jiung_p1h` — 2001-10-07 — `癸卯` — Water Rabbit
- `intak_p1h` — 2003-08-31 — `丙子` — Fire Rat
- `soul_p1h` — 2005-02-01 — `丙辰` — Fire Dragon
- `jongseob_p1h` — 2005-11-19 — `丁未` — Fire Goat

## Known Incidents

### File Truncation

Claude once truncated `assets/data/celebrities.json` to 62 entries during edit. It was recovered from `build/unit_test_assets/assets/data/celebrities.json` at 182 entries, then backed up.

Recovery if count decreases unexpectedly:

1. Stop all further edits.
2. Confirm latest stable backup:

```bash
ls -1 .codex_backups/celebrities_*_stable.json | sort | tail
```

3. Compare count:

```bash
jq length assets/data/celebrities.json
jq length .codex_backups/celebrities_<count>_stable.json
```

4. Restore only after confirming the latest known-good backup:

```bash
cp .codex_backups/celebrities_<count>_stable.json assets/data/celebrities.json
flutter test test/round83_celebrity_disclosure_test.dart
```

### Claude Hangs

- Heredoc prompts often hung.
- Prefer:

```bash
printf '%s\n' "prompt..." | claude -p --model opus --permission-mode bypassPermissions --allowedTools Bash
```

Timeout policy:

- 60s no output: check whether files changed.
- 120s no output and no file change: kill only the matching `claude -p` process.
- 2 failures: split data edit and test edit.
- 4 failures: stop and report to user.

### Test Update Omission

TREASURE data was appended but test baseline and B4 block were initially missing. Always grep both data and test files.

### Blurb Quality Violation

P1Harmony initially included forbidden `결` and English `day master`. Tests passed, but content quality failed. Always inspect new blurbs manually.

## Next Recommended Batch

Current target remains 300 entries if user resumes. From 223, need +77.

Recommended next batch: NCT/WayV selected 10.

Source status: Assumption from prior working memory, not freshly browsed in this document. MUST re-check public birthday/name data before Claude edits, because current celebrity data can be stale or disputed.

| id | name | birth | gender | source status |
|---|---|---:|:---:|---|
| `taeyong_nct` | Taeyong | 1995-07-01 | M | Must re-check before use |
| `yuta_nct` | Yuta | 1995-10-26 | M | Must re-check before use |
| `doyoung_nct` | Doyoung | 1996-02-01 | M | Must re-check before use |
| `ten_wayv` | Ten | 1996-02-27 | M | Must re-check before use |
| `jaehyun_nct` | Jaehyun | 1997-02-14 | M | Must re-check before use |
| `winwin_wayv` | Winwin | 1997-10-28 | M | Must re-check before use |
| `jungwoo_nct` | Jungwoo | 1998-02-19 | M | Must re-check before use |
| `xiaojun_wayv` | Xiaojun | 1999-08-08 | M | Must re-check before use |
| `hendery_wayv` | Hendery | 1999-09-28 | M | Must re-check before use |
| `yangyang_wayv` | Yangyang | 2000-10-10 | M | Must re-check before use |

Then consider:

- TWICE 9
- ATEEZ 8
- Stray Kids remaining 7
- BTS remaining 4
- K-drama actors 10-20
- global solo/icon 10-20

Birthdays/current popularity can change or be uncertain for newer groups. Browse and verify before adding uncertain entries.
