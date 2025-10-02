# CI/CD Documentation

## 📁 CI/CD Documentation Structure

```
ci-cd/
├── README.md                       # 📋 This file - CI/CD overview
├── build-process.md                # 🏗️ Build configuration
├── test-strategy.md                # 🧪 Testing strategy
└── troubleshooting.md              # 🚨 Common issues
```

## 🔧 CI/CD Overview

The Food Scanner app uses a robust CI/CD pipeline with offline mode support for reliable builds and testing.

## 🎯 Key Features

### ✅ **Offline Mode Support**
- **No network dependencies** during CI builds
- **Mock services** for API testing
- **Cached data** for offline functionality
- **Stable builds** regardless of network conditions

### ✅ **Multi-Platform Testing**
- **Unit Tests**: Individual component testing
- **Integration Tests**: Service interaction testing  
- **UI Tests**: User interface testing (local only)
- **Performance Tests**: Build time and memory usage

### ✅ **Automated Quality Checks**
- **Code linting** and style enforcement
- **Test coverage** reporting
- **Build optimization** and caching
- **Error handling** and retry logic

## 🏗️ Build Process

**📖 See [Build Process](build-process.md)** for detailed configuration.

### Build Stages
1. **Environment Setup**: Xcode, simulators, dependencies
2. **Code Quality**: Linting, formatting, static analysis
3. **Unit Testing**: Component testing with mocks
4. **Integration Testing**: Service interaction testing
5. **Build Verification**: Compilation and linking
6. **Artifact Generation**: App bundles and test reports

## 🧪 Test Strategy

**📖 See [Test Strategy](test-strategy.md)** for detailed approach.

### Test Organization
```
Tests/
├── Unit/                    # Unit tests (CI-friendly)
│   ├── Models/             # Model tests
│   ├── Services/           # Service tests
│   └── ViewModels/         # ViewModel tests
└── UI/                     # UI tests (Local only)
    ├── Screens/            # Screen tests
    └── Components/         # Component tests
```

### Test Types
- **Unit Tests**: Individual component testing
- **Integration Tests**: Service interaction testing
- **UI Tests**: User interface testing
- **Mock Tests**: External dependency testing

## 🚨 Troubleshooting

**📖 See [Troubleshooting](troubleshooting.md)** for common issues.

### Common Issues
- **Build timeouts**: Simulator management
- **Test failures**: Mock service configuration
- **Memory issues**: Resource cleanup
- **Network dependencies**: Offline mode setup

## 🎯 Key Scripts

### Build Scripts
- **`ci-test-runner.sh`**: CI test execution with warning filtering
- **`build-without-appintents-warning.sh`**: Warning-filtered build script
- **`simulator-manager.sh`**: Simulator management
- **`test-local-network.sh`**: Local network testing

### Test Plans
- **`FoodScanner.xctestplan`**: Full test coverage (default test plan)
- **`FoodScanner-CI-Offline.xctestplan`**: CI-optimized offline tests

### Test Target Configuration
- **FoodScannerTests**: Unit tests only (excludes UI test files)
- **FoodScannerUITests**: UI tests only (includes all UI test files)
- **Target Separation**: UI tests properly isolated from unit tests

## 🚀 Best Practices

### 1. **Offline-First Design**
- **Mock external services** for testing
- **Cache critical data** for offline functionality
- **Handle network failures** gracefully

### 2. **Test Organization**
- **Mirror source structure** in tests
- **Separate unit and UI tests**
- **Use descriptive test names**

### 3. **Build Optimization**
- **Parallel test execution**
- **Incremental builds**
- **Cache build artifacts**

This CI/CD system ensures reliable builds and comprehensive testing for the Food Scanner app.
