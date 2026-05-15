# Round 83 backlog — R82 이후 위임 항목 통합

> 작성: 2026-05-15 (R82 sprint 1 spec 확장 시점)
> 본 문서 = R83+ 후속 라운드 대기 큐. 사용자 mandate trigger 후 spec 변환.
> ground truth 항목 source: 외부 reviewer (2026-05-15 GitHub public 코드 audit) + R81 deferred + R76 / R77 / R78 deferred.

## 0. R83 입력 컨텍스트

본 backlog 는 R82 가 처리하지 않은 다음 3 source 의 통합:

1. **외부 reviewer 의 P1 / P2 항목** (2026-05-15 audit, GitHub public 코드 기준)
2. **R81 deferred** (만세력 영역 D1 KASI cross-check / D3 시간 picker UX / D4 H1 swap — R80 sprint 7 audit 에서 R81 로 위임된 항목 = 동일 D1/D3/D4. R82 우선 trigger 로 R81 sprint 1 직후 중단.)
3. **R76 / R77 / R78 deferred** (paywall 28 ARB / hotspot H3 / H6 / H8 / H13 / H14 / polarity 캐릭터 영역 / 자미두수 노출 옵션)

> R80 의 "deferred D1/D3/D4" 표현은 R80 sprint 7 audit 의 "R81 위임 audit" 결과 = R81 deferred 와 동일 항목을 가리킴. 본 backlog 는 R81 deferred 로 통일 명칭 사용.

R82 는 사용자 verbatim 9문제 + 외부 reviewer 작은 fix 4개 (Gender.other / 오행 라벨 / Profile reset / version 하드코딩) 에 집중. 나머지는 본 backlog.

## 0.1 외부 reviewer P0 / P1 / P2 전체 흡수·위임 매핑 (누락 0 증빙)

본 표는 외부 reviewer (2026-05-15 GitHub public 코드 audit) 의 P0 8 / P1 8 / P2 6 항목 = 총 22 항목 모두에 대한 R82 흡수 또는 R83 위임 매핑. 누락 0 증빙.

### P0 (출시 전 반드시) — 8 항목

| reviewer P0 # | 항목 | R82 흡수 sprint | R83 위임 항목 | 비고 |
|---|---|---|---|---|
| P0 #1 | Unsin/KASI 기준 확정 | (R81 sprint 1 측정 결과 = Unsin 100% 일치 — `docs/round82_spec.md` § 6 명시) | P1-A 후속 | R81 deferred D1 후속 + R83 P1-A 추적 |
| P0 #2 | 일주 불일치 샘플 3개 해결 | (동상 — R81 측정 + R82 spec 명시) | P1-A 후속 | R79 sprint 2 의 #2/#4/#5 sample R81 D1 위임 |
| P0 #3 | 글로벌 출생지/timezone 처리 | (R82 NON-GOAL #12 영문 i18n 새 콘텐츠 X) | P3-A | Co-Star 글로벌 진출 단계 trigger 후만 |
| P0 #4 | 23시 자시 학파 입력 화면 노출 | (R82 NON-GOAL #5 만세력 algorithmic 깊은 fix) | P1-B | R81 deferred D3 동일 |
| P0 #5 | ResultScreen 의 Today 섹션 제거 | R82 sprint 2 (✅ 흡수) | — | 본 spec #4 와 정확 일치 |
| P0 #6 | Gender.other 계산 문제 | R82 sprint 9 (✅ 흡수) | — | R82 신규 sprint |
| P0 #7 | 오행 퍼센트 설명 수정 | R82 sprint 10 (✅ 흡수) | — | R82 신규 sprint |
| P0 #8 | 결제/구독 시스템 정리 | (R82 NON-GOAL #2 새 기능 X) | P3-C | paywall 28 ARB R77 deferred 동시 활성 |

### P1 (품질 크게 올라가는 개선) — 8 항목

