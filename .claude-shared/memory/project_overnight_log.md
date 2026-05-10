---
name: 2026-04-29 야간 작업 로그
description: 사용자 자는 동안 진행한 작업·결과·다음 할 일. 새 세션 "이어서하자" 시 이거부터 보여주기.
type: project
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 시작: 2026-04-29 02:00 KST · 마지막 갱신: 02:35 KST

진행 큐 (project_pending_work_queue.md). append-only.

---

## ✅ 완료 (2026-04-29 02:00–02:35)

### 1. 빡신 Pro 가짜 가격 제거
- `bbaksin/lib/screens/settings_screen.dart` — "월 2,900원" → "올테마팩 활성화 (베타 무료)" + 베타 안내 문구
- App Store 베타 심사 reject 위험 제거

### 2. anger / pupil Pro·구매 화면 점검
- 둘 다 Pro 시트 없는 무료 앱 — 작업 불필요 확인

### 3. bbaksin / anger Apple 빌드 처리
- 02:00 첫 재업로드 → 처리 큐 진입 안 됨 (Apple 이 build=1 중복 거부 silent fail 추정)
- 02:30 build=2 로 새 IPA 빌드 + 업로드 → 3앱 모두 UPLOAD SUCCEEDED:
  - bbaksin build 2 (Delivery `35fa1614…`)
  - anger build 2 (Delivery `166215d2…`)
  - pupil build 2 (Delivery `21e5ba7e…`) — 이미 있던 build=1 외에 추가
- ASC processing 대기 중 (~30분 후부터 VALID 가능). 다음 폴링 때 확인.

### 4. 수익 모델 결정 + 구현 (구독 X 사용자 mandate)
- codex 와 1회 호출 (무료티어): 모델 추천 받음
  - 빡신: 무료 + 광고 + 올테마팩 1회 ₩2,900 / $1.99
  - pupil: 무료 + 광고 + 광고 제거 1회 ₩1,500 / $0.99
  - anger: 무료 + 광고 + 광고 제거 1회 ₩1,500 / $0.99
  - interstitial = 결과 화면 진입, 짝수번째만 노출, banner 없음
- ASC IAP 자동 생성 ✅: 3개 IAP product, ko+en 로컬라이제이션, USA 가격
  - state: **MISSING_METADATA** (정식 출시 시 review 스크린샷 — 사용자 ASC 웹 UI 작업 필요)
- AdService wire (3앱): shadowrun 패턴 그대로
- 베타-모드 purchase_service: SharedPreferences 토글로 무료 활성화. 정식 출시 시 in_app_purchase 패키지 wire 필요

### 5. Android release 키스토어 분리
- 3앱 모두 release 가 debug 키 사용했던 것 → 각 앱별 release 키스토어 생성
- `~/.seephone/keystores/{app}-upload.jks` (chmod 600, git 외부)
- `{app}/android/key.properties` (gitignore됨)
- `{app}/android/app/build.gradle.kts` shadowrun 패턴으로 업데이트
- 키스토어 비밀번호: `~/.seephone/keystores/{app}-password.txt`

### 6. ritual fallback 버튼 (빡신)
- 5초간 흔들기 0회 시 "흔들기 안 되면 — 탭으로 진행" 버튼 fade-in
- 시뮬레이터 / 약한 센서 기기 대응
- `bbaksin/lib/screens/ritual_screen.dart`

### 7. 3앱 영어 i18n + 설정 언어 토글
- `flutter_localizations` 추가 + `l10n.yaml` + `lib/l10n/app_{ko,en}.arb` + 자동생성
- `LocaleNotifier` (Riverpod): SharedPreferences `locale_code` 키
- 설정 UI 언어 토글: Auto / 한국어 / English (3앱 모두)
- 와이어한 화면:
  - **빡신**: home, settings (테마+언어), ritual (shake/fallback), result (홈으로)
  - **pupil**: intro, scan (SCANNING), result (label/buttons), 광고 제거 시트
  - **anger**: intro, measure (shakeAndTap/instantTotal/tapCount), result (저장/공유/한 번 더), 광고 제거 시트
- **남은 i18n** (ko 그대로, 점진 추가 필요):
  - bbaksin 멘트 1000개 (assets/data/messages.json) — 별도 큰 작업 (사용자 / Windows side 편번역)
  - anger result 의 verdict 멘트 (anger_calc.dart 의 mockery 등)
  - pupil lie_detector verdict 텍스트
  - bbaksin theme widgets 의 buildShakePrompt 등 내부 hardcoded
  - share text (share_service.dart) 내부 한국어

### 8. Git commit + push
- commit `0eed0ca` "feat: 야간 작업 — i18n / 수익 모델 / Android 서명 / ritual fallback"
- 30+ 파일 변경 + 새 l10n / ad_service / purchase_service / locale_service

---

## ⏳ 진행 중 / 대기

### Apple 빌드 처리 모니터링 (Task #6/#8)
- bbaksin build=2 / anger build=2 / pupil build=2 ASC 처리 대기
- VALID 되면 → 외부 베타 그룹 ganzitester 에 자동 제출
- /loop 가 3분 폴링 → HANDOFF.md 폴링과 별도로 ASC 상태도 체크하게 됨

---

## 🚧 사용자 손이 필요한 것 (출시 전)

1. **ASC IAP review 스크린샷 업로드** (3개 IAP)
   - 각 IAP 의 결제 시 보이는 시트 스크린샷 1장
   - 자동화 불가 — ASC 웹 UI 에서 직접
2. **AdMob 콘솔 광고 단위 생성 + ID 교체**
   - 3앱 각각 interstitial + rewarded ad unit 생성
   - 받은 ID 를 `{app}/lib/services/ad_service.dart` 의 `_realInterstitialId` / `_realRewardedId` 에 붙여넣기
   - 안 하면 release 빌드에서 광고 미노출 (지금은 placeholder ID)
3. **App Store 메타데이터** (앱 설명, 키워드, 스크린샷 5장씩 = 15장)
   - ASC 웹 UI 직접 입력
4. **나머지 영어 i18n** (멘트 데이터)
   - bbaksin/assets/data/messages.json — 1000개
   - 점진 추가 OK (한국어 우선 시장)
5. **in_app_purchase 패키지 wire** (정식 출시 시점)
   - 현재 베타 모드는 SharedPreferences 토글로 무료
   - 정식 출시 직전에 in_app_purchase 패키지 추가 + 영수증 검증 wire

---

## 🔑 새 세션 시작 시 첫 액션

1. 이 파일 + `MEMORY.md` + `HANDOFF.md` 읽기
2. ASC 빌드 상태 확인: `ruby /tmp/check_all_builds.rb` 또는 `ruby {app}/scripts/check_build_status.rb`
3. 모두 VALID 면 → 외부 베타 자동 제출 (`{app}/scripts/submit_external_beta.rb 2`)
4. 사용자 "출시" 명령 대기
