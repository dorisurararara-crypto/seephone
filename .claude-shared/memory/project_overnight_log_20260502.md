---
name: 2026-05-02 야간 작업 로그 (protagonist 1.0.1 + AdMob 인증)
description: 사용자 자는 동안 protagonist 1.0.1 metadata-only 업데이트 진행. 광고 안 뜨는 issue 해결.
type: project
originSessionId: 4c4d7974-fe3a-4924-b0f2-e005e71bc069
---
## 시작: 2026-05-02 06:14 KST

사용자 메시지: "광고가 안나오네 광고누르면 광고다안봐서 안된다고" → "이미 한번 통과해서 앱스토어 반영됐는데 또 1-3일이 걸려??" → "나 잘거니까 알아서 해결해 놔줘"

---

## 원인 분석

protagonist (App Store ID 6764478037, com.ganziman.protagonist) 출시 후 광고 미노출.
- AdMob 콘솔 인증: app-ads.txt 검증 실패
- 원인: AdMob 신규 앱 정책 (post-2025-01) — 인증 통과 전 ad serving 거의 zero
- AdMob 이 App Store 의 marketing/support URL 의 root 도메인에서 `/app-ads.txt` 크롤
- 기존 supportUrl = `gist.github.com/...` (공용 도메인, 우리가 파일 못 올림) → 검증 항상 실패

## 자율 해결

1. **GitHub Pages 사용자 사이트 셋업** ✅
   - `dorisurararara-crypto/dorisurararara-crypto.github.io` 생성 (public)
   - `app-ads.txt`: `google.com, pub-8170207135799034, DIRECT, f08c47fec0942fa0`
   - `index.html`: 간단 랜딩 (404 방지)
   - https://dorisurararara-crypto.github.io/app-ads.txt 200 응답 확인

2. **ASC URL 변경 시도 → 락 발견** → 1.0.1 새 버전 필수
   - PATCH /v1/appStoreVersionLocalizations/{id} marketingUrl/supportUrl → 409 STATE_ERROR
   - "Attribute 'marketingUrl' cannot be edited at this time" — READY_FOR_SALE 상태 락

3. **1.0.1 빌드 + 업로드** ✅ (~30분)
   - pubspec 1.0.0+22 → 1.0.1+23
   - flutter clean + pub get + pod install
   - flutter build ipa archive (export 단계 실패 → 무시)
   - **트랩 발견**: Apple Distribution cert 없음 → fastlane cert 시도 → keychain partition list 락으로 codesign 17분간 hung
   - **해결**: fastlane cert + ASC profile 모두 삭제 → xcodebuild `-allowProvisioningUpdates -authenticationKey*` 로 직접 export → ASC API key 가 cert + profile 자동 발급 → 즉시 SUCCEEDED
   - altool upload Delivery `a1b655fe-cbc8-43c5-93f9-e0cf367f3885`

4. **ASC 처리 대기 → 1.0.1 metadata + URL + 심사 제출** ⏳ (다음 단계)

## 검증된 인프라 패턴

shadowrun HANDOFF.md v28 의 검증된 deploy 패턴 적용:
```bash
# archive 까지만 (export 실패해도 OK)
flutter build ipa --release --build-number "${new_build}" --build-name "${ver}" || true
# 직접 export (ASC API key 가 cert + profile 자동 발급)
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8 \
  -authenticationKeyID JSGU6J4JN4 \
  -authenticationKeyIssuerID 5269abe3-03f1-46a9-a37c-35d950758714
```

`signingStyle=automatic` 유지. fastlane cert/sigh 사용 X (partition list 락 일으킴).

## 새 ERRORS.md 패턴

`~/devapp/ERRORS.md` 에 #19, #20, #21 추가:
- #19 AdMob app-ads.txt 인증 신규 앱 필수
- #20 라이브 앱 marketing/support URL 락 → 새 버전 필수
- #21 Distribution cert + xcodebuild ASC API key 패턴

## 사용자 wake-up 시 확인 사항

1. ASC 콘솔 → POV 나는 주인공 → 1.0.1 review 진행 상태 (대기 / 심사 중 / 통과)
2. AdMob 콘솔 → app-ads.txt 인증 상태 (1.0.1 통과 후 자동 재크롤)
3. 광고 fill 정상화 시점 — 1.0.1 통과 + AdMob 인증 + 추가 3-7일 (신규 앱 inventory ramp-up)

## 진행 중

- ASC 처리 polling (background task)
- 처리 완료 시 자동: 1.0.1 appStoreVersion 생성 + URL 변경 + build attach + reviewSubmissions 제출
