"""톤 검수 — entry 단위 분석 (룰 적용 + 단정·콜드·시점 카운트)."""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Tuple

from .rules import (
    HEDGE_RULES,
    ADVISORY_RULES,
    PROTECTOR_RULES,
    ORACLE_RULES,
    KPOP_ABSTRACT_RULES,
    ASSERTION_VERB_ENDINGS,
    TIME_PREDICTION_PATTERNS,
    COLD_TIME_ANCHORS,
    COLD_SPECIFIC_NOUNS,
)


CATEGORIES = ['dayMasterDeep', 'career', 'wealth', 'love', 'health', 'family', 'fame']


@dataclass
class Hit:
    pattern: str
    snippet: str
    suggestion: str = ''


@dataclass
class EntryReport:
    ji60: str
    name: str
    category: str
    sentence_count: int
    avg_char_per_sentence: float
    hedge_hits: List[Hit] = field(default_factory=list)
    advisory_hits: List[Hit] = field(default_factory=list)
    protector_hits: List[Hit] = field(default_factory=list)
    oracle_hits: List[Hit] = field(default_factory=list)
    kpop_abstract_hits: List[Hit] = field(default_factory=list)
    assertion_verb_count: int = 0
    assertion_ratio: float = 0.0
    cold_reading_hits: int = 0
    cold_reading_examples: List[str] = field(default_factory=list)
    time_prediction_hits: List[str] = field(default_factory=list)
    out_of_range_sentence_count: int = 0
    forer_hits: int = 0

    @property
    def violations_count(self) -> int:
        return (
            len(self.hedge_hits)
            + len(self.advisory_hits)
            + len(self.protector_hits)
            + len(self.oracle_hits)
            + len(self.kpop_abstract_hits)
        )

    @property
    def passes(self) -> bool:
        if self.violations_count > 2:
            return False
        if self.assertion_ratio < 0.6:
            return False
        if self.cold_reading_hits < 2:
            return False
        if len(self.time_prediction_hits) < 1:
            return False
        if self.sentence_count < 7 or self.sentence_count > 12:
            return False
        max_out = max(1, self.sentence_count // 4)
        if self.out_of_range_sentence_count > max_out:
            return False
        if self.forer_hits > 1:
            return False
        return True


_REGEX_NOISE = re.compile(r'\(\?[<:!=].*?\)|\\[a-zA-Z]|[\\^$.*+?()|\[\]{}]')


def _literal_len(pattern: str) -> int:
    """regex lookahead/escape 노이즈 제거 후 literal 길이 측정 (긴 패턴 우선)."""
    return len(_REGEX_NOISE.sub('', pattern))


def split_sentences(text: str) -> List[str]:
    raw = re.split(r'(?<=[\.\!\?])\s+|(?<= — )|(?<= - )', text)
    out: List[str] = []
    for s in raw:
        s = s.strip()
        if s and len(s) > 1:
            out.append(s)
    return out


def collect_hits(text: str, rules: List[Tuple[str, str]]) -> List[Hit]:
    """겹치는 span 은 한 번만 카운트. 긴 패턴 우선 (`무대 위` > `무대`)."""
    hits: List[Hit] = []
    claimed: List[Tuple[int, int]] = []
    ordered = sorted(rules, key=lambda r: -_literal_len(r[0]))
    for pat, sugg in ordered:
        for m in re.finditer(pat, text):
            s, e = m.start(), m.end()
            if any(not (e <= cs or s >= ce) for cs, ce in claimed):
                continue
            claimed.append((s, e))
            hits.append(Hit(pattern=pat, snippet=m.group(0), suggestion=sugg))
    return hits


def count_matches(text: str, patterns: List[str]) -> List[str]:
    out: List[str] = []
    for pat in patterns:
        for m in re.finditer(pat, text):
            out.append(m.group(0))
    return out


def _has_assertion_ending(s: str) -> bool:
    return any(re.search(pat, s) for pat in ASSERTION_VERB_ENDINGS)


def count_assertion_verbs(sentences: List[str]) -> int:
    return sum(1 for s in sentences if _has_assertion_ending(s))


# 행동·사건 동사 — "시점 예측" 강화 조건 (3-축 매칭).
_FUTURE_EVENT_VERBS = [
    r'온다', r'생긴다', r'시작된다', r'끝난다', r'바뀐다',
    r'만난다', r'닿는다', r'열린다', r'닫힌다', r'터진다',
    r'벌어진다', r'바뀌어', r'들어온다', r'다가온다',
    r'한다', r'보낸다', r'간다',
    r'기회', r'분기점', r'전환', r'변화',
    r'먼저 연락', r'표현',
]


def count_strong_time_prediction(text: str, sentences: List[str]) -> List[str]:
    """시점 예측 hit = (미래 anchor) + (행동·사건 어휘) + (단정 종결) 같은 문장 충족.

    spec §4.5 예시: "이번 달 안에 한 번, 평소 너답지 않게 먼저 연락하는 일이 생긴다" —
    anchor(이번 달) + 행동(먼저 연락 / 생긴다) + 단정 종결(생긴다).
    """
    out: List[str] = []
    for s in sentences:
        if not any(re.search(p, s) for p in TIME_PREDICTION_PATTERNS):
            continue
        if not any(re.search(p, s) for p in _FUTURE_EVENT_VERBS):
            continue
        if not _has_assertion_ending(s):
            continue
        out.append(s)
    return out


def count_cold_reading(text: str, sentences: List[str]) -> Tuple[int, List[str]]:
    """콜드리딩 hit = (시점 anchor) + (구체 명사) + (단정 종결) 같은 문장 동시 충족."""
    n = 0
    examples: List[str] = []
    for s in sentences:
        if not any(re.search(p, s) for p in COLD_TIME_ANCHORS):
            continue
        if not any(re.search(p, s) for p in COLD_SPECIFIC_NOUNS):
            continue
        if not _has_assertion_ending(s):
            continue
        n += 1
        if len(examples) < 4:
            examples.append(s)
    return n, examples


_FORER_HEDGE_PAIRS = [
    r'한 명은 .{2,20} 한 명은',
    r'하나는 .{2,20} 하나는',
    r'두 명이 된다',
    r'양면',
    r'양쪽 다',
]


def count_forer(text: str) -> int:
    n = 0
    for pat in _FORER_HEDGE_PAIRS:
        n += len(re.findall(pat, text))
    return n


def count_out_of_range(sentences: List[str]) -> int:
    return sum(1 for s in sentences if len(s) < 30 or len(s) > 80)


def analyze_entry(
    ji60: str,
    name: str,
    category: str,
    text: str,
    is_kpop_compat: bool,
) -> EntryReport:
    sentences = split_sentences(text)
    sc = len(sentences)
    avg = (sum(len(s) for s in sentences) / sc) if sc else 0
    rep = EntryReport(
        ji60=ji60, name=name, category=category,
        sentence_count=sc, avg_char_per_sentence=round(avg, 1),
    )
    rep.hedge_hits = collect_hits(text, HEDGE_RULES)
    rep.advisory_hits = collect_hits(text, ADVISORY_RULES)
    rep.protector_hits = collect_hits(text, PROTECTOR_RULES)
    rep.oracle_hits = collect_hits(text, ORACLE_RULES)
    rep.kpop_abstract_hits = (
        [] if is_kpop_compat else collect_hits(text, KPOP_ABSTRACT_RULES)
    )
    rep.assertion_verb_count = count_assertion_verbs(sentences)
    rep.assertion_ratio = rep.assertion_verb_count / sc if sc else 0.0
    rep.cold_reading_hits, rep.cold_reading_examples = count_cold_reading(text, sentences)
    # 시점 예측 = 3-축 충족 문장만 카운트 (단순 anchor 매칭 X — false positive 방지).
    rep.time_prediction_hits = count_strong_time_prediction(text, sentences)
    rep.out_of_range_sentence_count = count_out_of_range(sentences)
    rep.forer_hits = count_forer(text)
    return rep


def analyze_file(path: Path, is_kpop_compat: bool = False) -> List[EntryReport]:
    data = json.loads(path.read_text(encoding='utf-8'))
    out: List[EntryReport] = []
    for entry in data:
        ji60 = entry.get('ji60', '?')
        name = entry.get('name', '?')
        ko = entry.get('ko', {})
        for cat in CATEGORIES:
            text = ko.get(cat, '')
            if not text:
                continue
            out.append(analyze_entry(ji60, name, cat, text, is_kpop_compat))
    return out
