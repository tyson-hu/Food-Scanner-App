#!/bin/bash

# Build with Swift 6 strict concurrency checking (matches CI)
set -euo pipefail

echo "🔧 Building with Swift 6 strict concurrency checking..."

# Swift 6 strict concurrency flags (matching CI)
SWIFT6_FLAGS=(
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG STRICT_CONCURRENCY"
    "SWIFT_UPCOMING_FEATURE_STRICT_CONCURRENCY=YES"
    "SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY=YES"
    "SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES=YES"
    "SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT=YES"
    "SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES=YES"
    "SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_INFERENCE=YES"
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY=YES"
)

# Build command with Swift 6 flags
xcodebuild build \
    -scheme "Food Scanner" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    "${SWIFT6_FLAGS[@]}" \
    "$@"

echo "✅ Build completed with Swift 6 strict concurrency checking"
