# Round 73 Sprint 5 — polarity audit

## Per-pool metrics

| Pool | Entries | Hedge | Slop | 합니다체 | 폴라리티 흉:길:양면:중립 | 행동% | 양면% |
|------|---------|-------|------|---------|-----------------------|-------|-------|
| life_stage_pool.json | 60 | 0 | 0 | 0 | 29:19:4:8 | 27% | 48% |
| sipsin_persona.json | 120 | 0 | 0 | 0 | 62:45:10:3 | 22% | 68% |
| additional_life_pool.json | 30 | 0 | 0 | 0 | 14:10:5:1 | 14% | 100% |
| career_pool.json | 30 | 0 | 0 | 0 | 0:9:0:21 | 0% | 0% |
| wealth_detail.json | 24 | 0 | 0 | 0 | 9:2:3:10 | 37% | 29% |

## Overall (all pools combined)

- Total ko entries: 264
- Total sentences: 1224
- Hedge patterns:  0  (target: 0)
- AI 슬롭 patterns: 0  (target: 0)
- 합니다체 avoid:    0  (target: 0)
- 폴라리티 흉:114 길:85 양면:22 중립:43
  - pct: 흉 43%, 길 32%, 양면 8%, 중립 16%
  - target 5:4:1 ±1 → 흉 ~50% 길 ~40% 양면 ~10%
- 행동 처방: 278/1224 = 23%  (target ≥15%)
- 양면 anchor 비율: 147/264 = 56%  (target ≥30%)

## Threshold check

PASS — 전 항목 통과
