---
name: zero-gate factory 실제 검증 결과 + 신규 앱 부팅 절차
description: 사용자 손 0회로 아이디어→IPA upload 까지 자동. 첫 검증 50분(셋업+시행착오), 두 번째 6분. cookie 30일 재사용.
type: reference
originSessionId: 57bec09c-255a-4306-954d-87a055d0688c
---
2026-04-29 zero-gate factory 두 번 연속 검증 성공.

## 검증 기록

| 앱 | 시간 | 사용자 손 |
|---|---|---|
| **protagonist** (POV 나는 주인공) | 11:36–12:24 = 50분 (Fastlane 설치·spaceauth·시행착오 포함) | spaceauth 1회 |
| **memereport** (급식실 속보) | 12:54–13:00 = **6분** | **0회** |

⇒ 두 번째 앱부터는 **N개 만들어도 사용자 손 0회**, ~6분 사이클.
⇒ spaceauth cookie (`~/.fastlane/spaceship/{apple_id}/cookie`) 30일 유효 → 30일 안에 만들면 게이트 0.

## 검증된 자동 흐름 (사용자 손 0)

```
mkdir ~/devapp/{name}
flutter create --org com.ganziman --project-name {name} --platforms ios,android
ruby scripts/register_bundle_id.rb         # ASC API → Bundle ID 등록
fastlane produce_app                        # ← spaceship cookie 재사용 (zero-gate 의 핵심)
ruby scripts/create_beta_group.rb          # ASC API → ganzitester 외부 베타 그룹
# 보일러플레이트 + 본체 + Info.plist + Manifest 코드 작성 (LLM)
# Info.plist 필수: NSPhotoLibraryUsageDescription + NSPhotoLibraryAddUsageDescription
flutter pub get + analyze
flutter build ios --debug --simulator      # 시뮬 검증 (UI 확인)
scripts/deploy_testflight.sh               # IPA + altool + 자동 build-status 진단
cd ~/devapp/{name} && git init -b main + commit + gh repo create --private --push  # ← 앱별 단독 private repo
ruby scripts/check_build_status.rb         # ASC processing 폴링
ruby scripts/submit_external_beta.rb       # VALID 후 외부 그룹 + Beta Review 자동
# ← 사용자 "출시" 한마디 시 마지막 단계만
```

**GitHub 정책**: 앱별 단독 private repo `dorisurararara-crypto/{name}`. 모노레포 X. 시크릿 .gitignore 검증 필수.

## 검증된 인프라 컴포넌트 (재활용 표준)

| 파일 | 출처 | 용도 |
|---|---|---|
| `scripts/_helpers.rb` | shadowrun 패턴 | ASC API JWT + api() helper |
| `scripts/register_bundle_id.rb` | seephone 패턴 | Bundle ID 등록 (영문 name) |
| `scripts/create_beta_group.rb` | 신규 표준 | 외부 베타 그룹 'ganzitester' 생성 |
| `scripts/check_build_status.rb` | shadowrun 패턴 | `/v1/builds?filter[app]=` 형식 (ASC API 가 `/v1/apps/{id}/builds` 패턴 거부함) |
| `scripts/submit_external_beta.rb` | shadowrun 패턴 | 외부 그룹 할당 + Beta Review 제출 |
| `scripts/deploy_testflight.sh` | shadowrun 패턴 | flutter clean+pub+pod / flutter build ipa / xcodebuild exportArchive (ASC key) / altool |
| `fastlane/Appfile` + `Fastfile` | 신규 표준 | `apple_id="zkxmel@naver.com"` + lane :produce_app |
| `lib/services/capture_service.dart` | protagonist 표준 | screenshot + gal + share_plus |
| `lib/services/ad_service.dart` | protagonist 표준 | google_mobile_ads (테스트 ID, 출시 직전 사용자 교체) |

## 알려진 함정 (실측)

1. **`fastlane produce` 의 `api_key_path` 옵션 X** — ASC API key 안 받음. spaceship.tunes (Apple ID + 2FA) 만 사용. 30일 cookie 가 zero-gate 의 핵심.
2. **`flutter build ipa` export 단계 fail 정상** — local Distribution cert 없으면 fail. archive 만 확보 후 `xcodebuild -exportArchive -allowProvisioningUpdates -authenticationKey*` 로 우회 = ASC key 가 즉석 cert 발급.
3. **ASC API 의 빌드 query**: `/v1/apps/{APP_ID}/builds` HTTP 400 → `/v1/builds?filter[app]=APP_ID` 가 valid.
4. **ASC processing 직후 1~5분은 record 없음** (`빌드 없음`). 정상.
5. **Bundle ID name 한글 거부** — 영문만 (`'Memereport'` OK, `'급식실 속보'` X).
6. **첫 빌드 Beta Review 24~48h** (외부 그룹 신규). 그 후 빌드들은 즉시.

## 신규 앱 부팅 체크리스트 (6분 표준)

```
□ mkdir ~/devapp/{name}
□ flutter create --org com.ganziman --project-name {name} --platforms ios,android {name}
□ scripts/_helpers.rb 작성 (BUNDLE_ID + APP_ID placeholder)
□ scripts/register_bundle_id.rb (이번엔 영문 name 명시)
□ fastlane/Appfile + Fastfile (apple_id zkxmel@naver.com, app_identifier, app_name)
□ ruby scripts/register_bundle_id.rb
□ fastlane produce_app  ← App ID 받음
□ _helpers.rb APP_ID hard-code
□ ruby scripts/create_beta_group.rb  ← group_id + public link 받음
□ _helpers.rb GROUP_ID + PUBLIC_LINK hard-code
□ scripts/check/submit/deploy 복사 (protagonist 패턴)
□ pubspec.yaml 의존성 + 표준 디렉토리
□ ios/Runner/Info.plist (CFBundleDisplayName 한글, GAD ID, 권한, ITSAppUsesNonExemptEncryption=false)
□ ios/ExportOptions.plist
□ android/app/src/main/AndroidManifest.xml (한글 label, INTERNET, GAD meta-data)
□ 본체 코드 (LLM 생성)
□ flutter pub get + analyze (0 error)
□ flutter build ios --simulator + 시뮬 UI 검증 (1-3 PNG 한도)
□ codex 코드 리뷰 (선택)
□ scripts/deploy_testflight.sh ← IPA + 업로드
□ scripts/check_build_status.rb 폴링 (5~30분)
□ VALID 시 scripts/submit_external_beta.rb 자동
□ 사용자 "출시" 한마디 → public link 공유
```

## 발견된 두 앱

| 앱 | App ID | Bundle ID | Beta Group | Public TestFlight | 앱스토어 (정식 출시 후) |
|---|---|---|---|---|---|
| POV 나는 주인공 | `6764478037` | `com.ganziman.protagonist` | `764b1b9f-e228-4e13-89fc-d36644dfb727` | https://testflight.apple.com/join/SMpq8KrK | https://apps.apple.com/app/id6764478037 |
| 급식실 속보 | `6764482628` | `com.ganziman.memereport` | `efb2fb62-fa24-48f5-b62a-4a33271f21db` | https://testflight.apple.com/join/1MbXjYRd | https://apps.apple.com/app/id6764482628 |

**정식 출시 후**: 각 앱 `lib/services/share_service.dart` 의 `_isReleased = true` 로 바꾸면 TestFlight 줄 자동 제거되고 앱스토어 link 만 공유됨.
