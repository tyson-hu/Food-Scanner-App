# Development Guide

This guide provides comprehensive information for developers working on the Food Scanner iOS app, including setup, workflows, testing, and best practices.

## 🚀 Quick Start

### Prerequisites
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0 or later
- **Swift**: 5.9 or later
- **macOS**: 13.0 or later (for development)

### Setup
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd "Food Scanner"
   ```

2. **Open in Xcode**:
   ```bash
   open "Food Scanner.xcodeproj"
   ```

3. **No API Key Required**:
   - The app uses the calry.org proxy service without authentication
   - No additional configuration needed

4. **Run the app**:
   - Select iPhone simulator or device
   - Press Cmd+R to build and run

## 🌐 Multi-Source Data Support

The Food Scanner app now supports multiple data sources through a unified proxy API:

### Supported Data Sources
- **FDC (Food Data Central)**: USDA's comprehensive food database
- **DSLD (Dietary Supplement Label Database)**: NIH's supplement database
- **DSID (Dietary Supplement Ingredient Database)**: Future support planned
- **OFF (Open Food Facts)**: Community-driven food database (future support)

### Global ID (GID) System
All food items are identified using GIDs with source prefixes:
- `fdc:12345` - FDC food item
- `dsld:67890` - DSLD supplement item
- `dsid:11111` - DSID supplement ingredient (future)
- `off:22222` - Open Food Facts item (future)

### Product Support Detection
The app automatically determines product support status:
- **Supported**: FDC and DSLD items with detailed nutrition information
- **Unsupported**: DSID and OFF items with limited data
- **Unknown**: Items with unrecognized source prefixes

### DSLD Integration Features
- **Data Validation**: Comprehensive validation for DSLD data quality
- **Debugging Tools**: Detailed logging for DSLD API responses
- **Error Handling**: User-friendly messages for empty or invalid DSLD data
- **Source Detection**: Automatic identification of DSLD products

## 🏗️ Project Structure

```
Food Scanner/
├── App/                        # App-level configuration
│   ├── FoodScannerApp.swift   # Main app entry point
│   ├── RootView.swift         # Root view controller
│   ├── AppEnvironment.swift   # Dependency injection
│   └── AppTab.swift           # Tab bar configuration
├── Models/                     # Data models
│   ├── FDCModels.swift        # Main model imports
│   ├── FDCPublicModels.swift  # Public API models
│   ├── FDCProxyModels.swift   # Proxy API models
│   ├── FDCFoodDetailModels.swift # Food detail models
│   ├── FDCNutrientModels.swift # Nutrient models
│   ├── FDCUtilityModels.swift # Utility types
│   ├── FDCLegacyModels.swift  # Legacy compatibility
│   └── FDCConversionExtensions.swift # Model conversions
├── Services/                   # Business logic services
│   ├── Networking/            # Network layer
│   │   ├── FDCClient.swift    # Base API client
│   │   ├── FDCProxyClient.swift # Proxy API client
│   │   └── FDCCachedClient.swift # Cached client
│   ├── Caching/               # Caching layer
│   │   └── FDCCacheService.swift # Cache implementation
│   ├── Images/                # Image handling
│   └── Persistence/           # Data persistence
├── ViewModels/                # MVVM view models
│   ├── AddFood/              # Add food flow
│   └── Today/                # Today view
├── Views/                     # SwiftUI views
│   ├── AddFood/              # Add food screens
│   ├── Scanner/              # Barcode scanning
│   ├── Today/                # Today view
│   ├── Settings/             # Settings screens
│   └── Design/               # Design system
├── Resources/                 # App resources
│   ├── Assets.xcassets       # Images and colors
│   └── Samples/              # Sample data
├── Config/                    # Configuration files
│   ├── Config.Debug.xcconfig # Debug configuration
│   └── Config.Release.xcconfig # Release configuration
└── Utilities/                 # Utility functions
    ├── DataNormalization.swift # Data processing
    └── ProductSourceDetection.swift # Multi-source product detection
```

## 🧪 Testing

### Test Structure
```
FoodScannerTests/
├── AddFood/                   # Add food flow tests
├── Networking/                # Network layer tests
├── Scanner/                   # Barcode scanning tests
├── Utilities/                 # Utility function tests
└── FoodScannerTests.swift    # Main test file
```

### Running Tests

#### Local Development (Full Testing)
```bash
# Run all tests including network tests
./scripts/test-local-network.sh

