# Local CI Scripts

This directory contains scripts to replicate the CI environment locally, ensuring consistent builds and catching issues early.

## 📁 Scripts Overview

| Script | Purpose | CI Equivalent |
|--------|---------|---------------|
| `setup-local-ci.sh` | Initial environment setup and verification | CI environment setup |
| `build-local-ci.sh` | Build with CI-equivalent settings | CI build step |
| `test-local-ci.sh` | Run tests with CI-equivalent settings | CI test step |
| `lint-local-ci.sh` | Run linting with CI-equivalent settings | CI lint step |

## 🚀 Quick Start

### 1. Initial Setup
```bash
# Run the setup script to configure your environment
./scripts/setup-local-ci.sh
```

### 2. Run All CI Checks
```bash
# Build, test, and lint (in sequence)
./scripts/build-local-ci.sh && ./scripts/test-local-ci.sh && ./scripts/lint-local-ci.sh
```

### 3. Individual Commands
```bash
# Build only
./scripts/build-local-ci.sh

# Test only  
./scripts/test-local-ci.sh

# Lint only
./scripts/lint-local-ci.sh
```

## 🔧 Script Details

### `setup-local-ci.sh`
**Purpose**: Initial environment setup and verification

**What it does**:
- Checks Xcode 26.0.0 installation
- Verifies iOS 26 runtime availability
- Creates iPhone 16 simulator if needed
- Checks required tools (SwiftLint, SwiftFormat)
- Validates build settings
- Creates `.env.ci` file with CI environment variables

**Usage**:
```bash
./scripts/setup-local-ci.sh
```

**Output**:
- ✅ Success indicators for each check
- ⚠️ Warnings for non-critical issues
- ❌ Errors for critical failures

### `build-local-ci.sh`
**Purpose**: Build project with CI-equivalent settings

**What it does**:
- Cleans derived data
- Checks/creates iPhone 16 simulator
- Builds with strict concurrency enabled
- Uses warnings-as-errors
- Applies CI environment variables

**Usage**:
```bash
./scripts/build-local-ci.sh
```

**CI Settings Applied**:
- `SWIFT_STRICT_CONCURRENCY=complete`
- `OTHER_SWIFT_FLAGS='-warnings-as-errors'`
- `CODE_SIGNING_ALLOWED=NO`
- `ENABLE_PREVIEWS=NO`
- `CI_OFFLINE_MODE=YES`
- `NETWORK_TESTING_DISABLED=YES`

### `test-local-ci.sh`
**Purpose**: Run tests with CI-equivalent settings

**What it does**:
- Cleans derived data
- Sets up iPhone 16 simulator
- Grants necessary permissions
- Runs `Calry-CI-Offline` test plan
- Skips UI tests (for faster execution)
- Uses strict concurrency settings

**Usage**:
```bash
./scripts/test-local-ci.sh
```

**Test Configuration**:
- Test Plan: `Calry-CI-Offline`
- Destination: iPhone 16 simulator
- Parallel testing: Disabled
- UI tests: Skipped
- Timeouts: 30s default, 60s maximum

### `lint-local-ci.sh`
**Purpose**: Run linting with CI-equivalent settings

**What it does**:
- Checks tool availability
- Runs SwiftFormat lint on Sources and Tests
- Runs SwiftLint in strict mode
- Provides violation summary

**Usage**:
```bash
./scripts/lint-local-ci.sh
```

**Linting Tools**:
- SwiftFormat: Code formatting validation
- SwiftLint: Code style and quality checks

## 🛠️ Environment Variables

The scripts use these environment variables (set in `.env.ci`):

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

To use these variables:
```bash
source .env.ci
```

## 📊 Expected Results

### Build Success
- ✅ Compilation without errors
- ✅ No concurrency warnings
- ✅ No code signing issues
- ✅ Derived data in `./DerivedData`

### Test Success
- ✅ All unit tests pass
- ✅ ~78 tests in 11 suites
- ✅ No UI test failures
- ✅ Tests complete in <5 minutes

### Lint Success
- ✅ SwiftFormat: 0 files require formatting
- ✅ SwiftLint: 0 violations
- ✅ Code style compliance

## 🐛 Troubleshooting

### Common Issues

1. **"Xcode 26 not found"**
   ```bash
   # Check Xcode version
   xcodebuild -version
   
   # Install Xcode 26.0.0 from Apple Developer Portal
   ```

2. **"iOS 26 runtime not available"**
   ```bash
   # Install through Xcode → Settings → Platforms
   # Or check available runtimes
   xcrun simctl list runtimes
   ```

3. **"iPhone 16 simulator not found"**
   ```bash
   # The script will create it automatically
   # Or create manually:
   xcrun simctl create "iPhone 16" "iPhone 16" "iOS 26"
   ```

4. **"SwiftLint/SwiftFormat not found"**
   ```bash
   # Install via Homebrew
   brew install swiftlint swiftformat
   ```

5. **"Build fails with concurrency errors"**
   - This is expected! Fix the concurrency issues
   - Use `MainActor.run` for cross-actor access
   - Check the main-actor isolation guide

### Debug Mode

Run scripts with debug output:
```bash
# Enable bash debug mode
set -x
./scripts/build-local-ci.sh
set +x
```

### Log Files

Scripts create temporary log files:
- Build logs: `/tmp/xcodebuild_*.log`
- Test logs: `/tmp/xcodebuild_test.log`
- Debug logs: `/tmp/xcodebuild_debug.log`

## 🔄 Integration with Development Workflow

### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run CI-equivalent checks
./scripts/build-local-ci.sh && ./scripts/test-local-ci.sh && ./scripts/lint-local-ci.sh
```

### IDE Integration
- **Xcode**: Add build phases to run scripts
- **VS Code**: Add tasks to run scripts
- **Terminal**: Use aliases for quick access

### CI Verification
Before pushing to CI:
```bash
# Run full CI simulation
./scripts/setup-local-ci.sh
./scripts/build-local-ci.sh
./scripts/test-local-ci.sh
./scripts/lint-local-ci.sh
```

## 📚 Additional Resources

- [Local CI Setup Guide](../docs/development/local-ci-setup.md)
- [CI Configuration](../../.github/workflows/ci.yml)
- [Xcode 26 Documentation](https://developer.apple.com/documentation/xcode-release-notes)
- [Swift 6 Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

## 🤝 Contributing

When modifying these scripts:
1. Test with both success and failure scenarios
2. Update documentation if behavior changes
3. Ensure scripts work on both Intel and Apple Silicon Macs
4. Verify compatibility with different Xcode versions

---

*These scripts ensure your local development environment matches the CI environment exactly, helping you catch issues early and maintain consistent builds.*
