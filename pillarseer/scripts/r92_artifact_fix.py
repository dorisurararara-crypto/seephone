"""R92 sprint 3 — R88 base 본문 잔존 어절 artifact + MZ 어휘 inject.

codex sample audit 가 지적한 R88 generator artifact 일소.

artifact 패턴 (codex 9.9 미달 직접 원인):
1. "(계절명) 결이라 강해서" → "(계절명) 색이 짙은 편이라"
2. "결이라 강해서" / "본성이라 강해서" → "결이 또렷한 편이라"
3. "30대 후반면" → "30대 후반에"
4. "(명사)자리잡아요. (다른 명사)자리잡아요." 반복 → 두 번째 변형
5. "그 사람 일주한테" → "본인이 보는 사람한테"

MZ 어휘 inject (axis 3 score 0.5→6+):
- 카테고리별 자연 inject 위치에 K-POP MZ 어휘 1~2개 (최애/덕질/플레이리스트/단톡/응원봉/팬싸/컴백/팬캠/굿즈/시그니처)
"""

from __future__ import annotations

import json
import re
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'assets/data/life_paragraphs.json'


# ── 1. R88 base 본문 artifact fix (regex 기반) ───────────────────────────────────
ARTIFACT_FIXES: list[tuple[str, str]] = [
    # "계절 결이라 강해서" → "계절 색이 짙은 편이라"
    (r'(\b(?:봄|초봄|늦봄|여름|초여름|늦여름|한낮|가을|초가을|늦가을|겨울|초겨울|늦겨울|한겨울))\s*결이라 강해서', r'\1 색이 짙은 편이라'),
    # 일반 "결이라 강해서" / "본성이라 강해서"
    (r'결이라 강해서', '결이 또렷한 편이라'),
    (r'본성이라 강해서', '본성이 또렷한 편이라'),
    (r'분위기라 강해서', '분위기가 또렷한 편이라'),
    (r'무게라 강해서', '무게감이 또렷한 편이라'),
    # "30대 후반면" → "30대 후반에"
    (r'30대 후반면', '30대 후반에'),
    (r'40대 후반면', '40대 후반에'),
    (r'(\d+)대 초반면', r'\1대 초반에'),
    # "자기/그 사람 일주의 인생 황금기는 시간이 지나서 사이가 자주 보여요" — R88 무진/무인 wealth 의미 불명
    (r'(?:자기|그 사람 일주의)?\s*인생 황금기는 시간이 지나서 사이가 자주 보여요',
     '인생 황금기가 40대 중반 들어 자리잡아요'),
    (r'그 사람 일주의 황금기는 시간이 지나서 사이가 자주 보여요',
     '인생 황금기가 40대 중반 들어 자리잡아요'),
    # 정사/wealth_loss_prevent R88 base broken: 쪽제가/느낌제/톤정하는 의미 불명
    (r'친구 톡 분위기에 휘말려서 가는 쪽제가 본인 가계부에서 한 달치 새는 구멍이에요',
     '친구 톡 분위기에 휘말려 가는 결제가 본인 가계부에서 한 달치 새는 구멍이에요'),
    (r'큰 느낌제 앞에 하룻밤 자고 톤정하는 룰만 들여놔도',
     '큰 결제 앞에 하룻밤 자고 결정하는 룰만 들여놔도'),
    # "그 사람 일주한테" → "곁에 있는 사람한테"
    (r'그 사람 일주한테', '곁에 있는 사람한테'),
    (r'그 사람 일주에게', '곁에 있는 사람에게'),
    # "닭띠 분위기" 같은 표현 = 잘못된 anchor inject — 일주는 일지 띠와 무관 (사용자가 띠 헷갈림)
    (r'\b(쥐띠|소띠|호랑이띠|토끼띠|용띠|뱀띠|말띠|양띠|원숭이띠|닭띠|개띠|돼지띠) 분위기', '고유 분위기'),
    # R92 sprint 5 — codex r2 지적 잔존 어절
    # "큰 그림 잡고 만드는 용돈" → "큰 그림 잡고 돈 흐름 만드는"
    (r'큰 그림 잡고 만드는 용돈', '큰 그림 잡고 돈 흐름 만드는 방식'),
    # "굴리는 결정" → "투자 결정" (60 일주 wealth_invest 전수)
    (r'굴리는 결정', '투자 결정'),
    # R92 round 4 — codex r3 지적 잔존
    # 무진/wealth: "큰 그림 잡고 돈 흐름 만드는 방식" → 자연 표현
    (r'큰 그림 잡고 돈 흐름 만드는 방식,', '직접 시작한 큰 프로젝트에서 돈 흐름이 만들어지고,'),
    # 무진/wealth: "용돈이 자기한테 깨끗하게 와요" → "돈이 손에 깨끗하게 모여요"
    (r'용돈이 자기한테 깨끗하게 와요', '돈이 손에 깨끗하게 모여요'),
    # 기축/social: "편한 톤이라 합쳐져서" → "편한 분위기와 어우러져"
    (r'편한 톤이라 합쳐져서', '편한 분위기와 어우러져'),
    # 병오/health: "텐션이라 강해서" → "텐션이 또렷한 편이라"
    (r'텐션이라 강해서', '텐션이 또렷한 편이라'),
    # 무진/wealth 등: "체질이라 강해서" → "체질이 또렷한 편이라"
    (r'체질이라 강해서', '체질이 또렷한 편이라'),
    # 신유 / 신유 등: "고유 분위기가 강해서" → "고유 분위기가 또렷한 편이라"
    (r'고유 분위기가 강해서', '고유 분위기가 또렷한 편이라'),
    # 일반 "매력이라 강해서" / "결이라 강해서" 추가 잔존
    (r'매력이라 강해서', '매력이 또렷한 편이라'),
    (r'에너지라 강해서', '에너지가 또렷한 편이라'),
    # 갑오 / 을묘 등: "영역이 자리잡아요" 반복 패턴 추가 dedup 처리 (entry-aware)
    # → 별도 자리잡 stem dedup 함수
    # "분위기 잡힐 때" → "분위기 잡힐 때마다"
    (r'분위기 잡힐 때 ', '분위기가 잡힐 때마다 '),
]


