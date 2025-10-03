# Troubleshooting

## 🚨 Common Issues

This document provides solutions for common issues encountered during development and CI/CD of the Food Scanner app.

## 🔧 Local CI Environment Issues

### Setup Problems

#### "Xcode 26 not found"
**Symptoms**: Setup script fails to find Xcode 26
**Solutions**:
```bash
# Check Xcode version
xcodebuild -version

# Install Xcode 26.0.0 from Apple Developer Portal
# Verify installation
xcodebuild -version
```

#### "iOS 26 runtime not available"
**Symptoms**: Simulator creation fails
**Solutions**:
```bash
# Install iOS 26 runtime through Xcode
# Xcode → Settings → Platforms → iOS 26

# Or via command line
xcrun simctl runtime add "iOS 26"
```

#### "iPhone 16 simulator not found"
**Symptoms**: Test script fails to find simulator
**Solutions**:
```bash
# Create iPhone 16 simulator manually
xcrun simctl create "iPhone 16" "iPhone 16" "iOS 26"

# Or run setup script which creates it automatically
./scripts/setup-local-ci.sh
```

### Build Issues

#### "Build fails with concurrency errors locally but passes in CI"
**Symptoms**: Local build fails with Swift 6 concurrency errors
**Solutions**:
```bash
# Source CI environment variables
source .env.ci

# Run build with CI settings
./scripts/build-local-ci.sh
```

#### "Tests fail locally but pass in CI"
**Symptoms**: Local tests fail with different results than CI
**Solutions**:
```bash
# Use CI test plan
./scripts/test-local-ci.sh

# Check environment variables
echo $CI_OFFLINE_MODE
echo $NETWORK_TESTING_DISABLED
```

## 🏗️ Build Issues

### Build Failures

#### "No such file or directory"
**Symptoms**: Build fails with file not found errors
**Solutions**:
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean build folder
xcodebuild clean -scheme "Food Scanner"

# Reset package dependencies
rm -rf .build
xcodebuild -resolvePackageDependencies
```

#### "Code signing error"
**Symptoms**: Build fails with code signing issues
**Solutions**:
- Check provisioning profiles in Xcode
- Verify team settings
- Ensure certificates are valid
- Use automatic code signing

#### "Simulator not available"
**Symptoms**: Build fails because simulator is not found
**Solutions**:
```bash
# List available simulators
xcrun simctl list devices

# Create new simulator
xcrun simctl create "Food Scanner Test" "iPhone 16" "iOS 26.0"

# Reset simulator
xcrun simctl erase all
```

### Dependency Issues

#### "Package dependency resolution failed"
**Symptoms**: Swift Package Manager fails to resolve dependencies
**Solutions**:
```bash
# Clear package cache
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reset package dependencies
rm -rf .build
xcodebuild -resolvePackageDependencies

# Update packages
xcodebuild -scheme "Food Scanner" -resolvePackageDependencies
```

## 🧪 Test Issues

### Test Failures

#### "Test timeout"
**Symptoms**: Tests fail with timeout errors
**Solutions**:
- Increase test timeout in test plan
- Optimize slow tests
- Use mocks for external dependencies
- Check for infinite loops

#### "Network error in tests"
**Symptoms**: Tests fail due to network issues
**Solutions**:
- Use offline test plan for CI
- Mock network services
- Check network connectivity
- Use test-specific API endpoints

#### "Permission denied"
**Symptoms**: Tests fail due to permission issues
**Solutions**:
- Grant camera permissions in simulator
- Check privacy settings
- Use test-specific permission handling
- Reset simulator permissions

### Test Environment Issues

#### "Simulator state issues"
**Symptoms**: Tests fail due to simulator state
**Solutions**:
```bash
# Reset simulator
xcrun simctl erase all

# Restart simulator
xcrun simctl shutdown all
xcrun simctl boot "iPhone 16"

