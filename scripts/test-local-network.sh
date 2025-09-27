#!/bin/bash
# Local Network Test Runner
# This script runs ALL tests including network tests for local development

set -euo pipefail

echo "🧪 Running LOCAL tests with network tests enabled"
echo "This includes all network-dependent tests that are disabled in CI"
echo ""

# Find available iPhone 16 simulator
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16.*Booted" | head -1 | grep -o '[A-F0-9-]\{36\}' | head -1)

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No booted iPhone 16 simulator found. Please boot a simulator first:"
    echo "   xcrun simctl boot 'iPhone 16'"
    exit 1
fi

echo "📱 Using simulator: $SIMULATOR_ID"
echo ""

# Run tests with network tests enabled
xcodebuild \
    -scheme "Food Scanner" \
    -testPlan "FoodScanner-PR" \
    -destination "id=$SIMULATOR_ID" \
    -destination-timeout 180 \
    -derivedDataPath ./DerivedData \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_PREVIEWS=NO \
    SWIFT_STRICT_CONCURRENCY=complete \
    OTHER_SWIFT_FLAGS='-warnings-as-errors' \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    -disableAutomaticPackageResolution \
    -skip-testing:FoodScannerUITests \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    test

echo ""
echo "✅ Local network tests completed successfully!"
