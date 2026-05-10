---
name: seephone 알려진 이슈·트랩
description: 작업 중 발견한 함정·제약. 같은 실수 반복 방지용.
type: feedback
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## ML Kit ARM64 시뮬레이터 미지원
- `google_mlkit_face_detection` 플러그인이 iOS 시뮬레이터 (Apple Silicon) 에 install 실패
- 에러: "Failed to find matching arch for input file" + "‘앱이름’의 업데이트가 필요함"
- **빌드는 성공** (warning + IPA 생성 OK), 시뮬에 install 만 안 됨
- 실기기에서는 정상 작동

**Why:** ML Kit 의 `MLKitFaceDetection` 코코아팟 의존성이 arm64 simulator slice 미포함.

**How to apply:** 시뮬 테스트 불가능한 거 인지 + 실기기 / TestFlight 로만 검증. 빌드 자체는 막지 말 것.

---

## ASC API 가 App 생성 거부
- `POST /v1/apps` → HTTP 403 `FORBIDDEN_ERROR` — `"The resource 'apps' does not allow 'CREATE'"`
- 허용: `GET_COLLECTION`, `GET_INSTANCE`, `UPDATE`

**Why:** Apple 정책 — 신규 앱 등록은 ASC 웹 UI 만 가능.

**How to apply:** Bundle ID 까지는 API 자동 등록 → ASC App 등록은 사용자에게 위임 → App ID 받으면 그 뒤 모든 메타데이터·빌드·심사 자동화 가능.

---

## Bundle ID name 한글 거부
- `POST /v1/bundleIds` 의 `attributes.name` 에 한글 + 공백 넣으면 HTTP 409 `ENTITY_ERROR.ATTRIBUTE.INVALID`

**Why:** Apple 의 bundleId name 검증이 ASCII 만 통과시킴.

**How to apply:** 한국어 앱이라도 bundle ID name 은 영문 (`'Bbaksin'`, `'Pupil Detector'`, `'Anger Power'`).

---

## GitHub Pages private repo 미지원
- `gh api POST /repos/.../pages` → HTTP 422 `"Your current plan does not support GitHub Pages for this repository."`
- private repo 에서 Pages 쓰려면 GitHub Pro/Team/Enterprise 필요

**Why:** 사용자 plan 이 free.

**How to apply:** 공개 자료 (개인정보 처리방침, 약관 등) 는 **`gh gist create --public`** 으로 우회. 개인 repo 에 둘 필요 없음.

예: 개인정보 처리방침 → gist URL `https://gist.github.com/dorisurararara-crypto/1939b5ec8fb8f54693ac8f72345ca53f`.

---

## Flutter `flutter build ipa` 의 export 단계 fail 정상
- "No signing certificate 'iOS Distribution' found" 에러
- 로컬 키체인에 Distribution cert 없을 때 발생

**Why:** Flutter 의 내부 export 는 단순 xcodebuild 호출, ASC API key 없음.

**How to apply:** archive 만 확보하면 OK. 별도 `xcodebuild -exportArchive` + `-allowProvisioningUpdates -authenticationKeyPath ... -authenticationKeyID ... -authenticationKeyIssuerID ...` 로 export. Apple 이 즉석 cert 발급.

---

## CLIP 77 토큰 한계 (이미지 생성)
- SDXL 등 CLIP-based 이미지 모델은 prompt 77 토큰까지만 인식
- 긴 prompt 의 끝부분 (특히 "central blank for text" 같은 중요 지시) 잘려서 무시됨
- 한국 부적 batch_001 8장 중 6장이 이 이슈로 실패

**Why:** CLIP encoder 길이 제약.

**How to apply:** 짧고 핵심 키워드 우선 배치. "Korean traditional" 같은 무거운 지시는 빼고 재료/색감/구도만. 검증: SDXL + 60 토큰 안 = 적중률 75%.

---

## SDXL 의 "Korean → 중국풍" 해석
- "Korean traditional talisman" 프롬프트가 중국 만다라/관운장풍 으로 빠짐
- LoRA 없이 한국 도깨비 표현 불가능 (HF 에 Korean LoRA 사실상 없음)

**Why:** SDXL 학습 데이터 셋이 generic East Asian 으로 묶여있음.