# Check simulator status
xcrun simctl list devices
```

#### "Test data issues"
**Symptoms**: Tests fail due to test data problems
**Solutions**:
- Use consistent test data
- Create reusable test fixtures
- Clean up test data after tests
- Use isolated test environments

## 🌐 Network Issues

### API Communication

#### "Network request failed"
**Symptoms**: API calls fail
**Solutions**:
- Check internet connectivity
- Verify API endpoint availability
- Check rate limiting
- Review request format

#### "Invalid response format"
**Symptoms**: API responses can't be parsed
**Solutions**:
- Check response format
- Verify data models
- Handle malformed responses
- Add response validation

#### "Rate limit exceeded"
**Symptoms**: API calls fail due to rate limiting
**Solutions**:
- Implement exponential backoff
- Cache responses
- Reduce request frequency
- Use offline mode when possible

### Proxy Service Issues

#### "Proxy service unavailable"
**Symptoms**: calry.org proxy service is down
**Solutions**:
- Check service status
- Use cached data
- Implement fallback mechanisms
- Monitor service health

#### "Proxy response errors"
**Symptoms**: Proxy service returns errors
**Solutions**:
- Check request format
- Verify authentication
- Review error responses
- Implement retry logic

## 🎨 UI Issues

### SwiftUI Problems

#### "View not updating"
**Symptoms**: UI doesn't reflect state changes
**Solutions**:
- Check @Observable implementation
- Verify state binding
- Check view hierarchy
- Use SwiftUI Inspector

#### "Layout issues"
**Symptoms**: UI elements not positioned correctly
**Solutions**:
- Check layout constraints
- Verify view hierarchy
- Use View Debugger
- Review SwiftUI layout system

#### "Performance issues"
**Symptoms**: UI is slow or unresponsive
**Solutions**:
- Profile with Instruments
- Check for expensive operations
- Optimize view updates
- Use lazy loading

### Camera Issues

#### "Camera not working"
**Symptoms**: Barcode scanner doesn't work
**Solutions**:
- Check camera permissions
- Verify simulator camera settings
- Test on real device
- Check VisionKit integration

#### "Barcode detection fails"
**Symptoms**: Barcodes not detected
**Solutions**:
- Check barcode format
- Verify camera focus
- Test with different barcodes
- Review detection settings

## 💾 Data Issues

### Database Problems

#### "Data not persisting"
**Symptoms**: Data doesn't save between app launches
**Solutions**:
- Check SwiftData configuration
- Verify model definitions
- Check save operations
- Review database schema

#### "Data corruption"
**Symptoms**: Data becomes corrupted
**Solutions**:
- Implement data validation
- Add data integrity checks
- Use proper error handling
- Implement data recovery

### Cache Issues

#### "Cache not working"
**Symptoms**: Cached data not retrieved
**Solutions**:
- Check cache configuration
- Verify cache keys
- Review cache expiration
- Check cache storage

#### "Stale cache data"
**Symptoms**: Cached data is outdated
**Solutions**:
- Implement cache invalidation
- Set appropriate TTL
- Check cache update logic
- Monitor cache freshness

## 🔧 Development Issues

### Xcode Problems

#### "Xcode crashes"
**Symptoms**: Xcode becomes unresponsive
**Solutions**:
- Restart Xcode
- Clear derived data
- Check Xcode version
- Report to Apple

#### "Build hangs"
**Symptoms**: Build process stops responding
**Solutions**:
- Cancel and restart build
- Clean build folder
- Check for infinite loops
- Monitor system resources

### Debugging Issues

#### "Breakpoints not working"
**Symptoms**: Breakpoints don't trigger
**Solutions**:
- Check debug configuration
- Verify breakpoint conditions
- Use symbolic breakpoints
- Check optimization settings

#### "Console not showing logs"
**Symptoms**: Print statements not visible
**Solutions**:
- Check console output
- Use proper logging levels
- Verify log configuration
- Check filter settings

## 🚀 CI/CD Issues

### Build Pipeline

#### "CI build fails"
**Symptoms**: Continuous integration fails
**Solutions**:
- Check build logs
- Verify environment setup
- Review build configuration
- Test locally first

#### "Test execution fails"
**Symptoms**: Tests fail in CI environment
**Solutions**:
- Use offline test plan
- Check test environment
- Verify test data
- Review test configuration

### Deployment Issues

#### "App not installing"
**Symptoms**: App fails to install on device
**Solutions**:
- Check provisioning profiles
- Verify device registration
- Check app permissions
- Review installation logs

#### "App crashes on launch"
**Symptoms**: App crashes immediately after launch
**Solutions**:
- Check crash logs
- Verify app configuration
- Review launch process
- Test on different devices

## 🔍 Debugging Tools

### Xcode Tools
- **Console**: View logs and debug output
- **View Debugger**: Inspect view hierarchy
- **Memory Graph**: Analyze memory usage
- **Instruments**: Profile performance

### Command Line Tools
```bash
# View device logs
xcrun simctl spawn booted log stream --predicate 'process == "Food Scanner"'

# Check simulator status
xcrun simctl list devices

# Reset simulator
xcrun simctl erase all

