# pillarseer Round 79 — 사주 정확도 대전환 + 화면 분리 (미배포)

> 2026-05-15 / 9 sprint harness × codex 9.94 avg / 504/504 test / 5행 골든 보존

## 핵심 한 줄
R71~R78 누적 위에 **Task A (Playwright unsin reverse 6 sample) + Task B (Community 9 키워드 + 7 page WebFetch) + Task C (calibration: H3 본문 wire + H1 swap 시도 후 revert + H4 negative + D1 audit) + Task D (/today route 화면 분리)** 추가. PersonalizationEngine 격국·용신·신살 anchor 동적화 + 사용자 mandate "내 사주 = 평생사주만" 화면 분리. **사용자 mandate 준수 sprint 9 까지 미배포 (Sprint 10 trigger 대기).**

## Sprint 결과 (9 sprint)
- Sprint 1: 가설 8개 도출 + Top 3 분기 트랙 — PASS 9.9 (A 9.8/B 10.0/C 10.0/D 9.8) — commit 8a485a3
- Sprint 2: Playwright unsin reverse 6 sample — PASS 9.93 (A 9.9/B 9.9/C 10.0/D 9.9) — commit 6ea1f70
- Sprint 3: Community/WebSearch 9 키워드 + 7 fetch — PASS 9.95 (A 9.9/B 10.0/C 10.0/D 9.9) — commit 2d692bb
- Sprint 4: 종합 calibration plan — PASS 9.97 (A 9.9/B 10.0/C 10.0/D 10.0) — commit 06de9b2
- Sprint 5: H3 본문 wire (PersonalizationEngine 격국·용신 anchor) — PASS 9.93 — commit f5bad8b
- Sprint 6: 신살 anchor + 만세력 audit docs — PASS 9.96 — commit ea14b0d
- Sprint 7: 화면 분리 /today route — PASS 9.91 — commit 45bfaa6
- Sprint 8: 새 골든 test 9 추가 — PASS 9.92 — commit ae559db
- Sprint 9: cleanup + memory + 인수인계 — (본 commit)

평균 codex score: 9.94 / 8 codex 평가 sprint

## Round 79 핵심 발견

### Task A — Playwright unsin reverse-engineer (6 sample)
- **5행 raw sum = 216 고정 base** (정규화 raw/216 × 100 = % 분포).
- 6 sample 정량 비교 — 우리 앱 vs unsin **diff 평균 13%p**.
- **일주 일치율 50%** (3 일치 / 3 불일치) — sample #2/#4/#5 일간 불일치 (Round 80 deferred fix).
- 정적/동적 측정: 평생사주 총평·성격운 정적 60갑자 anchor / 5행·십신 동적.
- **사용자 명시 5행 골든 baseline = sample #6 (1995-10-27 男 17시 酉시) → 16/21/17/41/4** (절대 보존).

### Task B — Community 9 키워드 + 7 page WebFetch
- D1~D7 dimension 도출: 만세력 정확도 / 본문 매칭률 / 학파 혼재 / 신살 NEGATIVE / 페르소나 톤 / 시간 boundary / 4기둥 derive.
- 학파 표준: 자평진전 격국용신 + 적천수 억부 + 궁통보감 조후 3 학파 종합.
- 우리 앱 가중치 (본기 > 중기 > 여기) vs 학파 표준 (본기 > 여기 > 중기) 차이 발견 — H1 swap 가설.
- H4 신살 NEGATIVE 확정 (자평진전·적천수·난강망 학파 신살 기피).

### Task C — Calibration (코드 변경)
- **H3 본문 wire** (sprint 5): PersonalizationEngine.buildFor 시그니처 보존 + SajuContext + DynamicTextResolver wire.
  - bodyKo/En 끝 격국 anchor (DynamicTextResolver.gyeokgukAnchor 8 entry).
  - actionKo/En 끝 용신 anchor (DynamicTextResolver.yongsinSuffix 5 entry).
  - cautionKo/En 끝 신살 anchor (DynamicTextResolver.shinsaAnchor 8 entry — sprint 6 신규).
