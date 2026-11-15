#!/bin/bash
# Create/update both release drafts from the local metadata and screenshots.
# Builds remain managed by Xcode Cloud. This does not submit or release the app.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version> (for example: $0 6.0)" >&2
  exit 1
fi

cd "$(dirname "$0")/.."
exec fastlane ios prepare_release "version:$1"
