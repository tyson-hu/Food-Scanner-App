# Integration Tests

This project includes integration tests that make live network calls to external services. These tests are disabled by default to ensure the test suite runs reliably in CI/CD environments and offline.

## Running Integration Tests

### Option 1: Environment Variable
Set the `RUN_INTEGRATION_TESTS` environment variable to `1` or `true`:

```bash
# Run all tests including integration tests
RUN_INTEGRATION_TESTS=1 xcodebuild test -scheme "Food Scanner" -destination "platform=iOS Simulator,name=iPhone 15"

# Or in Xcode, set the environment variable in the scheme editor
```

### Option 2: Build Configuration
Add `INTEGRATION_TESTS=1` to your build settings or create a custom build configuration.

## Integration Test Categories

### Network-Dependent Tests
- **FDCProxyClientTests**: Tests that make live calls to `https://api.calry.org`
- **AddFoodDetailViewModelTests**: Tests that fetch real food data from external APIs
- **AddFoodSearchViewModelTests**: Tests that perform live search operations

### Test Behavior
- When integration tests are **disabled** (default): Tests skip with a success message
- When integration tests are **enabled**: Tests make live network calls and may fail if:
  - Network is unavailable
  - External services are down
  - Firewall blocks the requests
  - Services are slow to respond

## CI/CD Considerations

- **Default behavior**: Integration tests are skipped, ensuring reliable CI builds
- **Optional execution**: Enable integration tests only when needed for comprehensive testing
- **Timeout handling**: Integration tests include appropriate timeouts to prevent hanging

## Adding New Integration Tests

When adding new tests that require live network access:

1. Add the test to the appropriate test file
2. Prefix the test name with `integration_`
3. Add the integration test guard:
   ```swift
   guard TestConfig.runIntegrationTests else {
       #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
       return
   }
   ```
4. Update this documentation if needed
