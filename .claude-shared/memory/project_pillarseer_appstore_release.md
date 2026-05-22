---
name: pillarseer-appstore-release
description: pillarseer 앱스토어 정식 출시 작업 — 다음 세션 작업 예정. 현재 App Store 리스팅 백지 상태. 체크리스트 + 사용자 입력 필요 항목.
metadata: 
  node_type: memory
  type: project
  originSessionId: 69637c57-c2c9-491f-94d8-6abaa0cc02e9
---

# pillarseer 앱스토어 정식 출시 — 다음 세션 작업

**사용자 mandate (2026-05-22)**: "이제 앱스토어에 올리자 다음세션에서 작업할거야."
지금까지는 TestFlight 외부 베타(ganzitester)만. 이제 **App Store 정식 심사 제출**.
"이어서" → 이 작업부터.

## 현재 ASC 상태 (2026-05-22 probe)
- App Store version `v1.0.0` 존재, state=`PREPARE_FOR_SUBMISSION` (한 번도 제출 안 됨).
- localization = en-US 만, **description 0자 / keywords 빈칸 / promotionalText 빈칸**.
- appInfo state=`PREPARE_FOR_SUBMISSION`, **appStoreAgeRating 미설정**.
- appInfo en-US: name=`Pillar Seer`, subtitle 빈칸, **privacyPolicyUrl 빈칸**.
- 즉 App Store 리스팅 = 거의 백지. 최신 빌드 1.0.0+74 는 TestFlight 에 VALID.
- ASC App ID `6768096855`, helper = `pillarseer/scripts/_helpers.rb` (API 다 됨).

## 제출 전 채워야 할 것 — 체크리스트

### A. 사용자 입력·결정 필요 (선결)
1. **개인정보처리방침 URL** — App Store 필수. 앱이 개인정보처리방침을 호스팅한 URL 이 있어야 함. (메모리 `feedback_known_issues.md` — GitHub Pages private 이슈 주의. 호스팅 위치 결정 필요.)
2. **지원(Support) URL** — 필수. 간단한 페이지나 이메일 안내 페이지.
3. **스크린샷** — 6.7"(또는 6.9") + 6.5" iPhone 필수 (iPad 미지원이면 iPhone만). 실기기/시뮬 캡처 — ⚠️ CLAUDE.md 시뮬 부팅 금지. 사용자 실기기 캡처 또는 Windows 이미지 생성 협업 필요.
4. **가격·판매 지역** — 무료/유료, 한국만/글로벌.
5. **연령 등급 설문** — 사주/운세 앱. 점술 콘텐츠 → 설문 답변 필요.
6. **App Privacy(데이터 수집 라벨)** — 앱이 수집하는 데이터 정직 신고. AdMob 있으면 광고 식별자, 알림, 생년월일 입력 등. (현 앱 AdMob 여부 확인 필요.)
7. **카테고리** — 라이프스타일 / 엔터테인먼트 등 primary/secondary.

### B. Claude 가 자동/초안 가능
- description(ko/en) 초안 — 사주 + K-pop 셀럽 + 전생 66편 등 R108 기능 반영.
- keywords(ko/en, 100자) 초안.
- promotionalText, what's new(첫 출시).
- subtitle 초안 (30자).
- ASC API 로 appStoreVersionLocalizations / appInfoLocalizations PATCH (description·keywords·name·subtitle·urls).
- 빌드 선택 (1.0.0+74 attach 또는 신규 빌드).
- 연령 등급 declaration PATCH (사용자 답 받은 뒤).
- export compliance, 제출.

### C. 제출 흐름 (다음 세션)
1. 사용자에게 A 항목 일괄 질문(AskUserQuestion) — URL·가격·지역·연령등급·카테고리.
2. description/keywords 등 초안 → 사용자 승인.
3. 스크린샷 확보 (사용자 실기기 또는 Windows 협업).
4. ASC API 로 메타데이터 PATCH + 스크린샷 업로드 + privacy + age rating.
5. 빌드 attach → App Review 제출.
6. `scripts/` 에 submit 스크립트 패턴 재활용 (betaAppReview → appStoreVersionSubmission 으로 endpoint 다름 — `POST /v1/appStoreVersionSubmissions` 또는 reviewSubmissions).

## 주의
- App Review 는 Beta Review 보다 엄격 — 사주/운세 앱 가이드라인(미신·점술 콘텐츠는 4.x), 결제 있으면 IAP 규정.
- 현 TestFlight 빌드 1.0.0+74 그대로 App Store 제출 가능 (별도 빌드 불필요할 수 있음).
- round82 version pin 트랩은 App Store 제출엔 무관(빌드 안 올리면).
