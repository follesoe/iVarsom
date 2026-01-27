#!/bin/bash
# Upload metadata to App Store Connect
# This uploads all metadata without submitting for review

set -e

cd "$(dirname "$0")/.."

echo "Uploading metadata to App Store Connect..."
fastlane upload_metadata

echo "Done! Metadata has been uploaded to App Store Connect."
