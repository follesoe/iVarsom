#!/bin/bash
# Download existing metadata from App Store Connect
# This will overwrite local metadata files with what's currently on the App Store

set -e

cd "$(dirname "$0")/.."

echo "Downloading metadata from App Store Connect..."
fastlane download_metadata

echo "Done! Check fastlane/metadata for the downloaded content."
