# Build Process

## 🏗️ Build Configuration

This document explains the build process and configuration for the Calry iOS app.

## 🎯 Build Overview

The Calry app uses a robust build system with offline mode support for reliable CI/CD pipelines.

### Key Features
- **Offline Mode**: No network dependencies during CI builds
- **Parallel Testing**: Efficient test execution
- **Caching**: Build artifact caching for performance
- **Error Handling**: Comprehensive error handling and retry logic

## 🔧 Build Configuration

### Xcode Project Settings
```swift
// Build Settings
SWIFT_VERSION = 6.2
IPHONEOS_DEPLOYMENT_TARGET = 26.0
MACOSX_DEPLOYMENT_TARGET = 26.0

// Code Signing
CODE_SIGN_IDENTITY = "iPhone Developer"
CODE_SIGN_STYLE = Automatic

// Build Configurations
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_BITCODE = NO
```

### Build Schemes
- **Calry**: Main app scheme
- **Calry Tests**: Test scheme
- **Calry UI Tests**: UI test scheme

## 🚀 Build Process

### 1. **Environment Setup**
```bash
# Check Xcode version
xcodebuild -version

# Check available simulators
xcrun simctl list devices

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 2. **Code Quality Checks**
```bash
# Run SwiftLint for code style enforcement
swiftlint

# Run SwiftFormat to check formatting (dry run)
swiftformat --dryrun .

# Apply SwiftFormat changes
swiftformat .
```

### 3. **Build Steps**
```bash
# Clean build
xcodebuild clean -scheme "Calry"

# Build for simulator (with warning filtering)
./scripts/build-without-appintents-warning.sh

# Or build directly
xcodebuild build -scheme "Calry" -destination "platform=iOS Simulator,name=iPhone 16"

# Build for device
xcodebuild build -scheme "Calry" -destination "generic/platform=iOS"
```

### 4. **Test Execution**
```bash
# Run unit tests
xcodebuild test -scheme "Calry" -destination "platform=iOS Simulator,name=iPhone 16" -testPlan "Calry"

# Run CI offline tests
xcodebuild test -scheme "Calry" -destination "platform=iOS Simulator,name=iPhone 16" -testPlan "Calry-CI-Offline"
```

## 🔧 Build Scripts

### Warning-Filtered Build Script
```bash
# scripts/build-without-appintents-warning.sh
# Filters out harmless AppIntents metadata extraction warnings

# Default build (iPhone 16 simulator)
./scripts/build-without-appintents-warning.sh

# Custom destination
./scripts/build-without-appintents-warning.sh "platform=iOS Simulator,name=iPhone 15 Pro"
```

### CI Test Runner
```bash
# scripts/ci-test-runner.sh
# Enhanced CI test runner with warning filtering and retry logic

# Run CI tests
./scripts/ci-test-runner.sh <simulator_udid> ./DerivedData
```

## 🔧 Code Quality Tools

### SwiftLint
SwiftLint enforces code style and conventions:

```bash
# Run SwiftLint
swiftlint

# Run SwiftLint with specific file
swiftlint Sources/Models/API/FDC/FDCNutrientModels.swift

# Run SwiftLint with auto-fix
swiftlint --fix
```

**Key Rules**:
- `number_separator`: Requires underscores for numbers >= 1,000
- `closure_body_length`: Limits closure body length
- `api_model_codable`: Ensures API models conform to `Codable`
- `model_complexity`: Prevents overly complex models

### SwiftFormat
SwiftFormat provides automatic code formatting:

```bash
# Check what would be formatted (dry run)
swiftformat --dryrun .

# Apply formatting
swiftformat .

# Format specific file
swiftformat Sources/Models/API/FDC/FDCNutrientModels.swift

# Check formatting (lint mode)
swiftformat --lint .
```

**Configuration**: The `numberFormatting` rule is disabled to prevent conflicts with SwiftLint's number separator requirements.

### Tool Integration
Both tools are configured to work together without conflicts:

```bash
# Complete code quality check
swiftlint && swiftformat --lint .
```

## 🧪 Test Plans

### Calry.xctestplan
**Full test coverage including network tests**
- Unit tests for all components
- Integration tests with real API calls
- UI tests for user interface flows
- Performance tests for critical paths

### Calry-CI-Offline.xctestplan
**CI-optimized offline test plan**
- Unit tests with mocked services
- Integration tests with mock data
- UI tests without network dependencies
- Fast execution for CI environments

## 🔧 Build Scripts

### CI Test Runner
```bash
#!/bin/bash
# ci-test-runner.sh

