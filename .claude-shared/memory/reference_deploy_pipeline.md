---
name: iOS + Android 양 플랫폼 자동 배포 파이프라인
description: protagonist 에서 검증된 1인 개발자용 한 줄 명령 양쪽 스토어 출시 패턴. Play Console 자동화 포함.
type: reference
originSessionId: 71168d6f-9ae3-4130-9728-bd63b574f09a
---
`~/devapp/protagonist/DEPLOY.md` 가 ground truth. 신규 앱에 그대로 복사 가능.

## 양쪽 자동화 핵심 인프라
- **iOS**: ASC API key (`~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8`) + xcodebuild `-allowProvisioningUpdates -authenticationKey*` 패턴
- **Android**: Service account JSON (`~/.googleplay/protagonist-key.json`) + Google Play Developer API
- **둘 다 한 번 셋업하면 영구 재사용**

## 매 배포 4단계
1. `pubspec.yaml` 빌드번호 +1
2. `bash scripts/deploy_testflight.sh N` — iOS IPA 빌드 + 업로드
3. `ruby scripts/release_NNN.rb` — App Store 버전 생성 + Review 제출
4. `flutter build appbundle && python3 scripts/deploy_play.py --aab <path> --track <track>` — Android Play Console 게재

## 트랙 정책
- iOS: AFTER_APPROVAL (자동 게재). 외부 베타는 별도 명령
- Android: 신규 개발자 계정 = production 직행 X. 비공개 테스트 (alpha) 12명 × 14일 → production 액세스 신청 → production
- 즉시 사용 가능: `internal` 트랙 (Play Store 링크로 본인 + 가까운 5명)

## 검증된 트러블슈팅 10건
이모지 거부 / altool silent fail / versionCode 재사용 금지 / draft app rule / java home / reviewSubmission 5개 한도 등. DEPLOY.md 11~20번 항목.

## 신규 앱에 적용 시
`scripts/_helpers.rb` 의 APP_ID + Bundle ID + EXTERNAL_GROUP_ID 만 새 값으로. 나머지 (deploy_testflight.sh, release_NNN.rb 패턴, deploy_play.py) 그대로 복사.