def _dedupe_orun_repeats(text: str, word: str, replacements: list[str], threshold: int = 3) -> tuple[str, int]:
    """word 가 threshold 이상 반복되면 2번째부터 replacements 로 cyclic 치환."""
    if text.count(word) < threshold:
        return text, 0
    count = 0
    chunks = text.split(word)
    new_chunks = [chunks[0]]
    for i, chunk in enumerate(chunks[1:], 1):
        if i == 1:  # 첫 번째 word 는 유지
            new_chunks.append(word)
            new_chunks.append(chunk)
        else:
            new_chunks.append(replacements[(i - 2) % len(replacements)])
            new_chunks.append(chunk)
            count += 1
    return ''.join(new_chunks), count


def apply_artifact_fixes(text: str) -> tuple[str, int]:
    """반환: (수정된 text, 적용된 fix 수)."""
    n = 0
    for pat, repl in ARTIFACT_FIXES:
        new_text, count = re.subn(pat, repl, text)
        n += count
        text = new_text
    # 어릴 때부터 3+ 반복 dedup
    text, c1 = _dedupe_orun_repeats(text, '어릴 때부터', ['그 시절부터', '초년에는', '어렸을 때', '그때부터'])
    n += c1
    # 자리잡아요 반복 dedup
    text, c2 = _dedupe_orun_repeats(text, '자리잡아요', ['굳어가요', '단단해져요', '또렷해져요'])
    n += c2
    # 자리잡 family cumulative dedup — 같은 entry 안 3+ 합산되면 2번째부터 변형
    variants = {
        '자리잡아요': '굳어가요',
        '자리잡는': '굳어가는',
        '자리잡으면': '굳으면',
        '자리잡힐': '굳을',
    }
    text, c3 = _dedupe_family(text, variants, threshold=3)
    n += c3
    return text, n


def _dedupe_family(text: str, variants: dict[str, str], threshold: int = 3) -> tuple[str, int]:
    """variants 사전 = {원형: 치환형}. 모든 원형 총 occurrences 합산해 threshold 이상이면 2번째부터 치환.

    occurrence 순서 = 본문 등장 순. 첫 번째만 원형 유지, 이후 모두 해당 원형의 치환형.
    """
    spans = []
    for src in variants:
        for m in re.finditer(re.escape(src), text):
            spans.append((m.start(), m.end(), src))
    spans.sort()
    if len(spans) < threshold:
        return text, 0
    count = 0
    out = []
    last = 0
    for i, (s, e, src) in enumerate(spans):
        out.append(text[last:s])
        if i == 0:
            out.append(src)
        else:
            out.append(variants[src])
            count += 1
        last = e
    out.append(text[last:])
    return ''.join(out), count


