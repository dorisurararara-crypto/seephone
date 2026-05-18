"""R92 sprint 3 — codex sample audit.

Stratified sample (10 entry) 을 codex 에 평가 요청. 결과 분석으로 진짜 issue 패턴 파악.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'assets/data/life_paragraphs.json'

# Stratified sample: 10 entry (2 천간 × 5 카테고리, 일주 diverse)
SAMPLE = [
    ('갑자', 'early_life', None),
    ('갑오', 'mid_life', None),
    ('을묘', 'late_life', None),
    ('을미', 'innate_character', 'M'),
    ('병오', 'health', None),
    ('정해', 'love_fate', 'F'),
    ('무진', 'wealth', None),
    ('기축', 'social', None),
    ('경신', 'wealth_invest', None),
    ('신유', 'affection', 'M'),
]

RUBRIC = """다음 사주 운세 paragraph 를 5 axis 로 평가하라. 각 axis 0-10 점, 소수점 1자리.

axis 1 — 자연 한국어 흐름 (해요체, 어절 자연스러움, 조사 정확성)
axis 2 — persona depth (구체적 상황·디테일, 일반론 X)
axis 3 — K-POP MZ 친밀 톤 (단톡/덕질/플레이리스트/팬싸/응원봉/최애 等 자연 inject 또는 그 vibe)
axis 4 — 사주 anchor 함축 (해당 일주 천간·일지 본성이 본문에서 느껴짐)
axis 5 — readability (한 사람만 읽었을 때 self-contained, 한 entry 완결성)

최종 점수 = 5 axis 평균. 9.9 이상이 PASS.

각 entry 답변 format (JSON 1줄):
{"id":"<id>","scores":[a1,a2,a3,a4,a5],"avg":X.X,"verdict":"PASS|FAIL","issues":["..","..","..."]}
"""


def main() -> None:
    data = json.loads(DATA.read_text(encoding='utf-8'))

    prompt_parts = [RUBRIC, '', '=== 평가 대상 ===']
    for top_key, cat, gender in SAMPLE:
        entry = data[top_key][cat]
        if isinstance(entry, dict):
            text = entry.get(gender or 'M', '')
        else:
            text = entry
        sample_id = f'{top_key}-{cat}' + (f'-{gender}' if gender else '')
        prompt_parts.append(f'\n[id: {sample_id}]\n{text}')

    prompt_parts.append('\n=== 답변 ===\n각 entry 별 JSON 1줄씩 출력.')

    prompt = '\n'.join(prompt_parts)
    print(f'codex prompt length: {len(prompt)} chars')
    print('---')

    result = subprocess.run(
        ['codex', 'exec'],
        input=prompt,
        capture_output=True,
        text=True,
        timeout=180,
    )
    print('=== codex stdout (last 100 lines) ===')
    print('\n'.join(result.stdout.splitlines()[-100:]))
    if result.returncode != 0:
        print(f'=== codex stderr ===')
        print(result.stderr)


if __name__ == '__main__':
    main()