# Check Xcode version
xcodebuild -version
```

### Third-Party Tools
- **SwiftLint**: Code style checking
- **SwiftFormat**: Code formatting
- **Instruments**: Performance profiling
- **Network Monitor**: Network debugging

## 🔧 Code Quality Issues

### SwiftLint/SwiftFormat Conflicts

#### "UI Test Configuration Issues"
**Symptoms**: UI tests fail with "No target application path specified" error
**Root Cause**: UI test files incorrectly configured in project targets
**Solutions**:
```bash
# Check project configuration
# UI test files should be in FoodScannerUITests target, not FoodScannerTests

# Verify test target membership in Xcode:
# 1. Select UI test files in Tests/UI/
# 2. Check File Inspector
# 3. Ensure they're in FoodScannerUITests target only
```

#### "Duplicate Build File Warnings"
**Symptoms**: Build shows warnings about duplicate files in compile sources
**Root Cause**: Files included in multiple targets
**Solutions**:
```bash
# Check project.pbxproj for duplicate file references
# Remove files from incorrect targets
# Ensure UI tests are only in FoodScannerUITests target
```

#### "AppIntents metadata extraction warning"
**Symptoms**: Build shows warning about AppIntents framework dependency
**Solutions**:
```bash
# Use warning-filtered build script
./scripts/build-without-appintents-warning.sh

# Or filter manually
xcodebuild build 2>&1 | grep -v "appintentsmetadataprocessor.*warning: Metadata extraction skipped"
```

#### "Number formatting conflicts"
**Symptoms**: SwiftFormat removes underscores that SwiftLint requires
**Solutions**:
```bash
# Check SwiftFormat configuration
cat .swiftformat

# Ensure numberFormatting is disabled
echo "--disable numberFormatting" >> .swiftformat

# Verify no conflicts
swiftlint && swiftformat --lint .
```

#### "SwiftLint violations after SwiftFormat"
**Symptoms**: SwiftFormat changes violate SwiftLint rules
**Solutions**:
- Check SwiftFormat configuration
- Disable conflicting rules
- Run tools in correct order: SwiftLint first, then SwiftFormat
- Use `swiftformat --lint .` to check without applying changes

#### "Tool configuration issues"
**Symptoms**: Tools don't work as expected
**Solutions**:
```bash
# Check SwiftLint configuration
swiftlint --config .swiftlint.yml

# Check SwiftFormat configuration
swiftformat --rules

# Verify tool versions
swiftlint version
swiftformat --version
```

### Swift 6 Concurrency Issues

#### "Main actor-isolated default value in a nonisolated context"
**Symptoms**: Build fails with Swift 6 strict concurrency checking
**Root Cause**: Using `Date()` as default parameter in nonisolated context
**Solutions**:
```swift
// ❌ Problematic
nonisolated static func create(at date: Date = Date()) -> MyType

// ✅ Fixed
nonisolated static func create(at date: Date = .now) -> MyType
```

#### "Call to main actor-isolated static method in a synchronous nonisolated context"
**Symptoms**: Build fails when calling main actor-isolated methods from nonisolated contexts
**Root Cause**: Missing `nonisolated` annotation on static methods
**Solutions**:
```swift
// ❌ Problematic
static func from(data: Data) -> MyType {
    // Main actor-isolated code
}

// ✅ Fixed
nonisolated static func from(data: Data) -> MyType {
    // Main actor-isolated code
}
```

#### "Sending 'self' risks causing data races"
**Symptoms**: UI tests fail with data race warnings
**Root Cause**: Capturing `self` in `MainActor.assumeIsolated` closures
**Solutions**:
```swift
// ❌ Problematic
func testMethod() {
    MainActor.assumeIsolated {
        self.app.tap()  // Captures self
    }
}

// ✅ Fixed
@MainActor
func testMethod() {
    app.tap()  // No self capture needed
}
```

#### "Local tests pass but CI fails"
**Symptoms**: Tests work locally but fail in CI with concurrency errors
**Root Cause**: Different Swift concurrency checking levels
**Solutions**:
```bash
# Test locally with CI settings
./scripts/test-with-swift6-strict.sh

# Or manually with xcodebuild
xcodebuild test \
    -scheme "Food Scanner" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    SWIFT_STRICT_CONCURRENCY=complete \
    OTHER_SWIFT_FLAGS='-warnings-as-errors'
```

## 📞 Getting Help

### Documentation
- **Check relevant** documentation first
- **Search for** similar issues
- **Review code** examples

### Community
- **Ask questions** on relevant forums
- **Search existing** issues
- **Contribute solutions** to help others

### Professional Support
- **Apple Developer** support
- **Xcode documentation**
- **Swift community** resources

This troubleshooting guide provides solutions for common issues encountered during Food Scanner app development and deployment.