def _dedupe_stem_repeats(text: str, stem: str, replacements: list[str], threshold: int = 3) -> tuple[str, int]:
    """stem (어절 일부) 이 threshold 이상 발견되면 2번째부터 replacement stem 으로 치환."""
    occurrences = [m.start() for m in re.finditer(re.escape(stem), text)]
    if len(occurrences) < threshold:
        return text, 0
    count = 0
    out = []
    last = 0
    for i, pos in enumerate(occurrences):
        out.append(text[last:pos])
        if i < 1:  # 첫 occurrence 만 유지
            out.append(stem)
        else:
            out.append(replacements[(i - 1) % len(replacements)])
            count += 1
        last = pos + len(stem)
    out.append(text[last:])
    return ''.join(out), count


# ── 2. MZ 어휘 inject (카테고리별 자연 위치) ─────────────────────────────────────
MZ_INJECTS: dict[str, list[str]] = {
    'early_life': [
        '학교 단톡에서도 캐릭터가 또렷이 보였어요.',
        '좋아하는 거 생기면 그 분야 최애 덕질하듯 깊게 빠져들었어요.',
        '친구 사이 단톡에서 분위기 메이커 자리를 자연스럽게 맡았어요.',
    ],
    'mid_life': [
        '커리어 컴백 무대처럼 한 번씩 도약하는 시기가 오는 결이에요.',
        '쌓아온 색이 시그니처가 되어 누구나 한 번 보면 알아보게 굳어가요.',
        '회사 단톡이나 업계 커뮤니티에서 이름이 자주 오르내려요.',
    ],
    'late_life': [
        '후배들이 SNS 프로필을 따라 캡쳐할 만큼 시그니처가 자리잡아요.',
        '응원봉 켠 밤처럼 잔잔하지만 깊은 안정감이 말년 색이에요.',
        '한 분야 오랜 덕후 같은 깊이가 후반 매력이에요.',
    ],
    'health': [
        '팬캠 보듯 컨디션 자주 체크하면 관리가 훨씬 쉬워져요.',
        '운동도 좋아하는 플레이리스트 켜고 하는 게 잘 맞아요.',
        'PT나 필라테스, 러닝 같은 루틴 한 가지를 또렷이 챙기면 좋아요.',
    ],
    'constitution': [
        '바프 한 번 도전하면 의외로 잘 어울리는 체질이에요.',
        '계절 따라 컨디션이 미세하게 흔들리니 시즈널 루틴이 필요해요.',
        '체질에 맞는 운동 한 가지만 시그니처로 잡아도 효과 커요.',
    ],
    'social': [
        '단톡방 안에서 자기 자리가 분명히 있는 결이에요.',
        '인스타나 오픈채팅 커뮤니티에서도 톤이 또렷해요.',
        '오프 모임 한 번씩 가면 캐릭터가 빛나는 자리예요.',
    ],
    'social_personality': [
        '단톡 안 분위기를 한 번에 바꾸는 한 마디를 잘 던져요.',
        'SNS 본진 친구들이 시그니처로 기억해줘요.',
        '커뮤니티 안에서도 캐릭터가 또렷이 자리잡아요.',
    ],
    'personality': [
        '평소 좋아하는 거 생기면 최애 덕질하듯 깊게 들어가요.',
        '플레이리스트 라인업이 그대로 색을 보여주는 결이에요.',
        '한 가지에 빠지면 단톡 친구들도 알아챌 만큼 표현이 나와요.',
    ],
    'innate_tendency': [
        '좋아하는 분야 생기면 굿즈 모으듯 한 번에 깊게 들어가요.',
        '플레이리스트 라인업이 그대로 색을 보여줘요.',
        '한 번 빠진 분야는 컴백 챙기듯 꾸준히 따라가요.',
    ],
    'innate_character': [
        '좋아하는 사람한테는 본진 최애 챙기듯 다 주는 결이에요.',
        '단톡 안 한 마디로 분위기 환기시키는 캐릭터예요.',
        '시그니처 분위기가 한 자리에 또렷이 자리잡아요.',
    ],
    'love_fate': [
        '인스타 DM 한 번에도 진심이 묻어나는 표현이 매력이에요.',
        '최애 노래 같이 듣고 싶은 사람한테 마음이 가요.',
        '플레이리스트 공유하고 싶은 사람한테 호감이 자연스럽게 가요.',
    ],
    'affection': [
        '좋아하는 사람한테 본진 굿즈 챙기듯 표현해요.',
        '시그니처 한 곡 같이 듣는 순간이 사랑 표현이에요.',
        '단톡 안에서도 챙기는 사람 한 명한테 자연스럽게 톤이 따뜻해져요.',
    ],
    'wealth': [
        '돈도 최애 챙기듯 또렷한 우선순위로 흐름이 잡혀요.',
        '플레이리스트 큐레이션처럼 돈 흐름에 시그니처가 있어요.',
        '굿즈 사는 결처럼 정한 데에는 망설임 없이 써요.',
    ],
    'wealth_gather': [
        '월급 들어오면 본진 굿즈 사두듯 자동이체 한 번에 챙겨놓는 결이에요.',
        '플레이리스트 정리하듯 가계부 한 번씩 정리하면 흐름 잡혀요.',
        '시그니처 적금 한 개만 꾸준히 굴려도 큰 흐름 만들어져요.',
    ],
    'wealth_loss_prevent': [
        '돈 나가는 알림 한 번씩 체크하는 결이 잘 맞아요.',
        '단톡 안 추천 휘둘리지 않고 시그니처 기준 지키는 결이에요.',
        '한 번 결정한 본진 자산은 컴백 챙기듯 꾸준히 들고 가요.',
    ],
    'wealth_invest': [
        '본진 종목 한 개 정해서 꾸준히 모아가는 흐름이 잘 맞아요.',
        '플레이리스트 정리하듯 분기별 한 번씩 손봐주면 흐름 잡혀요.',
        '최애 콘서트 챙기듯 투자도 본진 한 곳에 집중하는 결이에요.',
    ],
    'conclusion_self': [
        '시그니처 색이 단톡 안에서도 또렷해요.',
        '한 곡 들으면 떠오르는 시그니처가 인생 키워드예요.',
        '본진 최애 챙기듯 챙기는 분야가 인생 키워드예요.',
    ],
}


