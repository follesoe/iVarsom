#!/bin/bash
# Frame screenshots with Apple device bezels and convert to webp.
#
# iPhone/iPad: composite into official Apple device bezels (from images/bezels/)
# macOS: drop shadow only (screenshots already have window chrome)
#
# Requirements: ImageMagick (magick), cwebp
#
# Input:
#   fastlane/screenshots_ios/{en-US,no,sv}/*_iphone_*.png  (1320x2868)
#   fastlane/screenshots_ios/{en-US,no,sv}/*_ipad_*.png    (2752x2064)
#   fastlane/screenshots_osx/{en-US,no,sv}/*.png           (2880x1800)
#
# Output:
#   images/iOS/*.webp          (en-US, default)
#   images/iOS/no/*.webp       (Norwegian)
#   images/iOS/sv/*.webp       (Swedish)
#   images/iPadOS/*.webp       (en-US, default)
#   images/iPadOS/no/*.webp    (Norwegian)
#   images/iPadOS/sv/*.webp    (Swedish)
#   images/macOS/*.webp        (en-US, default)
#   images/macOS/no/*.webp     (Norwegian)
#   images/macOS/sv/*.webp     (Swedish)
#
# Bezels:
#   images/bezels/iPhone_17_Pro_Max_Portrait.png  (1470x3000, screen at 75,66)
#   images/bezels/iPad_Pro_13_Landscape.png       (3000x2300, screen at 124,118)
#
# To update bezels, download from https://developer.apple.com/design/resources/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

IOS_SRC_DIR="$ROOT_DIR/fastlane/screenshots_ios"
MAC_SRC_DIR="$ROOT_DIR/fastlane/screenshots_osx"

IOS_OUT_BASE="$ROOT_DIR/images/iOS"
IPAD_OUT_BASE="$ROOT_DIR/images/iPadOS"
MAC_OUT_BASE="$ROOT_DIR/images/macOS"

# Locales to process. en-US outputs to the base directory; others get subdirectories.
LOCALES=("en-US" "no" "sv")

IPHONE_BEZEL="$ROOT_DIR/images/bezels/iPhone_17_Pro_Max_Portrait.png"
IPAD_BEZEL="$ROOT_DIR/images/bezels/iPad_Pro_13_Landscape.png"

# Screen area coordinates within each bezel (where the screenshot gets placed)
IPHONE_SCREEN_X=75
IPHONE_SCREEN_Y=66
IPAD_SCREEN_X=124
IPAD_SCREEN_Y=118

WEBP_QUALITY=90

# Check dependencies
for cmd in magick cwebp; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd not found. Install with: brew install ${cmd/magick/imagemagick}"
    exit 1
  fi
done

# Check bezels exist
for bezel in "$IPHONE_BEZEL" "$IPAD_BEZEL"; do
  if [[ ! -f "$bezel" ]]; then
    echo "Error: Bezel not found: $bezel"
    echo "Download from https://developer.apple.com/design/resources/"
    exit 1
  fi
done

# Output directory for a locale: en-US → base dir, others → base/locale subdir
out_dir() {
  local base="$1"
  local locale="$2"
  if [[ "$locale" == "en-US" ]]; then
    echo "$base"
  else
    echo "$base/$locale"
  fi
}

# Create screen-area masks from bezels using flood-fill.
# The bezel PNGs have transparent screen areas and transparent outside regions.
# Flood-filling from the screen center fills the connected interior, producing a mask
# that is white for the device shape (frame + screen) and black outside.
# This prevents screenshot corners from poking out past the rounded screen opening.
MASK_DIR=$(mktemp -d)
echo "Generating screen masks..."
magick "$IPHONE_BEZEL" -alpha extract -fill white -floodfill "+735+1500" black -alpha shape "$MASK_DIR/iphone_mask.png"
magick "$IPAD_BEZEL" -alpha extract -fill white -floodfill "+1500+1150" black -alpha shape "$MASK_DIR/ipad_mask.png"
trap 'rm -rf "$MASK_DIR"' EXIT

# Extract descriptive name from filename like "1_iphone_region_list.png" -> "region_list"
extract_name() {
  local basename="$1"
  local name="${basename%.png}"
  echo "$name" | sed -E 's/^[0-9]+_(iphone|ipad)_//'
}

