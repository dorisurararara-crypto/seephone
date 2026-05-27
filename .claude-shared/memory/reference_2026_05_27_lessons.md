---
name: 2026-05-27-lessons-learned
description: "2026-05-27 R111 + Android 첫 출시 자동화 중 처음엔 \"안 됨/사용자만 가능\" 이라 했다가 실제 해결된 케이스 17개 — 다음 세션이 같은 막다른 길에서 시간 안 쓰도록."
metadata: 
  node_type: memory
  type: reference
  originSessionId: fe930e1c-972f-49dd-84ef-bee93d930133
---

# 2026-05-27 — 자동화 발견 모음

오늘 한 일: iOS R111 Apple 4.3a 거절 → 재제출 + Android 첫 출시 (Play Console).
처음엔 "이건 API X / 사용자만 가능" 이라 한 것 중 실제 자동화 가능했던 17개 케이스.

## Apple ASC (App Store Connect) API

### 1. "Version is not ready to be submitted yet" silent blocker
**Why:** `appStoreVersions.usesIdfa` 가 null 이면 ASC submit 거절 (fastlane issue #20065).
**Fix:** `PATCH /v1/appStoreVersions/{id}` body `{attributes: {usesIdfa: false}}` (광고 없는 앱) 또는 true.
**잘못된 진단:** "Apple 백그라운드 sync 대기" 라 생각해 20분 polling 무의미.

### 2. 거절된 reviewSubmission "submitted:true" → API 만 안 됨, Playwright 는 OK
**Why API 안 됨:** PATCH `submitted: true` 가 일관되게 "Version is not ready to be submitted yet, please try again later." 응답. 20분 polling 해도 동일. Apple 이 API 채널에서만 의도적 차단.
**Fix Playwright:**
ASC 로그인된 Playwright 세션에서 `/apps/{id}/distribution/reviewsubmissions/details/{subId}` 페이지의 **"심사 업데이트"** (Update Submission) 버튼 클릭 시 정상 작동. 모바일 ASC 앱 / 데스크탑 웹 / Playwright 모두 같은 endpoint 호출 — API 만 막혀 있고 UI 채널은 OK.

**다음 세션 자동화 패턴 (사용자 손 0):**
1. r111_patch_metadata.rb / r111_patch_review_notes.rb 등 메타데이터 patch 자동
2. 사용자 Playwright 에서 한 번 ASC 로그인 (2FA — 이건 진짜 사람만)
3. Playwright 로 `/reviewsubmissions/details/{subId}` 진입
4. "심사 업데이트" 버튼 자동 클릭
5. 확인 dialog → "심사 업데이트" 다시 클릭
6. state → WAITING_FOR_REVIEW

**잘못된 진단 (오늘 내 실수):** "심사 업데이트 1클릭은 사용자만 가능" 이라 결론. 실제로는 ASC 로그인 후 Playwright 가능. 단 2FA 통과 자체는 사용자 손.

### 3. Resolution Center "Reply" UI 는 resubmit 후 사라짐
**Why:** "심사 업데이트" 누른 시점에 submission state = WAITING_FOR_REVIEW → Reply UI 자동 hidden.
**Fix:** `appStoreReviewDetail.notes` 필드에 영문 응답문 paste — 리뷰어가 새 심사 시작할 때 가장 먼저 보는 채널. Reply 와 동일 효과.

### 4. "whatsNew cannot be edited at this time" (STATE_ERROR)
**Why:** version 이 REJECTED 상태에선 whatsNew patch 거절. build attach 가 선행 필수.
**Fix 순서:**
1. `PATCH /v1/appStoreVersions/{id}/relationships/build` 로 attach
2. version state 가 PREPARE_FOR_SUBMISSION 으로 전환 확인
3. 그 다음 whatsNew PATCH

**예외:** 첫 출시 1.0.0 의 whatsNew 는 Apple 이 자동으로 "First version" 으로 처리 — 비어 있어도 OK.

### 5. "Item is already present in another reviewSubmission" 충돌
**Why:** 거절된 reviewSubmission (UNRESOLVED_ISSUES) 이 version 을 계속 점유.
**Try 한 것 (전부 막힘):**
- DELETE reviewSubmission → 403 FORBIDDEN
- PATCH cancel:true → 409 "not in cancellable state"
- DELETE reviewSubmissionItem → 409 "already submitted"
- 새 reviewSubmission + appStoreVersion item 추가 → 409 "already in another submission"
**Fix:** 기존 거절된 submission 의 ID 를 그대로 사용 → PATCH `submitted: true` (위 #2 의 사용자 클릭 필수 경로). 새 submission 만들면 안 됨.

### 6. ASC 앱 이름 + 서브타이틀 = appInfoLocalizations (version 아님)
**Why:** name / subtitle 은 appInfoLocalizations 리소스. description / keywords / promotionalText 는 appStoreVersionLocalizations.
**Fix:** 두 endpoint 분리 PATCH. subtitle PATCH 를 version 에 시도하면 409 UNKNOWN_ATTRIBUTE.

### 7. ASC 카테고리 변경 = appInfos PATCH
```
PATCH /v1/appInfos/{id} {
  relationships: {
    primaryCategory: { data: { type: 'appCategories', id: 'ENTERTAINMENT' } },
    secondaryCategory: { data: { type: 'appCategories', id: 'LIFESTYLE' } }
  }
}
```
HTTP 200. appInfo state 가 REJECTED 여도 patch 자체는 가능.

## Apple Xcode / 빌드

### 8. iOS 26.5 simulator runtime 누락 후 빌드 실패
**Symptom:** "iOS 26.5 is not installed. Please download and install the platform"
**Root cause:** Xcode auto-update 후 CoreSimulator runtime 만 누락.
**Fix:** `xcodebuild -downloadPlatform iOS` (8.5 GB 다운로드, ~3분).

### 9. `flutter build ipa` export 단계 실패
**Symptom:** "No signing certificate 'iOS Distribution' found, No Accounts"
**Root cause:** flutter 의 default export 가 local cert 기대.
**Fix:** archive 단계만 flutter 로, export 은 수동 `xcodebuild -exportArchive` + ASC API key:
```
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_<KID>.p8 \
  -authenticationKeyID <KID> \
  -authenticationKeyIssuerID <IID>
```

## Google Play Console

### 10. "API 액세스 메뉴 못 찾음" → 사용자 및 권한
**Why:** Play Console UI 가 변경. API 액세스 = 좌측 메인 메뉴 **"사용자 및 권한"** > **"서비스 계정"** 탭.

### 11. 기존 서비스 계정 재활용 (앱 간)
**Why:** 한 Google 개발자 계정의 서비스 계정은 모든 앱에 권한 부여 가능. protagonist 의 `play-deploy@automakeapp.iam.gserviceaccount.com` 를 pillarseer 에도 그대로 사용.
**Fix:** Play Console > 사용자 및 권한 > 해당 서비스 계정 > 앱 권한 추가. Google Cloud 에서 새 서비스 계정 만들 필요 X.

### 12. Asset library picker Playwright 불안정 → Play API 사용
**Symptom:** "애셋 추가" → 라이브러리 popup → 업로드 → "저장" 누르면 listing 에 반영 안 됨. Material UI anti-automation.
**Fix:** Play Developer API v3 `edits().images().upload()` — 한 edit 안에 icon/featureGraphic/phoneScreenshots 다 업로드 + listing 텍스트 PATCH + commit. 40줄 Python 으로 끝.
```python
svc.edits().images().upload(
    packageName=PKG, editId=eid, language=LANG,
    imageType='icon', media_body=MediaFileUpload(path, mimetype='image/png', resumable=True)
).execute()
```
imageType: `icon`, `featureGraphic`, `phoneScreenshots`, `sevenInchScreenshots`, ...

### 13. Listing 텍스트 commit gate — 이미지 6개 필수
**Why:** 첫 출시는 commit 시 icon + featureGraphic + ≥2 phoneScreenshots 검증.
**Fix:** 한 edit 안에서 이미지 6장 업로드 + text PATCH + commit 동시. partial save 거부. 사용자 mandate "이미지부터 채우고 텍스트" 가 정답.

### 14. `inappproducts.insert` deprecated (HTTP 403)
**Symptom:** "Please migrate to the new publishing API."
**Fix:** 신규 endpoint `monetization.onetimeproducts.patch` 사용.

### 15. Monetization onetimeproducts URL 정확한 패턴
**Discovery 확인 시:**
- URL: `PATCH /androidpublisher/v3/applications/{pkg}/onetimeproducts/{productId}` **(소문자, /monetization/ 세그먼트 없음)**
- Required query: `allowMissing=true&regionsVersion.version=2022%2F02&updateMask=listings,taxAndComplianceSettings,purchaseOptions`
- `updateMask=*` 거절 → 명시 필드 나열 필수
- Body 가격은 **`units` + `nanos`** (NOT `priceMicros` — 그건 레거시 inappproducts)

**get/list/batchGet 은 camelCase:** `oneTimeProducts` (불일치 정상).

### 16. IAP 활성화 = 별도 batchUpdateStates 호출
**Symptom:** PATCH 로 만든 IAP 의 `purchaseOptions[0].state=DRAFT` (ACTIVE 아님).
**Fix:**
```
POST /androidpublisher/v3/applications/{pkg}/oneTimeProducts/{productId}/purchaseOptions:batchUpdateStates
body: {
  requests: [{
    activatePurchaseOptionRequest: {
      packageName: PKG,
      productId: SKU,
      purchaseOptionId: OPT_ID
    }
  }]
}
```
Body 의 `productId` / `latencyTolerance` 를 outer 에 넣으면 400 — 반드시 `activatePurchaseOptionRequest` 안.

### 17. iOS 시뮬 스크린샷 1320×2868 → Play 9:16 으로 center crop
**Why:** iPhone 6.9" 비율 9:19.5 = 0.46. Play 요구 9:16 = 0.5625. 너무 길쭉.
**Fix:** PIL center-crop 1320×2868 → **1320×2347** (정확히 9:16).
```python
img = Image.open(src); w, h = img.size
new_h = int(w / (9/16))
y0 = (h - new_h) // 2
img.crop((0, y0, w, y0 + new_h)).save(out)
```

### 18. 신규 개인 계정 Production track 잠금 (정책 강제)
**Symptom:** Production / Open Testing 트랙 둘 다 "프로덕션에 액세스할 수 없습니다" 잠금.
**Cause:** Google Play 2024+ 정책 — 신규 개인 계정은 **Closed testing 20명 + 14일** 후 production access 신청 가능.
**Fix:** 자동화 우회 불가. 가장 빠른 글로벌 경로:
1. Internal track (즉시) — 개발자만
2. Closed (Alpha) track promote (Play API `tracks.update` + `track='alpha'`) — 20명 모집
3. 14일 후 production access 신청 (Play Console 수동)
4. Production / Open testing 풀림

## 자동화 가능 vs 불가능 최종 정리

### Apple (자율 100%, 사용자 = ASC 2FA 로그인 한 번만)
- 빌드 + altool 업로드 + ASC build VALID 폴링
- 메타데이터 전부 (name/subtitle/desc/keywords/category/notes)
- usesIdfa / contentRights / encryption 등 silent blocker 사전 fix
- 새 build attach + whatsNew patch
- **"심사 업데이트" 클릭은 Playwright 로 자동** (ASC 로그인 후)
- 진짜 사용자 손 = Apple ID 2FA 통과 1회 (Playwright 창에서)

### Google Play (자율 ~95%)
- 서명 keystore 생성 + AAB 빌드
- Internal/Closed track 게재 (API)
- Listing 텍스트 + 이미지 6장 ko + en (API)
- 10개 정책 선언 (Playwright — Material UI 폼은 안정)
- 콘텐츠 등급 설문 + 데이터 안전 설문 (Playwright)
- IAP 생성 + 가격 + 활성화 (API)
- **사용자 액션 = Google 14일 정책 대기 (자동화 불가)**

## 다음 세션 protocol

```
사용자 "Apple/Google 출시" →
  1. iOS R111 패턴: build → meta → notes → 사용자 "심사 업데이트" 1클릭
  2. Android: AAB → API listing+images → Playwright 선언 10개 → API IAP →
     Alpha 게재 → 14일 후 Production access 신청 안내
```

**Scripts ground truth:**
- `pillarseer/scripts/r111_*.rb` — Apple
- `pillarseer/scripts/upload_play_listing.py` — Play listing
- `pillarseer/scripts/create_play_iap_v3.py` + `activate_play_iap.py` — Play IAP
- `pillarseer/scripts/promote_to_production.py` — Play track promotion (PLAY_TRACK env)
- `pillarseer/scripts/r111_download_screenshots.rb` — ASC 스크린샷 → Play 재사용
