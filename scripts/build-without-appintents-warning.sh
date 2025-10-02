#!/bin/bash

# Build script that filters out AppIntents metadata extraction warning
# This warning is harmless but CI treats it as a failure

set -e

# Default to iPhone 16 simulator if no destination specified
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 16}"

echo "🔨 Building Food Scanner for destination: $DESTINATION"

# Build the project and filter out the AppIntents warning
xcodebuild -scheme "Food Scanner" -destination "$DESTINATION" build 2>&1 | \
    grep -v "appintentsmetadataprocessor.*warning: Metadata extraction skipped. No AppIntents.framework dependency found."

# Check if the build actually succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Build succeeded"
    exit 0
else
    echo "❌ Build failed"
    exit 1
fi
