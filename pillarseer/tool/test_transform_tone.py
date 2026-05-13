#!/usr/bin/env python3
"""transform_tone.py 룰 회귀 테스트 (pure python — flutter test 무관).

실행:
    python3 tool/test_transform_tone.py

모든 assertion 통과 시 종료코드 0. 실패 시 즉시 raise.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tone import (  # noqa: E402
    collect_hits,
    count_cold_reading,
    count_strong_time_prediction,
    count_forer,
    count_out_of_range,
    split_sentences,
    analyze_entry,
    HEDGE_RULES,
    ADVISORY_RULES,
    PROTECTOR_RULES,
    KPOP_ABSTRACT_RULES,
)


def t_hedge_basic() -> None:
    h = collect_hits('당신은 할 수 있어요.', HEDGE_RULES)
    assert len(h) == 1, f'할 수 있어요 expected 1 hit, got {len(h)}: {h}'
    assert h[0].snippet == '할 수 있어요'
    assert h[0].suggestion == '한다'


def t_hedge_dedupe() -> None:
    # `할 수 있어요` 가 `있어요` 보다 길어서 dedupe 효과로 1 hit 만.
    h = collect_hits('너는 그것을 할 수 있어요. 옆에 있어요.', HEDGE_RULES)
    snippets = sorted(x.snippet for x in h)
    assert '할 수 있어요' in snippets
    assert '있어요' in snippets  # 두 번째 문장의 standalone
    assert len(h) == 2


def t_hedge_expanded() -> None:
    h = collect_hits('자라요. 풀려요. 봐요. 와요. 새는 돈이 생겨요.', HEDGE_RULES)
    snippets = sorted(x.snippet for x in h)
    # 자라요/풀려요/봐요/와요/새는 돈이 생겨 모두 캐치
    assert '자라요' in snippets
    assert '풀려요' in snippets
    assert '봐요' in snippets
    assert '와요' in snippets
    assert '새는 돈이 생겨' in snippets


def t_advisory() -> None:
    h = collect_hits('이게 도움됩니다. 추천드려요. 게 좋아요.', ADVISORY_RULES)
    assert len(h) == 3


def t_protector() -> None:
    h = collect_hits('에너지를 아끼세요. 조심하세요.', PROTECTOR_RULES)
    assert len(h) == 2


def t_kpop_particles() -> None:
    h = collect_hits('함께 무대를 만든다. 무대가 있다. 무대는 즐겁다.', KPOP_ABSTRACT_RULES)
    assert len(h) == 3, f'무대 + 조사 3 형태 expected 3, got {len(h)}'


def t_kpop_dedupe_long_first() -> None:
    h = collect_hits('무대 위에서. 단독 무대를 만든다.', KPOP_ABSTRACT_RULES)
    snippets = sorted(x.snippet for x in h)
    assert '무대 위' in snippets  # 긴 패턴 먼저
    assert '무대' in snippets  # 두 번째 문장 plain


def t_cold_reading_three_conditions() -> None:
    # anchor + 구체 명사 + 단정 종결 3 조건 모두 충족
    t = '지난주에도 한 번 그랬지. 이번 달 안에 한 명한테 먼저 연락하는 일이 생긴다.'
    sents = split_sentences(t)
    n, _ = count_cold_reading(t, sents)
    assert n == 2, f'cold expected 2, got {n}'


def t_cold_reading_missing_assertion() -> None:
    # anchor + 명사 있지만 단정 종결 없음 → 0 hit
    t = '지난주에 카톡을 보냈는데요.'
    sents = split_sentences(t)
    n, _ = count_cold_reading(t, sents)
    assert n == 0


def t_out_of_range() -> None:
    sents = ['짧음.', 'b' * 50, 'c' * 100, 'd' * 35]
    n = count_out_of_range(sents)
    assert n == 2, f'expected 2 out-of-range (5자, 100자), got {n}'


def t_forer() -> None:
    n = count_forer('한 명은 담담한 너, 한 명은 곱씹는 너이다.')
    assert n >= 1


def t_analyze_entry_pass() -> None:
    """End-to-end PASS proof — tone_guide §5 예시 1 (甲申 dayMasterDeep After 문안) 변형.

    각 문장 30~80 자 범위 + 7~12 문장 + 헷지 0 + 단정 ≥60% + 콜드 ≥2 + 시점 ≥1.
    """
    ko = (
        '당신은 안과 밖이 다른 사람이다. '
        '밖에선 단단한 사람으로 보이지만 안에서는 의외로 무른 곳이 있다. '
        '결정은 빠르고 그 결정을 혼자 두세 번 되감는 사람이다. '
        '지난주에도 한 번 그 결정을 머릿속에서 다시 곱씹은 적이 있다고 본다. '
        '가까운 사람 한 명한테 먼저 연락하고 싶었지만 결국 안 보냈다. '
        '너는 계산이 많은 사람이고 그게 너의 가장 큰 무기로 작동한다. '
        '하지만 그 계산을 상대가 눈치챈 순간 너에 대한 신뢰는 닫힌다. '
        '이번 달 안에 한 번, 평소 너답지 않게 먼저 연락하는 일이 생긴다. '
        '그게 너의 다음 분기 전체 방향을 바꾸는 단 한 번의 정답이다.'
    )
    rep = analyze_entry(
        ji60='甲申', name='Wood Monkey', category='dayMasterDeep',
        text=ko, is_kpop_compat=False,
    )
    msg = (
        f'PASS expected. violations={rep.violations_count} '
        f'assertion={rep.assertion_ratio:.2f} '
        f'cold={rep.cold_reading_hits} '
        f'time={len(rep.time_prediction_hits)} '
        f'sentences={rep.sentence_count} '
        f'out-of-range={rep.out_of_range_sentence_count} '
        f'forer={rep.forer_hits}'
    )
    assert rep.passes, msg


def t_strong_time_prediction_three_axes() -> None:
    # anchor + future verb + 단정 종결 모두 충족
    t = '이번 달 안에 한 번, 평소 너답지 않게 먼저 연락하는 일이 생긴다.'
    sents = split_sentences(t)
    hits = count_strong_time_prediction(t, sents)
    assert len(hits) == 1, f'strong time prediction expected 1, got {len(hits)}: {hits}'


def t_strong_time_prediction_missing_verb() -> None:
    # anchor 있지만 행동/사건 어휘 없음 → 0 hit (false positive 방지)
    t = '이번 달은 좋은 달이다.'
    sents = split_sentences(t)
    hits = count_strong_time_prediction(t, sents)
    assert len(hits) == 0, f'no future verb → expected 0, got {len(hits)}'


def t_cli_report_md_smoke() -> None:
    """CLI --report-md 회귀 — entry-level 헷지/콜드/시점 카운트가 report 에 포함."""
    import subprocess
    import tempfile

    repo = Path(__file__).resolve().parent.parent
    with tempfile.NamedTemporaryFile(suffix='.md', delete=False) as tmp:
        report_path = tmp.name
    try:
        result = subprocess.run(
            ['python3', 'tool/transform_tone.py',
             '--all', '--summary-only', '--report-md', report_path],
            cwd=repo, capture_output=True, text=True, check=True,
        )
        assert 'Summary (420 ko 블록 검사 완료)' in result.stdout
        report = Path(report_path).read_text(encoding='utf-8')
        # 표 헤더 (헷지/콜드/시점 카운트 컬럼)
        assert '| ji60 | category |' in report
        assert '헷지' in report and '콜드' in report and '시점' in report
        # summary 섹션
        assert 'entries_total' in report
        assert 'hedge_total' in report
    finally:
        Path(report_path).unlink(missing_ok=True)


def t_cli_fixture_pass_entry() -> None:
    """non-zero fixture: tone_guide §5 예시 1 After 문안을 임시 JSON 으로 만들고
    CLI 가 PASS 1 entry / FAIL 0 으로 카운트하는지 회귀."""
    import subprocess
    import tempfile
    import json as _json

    repo = Path(__file__).resolve().parent.parent
    after_text = (
        '당신은 안과 밖이 다른 사람이다. '
        '밖에선 단단한 사람으로 보이지만 안에서는 의외로 무른 곳이 있다. '
        '결정은 빠르고 그 결정을 혼자 두세 번 되감는 사람이다. '
        '지난주에도 한 번 그 결정을 머릿속에서 다시 곱씹은 적이 있다고 본다. '
        '가까운 사람 한 명한테 먼저 연락하고 싶었지만 결국 안 보냈다. '
        '너는 계산이 많은 사람이고 그게 너의 가장 큰 무기로 작동한다. '
        '하지만 그 계산을 상대가 눈치챈 순간 너에 대한 신뢰는 닫힌다. '
        '이번 달 안에 한 번, 평소 너답지 않게 먼저 연락하는 일이 생긴다. '
        '그게 너의 다음 분기 전체 방향을 바꾸는 단 한 번의 정답이다.'
    )
    fixture = [{
        'ji60': '甲申', 'name': 'Wood Monkey',
        'ko': {'dayMasterDeep': after_text},
    }]
    with tempfile.NamedTemporaryFile(suffix='.json', delete=False, mode='w', encoding='utf-8') as tmp_json:
        _json.dump(fixture, tmp_json, ensure_ascii=False)
        fixture_path = tmp_json.name
    try:
        result = subprocess.run(
            ['python3', 'tool/transform_tone.py',
             '--file', fixture_path, '--summary-only'],
            cwd=repo, capture_output=True, text=True, check=True,
        )
        out = result.stdout
        assert 'entries_total: 1' in out, f'expected 1 entry, got:\n{out}'
        assert 'entries_passing: 1' in out, f'fixture should PASS, got:\n{out}'
        assert 'pass_rate: 100' in out, out
    finally:
        Path(fixture_path).unlink(missing_ok=True)


def main() -> int:
    tests = [
        t_hedge_basic,
        t_hedge_dedupe,
        t_hedge_expanded,
        t_advisory,
        t_protector,
        t_kpop_particles,
        t_kpop_dedupe_long_first,
        t_cold_reading_three_conditions,
        t_cold_reading_missing_assertion,
        t_strong_time_prediction_three_axes,
        t_strong_time_prediction_missing_verb,
        t_out_of_range,
        t_forer,
        t_analyze_entry_pass,
        t_cli_report_md_smoke,
        t_cli_fixture_pass_entry,
    ]
    failures = 0
    for fn in tests:
        try:
            fn()
            print(f'  PASS  {fn.__name__}')
        except AssertionError as e:
            failures += 1
            print(f'  FAIL  {fn.__name__}: {e}')
    print(f'\n{len(tests) - failures}/{len(tests)} 통과')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
