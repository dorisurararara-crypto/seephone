# Pillar Seer — App Store / TestFlight Review Checklist

Last updated: 2026-05-12 (Round 9)

## Build Pipeline Sanity
- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test` → all green (41+ tests including KASI 20-celeb regression)
- [ ] `flutter build ipa --release` succeeds (xcodebuild fallback wired)
- [ ] `altool upload` returns UPLOAD SUCCEEDED + BUILD-STATUS VALID + IMPORT-STATUS VALID

## Required Metadata (App Store production)
- [x] App name `Pillar Seer` (under 30 chars)
- [x] Subtitle: `Korean Saju, made easy for Gen Z` / `정통 사주, 누구나 쉽게`
- [x] Primary category: Lifestyle
- [x] Secondary category: Entertainment
- [x] Keywords (100 chars): 사주,운세,오늘의운세,신년운세,궁합,연애운,일일운세,무료운세,생년월일운세,오행,십신,대운,세운,타로,점성술
- [x] Description (ko/en) ready in `app_store_metadata.md`
- [x] Privacy policy URL: https://dorisurararara-crypto.github.io/pillarseer/privacy.html
- [x] Terms URL: https://dorisurararara-crypto.github.io/pillarseer/terms.html
- [x] Support URL: https://dorisurararara-crypto.github.io/pillarseer/support.html
- [x] Marketing URL: (optional — same as support)
- [x] Copyright: dorisurararara 2026
- [x] Age rating: 4+ (no IAP, no ads, no objectionable content)
- [ ] Screenshots (5+ per device size) — 6.7" / 6.5" / 5.5" required, iPad optional
- [ ] App icon production set (1024×1024 + iOS sizes already in assets/icon/)
- [x] App Privacy questionnaire: NO data collected
- [x] In-app purchases: NONE (no IAP, no subscriptions)

## Review Risk Audit (codex 권고)
- [x] **Hidden dev unlock gate** — release build 에서 `kDevGateEnabled=false`, `_load()` 가 잔존 prefs 도 강제 false 로 초기화 (Round 9 fix)
- [x] **알림 시간대** — `flutter_timezone.getLocalTimezone()` 으로 tz.local 설정. 8AM = 실제 디바이스 local 8AM (Round 8 fix)
- [x] **30일 pre-schedule** — `matchDateTimeComponents.time` 반복 사용 X. 매일 다른 NotificationPool 문구 30개 미리 예약 (Round 7 fix)
- [x] **Privacy/Terms/Support 링크** — url_launcher 실제 외부 브라우저 이동 + 실패 시 clipboard copy + snackbar fallback (Round 8+9)
- [x] **데이터 삭제 작동** — Settings → Delete all → SharedPreferences.clear + NotificationService.cancelDaily + provider invalidate + /input redirect (Round 6)
- [ ] **출생지 timezone 보정** — 현재 진태양시 -32분 서울 고정. 해외 사용자 미보정 (v1.1 후속)

## Known-date 정확도 회귀 테스트 (KASI 표준)
20명 celebrities.json 일주가 KASI klc 패키지와 100% 일치 (Round 7 fix). `test/integration_flow_test.dart` 가 회귀 보호.

| 이름 | 생일 | 일주 (KASI) |
|---|---|---|
| IU | 1993-05-16 | 丁卯 Fire Rabbit |
| BTS V | 1995-12-30 | 乙未 Wood Goat |
| Yuna Kim | 1990-09-05 | 癸酉 Water Rooster |
| Son Heung-min | 1992-07-08 | 乙酉 Wood Rooster |
| ... (20명 전체) | | |

## TestFlight 외부 베타 review submission flow
1. `bash scripts/deploy_testflight.sh <next_build_number>` → ASC upload
2. 5-20분 후 build VALID 확인: `ruby scripts/check_build_status.rb`
3. **알려진 막힘**: Build #3가 review 큐 점유 중. ASC API DELETE 403 FORBIDDEN — 수동 cancel 필요.
   - `appstoreconnect.apple.com` → Apps → Pillar Seer → TestFlight → Build #3 → Cancel Review
   - 그 후 `ruby scripts/submit_external_beta.rb <build>` 자동 제출

## App Store Connect Production Submission
1. ASC 콘솔에서 "+ Version" → 1.0.0 (Build #N 선택)
2. `app_store_metadata.md` 에서 description / keywords / subtitle 복사
3. Age Rating questionnaire 작성 (4+ 무 violence/sex/etc)
4. App Review Information:
   - Demo account: 없음 (로그인 X)
   - Review notes (예시):
     ```
     This is a free Korean Four Pillars (saju) reading app. No in-app purchases, no ads, no login.
     Reading is calculated locally using KASI (Korea Astronomy and Space Science Institute) manseryeok data.
     No external network calls. All data stored on device only.
     ```
5. Privacy Policy URL · Support URL · Marketing URL 입력
6. Screenshots upload
7. Submit for Review
8. (옵션) "Manually release this version" 선택 시 사용자가 게시 시점 결정

## codex 평가 변화 (10점 만점)
| Round | 점수 | 핵심 변화 |
|---|---|---|
| 1 (초기) | 4.6 | shadowrun fork 기본 |
| 2 (친근화) | 6.8 | 일간→당신의 본성, glow UP, easy mode banner |
| 3 (hourly+Pro+trust) | 8.5 | 시간대별 흐름, Pro hook, splash 단축 |
| 4 (만세력+카테고리+5행/십신) | 8.6 | KASI 통합, 데일리 리텐션 |
| 5+6 (Streak+Basis+Share+Notif Pool+Personalization) | 7.8 | 1등 baseline (codex 기준 raised) |
| 7 (critical bug fixes) | 8.1 | 토큰 치환, atom 14, chart hash, notif pre-schedule, celeb 20명 KASI |
| 8 (production hardening) | 8.7 | tz.local, dev gate release-safe, url_launcher |
| 9 (release safety) | TBD | dev gate persistence 차단, URL fallback snackbar |

## 9.5+ 가려면 후속 (사용자 mandate 외)
- [ ] Real paywall connected (RevenueCat + StoreKit + 구매 복원)
- [ ] Free/Pro UX 경계 명확
- [ ] Birth city timezone 자동 보정
- [ ] iOS WidgetKit (Today's Energy small/medium widget)
- [ ] Apple Watch complication
- [ ] Siri Shortcuts ("오늘의 운세")
- [ ] iCloud sync + multi-profile

## 실기기 QA 우선순위 (시뮬에서 catch 못함)
- [ ] iOS notification 실 권한 허용/거부/iOS Settings 유도
- [ ] DST/자정 경계 알림 fire
- [ ] Release build dev gate 실제 차단 검증
- [ ] Cold start 저장 상태 복원
- [ ] Korean font 렌더링 (한자 + 한글 + emoji)