| reviewer P1 # | 항목 | R82 흡수 sprint | R83 위임 항목 | 비고 |
|---|---|---|---|---|
| P1 #1 | ResultScreen 정보 구조 축소 | R82 sprint 7 (✅ 흡수) | — | 본 spec #1 와 정확 일치 |
| P1 #2 | BottomNav 라벨 변경 | — | P2-A | 한자 glyph 보조 장식 |
| P1 #3 | Home 단순화 (오늘 행동 중심) | — | P2-B | first-fold 7 영역 순서 |
| P1 #4 | 용신 억부/조후/격국 분리 설명 | — | P1-D | R80 D2 조후용신 wire 완료 후 UI 분리 |
| P1 #5 | 데일리 운세 Phase 2 | — | P4-D | 12지 충/합/형/파/해 + 절기 + 시간대 |
| P1 #6 | 모든 문구 l10n 정리 | — | P3-B | 에러 / 스낵바 / placeholder / helper text 전체 |
| P1 #7 | Profile reset confirm | R82 sprint 11 (✅ 흡수) | — | R82 신규 sprint (Settings delete-all 모달 패턴 일관) |
| P1 #8 | version 하드코딩 제거 | R82 sprint 12 (✅ 흡수) | — | R82 신규 sprint (package_info_plus) |

> reviewer TOP 15 #7 (지장간 가중치 본기 > 중기 > 여기 vs 본기 > 여기 > 중기) 는 외부의 P1 분류 밖 TOP 15 별도 항목 — R81 deferred D4 + 본 R83 P1-C 로 위임.

### P2 (있으면 좋은 개선) — 6 항목

| reviewer P2 # | 항목 | R82 흡수 sprint | R83 위임 항목 | 비고 |
|---|---|---|---|---|
| P2 #1 | K-pop 케미 고도화 | — | P2-E | Reports IA 의 K-pop 케미 vs 사주 정확도 진입 순서 |
| P2 #2 | 셀럽 출생정보 신뢰도 표시 | — | P1-F | celebrities.json + "출생시간 미상 기준" 라벨 |
| P2 #3 | 공유 카드 템플릿 다양화 | — | P2-D | 1080×1080 1종 → 3~5 종 |
| P2 #4 | 접근성 개선 | — | P6-B | 기능 라벨 ≥13~16px + WCAG AA |
| P2 #5 | 리포트 paywall 미리보기 | — | P3-C | paywall 28 ARB 활성 동시 |
| P2 #6 | 앱 내 "사주 계산 기준" 설명 페이지 | — | P1-G | 진태양시 / 자시 학파 / 절기 / 음력 / 도시 경도 명시 |

