# Development Documentation

This directory contains comprehensive guides and documentation for local development setup, ensuring consistency with the CI environment.

## 📚 Documentation Overview

| Document | Purpose | Audience |
|----------|---------|----------|
| [local-ci-setup.md](local-ci-setup.md) | Complete guide to set up local environment matching CI | All developers |
| [coding-standards.md](coding-standards.md) | Code style, patterns, and best practices | All developers |
| [testing.md](testing.md) | Testing strategies and guidelines | All developers |
| [debugging.md](debugging.md) | Debugging techniques and tools | All developers |

## 🚀 Quick Start

### 1. Initial Setup
```bash
# Run the automated setup script
./scripts/setup-local-ci.sh
```

### 2. Verify Environment
```bash
# Source CI environment variables
source .env.ci

# Run all CI-equivalent checks
./scripts/build-local-ci.sh && ./scripts/test-local-ci.sh && ./scripts/lint-local-ci.sh
```

### 3. Development Workflow
```bash
# Before committing changes
./scripts/build-local-ci.sh    # Build with CI settings
./scripts/test-local-ci.sh     # Test with CI settings  
./scripts/lint-local-ci.sh     # Lint with CI settings
```

## 🛠️ Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup-local-ci.sh` | Environment setup and verification | `./scripts/setup-local-ci.sh` |
| `build-local-ci.sh` | Build with CI-equivalent settings | `./scripts/build-local-ci.sh` |
| `test-local-ci.sh` | Test with CI-equivalent settings | `./scripts/test-local-ci.sh` |
| `lint-local-ci.sh` | Lint with CI-equivalent settings | `./scripts/lint-local-ci.sh` |

## 🔧 Environment Requirements

### System Requirements
- **macOS**: Sequoia 15.6 or later
- **Xcode**: Version 26.0.0 (matches CI exactly)
- **iOS Simulator**: iOS 26 runtime with iPhone 16 device type

### Tools Required
- **SwiftLint**: Code style checking
- **SwiftFormat**: Code formatting
- **Homebrew**: Package manager (for tool installation)

## 📋 Development Checklist

### Before Starting Development
- [ ] Run `./scripts/setup-local-ci.sh` to configure environment
- [ ] Verify all tools are installed and working
- [ ] Source environment variables: `source .env.ci`
- [ ] Run initial build: `./scripts/build-local-ci.sh`

### Before Committing Changes
- [ ] Run build script: `./scripts/build-local-ci.sh`
- [ ] Run test script: `./scripts/test-local-ci.sh`
- [ ] Run lint script: `./scripts/lint-local-ci.sh`
- [ ] Ensure all checks pass with CI-equivalent settings

### Before Pushing to CI
- [ ] Run full CI simulation: All scripts in sequence
- [ ] Verify no concurrency warnings
- [ ] Check that tests pass with strict concurrency
- [ ] Ensure linting passes with zero violations

## 🐛 Troubleshooting

### Common Issues

1. **"Xcode 26 not found"**
   - Install Xcode 26.0.0 from Apple Developer Portal
   - Verify with `xcodebuild -version`

2. **"iOS 26 runtime not available"**
   - Install through Xcode → Settings → Platforms
   - Or use `xcrun simctl runtime add "iOS 26"`

3. **"Build fails with concurrency errors"**
   - This is expected! Fix the concurrency issues
   - Use `MainActor.run` for cross-actor access
   - Check the main-actor isolation guide

4. **"Tests fail locally but pass in CI"**
   - Ensure you're using the same test plan: `Calry-CI-Offline`
   - Check environment variables are set correctly
   - Verify simulator is properly configured

### Getting Help

1. **Check the logs**: Scripts create detailed logs in `/tmp/`
2. **Review CI configuration**: See `.github/workflows/ci.yml`
3. **Compare with CI**: Run the same commands CI uses
4. **Check documentation**: Each script has detailed help

## 📊 CI Environment Details

### Build Settings
- `SWIFT_STRICT_CONCURRENCY=complete`
- `OTHER_SWIFT_FLAGS='-warnings-as-errors'`
- `DEFAULT_ISOLATION=MainActor`
- `CODE_SIGNING_ALLOWED=NO`
- `ENABLE_PREVIEWS=NO`

### Test Configuration
- Test Plan: `Calry-CI-Offline`
- Destination: iPhone 16 simulator
- Parallel testing: Disabled
- UI tests: Skipped
- Timeouts: 30s default, 60s maximum

### Linting Configuration
- SwiftFormat: Lint mode on Sources and Tests
- SwiftLint: Strict mode with zero violations allowed

## 🔄 Integration with IDEs

### Xcode Integration
1. Add build phases to run scripts
2. Configure scheme environment variables
3. Set up breakpoints for debugging

### VS Code Integration
1. Add tasks for script execution
2. Configure launch configurations
3. Set up debugging profiles

### Terminal Integration
1. Add aliases for quick access
2. Configure shell environment
3. Set up pre-commit hooks

## 📈 Performance Tips

### Build Performance
- Use derived data caching: `./DerivedData`
- Enable parallel compilation in Xcode
- Clean derived data regularly

### Test Performance
- Skip UI tests during development
- Use parallel testing for faster iteration
- Monitor test execution times

### Development Workflow
- Run scripts in background when possible
- Use incremental builds
- Cache simulator state

## 🎯 Best Practices

### Code Quality
- Follow coding standards in `coding-standards.md`
- Use consistent formatting with SwiftFormat
- Maintain zero linting violations

### Testing
- Write comprehensive unit tests
- Test with CI-equivalent settings
- Maintain high test coverage

### Debugging
- Use debugging techniques from `debugging.md`
- Monitor CI logs for issues
- Test locally before pushing

## 📚 Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift 6 Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Xcode 26 Release Notes](https://developer.apple.com/documentation/xcode-release-notes)
- [iOS 26 Simulator Documentation](https://developer.apple.com/documentation/xcode/simulator)

---

*This documentation ensures your local development environment matches the CI environment exactly, helping you catch issues early and maintain consistent builds.*