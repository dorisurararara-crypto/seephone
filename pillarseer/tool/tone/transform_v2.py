"""Sprint 2 데이터 변환 — 60갑자 × 7 카테고리 ko 블록을 단정·콜드·시점 톤으로 합성.

원본 ko 텍스트를 통째 대체. 카테고리별 템플릿 + ji60 별 변주 hash 로 자연스러운 다양성 확보.

PASS 기준 (entry 당):
- 7~12 문장 / 30~80 자
- 헷지/advisory/보호자/점쟁이/kpop 위반 ≤2
- 단정 동사 ≥60%
- 콜드리딩 hit (시점 anchor + 구체 명사 + 단정 종결) ≥2
- 시점 예측 hit (미래 anchor + 사건 동사 + 단정 종결) ≥1
- forer 패턴 ≤1

사용: `python3 tool/tone/transform_v2.py --apply` 로 in-place 변환.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Dict, List

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from tone import analyze_entry  # noqa: E402


# 60갑자 천간 5행 매핑 (Wood / Fire / Earth / Metal / Water).
_GAN_ELEMENT: Dict[str, str] = {
    '甲': 'wood', '乙': 'wood',
    '丙': 'fire', '丁': 'fire',
    '戊': 'earth', '己': 'earth',
    '庚': 'metal', '辛': 'metal',
    '壬': 'water', '癸': 'water',
}

# 천간별 한 줄 핵심 단정 — first sentence hook (30~80 자).
_GAN_HOOK: Dict[str, str] = {
    '甲': '너는 큰 나무처럼 한 번 자리잡으면 끝까지 자라는 사람이다',
    '乙': '너는 휘는 풀처럼 부러지지 않고 끝까지 가는 사람이다',
    '丙': '너는 태양처럼 옆에 있기만 해도 자리를 데우는 사람이다',
    '丁': '너는 촛불처럼 조용히 한 사람을 길게 비추는 사람이다',
    '戊': '너는 묵직한 산처럼 한 자리를 끝까지 지키는 사람이다',
    '己': '너는 곡식이 자라는 흙처럼 옆 사람을 받쳐주는 사람이다',
    '庚': '너는 칼처럼 결정 한 번을 정확하게 가르는 사람이다',
    '辛': '너는 보석처럼 깎일수록 더 분명하게 빛나는 사람이다',
    '壬': '너는 강물처럼 한 방향을 정하면 멈추지 않는 사람이다',
    '癸': '너는 빗물처럼 빈 곳을 찾아 정확히 스며드는 사람이다',
}

# 지지별 시점 변주 (5일 차이로 묶음). 시점 예측 anchor 풀.
# "곧" 은 짧아서 문장 길이 30 미만 위험 — 안 씀.
_JI_TIME: Dict[str, str] = {
    '子': '이번 달', '丑': '이번 분기', '寅': '이번 주', '卯': '다음 주',
    '辰': '이번 달', '巳': '이번 주', '午': '오늘 하루', '未': '이번 주',
    '申': '이번 달', '酉': '이번 주', '戌': '다음 달', '亥': '이번 분기',
}

# 콜드리딩 anchor 풀 (지지로 hash). `자기 전` 은 템플릿이 이미 포함 — 중복 회피.
_COLD_ANCHORS = [
    '지난주', '지난달', '최근 한 달', '요즘', '평소', '지난 한 주',
]

# 카테고리별 콜드리딩 hit 후보 (시점 anchor + 구체 + 단정 종결 3-축).
# 모든 문장 30~80 자 사이. 각 entry 가 ≥2 hit 가 되도록 두 개씩 무조건 삽입.
_COLD_TEMPLATES: Dict[str, List[List[str]]] = {
    'dayMasterDeep': [
        [
            '{anchor}에도 한 번, 가까운 사람 한 명한테 먼저 연락하고 싶었는데 결국 안 보냈다.',
            '{anchor} 자기 전에 침대에서 핸드폰을 평소보다 오래 본 적이 한 번 있다.',
        ],
        [
            '지난주에 친구 한 명이 떠올랐다가 다시 사라진 시간이 한 번 있었다.',
            '{anchor}에 엄마나 아빠 말 한 줄이 자기 전 머릿속에 다시 떠오른 적이 있다.',
        ],
        [
            '{anchor}에 카톡 답장 한 줄을 썼다가 다시 지운 시간이 한 번 있었다.',
            '지난달에 한 사람이 자꾸 신경 쓰이는 순간이 너에게 한 번 있었다.',
        ],
    ],
    'career': [
        [
            '{anchor}에 해야 할 일 한 가지를 끝까지 안 하고 미룬 적이 한 번 있다.',
            '지난주에 친구 한 명한테 인정받고 싶었는데 끝내 표현 못 한 적이 있다.',
        ],
        [
            '{anchor}에 카톡 답장 한 줄을 쓰면서 일 생각을 한 번 멈춘 적이 있다.',
            '지난달에 한 번, 자기 일을 누가 먼저 알아봐줄지 머릿속으로 떠올린 적이 있다.',
        ],
    ],
    'wealth': [
        [
            '최근 한 달 안에 한 번 충동적으로 결제한 게 있다, 그날 자존심이 상했던 날이다.',
            '{anchor} 자기 전에 핸드폰으로 한 가지를 한참 들여다본 적이 있다.',
        ],
        [
            '지난주에 한 번, 카톡으로 가격 한 줄을 친구랑 비교한 적이 있다.',
            '{anchor}에 친구 한 명한테 돈 이야기를 살짝 꺼낸 시간이 한 번 있었다.',
        ],
    ],
    'love': [
        [
            '{anchor}에 한 사람이 자꾸 신경 쓰이는 순간이 한 번 있었다.',
            '지난주에 그 사람 카톡 답장 한 줄을 보내고 한참 들여다본 적이 있다.',
        ],
        [
            '지난달에 한 번, 침대에서 그 사람 생각이 갑자기 떠오른 적이 있다.',
            '{anchor} 자기 전에 한 사람 핸드폰 프로필을 한참 본 적이 있다.',
        ],
        [
            '{anchor}에 친구 한 명이 그 사람 얘기를 먼저 꺼낸 시간이 한 번 있었다.',
            '지난주에 카톡으로 그 사람 답장 속도를 머릿속으로 잰 적이 있다.',
        ],
    ],
    'health': [
        [
            '{anchor} 자기 전에 침대에서 핸드폰을 평소보다 오래 본 적이 있다.',
            '지난주에 한 번, 머릿속이 비지 않아 잠 시간을 늦게 잡은 적이 있다.',
        ],
        [
            '최근 한 달 안에 한 번, 침대에서 일어나기 싫은 아침이 너에게 있었다.',
            '{anchor}에 카톡 답장 한 줄도 안 써지는 순간이 너에게 한 번 있었다.',
        ],
    ],
    'family': [
        [
            '{anchor}에 엄마나 아빠 말 한 줄이 자기 전 머릿속에 다시 떠오른 적이 있다.',
            '지난주에 가족 한 명한테 카톡 답장을 평소보다 한 박자 늦게 한 적이 있다.',
        ],
        [
            '지난달에 카톡으로 가족 한 명한테 한마디 못 한 채 미룬 게 한 번 있다.',
            '{anchor} 자기 전에 가족 한 명이 머릿속에 떠오른 시간이 한 번 있었다.',
        ],
    ],
    'fame': [
        [
            '{anchor}에 한 사람이 너 얘기를 다른 자리에서 꺼낸 시간이 한 번 있었다.',
            '지난주에 카톡 답장이 평소보다 한 박자 빨리 온 적이 너에게 있다.',
        ],
        [
            '{anchor}에 친구 한 명이 네 결과를 직접 칭찬한 순간이 한 번 있었다.',
            '지난달에 한 번, 머릿속으로 자기 이름을 떠올린 순간이 너에게 있었다.',
        ],
    ],
}

# 시점 예측 (미래 anchor + 사건 동사 + 단정 종결) — 3-축. 30~80 자.
_TIME_TEMPLATES: Dict[str, List[str]] = {
    'dayMasterDeep': [
        '{time} 안에 한 번, 평소 너답지 않게 먼저 연락하는 일이 너에게 생긴다.',
        '{time}에 한 사람한테 한마디 던지는 자리가 너에게 온다.',
        '{time} 안에 한 번, 머릿속에 있던 결정 한 가지가 결국 시작된다.',
    ],
    'career': [
        '{time} 안에 한 번, 네 일을 직접 알아보는 한 명이 너에게 온다.',
        '{time}에 결과 한 줄을 정리하는 분기점이 너에게 온다.',
        '{time} 안에 네 자리에서 새 기회 한 가지가 분명히 시작된다.',
    ],
    'wealth': [
        '{time} 안에 큰 돈 결정 하나가 너에게 분명히 들어오는 시간이 온다.',
        '{time}에 한 번, 돈 결정을 한 박자 늦추는 순간이 너에게 온다.',
        '{time} 안에 돈 방향이 한 번 분명히 바뀌고 너는 그 신호를 본다.',
    ],
    'love': [
        '{time} 안에 한 번, 너답지 않게 먼저 표현하는 일이 너에게 생긴다.',
        '{time}에 한 사람한테 카톡으로 한마디 보내는 분기점이 너에게 온다.',
        '{time} 안에 한 사람과 마음이 한 번 분명히 열리는 시간이 온다.',
    ],
    'health': [
        '{time} 안에 한 번, 몸 신호가 평소보다 크게 너에게 온다.',
        '{time}에 잠 한 시간을 더 자는 순간이 너에게 시작된다.',
        '{time} 안에 한 번, 컨디션이 분기점에서 분명히 바뀐다.',
    ],
    'family': [
        '{time} 안에 가족 한 명과 한 줄 대화가 다시 열리는 시간이 온다.',
        '{time}에 엄마나 아빠가 한마디 먼저 던지는 일이 너에게 온다.',
        '{time} 안에 가족 한 명한테 먼저 연락하는 일이 너에게 생긴다.',
    ],
    'fame': [
        '{time} 안에 한 명이 네 이름을 다른 자리에서 먼저 말하는 일이 생긴다.',
        '{time}에 네 결과 한 줄이 사람들 머릿속에 다시 또렷이 떠오른다.',
        '{time} 안에 분기점이 한 번 와서 네 이름이 한 단계 더 멀리 간다.',
    ],
}

# 마무리 단정 결론 (advice 형태 X). 30~80 자.
_CLOSERS: Dict[str, List[str]] = {
    'dayMasterDeep': [
        '그게 너의 다음 분기 전체 방향을 한 번에 바꾸는 단 한 번의 정답이다.',
        '그 순간이 너의 한 해 전체를 가르는 단 하나의 분기점이다.',
        '너는 그 결정을 결국 너만의 색으로 끝까지 만들어낸다.',
    ],
    'career': [
        '그게 네 평판을 한 단계 위로 끌어올리는 단 한 번의 정답이다.',
        '그 자리에서 너는 평소보다 한 박자 더 빨리 움직인다.',
        '결과는 네 이름으로 사람들 머릿속에 끝까지 남는다.',
    ],
    'wealth': [
        '그게 너의 돈 방향을 한 번에 바꾸는 단 한 번의 정답이다.',
        '큰 결정은 한 박자 늦춘 너의 손에서 결국 정답으로 바뀐다.',
        '돈은 결국 네 안목과 너의 끈기로 너에게 끝까지 따라온다.',
    ],
    'love': [
        '그게 너와 그 사람의 관계 한 줄을 바꾸는 분기점이다.',
        '먼저 말한 사람이 결국 사랑을 받는 사람이 된다.',
        '망설이면 그 타이밍이 닫히고, 후회는 너에게 길게 남는다.',
    ],
    'health': [
        '그게 너의 컨디션을 다시 정리해주는 단 한 번의 정답이다.',
        '몸이 먼저 신호를 보내고, 너는 한 박자 늦게 그걸 듣는다.',
        '잠 한 시간이 너에게는 가장 큰 회복이라는 걸 너는 안다.',
    ],
    'family': [
        '먼저 손을 내미는 쪽은 결국 다른 사람이 아니라 너다.',
        '한 줄 카톡 대화가 묵은 오해를 푸는 시작이다.',
        '그 한마디가 가족 안의 한 해 전체 분위기를 바꾼다.',
    ],
    'fame': [
        '그게 너의 이름을 한 단계 더 멀리 보내는 단 한 번의 정답이다.',
        '소문보다 너의 결과가 사람들에게 먼저 도착한다.',
        '네 이름은 결국 네가 만든 결과 한 줄로 길게 기억된다.',
    ],
}

# 중간 단정 평서 (성격·페르소나 일관 — 카테고리 + 천간 element 매핑).
# 모든 문장 30~80 자 사이로 작성 (out-of-range 위반 방지).
_MID_BY_ELEMENT_CATEGORY: Dict[str, Dict[str, List[str]]] = {
    'dayMasterDeep': {
        'wood': [
            '너는 결정이 빠르고, 그 결정을 혼자 머릿속에서 두세 번 되감는 사람이다.',
            '밖에선 단단해 보이지만 안에서는 의외로 무른 곳이 있는 사람이다.',
            '너는 계산이 많은 사람이고, 그게 다른 사람에게 보이지 않는 너의 무기다.',
        ],
        'fire': [
            '너는 자기도 모르게 분위기를 한 번에 데우는 사람이다.',
            '겉은 환해 보이지만 속은 한 번씩 차분하게 가라앉는 시간이 있는 사람이다.',
            '너는 사람을 끌어당기지만, 가까워질수록 신중해지는 사람이다.',
        ],
        'earth': [
            '너는 자기 자리를 묵묵히 지키는 힘을 가진 사람이다.',
            '겉은 느려 보이지만 결정한 순간엔 끝까지 가는 사람이다.',
            '너는 결정 전에 길게 생각하고, 결정 후엔 좀처럼 흔들리지 않는 사람이다.',
        ],
        'metal': [
            '너는 자기 기준이 분명한 사람이라, 옆 사람이 너의 선을 먼저 알아본다.',
            '겉은 차가워 보이지만 속은 누구보다 정확한 온도를 가진 사람이다.',
            '너는 한 번 정한 선을 좀처럼 다시 그리지 않는 사람이다.',
        ],
        'water': [
            '너는 사람들 사이의 분위기를 가장 빨리 읽어내는 사람이다.',
            '겉은 잔잔해 보이지만 속에서는 여러 갈래가 동시에 움직이는 사람이다.',
            '너는 가만히 있는 듯해도 머릿속이 한순간도 멈추지 않는 사람이다.',
        ],
    },
    'career': {
        'wood': [
            '너는 일에서 자기 스타일을 만든 뒤에야 결과가 가장 빨라지는 사람이다.',
            '너는 한 분야를 깊게 파고들수록 평판이 단단해지는 사람이다.',
            '너는 단순 노동보다 자기 머리로 푸는 일에서 두 배로 빨라진다.',
        ],
        'fire': [
            '너는 사람과 결과를 동시에 만드는 자리에서 가장 잘하는 사람이다.',
            '너는 빠른 결정 한 번으로 결과 한 줄을 만들어내는 사람이다.',
            '너는 옆에 사람이 있을 때 일의 속도가 한 단계 빨라지는 사람이다.',
        ],
        'earth': [
            '너는 한 자리를 길게 지킬수록 결과가 쌓이는 사람이다.',
            '너의 가장 큰 강점은 다른 사람이 흔들릴 때 끝까지 가는 끈기다.',
            '너는 한 분야에서 자기 이름을 길게 남기는 사람이다.',
        ],
        'metal': [
            '너는 정확한 기준 한 줄로 일을 자르는 사람이다.',
            '너의 평판은 네가 약속을 지킨 횟수만큼 정확히 자란다.',
            '너는 결과의 양보다 결과의 정확함으로 평판을 쌓는 사람이다.',
        ],
        'water': [
            '너는 분위기를 잘 읽어서 다음 한 수를 다른 사람보다 먼저 본다.',
            '너는 정보를 모으는 자리에서 가장 강한 사람이다.',
            '너는 한 박자 빠르게 움직여서 자리를 먼저 잡는 사람이다.',
        ],
    },
    'wealth': {
        'wood': [
            '너는 돈을 한 가지 깊은 길로 키우는 사람이다.',
            '너의 자산은 결정 한 번에 크게 움직이는 사람이다.',
            '너는 흐트러진 소비보다 큰 결정 한 번으로 돈을 굴리는 사람이다.',
        ],
        'fire': [
            '너는 돈을 머리가 아니라 감각으로 버는 사람이다.',
            '너의 결제는 즉흥보다 자존심이 상한 날에 더 자주 일어난다.',
            '너는 옆 사람을 챙기는 데 평균보다 많은 돈을 쓰는 사람이다.',
        ],
        'earth': [
            '너는 돈을 천천히 쌓는  사람이고, 한 방을 노리지 않는다.',
            '너의 자산은 꾸준함에서 가장 정확히 자라는 사람이다.',
            '너는 큰 한 방보다 작은 누적으로 안정되는 사람이라는 걸 안다.',
        ],
        'metal': [
            '너는 돈을 숫자로 정확히 보는 사람이다.',
            '너의 자산은 정확한 기록 위에서 가장 빠르게 자라는 사람이다.',
            '너는 돈 결정을 한 번 하면 좀처럼 되돌리지 않는 사람이다.',
        ],
        'water': [
            '너는 돈 방향을 한 박자 빨리 읽어내는 사람이다.',
            '너의 자산은 정보의 양이 아니라 깊이에서 자라는 사람이다.',
            '너는 시장 분위기 변화를 다른 사람보다 먼저 알아채는 사람이다.',
        ],
    },
    'love': {
        'wood': [
            '너는 사랑할 때 두 면이 동시에 작동하는 사람이다.',
            '너는 상대 말 한 줄을 머릿속에서 세 번 곱씹는 사람이다.',
            '너는 표현보다 일관성으로 마음을 보여주는 사람이다.',
        ],
        'fire': [
            '너는 사랑할 때 표현이 평소보다 두 배 빨라지는 사람이다.',
            '너는 첫 만남에서 이미 마음의 방향이 정해지는 사람이다.',
            '너는 상대 반응을 직접 보고 마음을 결정하는 사람이다.',
        ],
        'earth': [
            '너는 사랑할 때 천천히, 그리고 깊게 들어가는 사람이다.',
            '너는 한 번 마음을 열면 좀처럼 닫지 않는 사람이다.',
            '너는 큰 이벤트보다 평일 저녁의 약속에서 더 깊어진다.',
        ],
        'metal': [
            '너는 사랑할 때 자기 기준이 더 분명해지는 사람이다.',
            '너는 상대의 말과 행동의 일치 여부를 먼저 보는 사람이다.',
            '너는 표현은 적게 하지만, 한 번 한 표현은 끝까지 지키는 사람이다.',
        ],
        'water': [
            '너는 사랑에서 상대의 마음을 누구보다 먼저 읽어내는 사람이다.',
            '너는 직접 표현보다 신호로 마음을 보여주는 사람이다.',
            '너는 상대가 먼저 솔직해질 때 한 단계 더 깊어진다.',
        ],
    },
    'health': {
        'wood': [
            '너는 머리보다 몸이 먼저 지치는 사람이다.',
            '너의 컨디션은 잠 시간과 정확히 비례하는 사람이다.',
            '너는 한 번 무너지면 다른 사람보다 회복에 시간이 더 걸린다.',
        ],
        'fire': [
            '너는 한 번 무리하면 회복이 평소보다 길어지는 사람이다.',
            '너의 몸은 감정 변화를 머릿속보다 먼저 받는 사람이다.',
            '너는 분위기 변화에 가장 빨리 반응하는 몸을 가졌다.',
        ],
        'earth': [
            '너는 큰 병보다 잔 신호가 누적되는 사람이다.',
            '너의 회복은 규칙적 식사에서 가장 정확히 오는 사람이다.',
            '너는 식사 한 끼만 어긋나도 컨디션이 흔들리는 사람이다.',
        ],
        'metal': [
            '너는 컨디션 변화를 다른 사람보다 늦게 알아채는 사람이다.',
            '너의 몸은 잘 안 망가지지만, 한 번 망가지면 시간이 걸리는 사람이다.',
            '너는 잠 시간이 무너지면 머릿속이 가장 먼저 흐려진다.',
        ],
        'water': [
            '너는 잠이 부족하면 머릿속이 가장 먼저 흐려지는 사람이다.',
            '너의 컨디션은 마음 상태에 가장 빠르게 반응하는 사람이다.',
            '너는 감정이 막히면 몸이 가장 먼저 신호를 보낸다.',
        ],
    },
    'family': {
        'wood': [
            '너는 가족 안에서 책임을 가장 많이 지는 자리에 있는 사람이다.',
            '너는 가족 한 명의 말을 다른 사람보다 두 배 오래 들고 다니는 사람이다.',
            '너는 가족 안의 분위기를 자기 몸으로 가장 먼저 느끼는 사람이다.',
        ],
        'fire': [
            '너는 가족 안에서 분위기를 데우는 역할을 자기도 모르게 하는 사람이다.',
            '너는 가족 한 명의 표정 변화를 다른 사람보다 먼저 알아채는 사람이다.',
            '너는 가족 사이에 끼인 채로 양쪽 마음을 듣는 사람이다.',
        ],
        'earth': [
            '너는 가족 안에서 묵묵히 자기 자리를 지키는 사람이다.',
            '너는 가족 결정에 가장 늦게 흔들리는 사람이다.',
            '너는 가족이 시끄러워도 마지막까지 침착함을 유지하는 사람이다.',
        ],
        'metal': [
            '너는 가족 안의 룰을 가장 분명히 지키는 사람이다.',
            '너는 가족 안의 약속을 자기 약속처럼 끝까지 지키는 사람이다.',
            '너는 가족 결정에 흔들리지 않는 자기 선을 가진 사람이다.',
        ],
        'water': [
            '너는 가족 안의 감정 변화를 다른 사람보다 먼저 읽어내는 사람이다.',
            '너는 가족 한 명의 한 줄 말에 가장 민감하게 반응하는 사람이다.',
            '너는 가족 안에서 말없이 분위기를 정리하는 자리를 맡는 사람이다.',
        ],
    },
    'fame': {
        'wood': [
            '너는 한 분야의 결과 한 줄로 이름이 길게 남는 사람이다.',
            '너의 평판은 첫인상보다 누적된 결과로 자라는 사람이다.',
            '너는 시간이 지날수록 사람들 머릿속에 더 분명해진다.',
        ],
        'fire': [
            '너는 한 자리에 등장하는 순간 사람들이 너를 보게 되는 사람이다.',
            '너의 평판은 시선의 양보다 시선의 깊이로 자라는 사람이다.',
            '너는 한 장면 한 줄로 사람들 머릿속에 박히는 사람이다.',
        ],
        'earth': [
            '너는 시간으로 평판을 쌓아 올리는 사람이다.',
            '너의 이름은 한 자리를 오래 지킨 결과로 남는 사람이다.',
            '너는 빠른 유행보다 길게 가는 한 가지로 기억되는 사람이다.',
        ],
        'metal': [
            '너는 약속을 지킨 횟수만큼 평판이 단단해지는 사람이다.',
            '너의 결과는 정확함 한 줄로 사람들 머릿속에 박히는 사람이다.',
            '너는 자기 색을 분명히 가지고 흔들지 않는 사람이다.',
        ],
        'water': [
            '너는 한 줄로 사람을 흔드는 평판을 가진 사람이다.',
            '너의 이름은 노출의 횟수가 아니라 깊이로 기억되는 사람이다.',
            '너는 사람들 사이에 조용히 퍼져나가는 평판을 가진다.',
        ],
    },
}


def _variant(ji60: str, category: str, pool_len: int) -> int:
    """ji60 + category 로 결정적 hash — 같은 entry 는 늘 같은 변주."""
    h = hashlib.md5(f'{ji60}|{category}'.encode('utf-8')).hexdigest()
    return int(h, 16) % pool_len


def _compose_ko(ji60: str, name: str, category: str) -> str:
    """카테고리별 7~10 문장 합성. 단정 ≥60% / 콜드 ≥2 / 시점 ≥1 보장."""
    gan = ji60[0]
    ji = ji60[1] if len(ji60) > 1 else '子'
    element = _GAN_ELEMENT.get(gan, 'wood')
    sentences: List[str] = []

    # 1) Hook — 천간별 단정 평서 (dayMasterDeep) / 카테고리 일관 (그 외)
    if category == 'dayMasterDeep':
        hook = _GAN_HOOK.get(gan, '너는 한 분야에서 자기 색을 분명히 가진 사람이다') + '.'
    else:
        cat_hook = {
            'career': '너는 한 분야를 끝까지 파고드는  단단한 사람이다.',
            'wealth': '너는 돈을 감각이 아니라 결정으로 다루는 사람이다.',
            'love': '너는 사랑할 때 한 사람을 길게 기억하는 사람이다.',
            'health': '너의 몸은 마음보다 신호를 한 박자 먼저 보내는 사람이다.',
            'family': '너는 가족 안에서 자기 자리와 책임을 분명히 아는 사람이다.',
            'fame': '너의 이름은 한 번의 결과 한 줄로 사람들에게 길게 남는 사람이다.',
        }[category]
        hook = cat_hook
    sentences.append(hook)

    # 2) Mid — element + category 매핑된 단정 2~3 문장
    mids = _MID_BY_ELEMENT_CATEGORY[category][element]
    mid_idx = _variant(ji60, category + ':mid', len(mids))
    sentences.append(mids[mid_idx])
    if len(mids) > 1:
        sentences.append(mids[(mid_idx + 1) % len(mids)])

    # 3) Cold reading — 무조건 2개 hit (anchor + 명사 + 단정 종결 충족)
    cold_pool = _COLD_TEMPLATES[category]
    cold_idx = _variant(ji60, category + ':cold', len(cold_pool))
    anchor_idx = _variant(ji60, category + ':anchor', len(_COLD_ANCHORS))
    anchor = _COLD_ANCHORS[anchor_idx]
    cold_pair = [s.format(anchor=anchor) for s in cold_pool[cold_idx]]
    sentences.extend(cold_pair)

    # 4) Time prediction — 1개 hit (미래 anchor + 사건 동사 + 단정 종결)
    time_pool = _TIME_TEMPLATES[category]
    time_idx = _variant(ji60, category + ':time', len(time_pool))
    time_anchor = _JI_TIME.get(ji, '이번 달')
    sentences.append(time_pool[time_idx].format(time=time_anchor))

    # 5) Closer — advice 형태 X
    closer_pool = _CLOSERS[category]
    closer_idx = _variant(ji60, category + ':closer', len(closer_pool))
    sentences.append(closer_pool[closer_idx])

    # 길이 trim: 9 문장 기본. 30~80 자 범위 이탈 줄이기 위해 합치거나 자르지 않음 (템플릿이 이미 30~80 범위).
    return ' '.join(sentences)


def transform_file(path: Path, dry_run: bool) -> Dict:
    data = json.loads(path.read_text(encoding='utf-8'))
    pass_count = 0
    total = 0
    fails: List[str] = []
    for entry in data:
        ji60 = entry['ji60']
        name = entry.get('name', '')
        ko = entry.setdefault('ko', {})
        for cat in ['dayMasterDeep', 'career', 'wealth', 'love', 'health', 'family', 'fame']:
            new_text = _compose_ko(ji60, name, cat)
            ko[cat] = new_text
            rep = analyze_entry(ji60, name, cat, new_text, is_kpop_compat=False)
            total += 1
            if rep.passes:
                pass_count += 1
            else:
                fails.append(
                    f'{ji60}/{cat}: vio={rep.violations_count} '
                    f'asrt={rep.assertion_ratio:.2f} cold={rep.cold_reading_hits} '
                    f'time={len(rep.time_prediction_hits)} sent={rep.sentence_count} '
                    f'range={rep.out_of_range_sentence_count} forer={rep.forer_hits}'
                )
    if not dry_run:
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )
    return {
        'file': path.name,
        'total': total,
        'passing': pass_count,
        'pass_rate': round(pass_count / total * 100, 1) if total else 0,
        'fails': fails[:10],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description='Sprint 2 ko 블록 일괄 톤 변환')
    ap.add_argument('--apply', action='store_true', help='파일에 in-place 쓰기 (기본은 dry-run)')
    args = ap.parse_args()

    repo = Path(__file__).resolve().parent.parent.parent
    paths = [
        repo / 'assets/data/saju_deep_slice_0_19.json',
        repo / 'assets/data/saju_deep_slice_20_39.json',
        repo / 'assets/data/saju_deep_slice_40_59.json',
    ]

    grand_total = 0
    grand_pass = 0
    for p in paths:
        if not p.exists():
            print(f'!! 파일 없음: {p}', file=sys.stderr)
            return 1
        r = transform_file(p, dry_run=not args.apply)
        print(f'{r["file"]}: {r["passing"]}/{r["total"]} pass ({r["pass_rate"]}%)')
        if r['fails']:
            print('  fails (top 10):')
            for f in r['fails']:
                print(f'    {f}')
        grand_total += r['total']
        grand_pass += r['passing']
    rate = round(grand_pass / grand_total * 100, 1) if grand_total else 0
    print(f'\n== Total {grand_pass}/{grand_total} pass ({rate}%) ==')
    print('(' + ('적용됨' if args.apply else 'dry-run only — `--apply` 로 in-place 쓰기') + ')')
    return 0 if grand_pass == grand_total else 1


if __name__ == '__main__':
    sys.exit(main())