# Or run specific test plan
xcodebuild test -scheme "Food Scanner" -testPlan "FoodScanner" -destination "platform=iOS Simulator,name=iPhone 16"
```

#### CI Environment (Offline Mode)
```bash
# Run offline tests (no network dependencies)
./scripts/ci-test-runner.sh <simulator_id> ./DerivedData
```

### Test Plans
- **FoodScanner.xctestplan**: Full test coverage including network tests
- **FoodScanner-CI-Offline.xctestplan**: CI-optimized offline test plan

### Test Categories
- **Unit Tests**: Individual component testing with mocks
- **Integration Tests**: Network-dependent tests (local only)
- **UI Tests**: User interface testing (disabled in CI)

## 🔧 Development Workflow

### Feature Development
1. **Create feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Implement changes**:
   - Follow existing code patterns
   - Add appropriate tests
   - Update documentation if needed

3. **Test locally**:
   ```bash
   # Run full test suite
   ./scripts/test-local-network.sh
   
   # Run specific tests
   xcodebuild test -scheme "Food Scanner" -only-testing:FoodScannerTests/YourTestClass
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   git push origin feature/your-feature-name
   ```

5. **Create pull request**:
   - CI will automatically run offline tests
   - Review will include code quality checks

### Bug Fixes
1. **Create bug fix branch**:
   ```bash
   git checkout -b fix/your-bug-description
   ```

2. **Reproduce and fix**:
   - Add test case for the bug
   - Implement the fix
   - Verify fix with tests

3. **Test thoroughly**:
   - Run full test suite
   - Test edge cases
   - Verify no regressions

### Code Review Process
1. **Self-review**:
   - Check code quality and patterns
   - Ensure tests are comprehensive
   - Verify documentation is updated

2. **Peer review**:
   - Request review from team members
   - Address feedback promptly
   - Ensure CI passes

3. **Merge**:
   - Squash commits if needed
   - Merge to main branch
   - Delete feature branch

## 📝 Code Standards

### Swift Style
- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Prefer `let` over `var` when possible
- Use guard statements for early returns
- Implement proper error handling

### Architecture Patterns
- **MVVM**: Use ViewModels for business logic
- **Dependency Injection**: Use AppEnvironment for dependencies
- **Protocol-Oriented**: Define protocols for testability
- **Error Handling**: Use Result types and proper error propagation

### File Organization
- Keep files focused and single-purpose
- Use extensions for protocol conformance
- Group related functionality together
- Maintain clear separation of concerns

### Documentation
- Document public APIs with DocC comments
- Use meaningful commit messages
- Update README files for significant changes
- Maintain inline code comments for complex logic

## 🔍 Debugging

### Common Issues

#### Build Failures
- **Check**: Xcode version and iOS deployment target
- **Solution**: Update to latest Xcode and iOS SDK
- **Debug**: Review build logs for specific errors

#### Test Failures
- **Check**: Test plan configuration and environment
- **Solution**: Use appropriate test plan for environment
- **Debug**: Run tests individually to isolate issues

#### API Issues
- **Check**: Network connectivity and proxy service availability
- **Solution**: Verify proxy service connectivity and rate limiting
- **Debug**: Use mock data and check error logs

#### Simulator Issues
- **Check**: Simulator state and health
- **Solution**: Reset simulator or create new one
- **Debug**: Use simulator management scripts

### Debug Tools
```bash
# Check simulator status
xcrun simctl list devices

# Reset simulator
xcrun simctl erase all

# Check API connectivity
curl -I https://api.calry.org

# Run specific tests
xcodebuild test -scheme "Food Scanner" -only-testing:FoodScannerTests/YourTestClass