**How to apply:**
1. "korean" 키워드 빼고 generic 어휘 (`"red ornamental paper"`)
2. 도깨비 → "yokai / chibi / kawaii ogre mascot" (일본어 → 동양 만화풍 안전 도착)
3. 진짜 한국 부적 톤 필요하면 Mac 측에서 직접 디자인 → AI 는 이펙트/캐릭터만 담당

---

## google_mobile_ads SDK 초기화 누락 시 crash
- `Info.plist` 에 `GADApplicationIdentifier` 없으면 launch 시 throw `GADInvalidInitializationException`
- 앱이 즉시 종료됨

**How to apply:** 새 Flutter 앱에 `google_mobile_ads` 추가 시 반드시:
- iOS: `Info.plist` 에 `GADApplicationIdentifier` 키 + `SKAdNetworkItems` 배열 추가
- Android: `AndroidManifest.xml` 의 `<application>` 안에 `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" .../>` 추가

진짜 ID 없으면 Google 공식 테스트 ID 사용:
- iOS: `ca-app-pub-3940256099942544~1458002511`
- Android: `ca-app-pub-3940256099942544~3347511713`

---

## zsh `status` 변수 readonly
- bash/zsh 차이: `status=$(...)` 가 zsh 에선 `read-only variable: status` 에러
- 폴링 스크립트에서 hit 됨

**How to apply:** 변수명 `s` / `state` 등 다른 이름 사용.

---

## HealthKit (또는 새 capability) 추가 시 deploy 흐름 변경 필요
- `flutter build ipa` 가 archive 만들 때 ASC API key 를 못 받아서, ASC App ID 에
  capability 새로 추가하면 provisioning profile 갱신을 못 해 archive 단계에서 fail.
- 증상:
  ```
  Error (Xcode): No Accounts: Add a new account in Accounts settings.
  Provisioning profile doesn't include the X capability.
  ```

**Why:** Flutter 내부 xcodebuild archive 호출이 `-allowProvisioningUpdates -authenticationKey*` 를 안 붙임. 키체인의 Apple ID 도 없어 자동 발급 불가.

**How to apply:** deploy_testflight.sh 의 `flutter build ipa` 부분을 다음으로 교체:
```bash
flutter build ios --release --no-codesign --build-number "${new_build}" --build-name "${ver}"
xcodebuild archive \
  -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination "generic/platform=iOS" -archivePath build/ios/archive/Runner.xcarchive \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8" \
  -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER_ID" \
  FLUTTER_BUILD_NAME="${ver}" FLUTTER_BUILD_NUMBER="${new_build}"
```

추가로:
- entitlements 파일 만들고 `project.pbxproj` 의 Runner target 3 build configurations (Debug/Release/Profile) 에 `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` 추가 (sed 가능)
- App ID capability 는 ASC REST API (`POST /v1/bundleIdCapabilities`) 로 자동 추가
- `com.apple.developer.healthkit.access` (Verifiable Health Records) 키는 Apple 별도 승인 필요 → 일반 HealthKit 만 쓰면 빼야 archive 통과

pupil 2026-04-30 build 8 에서 hit & 해결.

---

## pupil/anger 의 deploy_testflight.sh 경로 버그 (`scripts/asc/`)
- pupil 등 신규 앱의 `deploy_testflight.sh` 가 `${SCRIPT_DIR}/asc/check_build_status.rb` 호출
- 실제 .rb 파일은 `scripts/` 직속 (asc 서브폴더 X) → `set -euo pipefail` 로 첫 줄에서 silent exit
- 증상: 스크립트가 30초 만에 exit 0, pubspec 도 안 바뀜, 아무것도 안 일어난 듯 보임

**Why:** shadowrun 의 `scripts/asc/` 구조에서 복사하면서 경로 안 고침.

**How to apply:** 신규 앱마다 `deploy_testflight.sh` 의 `${SCRIPT_DIR}/asc/` → `${SCRIPT_DIR}/` 로 sed 치환:
`sed -i '' 's|${SCRIPT_DIR}/asc/|${SCRIPT_DIR}/|g' scripts/deploy_testflight.sh`

pupil 은 2026-04-30 수정 완료. anger/bbaksin 도 같은 패턴이면 미리 점검.
