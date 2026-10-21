#!/bin/bash
# Capture the app after choosing its pose, orientation and language in Device Hub.
# Requires Xcode 27.1 and ImageMagick (also used by frame_screenshots.sh).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: screenshots_duo.sh --locale <en-US|no|sv|...> --display <outer|inner>
                         [--device <name-or-UDID>] [--output-dir <directory>]
                         [-- <name_suffix>]

Choose Closed for outer, or Open/Partially Open for inner in Device Hub first.
The script captures only; it does not change the pose, app language or screen.
Output defaults to fastlane/screenshots_ios/<locale>/NN_duo_<display>_<name>.png.
--output-dir overrides the screenshots_ios directory (a locale folder is added).
EOF
}

fail() { echo "Error: $*" >&2; exit 1; }

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="iPhone Duo"
LOCALE=""
DISPLAY=""
NAME="screenshot"
OUTPUT_DIR="$ROOT_DIR/fastlane/screenshots_ios"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --locale|--display|--device|--output-dir)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Missing value for $1"
      case "$1" in
        --locale) LOCALE="$2" ;;
        --display) DISPLAY="$2" ;;
        --device) DEVICE="$2" ;;
        --output-dir) OUTPUT_DIR="$2" ;;
      esac
      shift 2
      ;;
    --) shift; NAME="$*"; break ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "Unknown argument: $1" ;;
  esac
done

[[ "$LOCALE" =~ ^[a-z]{2}(-[A-Z]{2})?$ ]] || fail "Specify an App Store locale, e.g. en-US, no or sv."
[[ -d "$ROOT_DIR/fastlane/metadata_ios/$LOCALE" ]] || fail "No iOS metadata directory for locale: $LOCALE"
NAME="${NAME// /_}"
[[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]] || fail "Use letters, digits, spaces, underscores or hyphens in the name."

# Xcode 27.1's Duo names, visible in: xcrun simctl io <device> enumerate
case "$DISPLAY" in
  outer) SCREEN="primary" ;;
  inner) SCREEN="primary-1" ;;
  *) fail "Specify --display outer or --display inner." ;;
esac

command -v magick >/dev/null || fail "ImageMagick is required: brew install imagemagick"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

xcrun simctl io "$DEVICE" screenshot --type=png --display="$SCREEN" --mask=ignored "$TEMP_DIR/raw.png"
SIZE=$(magick identify -format '%wx%h' "$TEMP_DIR/raw.png")
case "$DISPLAY:$SIZE" in
  outer:1398x2034|outer:2034x1398|inner:2007x2853|inner:2853x2007) ;;
  *) fail "Unexpected $DISPLAY display size: $SIZE. Check the Duo device and pose in Device Hub." ;;
esac

# Even --mask=ignored captures can contain an alpha channel. PNG24 removes it
# without resizing or a lossy JPEG round trip, as required by App Store Connect.
magick "$TEMP_DIR/raw.png" -alpha off "PNG24:$TEMP_DIR/screenshot.png"
IS_BLACK=$(magick "$TEMP_DIR/screenshot.png" -format '%[fx:maxima==0]' info:)
[[ "$IS_BLACK" == "0" ]] || fail "The display is black. Select the matching pose in Device Hub, wait for the app to render, and retry."

DESTINATION="$OUTPUT_DIR/$LOCALE"
mkdir -p "$DESTINATION"
shopt -s nullglob
NEXT=1
while :; do
  printf -v NUMBER '%02d' "$NEXT"
  EXISTING=("$DESTINATION/${NUMBER}_duo_"*.png)
  [[ ${#EXISTING[@]} -eq 0 ]] && break
  NEXT=$((NEXT + 1))
done
OUTPUT_PATH="$DESTINATION/${NUMBER}_duo_${DISPLAY}_${NAME}.png"
mv "$TEMP_DIR/screenshot.png" "$OUTPUT_PATH"
echo "Saved: $OUTPUT_PATH ($SIZE, RGB without alpha)"
echo "Review the image before upload; display selection cannot verify the app content or language."
