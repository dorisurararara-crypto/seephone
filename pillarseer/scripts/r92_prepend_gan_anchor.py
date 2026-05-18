"""R92 sprint 2 — 60일주 entry 의 첫 문장 앞에 천간 modifier 1개 prepend.

목적: 같은 일지 5 일주 (예: 축 = 을축/정축/기축/신축/계축) 가 base 텍스트 동일 →
entry-간 첫 문장 중복 245 dup → 0.

전략:
- 일주별로 천간 (key[0]) 추출 → gan_traits 풀에서 trait 선택 (일지 인덱스 기반 → 5 일주가
  같은 천간이라도 일지별 다른 trait pick, 천간 6 일주는 6 trait 중 5만 있으니 mod).
- 카테고리별 modifier 종결 어휘 prepend.
- 원본 base 본문은 보존 (R91 quality + R69 lock + 5행 골든 등 baseline 100% 유지).

Mass batch. 결과: 1020 일주 entry × 1 추가 sentence. 평균 +35 char.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'assets/data/life_paragraphs.json'
ANCHORS = ROOT / 'scripts/r92_gan_anchors.json'

# 일지 순서 (60갑자 cycle 기준 12 일지)
JIJI_ORDER = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해']
JIJI_IDX = {jiji: i for i, jiji in enumerate(JIJI_ORDER)}


def _has_jongsung(text: str) -> bool:
    """마지막 한 글자가 받침이 있는지 (이/가 결정용)."""
    ch = text[-1]
    if not '가' <= ch <= '힣':
        return False
    return (ord(ch) - 0xAC00) % 28 != 0


def _strip_old_r92_prefix(text: str, anchors: dict) -> str:
    """이전 R92 sprint 2 prepend 가 남아있으면 제거 (idempotent re-run 용)."""
    for traits in anchors['gan_traits'].values():
        for trait in traits:
            for tail in [
                anchors['cat_modifiers_i'],
                anchors['cat_modifiers_ga'],
            ]:
                for mod in tail.values():
                    candidate = f'{trait}{mod} '
                    if text.startswith(candidate):
                        return text[len(candidate):]
    # legacy '이 본인의 색이에요.' 풀에서 빠진 fallback 도 제거
    return text


def prepend_for_entry(text: str, gan: str, jiji: str, cat: str, anchors: dict) -> str:
    """일주 entry 본문에 천간 modifier sentence prepend (이/가 받침 정확)."""
    text = _strip_old_r92_prefix(text, anchors)
    gan_traits = anchors['gan_traits'][gan]
    # 양 천간(갑/병/무/경/임) = 양 일지(자/인/진/오/신/술, jiji_idx 짝수)만 짝.
    # 음 천간(을/정/기/신/계) = 음 일지(축/묘/사/미/유/해, jiji_idx 홀수)만 짝.
    # → JIJI_IDX[jiji] // 2 = 0~5 균등 → 6 일주 모두 unique trait 보장.
    trait_idx = (JIJI_IDX[jiji] // 2) % len(gan_traits)
    trait = gan_traits[trait_idx]

    cat_mods = anchors['cat_modifiers_i'] if _has_jongsung(trait) else anchors['cat_modifiers_ga']
    modifier = cat_mods.get(cat, '이 본인의 색이에요.' if _has_jongsung(trait) else '가 본인의 색이에요.')

    prefix = f'{trait}{modifier} '
    if text.startswith(prefix):
        return text
    return prefix + text


def main() -> None:
    data = json.loads(DATA.read_text(encoding='utf-8'))
    anchors = json.loads(ANCHORS.read_text(encoding='utf-8'))

    iljoo_keys = [k for k in data if len(k) == 2]
    print(f'일주 entry: {len(iljoo_keys)}')

    changed = 0
    for top_key in iljoo_keys:
        gan, jiji = top_key[0], top_key[1]
        if gan not in anchors['gan_traits']:
            print(f'skip {top_key}: 천간 {gan} 없음')
            continue
        if jiji not in JIJI_IDX:
            print(f'skip {top_key}: 일지 {jiji} 없음')
            continue

        cats = data[top_key]
        for cat, val in cats.items():
            if isinstance(val, str):
                new_text = prepend_for_entry(val, gan, jiji, cat, anchors)
                if new_text != val:
                    cats[cat] = new_text
                    changed += 1
            elif isinstance(val, dict):
                for g, t in val.items():
                    new_text = prepend_for_entry(t, gan, jiji, cat, anchors)
                    if new_text != t:
                        val[g] = new_text
                        changed += 1

    print(f'changed entries: {changed}')
    DATA.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    print(f'wrote {DATA}')


if __name__ == '__main__':
    main()
