# Integration Tests

This project includes integration tests that make live network calls to external services. These tests are **disabled by default** in CI to ensure reliable builds, but can be enabled for comprehensive local testing.

## Test Configuration

### CI Environment (Default)
- **Status**: ❌ **Disabled** for stability
- **Mode**: 100% offline
- **Test Plan**: `FoodScanner-CI-Offline.xctestplan`
- **Duration**: 2-3 minutes
- **Network Tests**: Skipped with `XCTSkip`

### Local Development
- **Status**: ✅ **Enabled** for full coverage
- **Mode**: Full network testing
- **Test Plan**: `FoodScanner.xctestplan`
- **Duration**: 5-7 minutes
- **Network Tests**: All executed

## Running Integration Tests

### Option 1: Local Development Script (Recommended)
Use the provided script for full network testing:

```bash
# Run ALL tests including network tests
./scripts/test-local-network.sh
```

This script:
- Automatically finds a booted iPhone 16 simulator
- Uses the full test plan with network tests
- Provides detailed output and debugging
- Handles simulator management

### Option 2: Environment Variable
Set the `RUN_INTEGRATION_TESTS` environment variable to `1` or `true`:

```bash
# Run all tests including integration tests
RUN_INTEGRATION_TESTS=1 xcodebuild test -scheme "Food Scanner" -destination "platform=iOS Simulator,name=iPhone 16"

# Or in Xcode, set the environment variable in the scheme editor
```

### Option 3: Build Configuration
Add `INTEGRATION_TESTS=1` to your build settings or create a custom build configuration.

### Option 4: Xcode Test Plan
Select the appropriate test plan in Xcode:
- **CI Offline**: `FoodScanner-CI-Offline.xctestplan` (no network tests)
- **Local Development**: `FoodScanner.xctestplan` (includes network tests)

## Integration Test Categories

### Network-Dependent Tests
- **FDCProxyClientTests**: Tests that make live calls to `https://api.calry.org`
  - `searchFoodsWithNetworkError()`
  - `searchFoodsWithUPCNetworkError()`
  - `retryLogicWithNetworkTimeoutError()`
- **AddFoodDetailViewModelTests**: Tests that fetch real food data from external APIs
- **AddFoodSearchViewModelTests**: Tests that perform live search operations

### Test Behavior

#### When Integration Tests are **Disabled** (CI Default)
- Tests skip with `XCTSkip("Network tests disabled in CI offline mode")`
- **Exit code**: 0 (success)
- **Duration**: ~2-3 minutes
- **Reliability**: 100% (no external dependencies)

#### When Integration Tests are **Enabled** (Local Development)
- Tests make live network calls
- **Exit code**: 0 (success) or 1 (failure)
- **Duration**: ~5-7 minutes
- **May fail if**:
  - Network is unavailable
  - External services are down
  - Firewall blocks the requests
  - Services are slow to respond
  - Rate limiting is encountered

## CI/CD Considerations

### CI Pipeline (GitHub Actions)
- **Default behavior**: Integration tests are skipped
- **Test plan**: `FoodScanner-CI-Offline.xctestplan`
- **Environment**: `CI_OFFLINE_MODE=YES`
- **Benefits**: 
  - Reliable builds (no network dependencies)
  - Faster execution (2-3 minutes)
  - Consistent results
  - No external service failures

### Local Development
- **Default behavior**: All tests run including network tests
- **Test plan**: `FoodScanner.xctestplan`
- **Environment**: No special flags needed
- **Benefits**:
  - Full test coverage
  - Real network testing
  - Complete validation
  - Debugging support

## Test Implementation

### Conditional Compilation
Network tests use conditional compilation to skip in CI:

```swift
@Test @MainActor
func searchFoodsWithNetworkError() async throws {
    // Skip network tests in CI for stability
    #if CI_OFFLINE_MODE
    throw XCTSkip("Network tests disabled in CI offline mode")
    #endif
    
    // Test implementation...
}
```

### Test Plan Configuration
The CI offline test plan explicitly skips network tests:

