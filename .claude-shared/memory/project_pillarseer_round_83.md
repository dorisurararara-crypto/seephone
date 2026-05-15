---
name: project_pillarseer_round_83
description: "R83 종결 + R82 통합 — TestFlight 1.0.0+40 외부 베타 ganzitester 제출 완료 (Delivery 3c17cf42 / 698 test / R84 만세력 위임)"
metadata: 
  node_type: memory
  type: project
  date: 2026-05-15
  originSessionId: f718ca1f-90b5-4e42-908d-e7fa50b20f06
---

## R83 종합 통계 (sprint 9 회귀 가드 후)

- **완료 sprint**: 1 (spec) + 2~6 (P1-G/F/B/E/D 5 fix) + 9 (회귀 가드) = 7 sprint
- **R84 위임**: sprint 7 (P1-A 만세력 algorithmic) + sprint 8 (P1-C H1 swap) — 사용자 sample ≥10 선결
- **Test 추이**: R82 종결 610 → R83 종결 **698 test** (+88 신규)
- **flutter analyze**: 0 issue
- **Codex audit 평균**: ~9.79 (peak 9.96 sprint 2, 회귀 가드 sprint 9 = 9.6 supervisor 결정)
- **5행 골든**: 1995-10-27 男 17시 16/21/17/41/4 + 일주 辛卯 보존
- **R69 lock**: 78/78/72/74/57/71 + matchCount 5/6 보존
- **자미두수 hidden**: 보존 + 별 nameKo noLeak 회귀 가드
- **R71~R82 시그니처**: 모두 보존

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
| 5 | P1-E 출생 시간 모름 처리 | 中 | ✅ 완료 commit `a66e47a` (codex 9.9 / 669 test / HOUR Opacity 0.4 흐림 + disclaimer + ziwei 차단 분기) |
| 6 | P1-D 용신 억부/조후/격국 분리 표시 | 中 | ✅ 완료 commit `eebfffc` (codex 9.93 / 688 test / 3 분리 + 신뢰도 chip 4 분기) |
| 7 | P1-A 만세력 algorithmic 깊은 fix (KASI cross-check + 절기 ±5분 + 야자시) | **高** | ⏸️ **R84 위임** (사용자 추가 정성 sample ≥10 미수령) |
| 8 | P1-C H1 swap rootMiddleBonus ↔ rootTraceBonus | **高** | ⏸️ **R84 위임** (사용자 sample 선결) |
| 9 | 회귀 가드 + R69 lock + 5행 골든 통합 | HIGH | ✅ 완료 commit `7522510` (codex 9.6 / 698 test / 10 invariant / 5행 골든 + R69 lock + R71~R83 모든 시그니처 보존) |
| 10a | memory + 인수인계 R83 종결 | HIGH | ✅ 완료 commit `7d6998f` |
| 10b | TestFlight 1.0.0+40 R82+R83 통합 배포 | HIGH | ✅ **배포 완료** commit `5500f79` (Delivery `3c17cf42` / VALID / 외부 베타 ganzitester 제출) |

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

- "이어서" / "체크해줘" → git pull + 본 memory read + ASC 1.0.0+40 처리/심사 상태 확인
- "Sample 줄게" → R84 만세력 sprint (P1-A + P1-C) 진행
- "Round 84" / "다음 라운드" → 아래 R84 우선 작업

## 🚨 R84 우선 작업 — 사용자 2026-05-15 1.0.0+40 배포 직후 추가 mandate

사용자 verbatim: "8자 깊게 푼 풀이 / 두 번 봐도 같이 잡힌 강점 안의 내용도 우리 수정한 버전의 사주 풀이로 수정해야 함"

→ R82 sprint 3/8 의 어색 어휘 일소 mandate (벼린 칼 → 단단한데 말투는 부드러운) 를 다음 영역에도 적용:

### 1. sipsin_persona 120 entry (8자 깊게 풀이)
- 파일: `assets/data/sipsin_persona.json` (R73 baseline)
- 마지막 본문 update = R73 sprint 3 + R77 sprint 4
- 한자 jargon grep 0 (R77 정리 통과)
- 그러나 R82 sprint 3 의 어색 어휘 mandate (사용자 직관 어휘로 재작성) 미적용
- R84 sprint 으로 30~60 sample 재작성 또는 120 entry 전수 audit
- 폴라리티 5:4:1 / 양면 단정 ≥30% / 행동 처방 ≥15% R73 lock 보존

### 2. 6각 "두 번 봐도 같이 잡힌 강점" 안의 본문 영역 식별
- `_MatchBadge` 자체는 라벨 + matchCount + ✨ 만 (R82 sprint 4 라벨만 정정)
- `matchedAxes` getter 는 service 에 있지만 widget 사용 grep 0
- 사용자가 본 "안의 내용" = 별도 widget 가능성 (PersonalReading / six_axis 카드 내부 / etc)
- **다음 세션 1번째 작업**: 사용자에게 정확한 영역 screenshot 또는 텍스트 받기 + 영역 식별

