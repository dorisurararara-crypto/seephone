---
name: TestFlight 자동 배포 파이프라인 (Mac에서 직접 컨트롤)
description: ASC API + Xcode toolchain 으로 IPA 빌드부터 외부 베타 그룹 배포까지 사용자 손 안 거치고 자동화하는 전체 흐름.
type: reference
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 핵심 트릭: ASC API 키로 즉석 Distribution cert 발급

로컬 키체인에 "Apple Distribution" cert 가 없어도, `xcodebuild -exportArchive` 에 ASC API key 인증 플래그를 주면 Apple 이 서버에서 즉시 cert + 프로비저닝 프로파일 발급. 새 머신/새 앱 첫 배포가 한 방에 됨.

## 전체 파이프라인 (앱별 1번 setup, 그 뒤로 1줄 명령)

### 0. 사전 셋업 (앱별 1회)

1. **Bundle ID 등록** (`scripts/register_bundle_ids.rb` 패턴):
   ```ruby
   POST /v1/bundleIds {data: {type: 'bundleIds', attributes: {identifier, name (ASCII!), platform: 'IOS'}}}
   ```
   ⚠️ name 필드는 영문만 (`'분노 발전소'` 거부됨, `'Anger Power'` OK)

2. **ASC App 생성** (수동 — API 미지원, HTTP 403 FORBIDDEN_ERROR 확인됨):
   - https://appstoreconnect.apple.com/apps → "+" → 신규 앱
   - 입력: 플랫폼 iOS / 이름 (한글 OK) / 기본 언어 ko / Bundle ID 드롭다운 / SKU / 사용자 액세스
   - 생성 후 GET /v1/apps 로 App ID 자동 조회

3. **외부 베타 그룹 생성** (API 가능):
   ```ruby
   POST /v1/betaGroups {
     data: {
       type: 'betaGroups',
       attributes: { name: 'ganzitester', publicLinkEnabled: true, publicLinkLimitEnabled: false },
       relationships: { app: { data: { type: 'apps', id: APP_ID } } }
     }
   }
   ```
   응답에서 `data.attributes.publicLink` (TestFlight 가입 URL) + `data.id` (그룹 ID) 받음.

4. **각 앱 `scripts/_helpers.rb` 의 APP_ID 상수 wire** + `submit_external_beta.rb` 의 `EXTERNAL_GROUP_ID` wire.

5. **`{app}/ios/ExportOptions.plist` 생성** (shadowrun 패턴):
   ```xml
   <dict>
     <key>method</key><string>app-store</string>
     <key>destination</key><string>export</string>
     <key>teamID</key><string>Q6H9HCTK6W</string>
     <key>signingStyle</key><string>automatic</string>
     <key>stripSwiftSymbols</key><true/>
     <key>uploadSymbols</key><true/>
   </dict>
   ```

6. **각 앱 Info.plist 에 `GADApplicationIdentifier`** 추가 (없으면 google_mobile_ads SDK가 launch 시 throw → 앱 죽음).

### 1. 매번 배포 시 (3단계 자동)

#### 1-1. IPA 빌드 + 업로드
```bash
cd {app}
flutter build ipa --release  # 시그니처 단계 fail 정상 (archive 만 만들면 됨)
mkdir -p build/ios/ipa
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8 \
  -authenticationKeyID JSGU6J4JN4 \
  -authenticationKeyIssuerID 5269abe3-03f1-46a9-a37c-35d950758714
IPA=$(ls build/ios/ipa/*.ipa | head -1)
xcrun altool --upload-app --type ios -f "$IPA" --apiKey JSGU6J4JN4 --apiIssuer 5269abe3-03f1-46a9-a37c-35d950758714
```

업로드 끝나면 Apple 처리 5~20분.

#### 1-2. 처리 상태 폴링 (`scripts/check_build_status.rb`)
GET /v1/builds?filter[app]={APP_ID}&sort=-version&limit=10
- state: PROCESSING → VALID (or INVALID)
- VALID 되면 1-3 진행 가능

#### 1-3. 외부 그룹 할당 + Beta App Review 제출 (`scripts/submit_external_beta.rb`)
1. 빌드 ID 조회 (위 GET /v1/builds 응답에서 `data[0].id`)
2. POST /v1/builds/{build_id}/relationships/betaGroups
   `{ data: [{ type: 'betaGroups', id: EXTERNAL_GROUP_ID }] }`
3. POST /v1/betaAppReviewSubmissions
   `{ data: { type: 'betaAppReviewSubmissions', relationships: { build: { data: { type: 'builds', id: build_id } } } } }`

첫 빌드는 Beta App Review (24~48시간) 필요. 통과 후엔 다음 빌드들 자동 승인 (큰 변화 없으면).

## 주의사항 (트랩)
1. **Bundle ID name 한글 거부**: `ENTITY_ERROR.ATTRIBUTE.INVALID` — 영문으로.
2. **App 생성 API 막힘**: `POST /v1/apps` 는 HTTP 403 (Apple 정책, allowed: GET/UPDATE only). **수동 ASC 웹 UI 필수**.
3. **`flutter build ipa` 의 export 단계 실패는 정상**: 로컬 Distribution cert 없어서. archive 만 확보하고 `xcodebuild -exportArchive`로 별도 export.
4. **`google_mlkit_face_detection` ARM64 시뮬 미지원**: iOS sim 에서 install 실패 ("update needed"). 실기기에서만 작동.
5. **빌드 번호 충돌 방지**: shadowrun 의 `deploy_testflight.sh` 참고 — ASC 에 이미 올라간 최대 빌드 번호 +1 자동 계산.

## 사용자가 못 하게 막힌 것 (2026-04-29 시점)
- **AdMob OAuth 동의** (한 번 브라우저 클릭 필요) → 끝나면 광고 ID 자동 등록 가능
- **App Store 본 심사 (TestFlight 가 아닌)**: 한국어 메타데이터·키워드·스크린샷 사용자 결정사항. ASC API 로 메타데이터 자동 입력은 가능하지만 텍스트는 사용자가 정해야.
