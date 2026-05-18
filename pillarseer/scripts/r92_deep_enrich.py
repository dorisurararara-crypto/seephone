"""R92 sprint 5 round 3 — 천간 deep persona append + MZ 2nd inject.

codex round 2 지적 잔존 (평균 8.4 → 8.7+ 목표):
- MZ/덕질 톤 "얕음" → 본문 마지막에 2번째 MZ sentence append
- 천간 anchor "더 함축" → 천간별 deep persona 1 sentence append
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'assets/data/life_paragraphs.json'


# 천간별 deep persona append phrase (R88 본문 vocab 와 보완)
GAN_DEEP: dict[str, list[str]] = {
    '갑': [
        '곧게 뻗는 결이 시간이 갈수록 더 단단해져요.',
        '한 분야 큰 줄기로 자라는 흐름이 잘 맞아요.',
        '리더 자리가 자연스럽게 자리잡는 결이에요.',
    ],
    '을': [
        '바람 따라 휘어도 뿌리는 단단한 결이 매력이에요.',
        '천천히 가도 한 번 자리잡으면 흔들리지 않는 흐름이에요.',
        '작은 빈틈 채워가는 손길이 사람들에게 깊게 닿아요.',
    ],
    '병': [
        '한낮처럼 환한 분위기가 사람들 사이에서 시그니처예요.',
        '직진형 에너지가 흐름 자체를 밝게 만들어요.',
        '주위 데우는 따뜻한 결이 변하지 않는 매력이에요.',
    ],
    '정': [
        '촛불처럼 잔잔하지만 오래 빛나는 결이 매력이에요.',
        '디테일까지 챙기는 손길이 가까운 사람들에게 깊게 닿아요.',
        '작은 등불 같은 따뜻함이 한결같은 시그니처예요.',
    ],
    '무': [
        '큰 산처럼 변하지 않는 무게가 신뢰의 기반이에요.',
        '책임감 하나로 사람들을 끝까지 챙기는 결이에요.',
        '한 자리 깊게 뿌리내리는 흐름이 고유 매력이에요.',
    ],
    '기': [
        '비옥한 흙처럼 사람을 키워내는 결이 매력이에요.',
        '뒤에서 단단히 받쳐주는 역할이 한결같은 시그니처예요.',
        '조용히 자리 다지는 손길이 오래 기억돼요.',
    ],
    '경': [
        '한 번 결정하면 끝까지 가는 결단력이 매력이에요.',
        '벼린 칼 같은 단호함과 정 깊은 본성이 같이 가요.',
        '강하지만 신뢰 깊은 결이 한결같은 시그니처예요.',
    ],
    '신': [
        '정제된 보석처럼 깔끔하게 마무리하는 결이 매력이에요.',
        '날 선 감각과 단정한 결이 모든 일의 시그니처예요.',
        '광택 있는 결이 사람들 사이에서 또렷이 빛나요.',
    ],
    '임': [
        '큰 강처럼 깊이 흐르는 시야가 고유 매력이에요.',
        '한 곳에 갇히지 않는 자유로움과 통찰이 시그니처예요.',
        '잔잔하지만 거대한 흐름이 사람들 곁에 오래 남아요.',
    ],
    '계': [
        '맑은 이슬처럼 섬세한 직관이 매력이에요.',
        '조용하지만 깊이 있는 결이 가까운 사람들에게 깊게 닿아요.',
        '차분하게 흘러가는 무게가 변하지 않는 고유 색깔이에요.',
    ],
}

# 2nd MZ inject pool — 카테고리별 (1st inject 와 다른 분야 어휘)
MZ_2ND: dict[str, list[str]] = {
    'early_life': ['좋아하는 가수 콘서트 처음 갔던 날 기억이 또렷한 결이에요.',
                   '학교 도서관에서도 좋아하는 분야 책만 찾는 색이 또렷했어요.'],
    'mid_life': ['업계 인스타에서 이름이 종종 태그되는 시기로 들어가요.',
                 '한 분야 본진으로 자리잡은 인지도가 30·40대 색이에요.'],
    'late_life': ['후배 단톡 안에서 한 마디면 분위기 정리되는 무게예요.',
                  '한 분야 컴백 무대처럼 한 번씩 재조명 받는 시기가 와요.'],
    'health': ['좋아하는 플레이리스트 켜고 산책하는 루틴이 잘 맞아요.',
               '운동 시그니처 한 가지 고정하면 컨디션이 안정돼요.'],
    'constitution': ['시즈널 컨디션 변화 따라 루틴 한 번씩 손봐주면 좋아요.',
                     '본진 운동 한 가지 정하면 체질에 잘 맞춰져요.'],
    'social': ['오픈채팅 안에서도 톤이 한결같아 사람들이 신뢰해요.',
               '단톡 안 분위기 메이커 자리에 자연스럽게 가는 결이에요.'],
    'social_personality': ['커뮤니티 안에서도 한 마디로 분위기 잡는 무게가 있어요.',
                           '본진 친구들 사이에서 시그니처 한 마디가 또렷해요.'],
    'personality': ['한 번 빠지면 굿즈 챙기듯 깊게 들어가는 색이에요.',
                    '좋아하는 분야 컴백 챙기듯 꾸준한 결이에요.'],
    'innate_tendency': ['한 분야 시그니처로 자리잡는 흐름이 매력이에요.',
                        '본진 챙기듯 한 가지에 깊게 들어가는 결이에요.'],
    'innate_character': ['단톡 안 한 마디로 분위기 풀어주는 결이에요.',
                         '시그니처 한 가지로 사람들에게 기억되는 무게가 있어요.'],
    'love_fate': ['최애 플레이리스트 공유하고 싶은 사람한테 마음이 가요.',
                  '본진 콘서트 같이 가고 싶은 사람이 인연의 결이에요.'],
    'affection': ['좋아하는 사람한테는 시그니처 한 곡 공유하는 표현이 고유 색깔이에요.',
                  '본진 굿즈 챙기듯 사랑하는 사람 챙기는 결이에요.'],
    'wealth': ['플레이리스트 큐레이션처럼 돈 흐름에 시그니처 있어요.',
               '굿즈 사는 결처럼 한 번 정한 곳에는 망설임 없어요.'],
    'wealth_gather': ['본진 적금 한 개 고정하면 흐름 안정돼요.',
                      '시그니처 통장 한 가지 정해두면 돈이 자동 모이는 결이에요.'],
    'wealth_loss_prevent': ['본진 자산 한 곳에는 망설임 없이 지키는 결이에요.',
                            '시그니처 기준 한 번 정하면 흔들리지 않는 결이에요.'],
    'wealth_invest': ['최애 콘서트 챙기듯 본진 종목 꾸준히 챙기는 결이에요.',
                      '시그니처 한 곳에 집중하는 흐름이 잘 맞아요.'],
    'conclusion_self': ['시그니처 색 한 가지로 사람들에게 기억되는 결이에요.',
                        '본진 한 곳에 집중하는 무게가 핵심 색깔이에요.'],
}


def append_deep(text: str, gan: str, top_key: str, cat: str) -> tuple[str, int]:
    """천간 deep persona + MZ 2nd inject 본문 끝에 append."""
    added = 0
    deep_pool = GAN_DEEP.get(gan, [])
    if deep_pool:
        deep_idx = abs(hash(f'{top_key}|{cat}|deep')) % len(deep_pool)
        deep = deep_pool[deep_idx]
        if deep not in text:
            text = text.rstrip()
            if not text.endswith(('.', '!', '?')):
                text += '.'
            text += ' ' + deep
            added += 1
    mz2_pool = MZ_2ND.get(cat, [])
    if mz2_pool:
        mz_idx = abs(hash(f'{top_key}|{cat}|mz2')) % len(mz2_pool)
        mz2 = mz2_pool[mz_idx]
        if mz2 not in text:
            text = text.rstrip()
            if not text.endswith(('.', '!', '?')):
                text += '.'
            text += ' ' + mz2
            added += 1
    return text, added


def main() -> None:
    data = json.loads(DATA.read_text(encoding='utf-8'))
    entry_count = 0
    add_count = 0

    for top_key, cats in data.items():
        if len(top_key) != 2:
            continue
        gan = top_key[0]
        for cat, val in cats.items():
            if isinstance(val, str):
                new_text, n = append_deep(val, gan, top_key, cat)
                if new_text != val:
                    cats[cat] = new_text
                    entry_count += 1
                    add_count += n
            elif isinstance(val, dict):
                for g, t in val.items():
                    new_text, n = append_deep(t, gan, f'{top_key}-{g}', cat)
                    if new_text != t:
                        val[g] = new_text
                        entry_count += 1
                        add_count += n

    print(f'entries enriched: {entry_count}')
    print(f'sentences added: {add_count}')

    DATA.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    print(f'wrote {DATA}')


if __name__ == '__main__':
    main()
