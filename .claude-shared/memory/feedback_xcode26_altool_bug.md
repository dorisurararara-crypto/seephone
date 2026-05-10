---
name: Xcode 26 altool 다중 앱 silent fail 버그
description: 같은 팀에 비슷한 prefix bundle ID 가 여러 개 있을 때 altool 이 잘못된 app record 에 빌드 연결 → UPLOAD SUCCEEDED 받지만 ASC 에 안 나타남.
type: feedback
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 증상
- altool `UPLOAD SUCCEEDED` 메시지 받음
- ASC 의 builds API → 빌드 0개 (silent fail)
- IPA validate 는 VERIFY SUCCEEDED (정상)
- Bundle ID / provisioning profile / Info.plist 다 정상
- 같은 팀의 일부 앱은 잘 통과 (운/타이밍), 일부 silent fail
- 시간 무한 대기해도 안 나타남

**Why:** Xcode 26 의 altool 은 같은 팀에 비슷한 prefix Bundle ID 가 여러 개 있으면 (예: `com.ganziman.shadowrun`, `com.ganziman.bbaksin`, `com.ganziman.pupil`, `com.ganziman.anger`, ...) **잘못된 app record 에 build 를 연결시킴**. Apple 이 인식한 bundle ID 와 실제 IPA 의 bundle ID 가 mismatch 되어 silent drop. UPLOAD 는 성공해 보이지만 처리 단계에서 Apple 이 무시.

이 버그는 fastlane 이슈 트래커에 다수 보고:
- fastlane#29698 — altool incorrectly selects apple_id with multiple apps on Xcode 26
- fastlane#29680 — Issue with uploaded build getting associated with the wrong app
- fastlane#29743 — Upload to TestFlight silently fails due to recent Xcode 26 altool changes

## 해결책 — `--apple-id <numerical>` 명시

ASC App ID (숫자 ID) 를 altool 에 명시:
```bash
xcrun altool --upload-app \
  --apple-id 6764363757 \      # ← ASC App ID (숫자)
  --type ios \
  -f path/to/app.ipa \
  --apiKey JSGU6J4JN4 \
  --apiIssuer 5269abe3-03f1-46a9-a37c-35d950758714
```

## 차선책 — `--use-old-altool` 환경 변수
```bash
export DELIVER_ALTOOL_ADDITIONAL_UPLOAD_PARAMETERS="--verbose --use-old-altool"
```

**How to apply:** 
- seephone monorepo 의 `{app}/scripts/deploy_testflight.sh` 의 altool upload 라인에 반드시 `--apple-id <APP_ID>` 추가.
- 새 앱 만들 때 같은 팀에 비슷한 prefix bundle ID 가 이미 있으면 무조건 `--apple-id` 명시.
- shadowrun / pupil / 첫 시도 가 운 좋게 통과한 건, altool 이 우연히 맞는 app 에 attach 한 케이스. 보장 안 됨.

## 검증 (2026-04-30)
- bbaksin / anger silent fail 24h+ → `--apple-id` 명시 재업로드 → 정상 처리 확인

---

## 🔑 Silent fail 진단 키 — `xcrun altool --build-status --delivery-id <UUID>`

**진짜 원인을 찾는 유일한 방법.** altool 의 `--upload-app` 은 항상 `UPLOAD SUCCEEDED` 보고하지만 Apple 서버에서 실제로 reject 할 수 있음. 그 reject 사유는:

1. ASC API `/v1/apps/{id}/builds` 에 절대 안 나타남
2. 사용자에게 이메일 안 옴
3. `xcrun altool --build-status --delivery-id <UUID>` 로만 확인 가능

```bash
xcrun altool --build-status --delivery-id 58c68453-... \
  --apiKey JSGU6J4JN4 --apiIssuer 5269abe3-...
# 출력 예시 — silent fail 원인 가시화:
# BUILD-STATUS: FAILED
# IMPORT-STATUS: FAILED
# PROCESSING-ERRORS:
#   Missing purpose string in Info.plist. NSPhotoLibraryUsageDescription required (90683)
```

**How to apply:** 
- 업로드 후 5분 내 `--build-status --delivery-id` 로 즉시 검증.
- 처리 실패면 `PROCESSING-ERRORS` 에 정확한 원인 표시 (Info.plist 키 누락, 잘못된 entitlement 등).
- deploy_testflight.sh 에 자동 검증 단계 추가 권장: 업로드 후 30s 대기 → build-status 호출 → FAILED 면 abort.

---

## 실제 발견된 silent fail 원인들 (2026-04-30 bbaksin/anger 케이스)

**진짜 원인**: `NSPhotoLibraryUsageDescription` 누락 (Info.plist).
- `gal` 패키지가 photo library API 참조 → Apple 이 `NSPhotoLibraryUsageDescription` (읽기) 키 요구.
- `NSPhotoLibraryAddUsageDescription` (쓰기) 만 있어선 부족.
- 둘 다 추가 후 build=8 즉시 통과.

**이전에 잘못 의심한 원인들:**
- ❌ Paid Apps Agreement 미서명 (사용자 시간 낭비)
- ❌ IAP MISSING_METADATA
- ❌ Bundle ID IN_APP_PURCHASE capability
- ❌ Xcode 26 altool 다중 앱 버그 (이건 진짜 버그지만 우리 케이스의 주원인은 아니었음)

→ **Lesson: 업로드 후 항상 `--build-status` 먼저 확인.** 다른 가설 세우기 전에.