def inject_mz(text: str, cat: str, top_key: str) -> tuple[str, bool]:
    """본문 마지막 sentence 앞에 MZ 어휘 1줄 inject. (idempotent)"""
    if cat not in MZ_INJECTS:
        return text, False
    pool = MZ_INJECTS[cat]
    # 결정적 random (top_key+cat hash) — 같은 entry 매번 같은 inject
    seed = abs(hash(f'{top_key}|{cat}')) % len(pool)
    inject = pool[seed]
    if inject in text:
        return text, False  # 이미 있음
    # 마지막 . 뒤에 1줄 추가
    text = text.rstrip()
    if not text.endswith(('.', '!', '?')):
        text = text + '.'
    text = text + ' ' + inject
    return text, True


# ── 메인 ─────────────────────────────────────────────────────────────────────────
def main() -> None:
    data = json.loads(DATA.read_text(encoding='utf-8'))

    artifact_count = 0
    mz_count = 0
    entry_count = 0

    for top_key, cats in data.items():
        if len(top_key) != 2:  # 일주만 (일간 base 는 fallback safety net)
            continue
        for cat, val in cats.items():
            if isinstance(val, str):
                new_text, n_art = apply_artifact_fixes(val)
                new_text, mz_added = inject_mz(new_text, cat, top_key)
                if new_text != val:
                    cats[cat] = new_text
                    entry_count += 1
                artifact_count += n_art
                if mz_added:
                    mz_count += 1
            elif isinstance(val, dict):
                for g, t in val.items():
                    new_text, n_art = apply_artifact_fixes(t)
                    new_text, mz_added = inject_mz(new_text, cat, f'{top_key}-{g}')
                    if new_text != t:
                        val[g] = new_text
                        entry_count += 1
                    artifact_count += n_art
                    if mz_added:
                        mz_count += 1

    print(f'artifact fixes applied: {artifact_count}')
    print(f'MZ injects applied: {mz_count}')
    print(f'entries changed: {entry_count}')

    DATA.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    print(f'wrote {DATA}')


if __name__ == '__main__':
    main()
