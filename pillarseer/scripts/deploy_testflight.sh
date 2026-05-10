#!/usr/bin/env bash
# pillarseer IPA 빌드 + altool 업로드 (zero-gate 의 마지막 자동 단계)
set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"

KEY_ID=JSGU6J4JN4
ISSUER_ID=5269abe3-03f1-46a9-a37c-35d950758714
KEY_FILE=~/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8
APP_ID=6768096855

# 1. 버전 + 빌드번호 — pubspec 그대로 사용 (수동 bump 우선), 인자 있으면 빌드번호만 override
VERSION_NAME=$(grep '^version:' pubspec.yaml | sed -E 's/version: ([^+]+).*/\1/')
if [ -n "${1:-}" ]; then
  NEXT=$1
else
  CURRENT=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
  NEXT=$((CURRENT + 1))
fi
echo "▶︎ 버전: $VERSION_NAME  빌드 번호: $NEXT"

sed -i.bak "s/^version:.*/version: ${VERSION_NAME}+${NEXT}/" pubspec.yaml
rm -f pubspec.yaml.bak

# 2. Pod 클린 — 시뮬 빌드 직후 release archive 시 91169 회피
echo "▶︎ flutter clean + pub get + pod install"
flutter clean >/dev/null
flutter pub get >/dev/null
(cd ios && pod install >/dev/null 2>&1)

# 3. Flutter archive (export 단계 fail 정상)
echo "▶︎ flutter build ipa --release"
flutter build ipa --release --build-number "$NEXT" --build-name "$VERSION_NAME" || true

# 4. xcodebuild exportArchive — ASC API key 로 즉석 cert 발급
echo "▶︎ xcodebuild exportArchive"
mkdir -p build/ios/ipa
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_FILE" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID" 2>&1 | tail -5

IPA=$(ls -t build/ios/ipa/*.ipa | head -1)
[ -f "$IPA" ] || { echo "❌ IPA 생성 실패"; exit 1; }
echo "▶︎ IPA: $IPA ($(du -h "$IPA" | cut -f1))"

# 5. altool 업로드 — Xcode 26 silent fail 회피 위해 --apple-id 명시 (memory: feedback_xcode26_altool_bug)
echo "▶︎ altool upload-app (apple-id=$APP_ID)"
UPLOAD_OUT=$(xcrun altool --upload-app --type ios -f "$IPA" \
  --apple-id "$APP_ID" \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID" 2>&1)
echo "$UPLOAD_OUT" | tail -5
DELIVERY=$(echo "$UPLOAD_OUT" | grep -oE 'Delivery UUID: [a-f0-9-]+' | awk '{print $3}')

# 6. 자동 build-status 진단 — UPLOAD SUCCEEDED 가 거짓일 수 있음 (Apple silent fail)
if [ -n "$DELIVERY" ]; then
  echo
  echo "▶︎ Delivery UUID: $DELIVERY"
  echo "▶︎ 30초 후 build-status 진단..."
  sleep 30
  STATUS=$(xcrun altool --build-status --delivery-id "$DELIVERY" \
    --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID" 2>&1)
  echo "$STATUS" | grep -E "BUILD-STATUS|IMPORT-STATUS|PROCESSING-ERRORS|description :" | head -10
  if echo "$STATUS" | grep -q "BUILD-STATUS: FAILED"; then
    echo
    echo "❌ Apple 이 처리 거부함. 위 PROCESSING-ERRORS 확인 후 fix 하고 재업로드."
    exit 1
  fi
fi

echo
echo "✅ 업로드 끝. 5~20분 후 ASC processing 완료."
echo "   상태: ruby scripts/check_build_status.rb"
echo "   외부 베타 제출: ruby scripts/submit_external_beta.rb"
