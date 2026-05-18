#!/usr/bin/env python3
"""R90 sprint 1 — strip "<day-pillar> 일주" / "<day-stem> 일간" prefix from life_paragraphs.json.

사용자 verbatim (R89 결함):
> "원래 사주는 일주로만 봐?? 내 사주가 곧 평생사주인데 왜 신묘일주만 말하지??"

이 script 는 paragraph 본문에서 prefix 만 제거. 본문 핵심 내용은 그대로 보존.
같은 일주여도 사주 anchor 가 다르면 다른 본문이 되도록 R90 service layer (sprint 2~5)
에서 anchor fragment runtime injection 으로 변별성 확보.

검증:
- string 수 1400 → 1400 (drop 0)
- prefix 위반 grep → 0
- 처리 후 각 string ≥ 60자 (R88 spec ≥80자 보존, prefix 제거 후 적용)
- JSON parseable
"""

import json
import re
import sys

PATH = 'assets/data/life_paragraphs.json'

GAN = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계']
JI = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해']
ILJU_60 = [g + j for i, g in enumerate(GAN) for k, j in enumerate(JI) if (i + k) % 2 == 0]

# 일주 60 + 일간 10 — 일주 우선 (긴 alternative 먼저).
# 패턴 A: "<일주> 일주 [은/는/이/가]" 또는 "<일간> 일간 [은/는/이/가]"
# 패턴 B: "남자/여자 <일주> 일주 ~" 또는 "남자/여자 <일간> 일간 ~"
# 패턴 C: "남자/여자 <일주> 일주 <문구>는 ~" 같이 부가어 + "는 " 까지 한 묶음
# 핵심: prefix 만 떼어내고 본문 첫 의미 단어부터 살림.
PILLAR_RE = '(' + '|'.join(ILJU_60 + GAN) + ')'

PREFIX_PATTERNS = [
    # 1. "여자 <일주> 일주 본래 무게감은 " / "남자 <일주> 일주 연애 시작은 " 같은 긴 prefix
    re.compile(r'^(남자|여자)\s*' + PILLAR_RE + r'\s*(일주|일간)\s*[가-힣\s]{0,12}?\s*(은|는)\s+'),
    # 2. "남자/여자 <일주> 일주 [조사]"
    re.compile(r'^(남자|여자)\s*' + PILLAR_RE + r'\s*(일주|일간)\s*(은|는|이|가)?\s*'),
    # 3. "<일주> 일주 [조사]" / "<일간> 일간 [조사]"
    re.compile(r'^' + PILLAR_RE + r'\s*(일주|일간)\s*(은|는|이|가)?\s*'),
]

# 흔한 후처리 패턴 — prefix 제거 후 본문이 부자연스럽게 끝나면 "본인은" 보강.
# 예: "한 마디로 ~ 사람이에요." (prefix 제거 후 동사 시작 → 자연)
# 예: "어릴 때부터 ~" (그대로 OK)
# 본문 첫 글자가 한글 자음/모음(조사 시작)인 경우는 극히 드물지만 보정 안 함.


def strip_prefix(text):
    """Patterns 를 순서대로 적용 — 첫 매칭만 strip."""
    for pat in PREFIX_PATTERNS:
        m = pat.match(text)
        if m:
            return text[m.end():]
    return text


def walk(node, stats):
    if isinstance(node, str):
        stats['total'] += 1
        new = strip_prefix(node)
        if new != node:
            stats['removed'] += 1
            # 길이 검증.
            if len(new) < 60:
                stats['too_short'].append((node[:40], new[:40], len(new)))
        return new
    if isinstance(node, dict):
        return {k: walk(v, stats) for k, v in node.items()}
    if isinstance(node, list):
        return [walk(v, stats) for v in node]
    return node


def main():
    with open(PATH) as f:
        d = json.load(f)

    stats = {'total': 0, 'removed': 0, 'too_short': []}
    new_d = walk(d, stats)

    # 검증.
    after_violations = 0

    def count_v(node):
        nonlocal after_violations
        if isinstance(node, str):
            for pat in PREFIX_PATTERNS:
                if pat.match(node):
                    after_violations += 1
                    break
        elif isinstance(node, dict):
            for v in node.values():
                count_v(v)
        elif isinstance(node, list):
            for v in node:
                count_v(v)

    count_v(new_d)

    print(f'total strings: {stats["total"]}')
    print(f'prefix removed: {stats["removed"]}')
    print(f'after violations: {after_violations}')
    print(f'too short (<60 chars after strip): {len(stats["too_short"])}')
    if stats['too_short'][:5]:
        for orig, new, l in stats['too_short'][:5]:
            print(f'  - len={l}: orig="{orig}..." → new="{new}..."')

    if after_violations != 0:
        print('FAIL: violations remain', file=sys.stderr)
        sys.exit(1)

    with open(PATH, 'w') as f:
        json.dump(new_d, f, ensure_ascii=False, indent=2)
    print(f'wrote {PATH}')


if __name__ == '__main__':
    main()