SIMULATOR_ID=$1
DERIVED_DATA_PATH=$2

# Set up simulator
xcrun simctl boot $SIMULATOR_ID
xcrun simctl install $SIMULATOR_ID /path/to/app

# Run tests
xcodebuild test \
  -scheme "Calry" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -testPlan "Calry-CI-Offline" \
  -derivedDataPath $DERIVED_DATA_PATH \
  -resultBundlePath ./TestResults.xcresult
```

### Simulator Manager
```bash
#!/bin/bash
# simulator-manager.sh

# Create simulator
xcrun simctl create "Calry Test" "iPhone 16" "iOS 26.0"

# Boot simulator
xcrun simctl boot "Calry Test"

# Install app
xcrun simctl install "Calry Test" /path/to/app

# Run tests
xcrun simctl launch "Calry Test" com.foodscanner.app
```

## 🚨 Error Handling

### Build Errors
```bash
# Common build errors and solutions
ERROR: "No such file or directory"
SOLUTION: Clean derived data and rebuild

ERROR: "Code signing error"
SOLUTION: Check provisioning profiles

ERROR: "Simulator not available"
SOLUTION: Reset simulator or create new one
```

### Test Failures
```bash
# Test failure handling
ERROR: "Test timeout"
SOLUTION: Increase timeout or optimize test

ERROR: "Network error"
SOLUTION: Use offline test plan

ERROR: "Permission denied"
SOLUTION: Grant camera permissions
```

## 📊 Performance Optimization

### Build Performance
- **Parallel builds**: Use multiple cores
- **Incremental builds**: Only rebuild changed files
- **Caching**: Cache build artifacts
- **Derived data**: Manage derived data efficiently

### Test Performance
- **Parallel testing**: Run tests concurrently
- **Test batching**: Group related tests
- **Mock services**: Use mocks for external dependencies
- **Selective testing**: Run only changed tests

## 🔧 CI/CD Integration

### GitHub Actions
```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Code Quality Check
        run: |
          swiftlint
          swiftformat --lint .
      
      - name: Build
        run: xcodebuild build -scheme "Calry"
      
      - name: Test
        run: xcodebuild test -scheme "Calry" -testPlan "Calry-CI-Offline"
```

### Security Scanning

#### CodeQL (Temporarily Disabled)
**Status**: CodeQL security scanning is currently disabled in our GitHub Actions workflow.

**Reason**: CodeQL does not yet support:
- **Xcode 26.0.0**: Latest Xcode version used in our project
- **Swift 6.2**: Latest Swift version with strict concurrency
- **iOS 26**: Latest iOS target deployment

**Alternative Security Measures**:
- **Dependency Scanning**: Automated dependency vulnerability scanning
- **Manual Code Review**: Comprehensive code review process
- **Static Analysis**: SwiftLint and SwiftFormat for code quality
- **Build Validation**: Comprehensive CI/CD pipeline with quality gates

**Re-enablement**: CodeQL will be re-enabled once GitHub Actions supports Xcode 26 and Swift 6.2.

### Local CI
```bash
# Run local CI
./scripts/ci-test-runner.sh <simulator_id> ./DerivedData

# Run with network tests
./scripts/test-local-network.sh
```

## 🎯 Best Practices

### 1. **Build Reliability**
- **Clean builds** when needed
- **Consistent environment** across builds
- **Proper error handling** and retry logic
- **Monitor build performance**

### 2. **Test Strategy**
- **Use appropriate test plans** for different environments
- **Mock external dependencies** in CI
- **Parallel test execution** for efficiency
- **Comprehensive test coverage**

### 3. **Performance**
- **Optimize build times** with caching
- **Use incremental builds** when possible
- **Monitor resource usage** during builds
- **Clean up** build artifacts regularly

This build process ensures reliable, efficient builds and testing for the Calry app.
