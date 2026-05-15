---
name: project_pillarseer_round_83
description: "R83 sprint 1 — P1 정확도/UX 신뢰 7 항목 통합 spec (codex 9.91 PASS, 595 line, 미배포)"
metadata: 
  node_type: memory
  type: project
  date: 2026-05-15
  originSessionId: f718ca1f-90b5-4e42-908d-e7fa50b20f06
---

## R83 trigger — 사용자 mandate "Round 83 변환 우선 (더 수정 후 한 번에 배포)"

R82 14 sprint 중 13 + sprint 14a memory 완료 후 사용자 명시: "Round 83 변환 우선 (더 수정 후 한 번에 배포)" → sprint 14b TestFlight 1.0.0+40 배포 보류, R83 진입.

## R83 = P1 정확도/UX 신뢰 7 항목 통합

R83 backlog (`docs/round83_backlog.md`) 의 P1 7 항목을 한 라운드에 통합. 회귀 위험 낮은 항목 (低 → 中 → 高) 순서 sprint.

## Sprint 1 완료 — spec 작성 only (2026-05-15)

- 산출물: `pillarseer/docs/round83_spec.md` 신규 **595 line**
- codex audit **7 라운드** (9.40 → 9.48 → 9.68 → 9.33 → 9.78 → 9.72 → **9.91 PASS** A 9.95 / B 9.92 / C 9.82 / D 9.97)
- commit `f97e69d`
- 미배포 (M2 mandate)

## Sprint plan 10 sprint

| Sprint | 의제 | 회귀 위험 | 상태 |
|---|---|---|---|
| 1 | spec (P1 7 항목) | — | ✅ 완료 commit `f97e69d` (codex 9.91 / 595 line) |
| 2 | P1-G 사주 계산 기준 설명 페이지 | 低 | ✅ 완료 commit `0d9520d` (codex 9.96 / 624 test / 5 영역 + 15 arb key) |
| 3 | P1-F 셀럽 출생정보 신뢰도 라벨 | 低 | ✅ 완료 commit `b5e126f` (codex 9.90 / 634 test / disclaimer banner + confidence label) |
| 4 | P1-B 23시 자시 학파 입력 안내 | 中 | ✅ 완료 commit `2247742` (codex 9.90 / 646 test / _ZasiHelperBlock + 5 arb key + 학파 inline 옵션) |
| 5 | P1-E 출생 시간 모름 처리 | 中 | 대기 |
| 6 | P1-D 용신 억부/조후/격국 분리 표시 | 中 | 대기 |
| 7 | P1-A 만세력 algorithmic 깊은 fix (KASI cross-check + 절기 ±5분 + 야자시) | **高** | 대기 (사용자 추가 정성 sample ≥10 선결 mandate) |
| 8 | P1-C H1 swap rootMiddleBonus ↔ rootTraceBonus | **高** | 대기 (5행 골든 보존 algorithmic 어려움) |
| 9 | 회귀 가드 + R69 lock + 5행 골든 통합 | HIGH | 대기 |
| 10 | memory + 인수인계 + (사용자 mandate 후) TestFlight 1.0.0+40 통합 배포 | HIGH | 대기 |

## 사용자 mandate (영구)

1. M1 자율 진행
2. M2 자동 배포 X
3. M3 시뮬·에뮬 새 부팅 X
4. M4 1995-10-27 男 17시 5행 골든 16/21/17/41/4 + 일주 辛卯 보존
5. M5 한국 MZ 중학생 K-POP 팬 페르소나 (사주 도메인 어휘 OK)
6. R70 자미두수 UI hidden 보존

## Sprint 7/8 선결 조건

P1-A 만세력 algorithmic + P1-C H1 swap 은 **사용자 추가 정성 sample ≥10 선결 mandate**. 사용자가 sample 안 주면 두 sprint 는 deferred. 그 경우 sprint 6 후 바로 sprint 9 회귀 가드 진입.

## 다음 세션 trigger

- "이어서" / "체크해줘" → git pull + 본 memory read + R83 sprint 진행 상태 보고
- "Sprint 2" / "계속" → R83 sprint 2 진행 (P1-G 사주 계산 기준 페이지)
- "배포해" → R82 + R83 통합 1.0.0+40 배포 (R83 sprint 10 만 진입 시) 또는 안내 후 STOP (R83 sprint 9 회귀 가드 전이면)
- "Sample 줄게" → P1-A/C 만세력 sample 받기 sprint 시작

## 참고

- [`docs/round83_spec.md`](../../seephone/pillarseer/docs/round83_spec.md) — 595 line
- [`docs/round83_backlog.md`](../../seephone/pillarseer/docs/round83_backlog.md) — 22 항목 매핑
- [[project_pillarseer_round_82]] — R82 종결
- [[feedback_harness_pattern]]