# Frame an iPhone screenshot using Apple's device bezel
frame_iphone() {
  local src="$1"
  local dst="$2"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  # Place screenshot on canvas, overlay bezel, then clip to device shape
  magick -size 1470x3000 xc:none \
    "$src" -geometry "+${IPHONE_SCREEN_X}+${IPHONE_SCREEN_Y}" -composite \
    "$IPHONE_BEZEL" -composite \
    "$MASK_DIR/iphone_mask.png" -compose DstIn -composite \
    "$tmp_dir/framed.png"

  cwebp -q "$WEBP_QUALITY" -alpha_q 100 "$tmp_dir/framed.png" -o "$dst" -quiet

  rm -rf "$tmp_dir"
}

# Frame an iPad screenshot using Apple's device bezel
frame_ipad() {
  local src="$1"
  local dst="$2"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  magick -size 3000x2300 xc:none \
    "$src" -geometry "+${IPAD_SCREEN_X}+${IPAD_SCREEN_Y}" -composite \
    "$IPAD_BEZEL" -composite \
    "$MASK_DIR/ipad_mask.png" -compose DstIn -composite \
    "$tmp_dir/framed.png"

  cwebp -q "$WEBP_QUALITY" -alpha_q 100 "$tmp_dir/framed.png" -o "$dst" -quiet

  rm -rf "$tmp_dir"
}

# Add drop shadow to macOS screenshot (already has window chrome)
frame_macos() {
  local src="$1"
  local dst="$2"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  magick "$src" \
    \( +clone -background black -shadow "40x20+0+10" \) \
    +swap -background none -layers merge +repage \
    "$tmp_dir/final.png"

  cwebp -q "$WEBP_QUALITY" -alpha_q 100 "$tmp_dir/final.png" -o "$dst" -quiet

  rm -rf "$tmp_dir"
}

count=0

for locale in "${LOCALES[@]}"; do
  IOS_SRC="$IOS_SRC_DIR/$locale"
  MAC_SRC="$MAC_SRC_DIR/$locale"

  IOS_OUT=$(out_dir "$IOS_OUT_BASE" "$locale")
  IPAD_OUT=$(out_dir "$IPAD_OUT_BASE" "$locale")
  MAC_OUT=$(out_dir "$MAC_OUT_BASE" "$locale")

  # Skip locales whose source directories don't exist
  if [[ ! -d "$IOS_SRC" ]] && [[ ! -d "$MAC_SRC" ]]; then
    echo "Skipping $locale (no source directories)"
    continue
  fi

  mkdir -p "$IOS_OUT" "$IPAD_OUT" "$MAC_OUT"

  echo "--- $locale ---"

  # Process iPhone screenshots
  for f in "$IOS_SRC"/*_iphone_*.png; do
    [[ -f "$f" ]] || continue
    name=$(extract_name "$(basename "$f")")
    dst="$IOS_OUT/${name}.webp"
    echo "iPhone: $(basename "$f") → $dst"
    frame_iphone "$f" "$dst"
    count=$((count + 1))
  done

  # Process iPad screenshots
  for f in "$IOS_SRC"/*_ipad_*.png; do
    [[ -f "$f" ]] || continue
    name=$(extract_name "$(basename "$f")")
    dst="$IPAD_OUT/${name}.webp"
    echo "iPad:   $(basename "$f") → $dst"
    frame_ipad "$f" "$dst"
    count=$((count + 1))
  done

  # Process macOS screenshots
  if [[ -d "$MAC_SRC" ]]; then
    for f in "$MAC_SRC"/*.png; do
      [[ -f "$f" ]] || continue
      basename_f="$(basename "$f")"
      name="${basename_f%.png}"
      if [[ "$name" =~ ^([0-9]+)_screenshot$ ]]; then
        name="screenshot_${BASH_REMATCH[1]}"
      elif [[ "$name" =~ ^[0-9]+_ ]]; then
        name="${name#*_}"
      fi
      dst="$MAC_OUT/${name}.webp"
      echo "macOS:  $basename_f → $dst"
      frame_macos "$f" "$dst"
      count=$((count + 1))
    done
  fi
done

echo ""
echo "Done. Framed $count screenshots."