# Check build settings
xcodebuild -showBuildSettings -scheme "Food Scanner"
```

## 🚀 Performance

### Optimization Guidelines
1. **Use caching** for frequently accessed data
2. **Implement lazy loading** for large datasets
3. **Optimize images** and use appropriate formats
4. **Profile memory usage** regularly
5. **Test on older devices** for performance validation

### Monitoring
- **Memory Usage**: Monitor with Xcode Instruments
- **Network Requests**: Use network debugging tools
- **Cache Performance**: Track hit/miss ratios
- **Build Times**: Monitor CI build performance

## 🔒 Security

### Best Practices
1. **Configuration**: No sensitive data required - uses proxy service
2. **Data Validation**: Validate all user inputs
3. **Network Security**: Use HTTPS for all API calls
4. **Error Handling**: Don't expose sensitive information in errors
5. **Code Review**: Security-focused code reviews

### Configuration
- **Configuration**: No sensitive data required - app uses proxy service without authentication
- **Environment**: Separate configurations for debug/release
- **Validation**: Implement proper input validation
- **Sanitization**: Sanitize user inputs before processing

## 📚 Resources

### Documentation
- **Project Docs**: `/docs/` directory
- **API Docs**: `/docs/api/` directory
- **CI Docs**: `/docs/ci/` directory
- **Testing Docs**: `/docs/testing/` directory

### External Resources
- **Swift Documentation**: [developer.apple.com/swift](https://developer.apple.com/swift)
- **SwiftUI Guide**: [developer.apple.com/swiftui](https://developer.apple.com/swiftui)
- **FDC API**: [fdc.nal.usda.gov](https://fdc.nal.usda.gov)
- **iOS Human Interface Guidelines**: [developer.apple.com/design](https://developer.apple.com/design)

### Tools
- **Xcode**: Primary development environment
- **Simulator**: iOS device simulation
- **Instruments**: Performance profiling
- **Git**: Version control
- **GitHub Actions**: CI/CD pipeline

## 🤝 Contributing

### Getting Started
1. **Fork the repository**
2. **Clone your fork**
3. **Create feature branch**
4. **Make changes**
5. **Test thoroughly**
6. **Submit pull request**

### Contribution Guidelines
- **Code Quality**: Follow established patterns and standards
- **Testing**: Add tests for new features and bug fixes
- **Documentation**: Update docs for significant changes
- **Performance**: Consider performance impact of changes
- **Security**: Follow security best practices

### Review Process
- **Automated Checks**: CI runs automatically on PRs
- **Code Review**: Peer review required for all changes
- **Testing**: Full test suite must pass
- **Documentation**: Docs must be updated if needed

## 🔧 Troubleshooting

### CI Build Issues

#### Permission Dialog Appears During Tests
**Problem**: Camera permission popup interrupts test execution
**Solution**:
```bash
# Check if permissions are granted
xcrun simctl privacy <simulator_udid> status camera tysonhu.foodscanner

# Grant permissions manually
xcrun simctl privacy <simulator_udid> grant camera tysonhu.foodscanner
xcrun simctl privacy <simulator_udid> grant photos tysonhu.foodscanner
xcrun simctl privacy <simulator_udid> grant microphone tysonhu.foodscanner
```

#### CI Builds Hanging or Timing Out
**Problem**: Tests get stuck and don't complete
**Solution**:
1. Check simulator health: `./scripts/simulator-manager.sh health <udid>`
2. Reset simulator: `./scripts/simulator-manager.sh reset <udid>`
3. Clean up all simulators: `./scripts/simulator-manager.sh cleanup-all`
4. Check CI logs for specific error messages

#### Low Test Count in CI
**Problem**: CI reports fewer tests than expected
**Solution**:
1. Verify test plan is correct: `FoodScanner-CI-Offline.xctestplan`
2. Check for test compilation errors
3. Ensure all test targets are included
4. Review CI logs for test execution details

### Local Development Issues

#### Network Tests Failing
**Problem**: Network-dependent tests fail locally
**Solution**:
1. Use the local network test runner: `./scripts/test-local-network.sh`
2. Check network connectivity
3. Verify external services are available
4. Check for firewall or proxy issues

#### Simulator Issues
**Problem**: Simulator won't boot or is unresponsive
**Solution**:
1. Reset simulator: `xcrun simctl reset <udid>`
2. Erase simulator: `xcrun simctl erase <udid>`
3. Create fresh simulator: `./scripts/simulator-manager.sh create`
4. Check system resources and available space

### Common Error Messages

#### "Expression is 'async' but is not marked with 'await'"
**Fix**: Add `await` keyword before async function calls
```swift
// Wrong
viewModel.checkPermissions()

// Correct
await viewModel.checkPermissions()
```

#### "Force unwrapping should be avoided"
**Fix**: Use safe unwrapping with `guard let` or `if let`
```swift
// Wrong
let source = extractSource(from: gid)!

// Correct
guard let source = extractSource(from: gid) else { return .unknown }
```

#### "Function should have complexity 10 or less"
**Fix**: Extract complex logic into smaller helper methods
```swift
// Extract complex logic into private methods
private func logDSLDResponseIfNeeded(gid: String, data: Data) { /* ... */ }
private func validateDSLDDataIfNeeded(gid: String, foodCard: FoodMinimalCard) { /* ... */ }
```

## 📞 Support

### Getting Help
1. **Check documentation** first
2. **Search existing issues** on GitHub
3. **Ask team members** for guidance
4. **Create new issue** if needed

### Reporting Issues
1. **Use issue templates** when available
2. **Provide detailed information** about the problem
3. **Include steps to reproduce** the issue
4. **Attach relevant logs** and screenshots

---

**Last Updated**: September 2024  
**Version**: 2.1 (CI Permission Handling)  
**Status**: Production Ready ✅

This development guide is maintained alongside the codebase and reflects the current state of the Food Scanner app's development practices and workflows.
