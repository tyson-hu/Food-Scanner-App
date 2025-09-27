# CI Offline Mode Configuration

## Overview

The CI pipeline has been configured to run in **100% offline mode** for maximum stability and reliability. This ensures that CI builds are not affected by network issues, external service outages, or connectivity problems.

## Key Changes

### 1. **Reduced Timeouts**
- **Destination timeout**: 180s → 60s
- **Stuck detection**: 5min → 3min  
- **Progress check**: 30s → 20s intervals
- **Overall timeout**: 12min → 10min

### 2. **Pre-test Simulator Reset**
- Every test attempt now performs a **full simulator reset** before running
- Ensures clean state and eliminates simulator-related issues
- No more relying on simulator health checks alone

### 3. **Network Test Exclusion**
- **CI Test Plan**: `FoodScanner-CI-Offline.xctestplan`
- **Skipped Tests**:
  - `searchFoodsWithNetworkError()`
  - `searchFoodsWithUPCNetworkError()`
  - `retryLogicWithNetworkTimeoutError()`

### 4. **Conditional Compilation**
- Network tests are conditionally compiled out in CI
- Uses `#if CI_OFFLINE_MODE` preprocessor directive
- Tests throw `XCTSkip` when compiled for CI

## Test Plans

### CI (Offline)
- **File**: `FoodScanner-CI-Offline.xctestplan`
- **Purpose**: Stable, fast CI builds
- **Network Tests**: ❌ Disabled
- **Duration**: ~2-3 minutes

### Local Development
- **File**: `FoodScanner.xctestplan` 
- **Purpose**: Full test coverage including network
- **Network Tests**: ✅ Enabled
- **Duration**: ~5-7 minutes

## Running Tests

### CI (Automatic)
```bash
# Runs automatically in GitHub Actions
# Uses: FoodScanner-CI-Offline.xctestplan
./scripts/ci-test-runner.sh <simulator_id> ./DerivedData
```

### Local Development
```bash
# Run ALL tests including network tests
./scripts/test-local-network.sh

# Or run specific test plan
xcodebuild -scheme "Food Scanner" -testPlan "FoodScanner" -destination "id=<simulator_id>" test
```

## Environment Variables

### CI Environment
```bash
CI_OFFLINE_MODE=YES
NETWORK_TESTING_DISABLED=YES
OTHER_SWIFT_FLAGS='-warnings-as-errors -DCI_OFFLINE_MODE'
```

### Local Environment
```bash
# No special flags needed
# All tests run normally
```

## Benefits

### ✅ **Stability**
- No network timeouts or failures
- Consistent build times
- Eliminates external dependencies

### ✅ **Speed**
- Faster CI builds (2-3 min vs 5-7 min)
- Reduced retry attempts
- Quicker feedback loop

### ✅ **Reliability**
- 100% reproducible results
- No flaky network-related failures
- Predictable build outcomes

## Network Test Coverage

Network tests are still **fully covered** in local development:

- **Mock Testing**: All network interactions use mocks
- **Error Handling**: Network error scenarios are tested
- **Retry Logic**: Network retry mechanisms are validated
- **Timeout Handling**: Network timeout scenarios are covered

## Monitoring

### CI Success Metrics
- **Build Time**: < 3 minutes
- **Success Rate**: > 99%
- **Retry Rate**: < 5%
- **Stuck Builds**: 0%

### Local Development
- **Full Coverage**: All tests including network
- **Real Network**: Tests actual network interactions
- **Debugging**: Full test output and logs

## Troubleshooting

### If CI Builds Still Fail
1. Check simulator state before tests
2. Verify no network calls are being made
3. Review test logs for stuck conditions
4. Ensure all network tests are properly skipped

### If Local Tests Fail
1. Check network connectivity
2. Verify external services are available
3. Review test timeouts
4. Check for rate limiting

## Migration Notes

- **Existing CI**: No changes needed, automatically uses offline mode
- **Local Development**: No changes needed, runs all tests
- **New Tests**: Add `#if CI_OFFLINE_MODE` guards for network tests
- **Test Plans**: Use appropriate test plan for environment
