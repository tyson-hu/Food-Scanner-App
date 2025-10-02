#!/bin/bash

# Configure local environment to match CI Swift 6 concurrency settings
# This script sets up the same Swift 6 strict concurrency checking as CI

set -euo pipefail

echo "🔧 Configuring local environment to match CI Swift 6 concurrency settings..."

# Check if we're in the right directory
if [[ ! -f "Food Scanner.xcodeproj/project.pbxproj" ]]; then
    echo "❌ Error: Please run this script from the Food Scanner project root directory"
    exit 1
fi

# Check Xcode version
echo "📱 Checking Xcode version..."
XCODE_VERSION=$(xcodebuild -version | head -n1)
echo "   $XCODE_VERSION"

if [[ ! "$XCODE_VERSION" =~ "Xcode 26" ]]; then
    echo "⚠️  Warning: CI uses Xcode 26.0.0, but you have a different version"
    echo "   This may cause differences in Swift concurrency behavior"
fi

echo ""
echo "🎯 Current Swift settings:"
xcodebuild -showBuildSettings -scheme "Food Scanner" | grep -E "(SWIFT_VERSION|SWIFT_DEFAULT_ACTOR_ISOLATION|SWIFT_APPROACHABLE_CONCURRENCY)" || true

echo ""
echo "🔧 To enable Swift 6 strict concurrency checking locally, you have several options:"
echo ""
echo "1️⃣  **Recommended: Use xcodebuild with Swift 6 flags**"
echo "   Add these flags to your xcodebuild commands:"
echo "   -Xfrontend -enable-upcoming-feature StrictConcurrency"
echo "   -Xfrontend -enable-upcoming-feature GlobalActorIsolatedTypesUsability"
echo "   -Xfrontend -enable-upcoming-feature InferSendableFromCaptures"
echo ""
echo "2️⃣  **Update project settings in Xcode**"
echo "   - Open Food Scanner.xcodeproj in Xcode"
echo "   - Select the project in the navigator"
echo "   - Go to Build Settings"
echo "   - Search for 'Swift Language Version'"
echo "   - Change from 'Swift 5' to 'Swift 6'"
echo "   - Search for 'Swift Concurrency Checking'"
echo "   - Set to 'Complete' or 'Minimal'"
echo ""
echo "3️⃣  **Use the enhanced build script**"
echo "   Run: ./scripts/build-with-swift6-strict.sh"
echo ""

# Create enhanced build script
echo "📝 Creating enhanced build script with Swift 6 strict concurrency..."

cat > scripts/build-with-swift6-strict.sh << 'EOF'
#!/bin/bash

# Build with Swift 6 strict concurrency checking (matches CI)
set -euo pipefail

echo "🔧 Building with Swift 6 strict concurrency checking..."

# Swift 6 strict concurrency flags (matching CI)
SWIFT6_FLAGS=(
    "-Xfrontend" "-enable-upcoming-feature" "StrictConcurrency"
    "-Xfrontend" "-enable-upcoming-feature" "GlobalActorIsolatedTypesUsability"
    "-Xfrontend" "-enable-upcoming-feature" "InferSendableFromCaptures"
    "-Xfrontend" "-enable-upcoming-feature" "NonisolatedNonsendingByDefault"
    "-Xfrontend" "-enable-upcoming-feature" "InferIsolatedConformances"
    "-Xfrontend" "-enable-upcoming-feature" "DisableOutwardActorInference"
    "-Xfrontend" "-enable-upcoming-feature" "MemberImportVisibility"
)

# Build command with Swift 6 flags
xcodebuild build \
    -scheme "Food Scanner" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    "${SWIFT6_FLAGS[@]}" \
    "$@"

echo "✅ Build completed with Swift 6 strict concurrency checking"
EOF

chmod +x scripts/build-with-swift6-strict.sh

# Create enhanced test script
cat > scripts/test-with-swift6-strict.sh << 'EOF'
#!/bin/bash

# Test with Swift 6 strict concurrency checking (matches CI)
set -euo pipefail

echo "🧪 Testing with Swift 6 strict concurrency checking..."

# Swift 6 strict concurrency flags (matching CI)
SWIFT6_FLAGS=(
    "-Xfrontend" "-enable-upcoming-feature" "StrictConcurrency"
    "-Xfrontend" "-enable-upcoming-feature" "GlobalActorIsolatedTypesUsability"
    "-Xfrontend" "-enable-upcoming-feature" "InferSendableFromCaptures"
    "-Xfrontend" "-enable-upcoming-feature" "NonisolatedNonsendingByDefault"
    "-Xfrontend" "-enable-upcoming-feature" "InferIsolatedConformances"
    "-Xfrontend" "-enable-upcoming-feature" "DisableOutwardActorInference"
    "-Xfrontend" "-enable-upcoming-feature" "MemberImportVisibility"
)

# Test command with Swift 6 flags
xcodebuild test \
    -scheme "Food Scanner" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -testPlan "FoodScanner" \
    "${SWIFT6_FLAGS[@]}" \
    "$@"

echo "✅ Tests completed with Swift 6 strict concurrency checking"
EOF

chmod +x scripts/test-with-swift6-strict.sh

echo "✅ Enhanced build scripts created:"
echo "   📝 scripts/build-with-swift6-strict.sh"
echo "   📝 scripts/test-with-swift6-strict.sh"
echo ""
echo "🚀 Usage:"
echo "   Build: ./scripts/build-with-swift6-strict.sh"
echo "   Test:  ./scripts/test-with-swift6-strict.sh"
echo ""
echo "💡 These scripts use the same Swift 6 concurrency flags as CI,"
echo "   so you'll catch concurrency issues locally before they reach CI!"
