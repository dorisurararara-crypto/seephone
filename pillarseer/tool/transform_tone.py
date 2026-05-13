#!/usr/bin/env python3
"""Pillarseer 톤 검수 + 변환 제안 CLI — Round 67/71 톤 가이드 enforce.

해결 사용자 불만:
- #6 확정 단정조 (헷지 금지)
- #4 콜드리딩 hit rate (high-base-rate 단정 ≥2개 / entry)
- #2 콜드리딩 표현 약함 (예언 같지 않음)

사용:
    python3 tool/transform_tone.py --file assets/data/saju_deep_slice_20_39.json
    python3 tool/transform_tone.py --all --report-md /tmp/tone_report.md
    python3 tool/transform_tone.py --preview 甲申.dayMasterDeep --all

룰 정의는 `tool/tone/rules.py`, 분석 로직은 `tool/tone/analyze.py` 분리.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tone import (  # noqa: E402
    EntryReport,
    analyze_file,
    HEDGE_RULES, ADVISORY_RULES, PROTECTOR_RULES, ORACLE_RULES, KPOP_ABSTRACT_RULES,
)
from tone.analyze import _literal_len  # noqa: E402

ALL_FILES = [
    'assets/data/saju_deep_slice_0_19.json',
    'assets/data/saju_deep_slice_20_39.json',
    'assets/data/saju_deep_slice_40_59.json',
]


def summarize(reports: List[EntryReport]) -> Dict:
    total = len(reports)
    if not total:
        return {'entries_total': 0}
    passing = sum(1 for r in reports if r.passes)
    return {
        'entries_total': total,
        'entries_passing': passing,
        'pass_rate': round(passing / total * 100, 1),
        'hedge_total': sum(len(r.hedge_hits) for r in reports),
        'advisory_total': sum(len(r.advisory_hits) for r in reports),
        'protector_total': sum(len(r.protector_hits) for r in reports),
        'oracle_total': sum(len(r.oracle_hits) for r in reports),
        'kpop_abstract_total': sum(len(r.kpop_abstract_hits) for r in reports),
        'cold_reading_total': sum(r.cold_reading_hits for r in reports),
        'time_prediction_total': sum(len(r.time_prediction_hits) for r in reports),
        'avg_assertion_ratio': round(sum(r.assertion_ratio for r in reports) / total, 3),
        'avg_sentence_count': round(sum(r.sentence_count for r in reports) / total, 1),
    }


def print_table(reports: List[EntryReport]) -> None:
    print(
        f"{'ji60':<6}{'cat':<16}{'sent':>5}{'avg':>6}"
        f"{'hedge':>6}{'adv':>5}{'prot':>5}{'orac':>5}{'kpop':>5}"
        f"{'asrt%':>7}{'cold':>5}{'time':>5}  pass"
    )
    print('─' * 100)
    for r in reports:
        ok = 'YES' if r.passes else 'no'
        print(
            f"{r.ji60:<6}{r.category:<16}{r.sentence_count:>5}{r.avg_char_per_sentence:>6.1f}"
            f"{len(r.hedge_hits):>6}{len(r.advisory_hits):>5}{len(r.protector_hits):>5}"
            f"{len(r.oracle_hits):>5}{len(r.kpop_abstract_hits):>5}"
            f"{r.assertion_ratio*100:>6.0f}%{r.cold_reading_hits:>5}{len(r.time_prediction_hits):>5}  {ok}"
        )


def write_report_md(reports: List[EntryReport], out_path: Path, max_offenders: int) -> None:
    summary = summarize(reports)
    lines: List[str] = ['# Pillarseer 톤 검수 보고서 (Round 67/71 톤 가이드)', '']
    lines.append(f'## Summary ({summary["entries_total"]} ko 블록 검사 완료)')
    for k, v in summary.items():
        lines.append(f'- **{k}**: {v}')
    lines.append('')
    lines.append('## Entry-level 카운트 표 (전체)')
    lines.append('')
    lines.append('| ji60 | category | 문장 | 평균자 | 헷지 | adv | prot | orac | kpop | 단정% | 콜드 | 시점 | range^ | forer | PASS |')
    lines.append('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---:|')
    for r in reports:
        ok = '✓' if r.passes else '×'
        lines.append(
            f'| {r.ji60} | {r.category} | {r.sentence_count} | {r.avg_char_per_sentence} |'
            f' {len(r.hedge_hits)} | {len(r.advisory_hits)} | {len(r.protector_hits)} |'
            f' {len(r.oracle_hits)} | {len(r.kpop_abstract_hits)} |'
            f' {r.assertion_ratio*100:.0f}% | {r.cold_reading_hits} |'
            f' {len(r.time_prediction_hits)} | {r.out_of_range_sentence_count} |'
            f' {r.forer_hits} | {ok} |'
        )
    lines.append('')
    lines.append('_range^ = 30~80 자 범위 이탈 문장 수._')
    lines.append('')
    lines.append('## Top offenders (위반 합계 기준)')
    lines.append('')
    fails = sorted(
        [r for r in reports if not r.passes],
        key=lambda r: r.violations_count, reverse=True,
    )
    shown = fails[:max_offenders]
    if not shown:
        lines.append('_없음 — 모든 entry PASS_')
    for r in shown:
        lines.append(
            f'### {r.ji60} / {r.category}  '
            f'(위반 {r.violations_count} · 단정 {r.assertion_ratio*100:.0f}% · '
            f'콜드 {r.cold_reading_hits} · 시점 {len(r.time_prediction_hits)} · 문장 {r.sentence_count})'
        )
        if r.hedge_hits:
            lines.append('- 헷지 → 단정 치환 제안:')
            for h in r.hedge_hits[:6]:
                lines.append(f'  - `{h.snippet}` → `{h.suggestion}`')
        if r.advisory_hits:
            lines.append('- advisory → 단정 치환 제안:')
            for h in r.advisory_hits[:6]:
                lines.append(f'  - `{h.snippet}` → `{h.suggestion}`')
        if r.protector_hits:
            lines.append('- 보호자체 → 명령 치환 제안:')
            for h in r.protector_hits[:6]:
                lines.append(f'  - `{h.snippet}` → `{h.suggestion}`')
        if r.oracle_hits:
            lines.append('- 점쟁이체 치환 제안:')
            for h in r.oracle_hits[:6]:
                lines.append(f'  - `{h.snippet}` → `{h.suggestion}`')
        if r.kpop_abstract_hits:
            lines.append('- K-pop 추상 비유 치환 제안:')
            for h in r.kpop_abstract_hits[:6]:
                lines.append(f'  - `{h.snippet}` → `{h.suggestion}`')
        if r.cold_reading_examples:
            lines.append('- 콜드리딩 현재 hit 예시:')
            for s in r.cold_reading_examples[:2]:
                lines.append(f'  - {s}')
        lines.append('')
    lines.append(f'_총 fail {len(fails)} 중 상위 {len(shown)} 개만 표시. `--max-offenders N` 으로 조정 가능._')
    out_path.write_text('\n'.join(lines), encoding='utf-8')


def _apply_rules(text: str, rules: List[Tuple[str, str]]) -> str:
    """길이 내림차순 1:1 치환 (preview)."""
    out = text
    for pat, sugg in sorted(rules, key=lambda r: -_literal_len(r[0])):
        out = re.sub(pat, sugg, out)
    return out


def _print_preview(targets: List[Path], key: str, is_kpop_compat: bool) -> None:
    try:
        ji60, category = key.split('.', 1)
    except ValueError:
        print(f'!! --preview 형식 오류: {key} (예: 甲申.dayMasterDeep)', file=sys.stderr)
        return
    for path in targets:
        data = json.loads(path.read_text(encoding='utf-8'))
        for entry in data:
            if entry.get('ji60') != ji60:
                continue
            text = entry.get('ko', {}).get(category, '')
            if not text:
                continue
            print(f'\n=== Preview: {ji60} / {category} ({path.name}) ===')
            print(f'BEFORE:\n  {text}\n')
            after = _apply_rules(text, HEDGE_RULES)
            after = _apply_rules(after, ADVISORY_RULES)
            after = _apply_rules(after, PROTECTOR_RULES)
            after = _apply_rules(after, ORACLE_RULES)
            if not is_kpop_compat:
                after = _apply_rules(after, KPOP_ABSTRACT_RULES)
            print(f'AFTER (rule-only auto-replace — 사람·LLM 추가 다듬기 필요):\n  {after}\n')
            return
    print(f'!! ji60={ji60} 카테고리={category} 못 찾음', file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser(
        description='Pillarseer 톤 검수 + 변환 제안 (Round 67/71 톤 가이드 enforce)')
    ap.add_argument('--file', help='검사할 파일 한 개')
    ap.add_argument('--all', action='store_true', help='3종 saju_deep_slice 전체')
    ap.add_argument('--report-md', help='Markdown 보고서 출력 경로')
    ap.add_argument('--summary-only', action='store_true', help='entry 표 생략')
    ap.add_argument('--max-offenders', type=int, default=30)
    ap.add_argument('--kpop-compat', action='store_true',
                    help='kpop 추상 비유 위반 검사 제외 (kpop_compat 콘텐츠 검사 시)')
    ap.add_argument('--fail-on-violation', action='store_true',
                    help='어느 entry라도 PASS 미달이면 종료코드 1 (CI gate)')
    ap.add_argument('--preview', metavar='JI60.CATEGORY',
                    help='예: 甲申.dayMasterDeep — 1차 치환 dry-run preview')
    args = ap.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    targets: List[Path]
    if args.all:
        targets = [repo_root / p for p in ALL_FILES]
    elif args.file:
        p = Path(args.file)
        targets = [p if p.is_absolute() else repo_root / p]
    else:
        ap.error('--file 또는 --all 중 하나 필수')
        return 2

    all_reports: List[EntryReport] = []
    for path in targets:
        if not path.exists():
            print(f'!! 파일 없음: {path}', file=sys.stderr)
            return 1
        reports = analyze_file(path, is_kpop_compat=args.kpop_compat)
        all_reports.extend(reports)
        print(f'== {path.name} ({len(reports)} entries) ==')
        if not args.summary_only:
            print_table(reports)
        print('')

    summary = summarize(all_reports)
    print(f'== Summary ({summary["entries_total"]} ko 블록 검사 완료) ==')
    for k, v in summary.items():
        print(f'  {k}: {v}')

    if args.report_md:
        out = Path(args.report_md)
        write_report_md(all_reports, out, max_offenders=args.max_offenders)
        print(f'\n보고서 작성: {out}')

    if args.preview:
        _print_preview(targets, args.preview, is_kpop_compat=args.kpop_compat)

    if args.fail_on_violation and summary.get('entries_passing', 0) < summary.get('entries_total', 0):
        fails = summary['entries_total'] - summary['entries_passing']
        print(f'\n!! CI gate: {fails} entry PASS 미달 — 종료코드 1', file=sys.stderr)
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
