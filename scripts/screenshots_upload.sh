#!/bin/bash
# Upload screenshots to App Store Connect
#
# iOS/iPadOS: Place screenshots in fastlane/screenshots_ios/<locale>/
# macOS:      Place screenshots in fastlane/screenshots_osx/<locale>/
# Locales: en-US, nb-NO, sv-SE
# Fastlane auto-detects device size class from image resolution
#
# Usage:
#   ./scripts/screenshots_upload.sh          # Upload iOS + macOS
#   ./scripts/screenshots_upload.sh ios      # Upload iOS only
#   ./scripts/screenshots_upload.sh mac      # Upload macOS only

set -e

cd "$(dirname "$0")/.."

TARGET=${1:-all}

case "$TARGET" in
  ios)
    echo "Uploading iOS screenshots to App Store Connect..."
    fastlane upload_screenshots
    ;;
  mac)
    echo "Uploading macOS screenshots to App Store Connect..."
    fastlane upload_screenshots_mac
    ;;
  all)
    echo "Uploading iOS and macOS screenshots to App Store Connect..."
    fastlane upload_screenshots_all
    ;;
  *)
    echo "Usage: $0 [ios|mac|all]"
    exit 1
    ;;
esac

echo "Done! Screenshots have been uploaded to App Store Connect."
