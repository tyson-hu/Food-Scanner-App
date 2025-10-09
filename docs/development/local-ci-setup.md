# Local Development Environment Setup Guide

## 🎯 Overview

This guide helps you set up your local development environment to match the CI environment exactly, ensuring consistent builds and catching issues early.

## 📋 Prerequisites

### System Requirements
- **macOS**: Sequoia 15.6 or later (required for Xcode 26)
- **Xcode**: Version 26.0.0 (matches CI exactly)
- **iOS Simulator**: iOS 26 runtime with iPhone 16 device type

### Hardware Requirements
- **RAM**: 16GB minimum (CI uses 16GB)
- **Storage**: 50GB free space for Xcode, simulators, and derived data
- **CPU**: Apple Silicon (M1/M2/M3) or Intel with 8+ cores

## 🛠️ Installation Steps

### 1. Install Xcode 26.0.0

```bash
# Download from Apple Developer Portal
# https://developer.apple.com/xcode/

# Verify installation
xcodebuild -version
# Expected output: Xcode 26.0.0

# Accept license
sudo xcodebuild -license accept
```

### 2. Install iOS 26 Simulator Runtime

```bash
# List available runtimes
xcrun simctl list runtimes

# Install iOS 26 runtime (if not already installed)
# This is done through Xcode > Settings > Platforms > iOS 26
# Or via command line:
xcrun simctl runtime add "iOS 26"
```

### 3. Install Required Tools

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install SwiftLint and SwiftFormat
brew install swiftlint swiftformat

# Verify installations
swiftlint version
swiftformat --version
```

## ⚙️ Project Configuration

### 1. Build Settings Configuration

Create a script to apply CI-equivalent build settings:

```bash
#!/bin/bash
# scripts/setup-local-ci.sh

echo "🔧 Setting up local environment to match CI..."

# Set build settings to match CI
xcodebuild -project "Calry.xcodeproj" \
    -scheme "Calry" \
    -configuration Debug \
    -showBuildSettings | grep -E "(SWIFT_STRICT_CONCURRENCY|DEFAULT_ISOLATION|OTHER_SWIFT_FLAGS)"

echo "✅ Build settings verification complete"
```

### 2. Xcode Scheme Configuration

1. **Open Xcode** and select your project
2. **Edit Scheme** (Product → Scheme → Edit Scheme...)
3. **Run Tab** → **Arguments** → **Environment Variables**:
   ```
   CI_OFFLINE_MODE = YES
   NETWORK_TESTING_DISABLED = YES
   ENABLE_PREVIEWS = NO
   ```
4. **Test Tab** → **Arguments** → **Environment Variables**:
   ```
   CI_OFFLINE_MODE = YES
   NETWORK_TESTING_DISABLED = YES
   ENABLE_PREVIEWS = NO
   ```

### 3. Build Settings in Xcode

Navigate to **Project Settings** → **Build Settings** and ensure:

| Setting | Value | Purpose |
|---------|-------|---------|
| `SWIFT_STRICT_CONCURRENCY` | `complete` | Enforce strict concurrency checks |
| `OTHER_SWIFT_FLAGS` | `-warnings-as-errors` | Treat warnings as errors |
| `DEFAULT_ISOLATION` | `MainActor` | Default actor isolation |
| `CODE_SIGNING_ALLOWED` | `NO` | Disable code signing for CI compatibility |

## 🧪 Testing Setup

### 1. Create Local Test Script

```bash
#!/bin/bash
# scripts/test-local-ci.sh

set -euo pipefail

echo "🧪 Running tests with CI-equivalent settings..."

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Calry-*

# Create iPhone 16 simulator if it doesn't exist
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16" | grep "Booted" | head -1 | grep -o '[A-F0-9-]\{36\}' || echo "")

if [ -z "$SIMULATOR_ID" ]; then
    echo "📱 Creating iPhone 16 simulator..."
    SIMULATOR_ID=$(xcrun simctl create "CI-iPhone-16" "iPhone 16" "iOS 26")
    xcrun simctl boot "$SIMULATOR_ID"
    sleep 10
fi

echo "📱 Using simulator: $SIMULATOR_ID"

# Run tests with CI settings
xcodebuild test \
    -scheme "Calry" \
    -testPlan "Calry-CI-Offline" \
    -destination "id=$SIMULATOR_ID" \
    -destination-timeout 60 \
    -derivedDataPath "./DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_PREVIEWS=NO \
    SWIFT_STRICT_CONCURRENCY=complete \
    OTHER_SWIFT_FLAGS='-warnings-as-errors' \
    CI_OFFLINE_MODE=YES \
    NETWORK_TESTING_DISABLED=YES \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    -disableAutomaticPackageResolution \
    -skip-testing:CalryUITests \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 30 \
    -maximum-test-execution-time-allowance 60 \
    2>&1 | grep -v "appintentsmetadataprocessor.*warning: Metadata extraction skipped"

