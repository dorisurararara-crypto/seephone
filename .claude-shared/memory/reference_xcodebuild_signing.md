---
name: Distribution cert + xcodebuild 자동 발급 패턴 (검증)
description: flutter build ipa export 단계 우회 + xcodebuild + ASC API key 로 cert/profile 자동 발급. fastlane cert/sigh 사용 금지.
type: reference
originSessionId: 4c4d7974-fe3a-4924-b0f2-e005e71bc069
---
## 핵심 패턴

`flutter build ipa --release` 가 매 세션 첫 시도에서 "No signing certificate iOS Distribution found" 로 실패. archive 는 만들어지므로 무시하고 `xcodebuild` 로 직접 export.

```bash
# Step 1: archive 까지만 (export 실패해도 OK)
flutter build ipa --release --build-number "${new_build}" --build-name "${ver}" || true

# Step 2: 직접 export (ASC API key 로 cert/profile 자동 발급)
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8 \
  -authenticationKeyID JSGU6J4JN4 \
  -authenticationKeyIssuerID 5269abe3-03f1-46a9-a37c-35d950758714

# Step 3: altool 업로드
xcrun altool --upload-app -f build/ios/ipa/<app>.ipa -t ios \
  --apiKey JSGU6J4JN4 --apiIssuer 5269abe3-03f1-46a9-a37c-35d950758714
```

## ExportOptions.plist 형식

```xml
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>export</string>
    <key>teamID</key><string>Q6H9HCTK6W</string>
    <key>signingStyle</key><string>automatic</string>
    <key>stripSwiftSymbols</key><true/>
    <key>uploadSymbols</key><true/>
</dict>
```

## ❌ 절대 하지 말 것

**fastlane cert / sigh 사용 X**:
- fastlane 이 발급한 cert 의 private key 가 keychain partition list 락을 일으킴
- codesign 실행 시 SecurityAgent 다이얼로그가 떠 keychain 비번 요구 → CI/자율 환경에서 hung
- 매번 사용자 응답 필요 → 자율 작업 불가

**증상**: codesign 자식 프로세스가 0% CPU 로 무한 hung. `osascript` 로 확인하면 SecurityAgent 떠있음.

**복구**:
```bash
# 1. hung 프로세스 죽이기
killall SecurityAgent
pkill -9 xcodebuild codesign

# 2. fastlane 이 만든 cert + private key 삭제
security delete-certificate -c "Apple Distribution: ..." ~/Library/Keychains/login.keychain-db

# 3. ASC 서버 cert 도 삭제 (다음 xcodebuild 가 새로 발급하도록)
ruby -e "
require '...scripts/_helpers.rb'
JSON.parse(api(:get, '/v1/certificates?limit=20')[1])['data'].each do |c|
  api(:delete, \"/v1/certificates/#{c['id']}\") if c['attributes']['certificateType'].include?('DISTRIBUTION')
end
"

# 4. provisioning profile 도 ASC + local 모두 삭제
ruby -e "...api(:get, '/v1/profiles?...')..."
rm -f ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision

# 5. xcodebuild 재시도 → ASC API key 가 새로 발급
```

## 왜 xcodebuild 가 fastlane 보다 좋은가

xcodebuild 의 `-allowProvisioningUpdates -authenticationKey*` 조합은:
1. ASC API 로 새 Distribution cert 발급 요청
2. 응답받은 cert 를 keychain 에 import 하면서 partition list 자동 설정 (네이티브 Xcode 동작)
3. provisioning profile 도 자동 발급/다운로드/설치
4. 매 세션 깨끗한 상태에서 first-shot 성공

fastlane 은 단계별로 사용자 keychain 권한을 요구하므로 자율 환경에 부적합.

## 검증 출처

- shadowrun HANDOFF.md v28 (2026-04 검증)
- protagonist 1.0.1 build 23 (2026-05-02 검증) — fastlane 시도 실패 후 xcodebuild 즉시 성공