```json
{
  "skippedTests" : [
    {
      "identifier" : "FoodScannerTests.FDCProxyClientTests.searchFoodsWithNetworkError",
      "name" : "searchFoodsWithNetworkError"
    },
    {
      "identifier" : "FoodScannerTests.FDCProxyClientTests.searchFoodsWithUPCNetworkError", 
      "name" : "searchFoodsWithUPCNetworkError"
    },
    {
      "identifier" : "FoodScannerTests.FDCProxyClientTests.retryLogicWithNetworkTimeoutError",
      "name" : "retryLogicWithNetworkTimeoutError"
    }
  ]
}
```

## Adding New Integration Tests

When adding new tests that require live network access:

1. **Add the test** to the appropriate test file
2. **Prefix the test name** with `integration_` (optional but recommended)
3. **Add the integration test guard**:
   ```swift
   @Test @MainActor
   func integration_newNetworkTest() async throws {
       // Skip network tests in CI for stability
       #if CI_OFFLINE_MODE
       throw XCTSkip("Network tests disabled in CI offline mode")
       #endif
       
       // Test implementation...
   }
   ```
4. **Add to test plan** if needed:
   - Add to `FoodScanner.xctestplan` for local development
   - Add to `FoodScanner-CI-Offline.xctestplan` skipped tests for CI
5. **Update documentation** if needed

## Best Practices

### For CI Stability
- **Always skip network tests** in CI environment
- **Use conditional compilation** (`#if CI_OFFLINE_MODE`)
- **Provide clear skip messages** for debugging
- **Test both modes** during development

### For Local Development
- **Run full test suite** regularly
- **Use the local test script** for convenience
- **Test with poor network conditions** occasionally
- **Monitor test duration** and optimize if needed

### For Test Design
- **Mock external dependencies** when possible
- **Use realistic test data** for network tests
- **Include timeout handling** in network tests
- **Test error scenarios** (network failures, timeouts)

## Troubleshooting

### Common Issues

#### CI Builds Failing
- **Check**: Are network tests being skipped properly?
- **Solution**: Verify `CI_OFFLINE_MODE` is set and conditional compilation is working
- **Debug**: Look for `XCTSkip` messages in test output

#### Local Tests Failing
- **Check**: Network connectivity and external service availability
- **Solution**: Use `./scripts/test-local-network.sh` for proper setup
- **Debug**: Check test logs for specific network errors

#### Test Timeouts
- **Check**: Network service response times
- **Solution**: Increase timeout values if needed
- **Debug**: Monitor test execution and identify slow tests

### Debug Commands

```bash
# Check if CI offline mode is enabled
grep -r "CI_OFFLINE_MODE" FoodScannerTests/

# Run specific test plan
xcodebuild test -scheme "Food Scanner" -testPlan "FoodScanner" -destination "platform=iOS Simulator,name=iPhone 16"

# Check network connectivity
curl -I https://api.calry.org

# Run local network tests
./scripts/test-local-network.sh

# Check test plan configuration
cat FoodScanner-CI-Offline.xctestplan
cat FoodScanner.xctestplan
```

## Performance Impact

### CI Environment
- **Build time**: 2-3 minutes (no network tests)
- **Success rate**: >99%
- **Resource usage**: Minimal
- **External dependencies**: None

### Local Development
- **Build time**: 5-7 minutes (with network tests)
- **Success rate**: ~95-98% (depends on network)
- **Resource usage**: Moderate
- **External dependencies**: API services

## Future Improvements

### Potential Enhancements
1. **Test data caching**: Cache network responses for faster local testing
2. **Mock services**: Local mock server for consistent testing
3. **Test parallelization**: Run compatible tests in parallel
4. **Network simulation**: Test with various network conditions
5. **Performance monitoring**: Track test execution times and success rates

### Monitoring
- Track test success rates in both modes
- Monitor build times and resource usage
- Measure network test reliability
- Identify flaky tests and optimize

This integration test setup provides **maximum stability for CI** while maintaining **comprehensive testing for local development**.