echo "✅ Tests completed successfully"
```

### 2. Create Build Script

```bash
#!/bin/bash
# scripts/build-local-ci.sh

set -euo pipefail

echo "🔨 Building with CI-equivalent settings..."

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Calry-*

# Build with CI settings
xcodebuild build \
    -scheme "Calry" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -derivedDataPath "./DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_PREVIEWS=NO \
    SWIFT_STRICT_CONCURRENCY=complete \
    OTHER_SWIFT_FLAGS='-warnings-as-errors' \
    CI_OFFLINE_MODE=YES \
    NETWORK_TESTING_DISABLED=YES \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    -disableAutomaticPackageResolution

echo "✅ Build completed successfully"
```

### 3. Create Linting Script

```bash
#!/bin/bash
# scripts/lint-local-ci.sh

set -euo pipefail

echo "🔍 Running linting with CI-equivalent settings..."

# SwiftFormat (lint only)
echo "📝 Running SwiftFormat..."
swiftformat --lint Sources
swiftformat --lint Tests

# SwiftLint (strict mode)
echo "📝 Running SwiftLint..."
swiftlint --strict

echo "✅ Linting completed successfully"
```

## 🚀 Quick Start Commands

Make the scripts executable and run them:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run all CI-equivalent checks
./scripts/build-local-ci.sh && ./scripts/test-local-ci.sh && ./scripts/lint-local-ci.sh

# Or run individually
./scripts/build-local-ci.sh    # Build only
./scripts/test-local-ci.sh     # Test only
./scripts/lint-local-ci.sh     # Lint only
```

## 🔧 Environment Variables

Set these environment variables in your shell profile (`~/.zshrc` or `~/.bash_profile`):

```bash
# CI Environment Variables
export CI_OFFLINE_MODE=YES
export NETWORK_TESTING_DISABLED=YES
export ENABLE_PREVIEWS=NO

# Xcode Settings
export SWIFT_STRICT_CONCURRENCY=complete
export OTHER_SWIFT_FLAGS='-warnings-as-errors'
export DEFAULT_ISOLATION=MainActor
```

## 📊 Verification Checklist

- [ ] Xcode 26.0.0 installed and licensed
- [ ] iOS 26 simulator runtime installed
- [ ] iPhone 16 simulator device available
- [ ] SwiftLint and SwiftFormat installed
- [ ] Build settings configured
- [ ] Environment variables set
- [ ] Scripts created and executable
- [ ] Local build succeeds
- [ ] Local tests pass
- [ ] Local linting passes

## 🐛 Troubleshooting

### Common Issues

1. **"Xcode 26 not found"**
   - Ensure Xcode 26.0.0 is installed from Apple Developer Portal
   - Check `xcodebuild -version` output

2. **"iOS 26 runtime not available"**
   - Install through Xcode → Settings → Platforms
   - Or use `xcrun simctl runtime add "iOS 26"`

3. **"iPhone 16 simulator not found"**
   - Create manually: `xcrun simctl create "iPhone 16" "iPhone 16" "iOS 26"`
   - Or use the test script which creates it automatically

4. **"Build fails with concurrency errors"**
   - This is expected! Fix the concurrency issues to match CI behavior
   - Use `MainActor.run` for cross-actor access

5. **"Tests fail locally but pass in CI"**
   - Ensure you're using the same test plan: `Calry-CI-Offline`
   - Check environment variables are set correctly

### Performance Tips

1. **Use DerivedData caching**:
   ```bash
   # Set custom derived data path
   export DERIVED_DATA_PATH="./DerivedData"
   ```

2. **Parallel testing** (for faster local development):
   ```bash
   # Enable parallel testing for local development
   -parallel-testing-enabled YES
   -maximum-concurrent-test-simulator-destinations 4
   ```

3. **Skip UI tests** (for faster iteration):
   ```bash
   # Skip UI tests during development
   -skip-testing:CalryUITests
   ```

## 📚 Additional Resources

- [Xcode 26 Release Notes](https://developer.apple.com/documentation/xcode-release-notes)
- [Swift 6 Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [iOS 26 Simulator Documentation](https://developer.apple.com/documentation/xcode/simulator)
- [CI Configuration Reference](.github/workflows/ci.yml)

## 🎯 Next Steps

1. **Set up the environment** using this guide
2. **Run the verification checklist** to ensure everything works
3. **Integrate into your workflow** by running CI-equivalent checks before commits
4. **Customize scripts** based on your specific development needs
5. **Monitor CI logs** to ensure local and CI environments stay in sync

---

*This guide ensures your local development environment matches the CI environment exactly, helping you catch issues early and maintain consistent builds.*
