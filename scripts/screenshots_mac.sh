#!/bin/bash
# Take a macOS App Store screenshot of the Skredvarsel app.
#
# This script:
#   1. Resizes the app window to 1440x900 points (2880x1800 on Retina)
#   2. Captures a screenshot of the window
#   3. Saves it with the next available number in the correct locale folder
#
# The locale is auto-detected from macOS system language, or pass --locale.
# Optionally pass a descriptive name suffix after --.
#
# Usage:
#   ./scripts/screenshots_mac.sh                          # auto name + locale
#   ./scripts/screenshots_mac.sh -- region_details        # custom name suffix
#   ./scripts/screenshots_mac.sh --locale no              # override locale
#   ./scripts/screenshots_mac.sh --locale sv -- map_dark  # both
#
# Output example: fastlane/screenshots_osx/no/1_region_details.png

set -e

BUNDLE_ID="no.follesoe.iVarsom"

# Window size: 1440x900 points = 2880x1800 pixels on 2x Retina
WINDOW_WIDTH=1440
WINDOW_HEIGHT=900

# Parse arguments
LOCALE_OVERRIDE=""
NAME_SUFFIX=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --locale)
      LOCALE_OVERRIDE="$2"
      shift 2
      ;;
    --)
      shift
      NAME_SUFFIX="$*"
      break
      ;;
    *)
      echo "Usage: $0 [--locale <en-US|no|sv>] [-- <name_suffix>]"
      exit 1
      ;;
  esac
done

# Map macOS system language to fastlane locale directory name
detect_fastlane_locale() {
  local sys_lang
  sys_lang=$(defaults read NSGlobalDomain AppleLocale 2>/dev/null || echo "en_US")

  case "$sys_lang" in
    nb*|nn*)  echo "no" ;;
    sv*)      echo "sv" ;;
    *)        echo "en-US" ;;
  esac
}

if [[ -n "$LOCALE_OVERRIDE" ]]; then
  FASTLANE_LOCALE="$LOCALE_OVERRIDE"
else
  FASTLANE_LOCALE=$(detect_fastlane_locale)
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOT_DIR="$SCRIPT_DIR/../fastlane/screenshots_osx/$FASTLANE_LOCALE"

# Ensure output directory exists
mkdir -p "$SCREENSHOT_DIR"

# Get the PID from the bundle ID (locale-independent)
APP_PID=$(osascript -e "tell application \"System Events\" to get unix id of first process whose bundle identifier is \"$BUNDLE_ID\"" 2>/dev/null || true)
if [[ -z "$APP_PID" ]]; then
  echo "Error: No running app found with bundle ID $BUNDLE_ID. Please launch the app first."
  exit 1
fi

# Get the localized process name for AppleScript window manipulation
APP_NAME=$(osascript -e "tell application \"System Events\" to get name of first process whose bundle identifier is \"$BUNDLE_ID\"")

# Activate the app and resize via System Events (works with all apps)
osascript -e "
tell application \"System Events\"
  tell process \"$APP_NAME\"
    set frontmost to true
    delay 0.3
    set position of front window to {0, 25}
    set size of front window to {$WINDOW_WIDTH, $WINDOW_HEIGHT}
  end tell
end tell
"

# Brief pause to let the window settle after resize
sleep 0.5

# Find the next available number
NEXT_NUM=1
while ls "$SCREENSHOT_DIR"/${NEXT_NUM}_*.png &>/dev/null; do
  NEXT_NUM=$(( NEXT_NUM + 1 ))
done

# Build filename
if [[ -n "$NAME_SUFFIX" ]]; then
  # Replace spaces with underscores
  NAME_SUFFIX="${NAME_SUFFIX// /_}"
  FILENAME="${NEXT_NUM}_${NAME_SUFFIX}.png"
else
  FILENAME="${NEXT_NUM}_screenshot.png"
fi

OUTPUT_PATH="$SCREENSHOT_DIR/$FILENAME"

# Get the CGWindow ID for screencapture using PID (locale-independent)
WINDOW_ID=$(swift -e "
import CoreGraphics
let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
for w in windows {
    if let pid = w[kCGWindowOwnerPID as String] as? Int,
       pid == $APP_PID,
       let layer = w[kCGWindowLayer as String] as? Int,
       layer == 0,
       let num = w[kCGWindowNumber as String] as? Int {
        print(num)
        break
    }
}
")

# Capture the window (no shadow with -o)
screencapture -o -l "$WINDOW_ID" "$OUTPUT_PATH"

echo "Saved: $OUTPUT_PATH"
echo "  Locale: $FASTLANE_LOCALE"
echo "  File:   $FILENAME"
