#!/bin/bash
# Preview metadata changes (dry run)
# Shows what would be uploaded without making changes

set -e

cd "$(dirname "$0")/.."

echo "Previewing metadata changes..."
fastlane preview_metadata

echo "This was a preview. Run metadata_upload.sh to actually upload."