- **H1 swap 시도** (sprint 5): rootMiddleBonus 0.6 ↔ rootTraceBonus 0.3 — **1995-10-27 男 17시 골든 깨짐 → revert**. Round 80 deferred.
- **H4 negative**: 신살 list 추가 작업 X (학파 기피).
- **D1 만세력 audit** (sprint 6): sample #2/#4/#5 일간 불일치 가설 A/B/C — KASI vs unsin 시차 / 야자시 학파 / 절기 boundary. **algorithmic 변경 X (5행 골든 보존 mandate)** — Round 80 deferred.

### Task D — 화면 분리 (/today route)
- 신규 `/today` GoRoute + protected list 등록 (`lib/router.dart`).
- 신규 `lib/screens/today_screen.dart` — TodayEventDetailSection + TodayDeepReadingSection 둘 다 mount.
- `_TodayEventDetailSection` (private) → `TodayEventDetailSection` (public) — result_screen 안 mount backward compat 유지.
- `_TodayDeepReadingSection` (private) → `TodayDeepReadingSection` (public).
- home `_TodayEventCard` push target `/result?anchor=today_event` → `/today`.
- 알림 deep-link redirect rule: `/result?anchor=today_event` → `/today` (router redirect).

## 변경 파일 (sprint 5-8)
- `lib/services/personalization_engine.dart` (H3 wire + 신살 anchor wire)
- `lib/services/dynamic_text_resolver.dart` (shinsaAnchor 함수 추가)
- `lib/services/manseryeok_service.dart` (H1 swap 시도 → revert)
- `lib/router.dart` (/today route + redirect)
- `lib/screens/today_screen.dart` (신규)
- `lib/screens/result_screen.dart` (public rename)
- `lib/screens/home_screen.dart` (public rename + push target)
- `test/round79_golden_test.dart` (9 골든 test 신규)
- `test/today_event_card_test.dart` (grep target 업데이트)
- `docs/round79_hypotheses.md` (가설 8개)
- `docs/unsin_analysis_v3.md` (Playwright reverse)
- `docs/saju_accuracy_research.md` (Community)
- `docs/round79_calibration_plan.md` (종합)
- `docs/round79_manseryeok_audit.md` (만세력 audit)

## 사용자 mandate 충실

### 5행 골든 보존 (절대 룰)
- 1995-10-27 男 17:00 양력 → 5행 **16/21/17/41/4** + 일주 **辛卯**.
- 모든 sprint 의 G1 골든 test PASS 검증.

### 한국 MZ K-POP 친근 해요체 톤
- 한자 jargon 본문 0 (G8 회귀 가드).
- 폐기 phrase 0 ("본인의 결" / "센터처럼" / "리텐션" / "퍼포먼스" / "PT" / "K팝 센터처럼" 등).
- 의료·금융·사망 단정 0 (양면 단정 톤).

### 사용자 mandate "내 사주 = 평생사주만"
- 신규 `/today` route 로 today section 분리.
- result_screen backward compat 유지 (회귀 가드).

### TestFlight 미배포 (Sprint 10 trigger 까지)
- 모든 commit + push 완료.
- 1.0.0+39 IPA 빌드 X / altool 업로드 X.

## NON-GOAL / Round 80 deferred
1. 만세력 algorithmic 깊은 fix (sample #2/#4/#5 일간 완전 정합).
2. D3 조후용신 wire (`yongsin_service` 계절 보정).
3. D6 시간 입력 picker UX (30분 boundary 시각화 + 야자시 학파 선택).
4. H1 가중치 swap (`rootMiddleBonus` ↔ `rootTraceBonus`) — 5행 골든 보존 algorithmic 해법 (예: 다른 sample 만 학파 표준 적용 / 조건부 swap).

## 검증
- **504/504 test PASS** (Round 78 495 + Round 79 9 신규).
- `flutter analyze`: 0 error.
- 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존 (G1).
- R71-R78 시그니처 모두 손실 X (60일주 1440 phrase / 자미두수 / 6각 radar / 십신 음양 10분류 / SajuContext + DynamicTextResolver / 알림 hh:mm picker).

## 다음 세션 트리거
새 세션 "이어서" / "체크해줘" / "다음 라운드" / "Round 80" 한 마디 →
1. git pull
2. memory R79 read (본 docs)
3. 진행 상태 보고
4. Round 80 후보: Sprint 10 (1.0.0+39 TestFlight) + Round 80 deferred 4 영역
