#!/bin/bash
# ============================================================
# Alee iOS — App Store release build (4.3.1 / build 12)
# Run on macOS only. Requires:
#   - Xcode 16+ (xcodebuild -version)
#   - CocoaPods (pod --version)
#   - Flutter 3.44.2 stable (Dart 3.12.2)
#     MUST match pubspec.lock (resolved with flutter >=3.41.0).
#     Flutter 3.19.5 CANNOT resolve these deps (fails on flutter_lints).
#   - Xcode signed in with an Apple ID that has App Manager/Admin
#     role in team NUQ5XHT8NT (Xcode > Settings > Accounts),
#     so automatic signing can create the App Store distribution
#     certificate + provisioning profile.
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

BUILD_NAME="4.3.1"
BUILD_NUMBER="12"

echo "=== Environment check ==="
flutter --version
xcodebuild -version
pod --version
security find-identity -v -p codesigning | grep -i "distribution" || \
  echo "NOTE: no Apple Distribution cert yet — Xcode automatic signing will create one during archive."

echo "=== Clean + deps ==="
flutter clean
flutter pub get

echo "=== Build archive + export IPA (App Store distribution) ==="
flutter build ipa --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/ExportOptions.plist

IPA=$(ls build/ios/ipa/*.ipa | head -1)
echo "=== Verify: $IPA ==="

TMP=$(mktemp -d)
unzip -q "$IPA" -d "$TMP"
APP="$TMP/Payload/Runner.app"

echo "--- Signing (expect: Authority=Apple Distribution ...) ---"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier="
codesign --verify --deep --strict "$APP" && echo "codesign verify: PASS"

echo "--- Version (expect: $BUILD_NAME / $BUILD_NUMBER) ---"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist"

echo "--- Embedded provisioning (expect: get-task-allow=false, team NUQ5XHT8NT) ---"
security cms -D -i "$APP/embedded.mobileprovision" | \
  /usr/libexec/PlistBuddy -c "Print :Entitlements:get-task-allow" /dev/stdin
security cms -D -i "$APP/embedded.mobileprovision" | grep -A1 "TeamIdentifier" | tail -1

echo "--- Push entitlement (expect: production) ---"
codesign -d --entitlements :- "$APP" 2>/dev/null | grep -A1 aps-environment | tail -1

echo "=== DONE: $IPA ==="
