#!/bin/bash
# Generate Instagram Story images (9:16) from bezeled screenshots.
#
# Places each bezeled screenshot centered on a dark background with margin.
# iPhone screenshots are portrait and fill the frame nicely.
# iPad/macOS screenshots are landscape and are scaled to fit with more margin.
#
# Requirements: ImageMagick (magick)
#
# Input:  images/{iOS,iPadOS,macOS}/{,no/,sv/}*.webp
# Output: images/instagram/{iOS,iPadOS,macOS}/{,no/,sv/}*.png

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

OUT_BASE="$ROOT_DIR/images/instagram"
BG_COLOR="#1a1a1a"

# Instagram story dimensions (9:16)
STORY_W=1080
STORY_H=1920

# Margin as percentage of the shorter dimension (width)
MARGIN_PCT=8

# Check dependencies
if ! command -v magick &>/dev/null; then
  echo "Error: magick not found. Install with: brew install imagemagick"
  exit 1
fi

count=0

for category in iOS iPadOS macOS; do
  src_dir="$ROOT_DIR/images/$category"
  [[ -d "$src_dir" ]] || continue

  for f in "$src_dir"/*.webp "$src_dir"/**/*.webp; do
    [[ -f "$f" ]] || continue

    # Determine relative path within category (e.g. "no/region_list.webp")
    rel="${f#"$src_dir"/}"
    name="${rel%.webp}"
    out_dir="$OUT_BASE/$category/$(dirname "$rel")"
    mkdir -p "$out_dir"
    dst="$OUT_BASE/$category/${name}.png"

    echo "$category: $rel → $dst"

    # Calculate margin in pixels
    margin=$(( STORY_W * MARGIN_PCT / 100 ))
    max_w=$(( STORY_W - 2 * margin ))
    max_h=$(( STORY_H - 2 * margin ))

    # Resize image to fit within the available area, then center on background
    magick "$f" \
      -resize "${max_w}x${max_h}" \
      -background "$BG_COLOR" \
      -gravity center \
      -extent "${STORY_W}x${STORY_H}" \
      "$dst"

    count=$((count + 1))
  done
done

echo ""
echo "Done. Generated $count Instagram story images."
