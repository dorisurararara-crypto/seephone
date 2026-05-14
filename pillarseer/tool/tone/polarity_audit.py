#!/usr/bin/env python3
"""Round 73 sprint 5 — Polarity / hedge / action / both-side audit.

신규 5 JSON 풀 (Sprint 2~6 + 4) 의 톤 정량 측정:
  - life_stage_pool.json (Sprint 2)
  - sipsin_persona.json (Sprint 3)
  - career_pool.json (Sprint 6)
  - wealth_detail.json (Sprint 6)
  - additional_life_pool.json (Sprint 4)

Threshold:
  - 헷지 패턴 0
  - 합니다체 0
  - AI 슬롭 0
  - 폴라리티 흉:길:양면 ≈ 5:4:1 (±1)
  - 행동 처방 ≥15%
  - 양면 anchor ≥30%

Usage:
  python3 tool/tone/polarity_audit.py [--detail]
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets' / 'data'

POOLS = [
    ('life_stage_pool.json', 'flat'),     # 모든 key.ko/.en (entry-level)
    ('sipsin_persona.json', 'flat'),
    ('additional_life_pool.json', 'el5'), # 5행 × 카테고리Ko (key.endswith('Ko'))
    ('career_pool.json', 'note'),         # key.noteKo
    ('wealth_detail.json', 'wealth'),     # accumKo / lossKo / techKo
]

HEDGE_PATTERNS = [
    r'있어요\.', r'없어요\.', r'편이에요', r'것 같다', r'일지도',
    r'도움됩니다', r'추천드려요', r'조심하세요',
    r'될 수도', r'무너뜨릴 수', r'키울 수도', r'단정 짓기 어려운',
]

AI_SLOP_PATTERNS = [
    r'본인\s*결', r'본인의\s*결', r'흐름이', r'결이에요',
    r'운세의신 정확도 비결',
    r'건강\s*잃',  # 의료 단정
]

# 단정형 합니다체 패턴 (피해야 할 합니다체)
HAMNIDA_AVOID = re.compile(r'[가-힣]+(?:맞|어울리|살아있|살아 있|분포)습니다\.|입니다\.')

BAD_KW = ['단점', '손해', '손실', '갈등', '실패', '잃', '곤란', '주의', '피하',
         '늦', '부족', '외로', '흔들', '위기', '약점', '닳', '약']
GOOD_KW = ['좋', '복', '풀', '단단', '강점', '인기', '편안', '받쳐', '성공', '성장']
BOTH_ANCHOR = re.compile(r'단,')
ACT_PATTERN = re.compile(r'(세요|마세요|하세요|받으세요|챙기세요|두세요|만드세요|꺼내세요|넘기세요|옮기세요)\.')


def collect_ko_entries(data, mode):
    """Pool 별 ko entries 수집."""
    out = []
    for k, v in data.items():
        if k.startswith('_'):
            continue
        if mode == 'flat':
            ko = v.get('ko') if isinstance(v, dict) else None
            if ko:
                out.append((k, ko))
        elif mode == 'el5':
            if isinstance(v, dict):
                for kk, vv in v.items():
                    if kk.endswith('Ko') and isinstance(vv, str):
                        out.append((f'{k}.{kk}', vv))
        elif mode == 'note':
            ko = v.get('noteKo') if isinstance(v, dict) else None
            if ko:
                out.append((f'{k}.noteKo', ko))
        elif mode == 'wealth':
            if isinstance(v, dict):
                for kk in ('accumKo', 'lossKo', 'techKo'):
                    if kk in v:
                        out.append((f'{k}.{kk}', v[kk]))
    return out


def polarity(text):
    b = sum(1 for kw in BAD_KW if kw in text)
    g = sum(1 for kw in GOOD_KW if kw in text)
    if b > g and b > 0:
        return 'bad'
    if g > b and g > 0:
        return 'good'
    if b > 0 and g > 0:
        return 'both'
    return 'neutral'


def measure(pool_path, mode):
    data = json.loads(pool_path.read_text(encoding='utf-8'))
    entries = collect_ko_entries(data, mode)
    if not entries:
        return None

    hedge_hits = 0
    slop_hits = 0
    hamnida_hits = 0
    total_sentences = 0
    action_sentences = 0
    bothside_entries = 0
    pol = {'bad': 0, 'good': 0, 'both': 0, 'neutral': 0}

    for _, ko in entries:
        for pat in HEDGE_PATTERNS:
            hedge_hits += len(re.findall(pat, ko))
        for pat in AI_SLOP_PATTERNS:
            slop_hits += len(re.findall(pat, ko))
        hamnida_hits += len(HAMNIDA_AVOID.findall(ko))

        sentences = [s.strip() for s in re.split(r'\.\s*', ko) if s.strip()]
        total_sentences += len(sentences)
        for s in sentences:
            if ACT_PATTERN.search(s + '.'):
                action_sentences += 1

        if BOTH_ANCHOR.search(ko):
            bothside_entries += 1
        pol[polarity(ko)] += 1

    total = len(entries)
    return {
        'pool': pool_path.name,
        'entries': total,
        'hedge_hits': hedge_hits,
        'ai_slop_hits': slop_hits,
        'hamnida_avoid_hits': hamnida_hits,
        'polarity': pol,
        'polarity_pct': {k: v / total for k, v in pol.items()},
        'sentences': total_sentences,
        'action_sentences': action_sentences,
        'action_ratio': action_sentences / total_sentences if total_sentences else 0,
        'bothside_entries': bothside_entries,
        'bothside_ratio': bothside_entries / total,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--detail', action='store_true')
    args = ap.parse_args()

    print(f'# Round 73 Sprint 5 — polarity audit\n')

    overall = {'hedge': 0, 'slop': 0, 'hamnida': 0,
               'pol': {'bad': 0, 'good': 0, 'both': 0, 'neutral': 0},
               'sents': 0, 'acts': 0, 'both_e': 0, 'ent': 0}
    rows = []
    for name, mode in POOLS:
        path = ASSETS / name
        if not path.exists():
            print(f'  WARN: {name} not found, skipping')
            continue
        r = measure(path, mode)
        if r is None:
            continue
        rows.append(r)
        overall['hedge'] += r['hedge_hits']
        overall['slop'] += r['ai_slop_hits']
        overall['hamnida'] += r['hamnida_avoid_hits']
        for k, v in r['polarity'].items():
            overall['pol'][k] += v
        overall['sents'] += r['sentences']
        overall['acts'] += r['action_sentences']
        overall['both_e'] += r['bothside_entries']
        overall['ent'] += r['entries']

    # Per-pool table
    print('## Per-pool metrics\n')
    print(f"| Pool | Entries | Hedge | Slop | 합니다체 | 폴라리티 흉:길:양면:중립 | 행동% | 양면% |")
    print(f"|------|---------|-------|------|---------|-----------------------|-------|-------|")
    for r in rows:
        p = r['polarity']
        print(f"| {r['pool']} | {r['entries']} | {r['hedge_hits']} | {r['ai_slop_hits']} | "
              f"{r['hamnida_avoid_hits']} | {p['bad']}:{p['good']}:{p['both']}:{p['neutral']} | "
              f"{r['action_ratio']:.0%} | {r['bothside_ratio']:.0%} |")

    # Overall
    total_ent = overall['ent']
    if total_ent == 0:
        print('\nNo entries measured.')
        return
    print('\n## Overall (all pools combined)\n')
    print(f"- Total ko entries: {total_ent}")
    print(f"- Total sentences: {overall['sents']}")
    print(f"- Hedge patterns:  {overall['hedge']}  (target: 0)")
    print(f"- AI 슬롭 patterns: {overall['slop']}  (target: 0)")
    print(f"- 합니다체 avoid:    {overall['hamnida']}  (target: 0)")
    pb = overall['pol']['bad']
    pg = overall['pol']['good']
    pbo = overall['pol']['both']
    pn = overall['pol']['neutral']
    print(f"- 폴라리티 흉:{pb} 길:{pg} 양면:{pbo} 중립:{pn}")
    print(f"  - pct: 흉 {pb/total_ent:.0%}, 길 {pg/total_ent:.0%}, "
          f"양면 {pbo/total_ent:.0%}, 중립 {pn/total_ent:.0%}")
    print(f"  - target 5:4:1 ±1 → 흉 ~50% 길 ~40% 양면 ~10%")
    print(f"- 행동 처방: {overall['acts']}/{overall['sents']} = "
          f"{overall['acts']/overall['sents']:.0%}  (target ≥15%)")
    print(f"- 양면 anchor 비율: {overall['both_e']}/{total_ent} = "
          f"{overall['both_e']/total_ent:.0%}  (target ≥30%)")

    # PASS/FAIL
    print('\n## Threshold check\n')
    fails = []
    if overall['hedge'] != 0:
        fails.append(f"FAIL hedge {overall['hedge']} ≠ 0")
    if overall['slop'] != 0:
        fails.append(f"FAIL ai-slop {overall['slop']} ≠ 0")
    if overall['hamnida'] != 0:
        fails.append(f"FAIL 합니다체 avoid {overall['hamnida']} ≠ 0")
    action_ratio = overall['acts'] / overall['sents']
    if action_ratio < 0.15:
        fails.append(f"FAIL action ratio {action_ratio:.0%} < 15%")
    bothside_ratio = overall['both_e'] / total_ent
    if bothside_ratio < 0.30:
        fails.append(f"FAIL bothside ratio {bothside_ratio:.0%} < 30%")
    # polarity 5:4:1 ±1
    pct_bad = pb / total_ent
    pct_good = pg / total_ent
    pct_both = pbo / total_ent
    if not (0.40 <= pct_bad <= 0.60):
        fails.append(f"FAIL polarity 흉 {pct_bad:.0%} out of 40-60%")
    if not (0.30 <= pct_good <= 0.50):
        fails.append(f"FAIL polarity 길 {pct_good:.0%} out of 30-50%")
    if not (0.05 <= pct_both <= 0.20):
        fails.append(f"FAIL polarity 양면 {pct_both:.0%} out of 5-20%")

    # Round 76 sprint 7 — 사건 영역 (today_event_pool.json) 분리 audit.
    # 캐릭터 영역과 룰이 다름: hedge OK (사용자 verbatim mandate), 단정 예언 금지.
    print('\n## Round 76 sprint 7 — 사건 영역 (today_event_pool.json)\n')
    event_pool_path = ASSETS / 'today_event_pool.json'
    if not event_pool_path.exists():
        # 누락은 FAIL (Round 76 sprint 4 산출물 mandate).
        fails.append('FAIL today_event_pool.json 누락 (Round 76 sprint 4 mandate)')
    else:
        event_fails = _audit_event_pool(event_pool_path)
        if not event_fails:
            print('  PASS — 사건 영역 헷지 / 행동 / 금지 패턴 통과')
        else:
            for f in event_fails:
                print(f'  {f}')
            fails.extend(event_fails)

    if not fails:
        print('\nPASS — 캐릭터 영역 + 사건 영역 모두 통과')
        return 0
    else:
        return 1


# Round 76 sprint 7 — 사건 영역 사용자 verbatim mandate 검증.
# hedge OK (생기기 쉬워요 / 흐름이 강해요 / 가능성이 있어요 / 쉬워요 / 흔들릴 수 있어요),
# 단정 예언 금지 (반드시 / 사고가 날 / 큰돈을 잃 / 병원 / 이성과 만납니다),
# body/caution/recommend 각 ≤120자, body 헷지 패턴 1개 이상.
EVENT_HEDGE = re.compile(
    r'(생기기 쉬워요|흐름이 강해요|가능성이 있어요|쌓이기 쉬워요|쉬워요|흔들릴 수 있어요|커지기 쉬워요|들어올|들어오는|기회가|있는 날|어울리는|있을 흐름|풀리는|흐름이에요|잘 풀리는|만날 수 있어요|떠오르기 쉬워요|들어와|수 있어요|쉬운 날|살아날|가능성이|올라올)')
EVENT_FORBID = re.compile(r'(반드시|사고가 날|큰돈을 잃|병원|이성과 만납니다)')


def _audit_event_pool(path: Path):
    fails = []
    data = json.loads(path.read_text(encoding='utf-8'))
    events = data.get('events', {})
    shinsa = data.get('shinsa', {})
    if not events:
        fails.append('FAIL events 비어 있음')
        return fails

    # 30 key check — 정확히 30 key + 5 그룹 × 6 카테고리 모두 존재.
    groups = ['비겁', '식상', '재성', '관성', '인성']
    cats = ['relationship', 'money', 'work', 'love', 'health', 'luck']
    expected_keys = {f'{g}_{c}' for g in groups for c in cats}
    actual_keys = set(events.keys())
    missing = expected_keys - actual_keys
    extra = actual_keys - expected_keys
    if missing:
        fails.append(f'FAIL 사건 영역 key 누락 {sorted(missing)}')
    if extra:
        fails.append(f'FAIL 사건 영역 예상 외 key {sorted(extra)}')
    if len(events) != 30:
        fails.append(f'FAIL events key 수 {len(events)} != 30')
    # 각 key 정확히 3 set entry.
    for key, lst in events.items():
        if not isinstance(lst, list) or len(lst) != 3:
            fails.append(f'FAIL {key} set 수 {len(lst) if isinstance(lst, list) else "non-list"} != 3')

    # entry 톤.
    total_entries = 0
    body_hedge_misses = 0
    forbidden = 0
    over_120 = 0
    for key, lst in events.items():
        for e in lst:
            total_entries += 1
            body = e.get('body', '')
            caution = e.get('caution', '')
            recommend = e.get('recommend', '')
            if len(body) > 120 or len(caution) > 120 or len(recommend) > 120:
                over_120 += 1
            if not EVENT_HEDGE.search(body):
                body_hedge_misses += 1
            for s in (body, caution, recommend):
                if EVENT_FORBID.search(s):
                    forbidden += 1

    print(f'  events entries: {total_entries}')
    print(f'  body hedge 미포함: {body_hedge_misses}  (target 0)')
    print(f'  단정 예언 금지 hit: {forbidden}  (target 0)')
    print(f'  120자 초과: {over_120}  (target 0)')
    print(f'  shinsa keys: {len(shinsa)}  (target 8)')

    if body_hedge_misses != 0:
        fails.append(f'FAIL 사건 영역 body hedge 누락 {body_hedge_misses}건')
    if forbidden != 0:
        fails.append(f'FAIL 사건 영역 단정 예언 hit {forbidden}건')
    if over_120 != 0:
        fails.append(f'FAIL 사건 영역 120자 초과 {over_120}건')
    if len(shinsa) != 8:
        fails.append(f'FAIL shinsa keys {len(shinsa)} != 8')
    return fails


if __name__ == '__main__':
    sys.exit(main() or 0)