### 매핑 요약
- 외부 reviewer 전체 22 항목 매핑 100% 누락 0.
- R82 흡수 = 6 항목 (P0 #5 / P0 #6 / P0 #7 / P1 #1 / P1 #7 / P1 #8).
- R83 위임 = 16 항목 (P1-A~G / P2-A~E / P3-A~D / P4-D / P6-B).

## 1. 우선순위 분류

### P1 — 정확도 / UX 신뢰

| # | 항목 | source | 추정 위치 | 비고 |
|---|---|---|---|---|
| P1-A | 만세력 algorithmic 깊은 fix | R81 deferred D1 + 외부 P0 #1·#2 | `solar_term_service.dart` 입추 / 입춘 / 동지 ±5분 + `manseryeok_service.dart` 야자시 / 조자시 학파 boundary | 5행 골든 보존 mandate. 사용자 추가 정성 sample ≥10 선결. |
| P1-B | 23시 자시 학파 입력 안내 | R81 deferred D3 + 외부 P0 #4 | `input_screen.dart` 23h helper text + 30분 boundary 시각화 | widget 큰 변경 회귀 위험. |
| P1-C | H1 swap rootMiddleBonus ↔ rootTraceBonus | R81 deferred D4 (+ 외부 reviewer TOP 15 #7 "지장간 가중치 순서" 동일 권고) | `manseryeok_service.dart:22~34` | 5행 골든 보존 algorithmic 어려움. 두 모드 분리 (weightProfile: appCalibrated / traditionalHiddenStem) 후 sample 비교. 외부 reviewer P1 #7 (Profile reset confirm) 와는 다른 항목 — R82 sprint 11 에서 흡수. |
| P1-D | 용신 억부/조후/격국 분리 표시 | 외부 P1 #4 | `result_screen.dart` 용신 카드 영역 + `yongsin_service.dart` | 사용자 신뢰도 라벨 — "강한 확신" / "두 줄기가 함께 보이는 복합 사주" 같이 평이한 표현 (한자 jargon 회피, "기운" / "결" 금지어 사용 0). |
| P1-E | 출생 시간 모름 처리 | 외부 P0 #4 + 추가 권고 | `input_screen.dart` 시간 입력 영역 + `saju_result.dart` 시주 표시 영역 | "시주 미포함 결과" 라벨 + 대운/성향 중 시간 영향 큰 부분 흐리게 |
| P1-F | 셀럽 출생정보 신뢰도 표시 | 외부 P2 #2 | `discover_screen.dart` celebrities.json 카드 영역 | "출생시간 미상 기준, 공개 생일 기반의 가벼운 비교" 라벨 |
| P1-G | "사주 계산 기준" 설명 페이지 | 외부 P2 추가 | `settings_screen.dart` 내 설명 페이지 신규 + `info_screen.dart` | 진태양시 / 자시 학파 / 절기 / 음력 / 도시 경도 명시 → 사용자 신뢰도 transparency |

### P2 — UX / IA

| # | 항목 | source | 추정 위치 | 비고 |
|---|---|---|---|---|
| P2-A | BottomNav 라벨 변경 | 외부 P1 #2 | `bottom_nav.dart` + arb | Home/Reading/Reports/Profile → 오늘/내 사주/리포트/프로필 (한국어) + Today/My Chart/Reports/Me (영문). 한자 glyph 는 보조 장식. |
| P2-B | Home 단순화 (오늘 행동 중심) | 외부 P1 #3 | `home_screen.dart` | 오늘 한 줄 / 점수 / 행동 1개 / 피해야 할 것 1개 / 시간대 흐름 / 더 보기 — 순서 정리 |
| P2-C | 2026 신년운세 → 올해운 / Yearly Flow | 외부 P1 #12 | `reports_screen.dart` + `new_year_2026_screen.dart` + arb | 시즌감 떨어진 라벨 갱신 + 7월 이후 "하반기 운세" 라벨 옵션 |
| P2-D | Profile 공유 카드 템플릿 다양화 | 외부 P2 #3 | `profile_screen.dart` 공유 카드 widget | 현재 1080×1080 1종 → 3~5 종 (K-pop 팬덤 바이럴 친화) |
| P2-E | Reports 의 K-pop 케미 vs 사주 정확도 진입 순서 | 외부 P2 #1 + reports IA | `reports_screen.dart` 카드 배치 | 처음 사용자 = 내 사주 정확도 → 오늘운 → K-pop 케미. 재방문 사용자 = K-pop 케미 추천 우선 |

### P3 — 글로벌 / 결제

| # | 항목 | source | 추정 위치 | 비고 |
|---|---|---|---|---|
| P3-A | 글로벌 출생지/timezone 처리 | 외부 P0 #3 | `input_screen.dart` 출생지 영역 + `manseryeok_service.dart` 도시 경도 + IANA timezone + DST | Co-Star 글로벌 진출 단계 trigger 후만. 한국 mandate 단계 X. |
| P3-B | 모든 문구 l10n 정리 | 외부 P1 #6 | `lib/l10n/app_*.arb` + arb 누락 사용자 노출 grep | 에러 / 스낵바 / placeholder / helper text / 버튼 / 리포트 제목 전체 |
| P3-C | 결제 / 구독 / RevenueCat 구현 | 외부 P0 #8 + R77 deferred | `pubspec.yaml` deps + paywall flow + entitlement + purchase restore + refund-safe | paywall 28 ARB R77 deferred 동시 활성 + compat/datePick 77 ARB |
| P3-D | 영문 i18n 새 콘텐츠 작성 | R73 회귀 가드 외 deferred | `lib/l10n/app_en*.arb` + saju_deep_slice en 본문 | Co-Star 글로벌 진출 단계 trigger 후만 |

### P4 — 콘텐츠 / 본문 정밀도

| # | 항목 | source | 추정 위치 | 비고 |
|---|---|---|---|---|
| P4-A | polarity 캐릭터 영역 정정 | R78 deferred | `life_stage_pool.json` / `sipsin_persona.json` / `additional_life_pool.json` / `career_pool.json` / `wealth_detail.json` | R72~R77 baseline 영역, hedge 98 / ai-slop 5 / 흉 39% / 길 26% 정리 |
| P4-B | R78 hotspot H3 / H6 / H8 / H13 / H14 algorithmic fix | R78 sprint 5 deferred | SajuContext + DynamicTextResolver 4단계 chain 의 완전 활용 영역 | personalization_engine deprecation / 자미두수 hidden / notification_pool adult / career_recommend fallback / sipsin_persona fallback |
| P4-C | saju_deep_slice 잔여 210 entry 본문 재작성 | R82 sprint 8 multi-sprint | `saju_deep_slice_*.json` | R82 sprint 8 의 30 entry sample 처리 후 잔여 210 entry |
| P4-D | 데일리 운세 Phase 2 | 외부 P1 #5 + R76 baseline | `daily_service.dart` + `today_event_service.dart` | 12지 충/합/형/파/해 + 세운/월운/일진 중첩 + 신살 우선순위 + 절기 |

### P5 — 코드 품질

| # | 항목 | source | 추정 위치 | 비고 |
|---|---|---|---|---|
| P5-A | dart format 전체 적용 + 큰 위젯 파일 분리 | 외부 P1 추가 | `lib/` 전체 | result_screen.dart 4290 line → 위젯별 file 분리 |
| P5-B | SajuProvider 영속 저장 정책 결정 | 외부 P1 추가 | `saju_provider.dart` + `shared_preferences` 또는 encrypted storage | 의도 = 저장 X 또는 opt-in 저장 결정. 사용자 mandate 필요 |
| P5-C | SixAxisScore 타입 강화 | 외부 P1 추가 | `models/saju_result.dart` SixAxisScore | Map<String, int> → enum key 기반 |
| P5-D | DailyService DateTime.now() clock provider 주입 | 외부 P1 추가 | `daily_service.dart` | 테스트 reproducibility |

### P6 — 디자인 / 톤

| # | 항목 | source | 추정 위치 | 비고 |
|---|---|---|---|---|
| P6-A | README / DESIGN docs 톤 동기화 | 외부 P1 #13 | `README.md` + `docs/DESIGN_*.md` | 초기 다크 / 보라 / 별 → 현재 Aesop 톤 (크림 / 잉크 / 골드) 으로 docs 정정 |
| P6-B | 접근성 (글자 크기 / 대비) 검토 | 외부 P2 #4 | `lib/theme/` + 작은 라벨 영역 전체 | 장식 라벨 작음 OK, 기능 라벨 ≥13~16px / WCAG AA 대비 |
| P6-C | Reports / K-pop 케미 화면 accent | 외부 P1 #13 추가 | `reports/kpop_compat_screen.dart` | 기본 Aesop 톤 유지 + K-pop 영역 만 accent 강화 (사용자 mandate 후만) |

## 2. R83 trigger 후 spec 변환 순서 (권고)

새 라운드 spec 변환 시 다음 순서 권고:

1. P1 (정확도 / UX 신뢰) — 사용자 felt 직결 → 최우선
2. P4 (콘텐츠 본문 정밀도) — 외부 reviewer 평가 직결
3. P5 (코드 품질) — 개발자 audit 영역
4. P2 (UX / IA) — UX 보강
5. P3 (글로벌 / 결제) — 한국 mandate 단계 후만
6. P6 (디자인 / 톤) — sustaining

## 3. R83 trigger 신호 (사용자)

새 세션에서 사용자 한 마디:

- "Round 83 시작" / "다음 라운드" → 본 backlog 의 P1~P6 중 사용자 mandate 항목 spec 변환
- "정확도 fix" / "만세력 audit" → P1-A / P1-B / P1-C / P1-D / P1-E 우선
- "글로벌 / 영어 / Co-Star" → P3-A / P3-D 단계 진입 (한국 mandate 종결 confirm 후만)
- "결제 / paywall" → P3-C 우선

## 4. R82 와의 분리 mandate

본 backlog 의 모든 항목은 R82 와 동시 진행 X. R82 sprint 14 (memory + 인수인계 + 배포) 종결 후 사용자가 별도 trigger 시에만 R83+ 로 라운드 시작.

- M2 자동 배포 X mandate 영구 — R83 도 사용자 명시 후만 배포.
- M3 시뮬·에뮬 새 부팅 X 영구.
- M4 5행 골든 보존 영구 — R83 의 P1 algorithmic fix 도 골든 보존 조건부.
- M5 한국 MZ 페르소나 영구 — P3 글로벌 단계는 별도 mandate trigger 후만.

## 5. 참고

- 외부 reviewer audit 보고서 (2026-05-15) — 본 backlog 의 1차 source
- `docs/round82_spec.md` § 6 외부 review 보고서 대응 노트 — R82 흡수 / 위임 매핑
- `pillarseer/인수인계.md` — 다음 세션 trigger 진입점
- R80 memory: `project_pillarseer_round_80.md`
- R81 sprint 1 spec: `docs/round81_spec.md`