### 3. K-POP 멤버 + 글로벌 한류 셀럽 궁합 데이터 대폭 확장 (사용자 추가 mandate)

사용자 verbatim (2 회):
1. "현재 우리 앱에 맞게 kpop 멤버들과 궁합 보는 거 인원을 훨씬 더 늘리고 싶어. 최근 5년 안에 활동한 그룹 전부 다"
2. "훨씬 더 최근 5년 안에 활동한 그룹과 **해외에 팬덤이 많은 그룹이나 배우 가수**"

→ scope 확장: idol 만 X. **K-pop 그룹 + 솔로 + K-drama 배우 + 글로벌 한류 가수** 모두 포함.

현재: `celebrities.json` 62 entry (idol 54 + actor 5 + athlete 2 + icon 1)
목표: **370~500 entry** (6~8배 확장)

scope:
- **A. K-pop idol** ≈ 250~280 (4세대 + 3세대 활동중 + 5세대)
- **B. K-pop 솔로** ≈ 50~60 (BTS 7 / 블핑 4 / IU / TAEYEON / G-Dragon / Psy / Sunmi / CHUNG HA / Hwasa 등)
- **C. K-drama 배우 (kind=actor)** ≈ 50~60 (Squid Game / Parasite / 글로벌 A급 / 인기 신예)
- **D. 글로벌 가수/icon** ≈ 20~30 (Park Hyo-shin / Lim Young-woong / Zico / Crush 등)

빠진 그룹 (최근 5년 활동) 대표:
- 여자 4세대: TWICE / RED VELVET / MAMAMOO / (G)I-DLE / STAYC / NMIXX / KEP1ER / BABYMONSTER / ILLIT / KISS OF LIFE / fromis_9
- 남자 4세대: Stray Kids (1→8) / TREASURE / ATEEZ / RIIZE (2→7) / BOYNEXTDOOR / ZEROBASEONE / TWS / NCT WISH / P1Harmony / The Boyz / NCT DREAM / NCT 127
- BTS (3→7) / SEVENTEEN (5→13) 누락 멤버
- 5세대: MEOVV / IZNA / Hearts2Hearts

K-drama 배우 (해외 팬덤):
- A급 글로벌: Song Joong-ki / Song Hye-kyo / Gong Yoo / Park Seo-joon / Lee Min-ho / Hyun Bin / Son Ye-jin / Park Bo-gum / Kim Soo-hyun / Lee Jong-suk / Bae Suzy
- Squid Game / Parasite: Lee Jung-jae / Park Hae-soo / Wi Ha-jun / Hoyeon Jung / Choi Woo-shik / Park So-dam / Yoon Yeo-jeong
- 액션/영화: Ma Dong-seok (Don Lee) / Lee Byung-hun / Bae Doona / Kim Da-mi / Han So-hee
- MZ 인기: Park Shin-hye / Lee Sung-kyung / Kim Go-eun / Park Min-young / Kim Tae-ri / Cha Eun-woo

새 entry 필요 fields:
- kind: `idol` / `actor` / `icon` (가수+배우 겸업)
- dayPillar 자동 산출 (ManseryeokService)
- blurb 한/영 (R82 sprint 3 mandate 어색 어휘 일소 적용)
- (선택) globalTier 또는 popularityHint

작업 절차 (R84 5~10 sprint):
- Sprint A — 글로벌 인지도 list 정성 (Google Trends + Netflix Top 10 cross-check)
- Sprint B/C — K-pop idol batch (150 + 100)
- Sprint D — K-drama 배우 batch (50~60)
- Sprint E — 글로벌 가수/icon batch (20~30)
- Sprint F — dayPillar batch 계산 스크립트
- Sprint G — blurb 한/영 작성 (30~50 entry 단위 codex audit)
- Sprint H — merge + 회귀 가드

### R84 sprint 우선순위
1. 영역 식별 (사용자 confirm 후)
2. sipsin_persona 본문 audit + sample 재작성
3. 식별된 영역 본문 audit + R82 sprint 3/8 mandate 적용
4. **K-POP idol 데이터 확장 (≥250 entry, 사용자 추가 mandate)**
5. R83 deferred sprint 7/8 (P1-A 만세력 algorithmic + P1-C H1 swap, 사용자 sample ≥10 후)
6. 회귀 가드 + 1.0.0+41 배포 (사용자 mandate 후)

## 참고

- [`docs/round83_spec.md`](../../seephone/pillarseer/docs/round83_spec.md) — 595 line
- [`docs/round83_backlog.md`](../../seephone/pillarseer/docs/round83_backlog.md) — 22 항목 매핑
- [[project_pillarseer_round_82]] — R82 종결
- [[feedback_harness_pattern]]
