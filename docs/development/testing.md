# Testing Guidelines

## 🧪 Testing Strategy

This document provides comprehensive testing guidelines for the Calry iOS app.

## 🎯 Testing Philosophy

### 1. **Test-Driven Development**
- **Write tests first** when possible
- **Test behavior**, not implementation
- **Maintain high** test coverage

### 2. **Testing Pyramid**
- **Unit Tests**: Foundation (70%)
- **Integration Tests**: Middle layer (20%)
- **UI Tests**: Top layer (10%)

### 3. **Test Isolation**
- **Independent tests** that don't affect each other
- **Mock external** dependencies
- **Clean state** between tests

### 4. **CI Environment Consistency**
- **Local tests match CI** exactly
- **Same build settings** and flags
- **Same test plans** and configurations
- **Swift 6 strict concurrency** enabled

## 📁 Test Organization

### Test Structure
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

### Test Naming Convention
- **Test files**: `*Tests.swift`
- **Test methods**: `test*()` or `@Test func *()`
- **Mock classes**: `Mock*`

### Test Target Configuration
- **CalryTests**: Unit tests only (excludes UI test files)
- **CalryUITests**: UI tests only (includes all UI test files)
- **Proper Separation**: UI tests isolated from unit tests to prevent configuration issues

### Test Plans
- **Default Test Plan**: Full test coverage including UI tests
- **CI Test Plan**: Unit tests only for reliable CI/CD pipelines

### Local CI Testing
Run tests with CI-equivalent settings locally:

```bash
# Setup local CI environment
./scripts/setup-local-ci.sh

# Source CI environment variables
source .env.ci

# Run tests with CI settings
./scripts/test-local-ci.sh
```

**Benefits**:
- **Exact CI replication**: Same settings, flags, and configuration
- **Early issue detection**: Catch problems before they reach CI
- **Consistent results**: Local tests match CI exactly
- **Swift 6 compliance**: Strict concurrency checking enabled

### Swift 6 Concurrency Testing
When testing with Swift 6 strict concurrency enabled, follow these patterns:

#### Unit Test Actor Isolation
```swift
@MainActor
struct MyServiceTests {
    @Test
    func testServiceFunctionality() async throws {
        // Tests run on MainActor - safe for UI-related code
        let service = MyService()
        let result = try await service.performAction()
        #expect(result.isSuccess)
    }
}
```

#### Nonisolated Test Methods
```swift
struct MyModelTests {
    @Test
    func testModelInitialization() {
        // Nonisolated test - safe for pure data operations
        let model = MyModel(id: "123", name: "Test")
        #expect(model.id == "123")
    }
}
```

#### UI Test Actor Isolation
```swift
final class MyUITests: BaseUITestCase {
    @MainActor
    func testUserFlow() {
        // UI tests must be @MainActor for XCUI access
        let addTab = app.tabBars.buttons["Add"]
        XCTAssertTrue(addTab.waitForExistence(timeout: 3))
        addTab.tap()
    }
}
```

#### Testing with Swift 6 Strict Concurrency
```bash
# Run tests with Swift 6 strict concurrency (matches CI)
./scripts/test-with-swift6-strict.sh

# Or use xcodebuild directly
xcodebuild test \
    -scheme "Calry" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -testPlan "Calry-CI-Offline" \
    SWIFT_STRICT_CONCURRENCY=complete \
    OTHER_SWIFT_FLAGS='-warnings-as-errors'
```

## 🔬 Unit Testing

### Test Structure
```swift
@Test func testFunctionality() async throws {
    // Arrange
    let mockDependency = MockDependency()
    let sut = SystemUnderTest(dependency: mockDependency)
    
    // Act
    let result = try await sut.performAction()
    
    // Assert
    #expect(result.isSuccess)
    #expect(mockDependency.wasCalled)
}
```

### Model Testing
```swift
@Test func testFoodCardInitialization() {
    // Arrange
    let id = "fdc:123456"
    let description = "Apple"
    let nutrients = [FoodNutrient(id: 1008, name: "Energy", amount: 52.0, unit: "kcal")]
    
    // Act
    let foodCard = FoodCard(
        id: id,
        description: description,
        nutrients: nutrients
    )
    
    // Assert
    #expect(foodCard.id == id)
    #expect(foodCard.description == description)
    #expect(foodCard.nutrients.count == 1)
}
```

### Service Testing
```swift
@Test func testFoodNormalizationService() async throws {
    // Arrange
    let service = FoodNormalizationService()
    let envelope = createMockFdcEnvelope()
    
    // Act
    let result = service.normalizeFDC(envelope)
    
    // Assert
    #expect(result.gid == envelope.gid)
    #expect(result.nutrients.count > 0)
    #expect(result.primaryName != nil)
}
```

### ViewModel Testing
```swift
@Test func testSearchViewModel() async throws {
    // Arrange
    let mockClient = MockFoodDataClient()
    let viewModel = FoodSearchViewModel(client: mockClient)
    
    // Act
    await viewModel.searchFoods(query: "apple")
    
    // Assert
    #expect(viewModel.searchResults.count > 0)
    #expect(viewModel.isLoading == false)
}
```

## 🔗 Integration Testing

### Service Integration
```swift
@Test func testServiceIntegration() async throws {
    // Arrange
    let client = FoodDataClient()
    let service = FoodNormalizationService()
    
    // Act
    let response = try await client.searchFoods(query: "apple")
    let normalized = service.normalize(response.results.first!)
    
    // Assert
    #expect(normalized.primaryName != nil)
    #expect(normalized.nutrients.count > 0)
}
```

### Data Flow Testing
```swift
@Test func testDataFlow() async throws {
    // Test complete data flow from API to UI
    let client = FoodDataClient()
    let converter = FoodDataConverter()
    
    let response = try await client.searchFoods(query: "apple")
    let normalized = service.normalize(response.results.first!)
    let publicModel = converter.convertToFoodCard(normalized)
    
    #expect(publicModel.id != nil)
    #expect(publicModel.description != nil)
}
```

## 🎨 UI Testing

### Screen Testing
```swift
func testSearchScreen() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to search
    app.tabBars.buttons["Search"].tap()
    
    // Enter search query
    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("apple")
    
    // Submit search
    app.keyboards.buttons["Search"].tap()
    
    // Verify results
    XCTAssertTrue(app.tables.cells.count > 0)
}
```

### Component Testing
```swift
func testFoodResultRow() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to search results
    navigateToSearchResults()
    
    // Verify row elements
    let firstCell = app.tables.cells.firstMatch
    XCTAssertTrue(firstCell.staticTexts["Apple"].exists)
    XCTAssertTrue(firstCell.staticTexts["52 kcal"].exists)
}
```

## 🎭 Mock Implementation

### Mock Services
```swift
class MockFoodDataClient: FoodDataClientProtocol {
    var mockSearchResponse: FoodSearchResponse?
    var mockDetailResponse: FoodDetailResponse?
    var shouldThrowError: Error?
    
    func searchFoods(query: String) async throws -> FoodSearchResponse {
        if let error = shouldThrowError {
            throw error
        }
        return mockSearchResponse ?? createMockSearchResponse()
    }
    
    func getFoodDetails(gid: String) async throws -> FoodDetailResponse {
        if let error = shouldThrowError {
            throw error
        }
        return mockDetailResponse ?? createMockDetailResponse()
    }
}
```

### Mock Data Creation
```swift
func createMockSearchResponse() -> FoodSearchResponse {
    return FoodSearchResponse(
        query: "apple",
        totalResults: 1,
        pageSize: 50,
        currentPage: 1,
        results: [
            createMockSearchResult()
        ]
    )
}

func createMockSearchResult() -> SearchResult {
    return SearchResult(
        gid: "fdc:123456",
        source: .fdc,
        description: "Apple, raw, with skin",
        brand: nil,
        barcode: nil,
        imageUrl: nil,
        nutritionSummary: createMockNutritionSummary()
    )
}
```

## 🚨 Error Testing

### Network Error Testing
```swift
@Test func testNetworkError() async throws {
    // Arrange
    let mockClient = MockFoodDataClient()
    mockClient.shouldThrowError = FoodDataError.networkUnavailable
    let viewModel = FoodSearchViewModel(client: mockClient)
    
    // Act
    await viewModel.searchFoods(query: "apple")
    
    // Assert
    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.searchResults.isEmpty)
}
```

### Validation Error Testing
```swift
@Test func testInvalidInput() async throws {
    // Arrange
    let viewModel = FoodSearchViewModel()
    
    // Act
    await viewModel.searchFoods(query: "")
    
    // Assert
    #expect(viewModel.searchResults.isEmpty)
    #expect(viewModel.isLoading == false)
}
```

## 📊 Test Coverage

### Coverage Goals
- **Models**: 100% coverage
- **Services**: 90% coverage
- **ViewModels**: 85% coverage
- **Views**: 70% coverage

### Coverage Measurement
```bash
# Generate coverage report
xcodebuild test -scheme "Calry" -destination "platform=iOS Simulator,name=iPhone 16" -enableCodeCoverage YES

# View coverage report
xcrun xccov view DerivedData/Logs/Test/*.xcresult
```

## 🔧 Test Configuration

### Test Plans
- **Calry.xctestplan**: Full test coverage
- **Calry-CI-Offline.xctestplan**: CI-optimized offline tests

### Test Environment
```swift
enum TestEnvironment {
    case unit
    case integration
    case ui
    
    var configuration: TestConfiguration {
        switch self {
        case .unit:
            return TestConfiguration(mockServices: true, offlineMode: true)
        case .integration:
            return TestConfiguration(mockServices: false, offlineMode: false)
        case .ui:
            return TestConfiguration(mockServices: false, offlineMode: false)
        }
    }
}
```

## 🚀 Best Practices

### 1. **Test Organization**
- **Group related tests** in test classes
- **Use descriptive** test names
- **Follow AAA pattern** (Arrange, Act, Assert)

### 2. **Mock Usage**
- **Mock external** dependencies
- **Use realistic** mock data
- **Verify mock** interactions

### 3. **Test Data**
- **Use consistent** test data
- **Create reusable** test fixtures
- **Avoid hardcoded** values

### 4. **Performance**
- **Keep tests fast** (< 1 second each)
- **Use parallel** execution
- **Minimize setup** overhead

## 🔍 Debugging Tests

### Test Failures
```swift
// Add debug information
@Test func testWithDebugInfo() {
    let result = performAction()
    
    if result.isFailure {
        print("Debug info: \(result.debugDescription)")
        print("Expected: \(expectedValue)")
        print("Actual: \(result.actualValue)")
    }
    
    #expect(result.isSuccess)
}
```

### Test Logging
```swift
// Enable test logging
func testWithLogging() {
    print("Starting test: \(#function)")
    
    let result = performAction()
    print("Result: \(result)")
    
    #expect(result.isSuccess)
    print("Test completed successfully")
}
```

This testing guide ensures comprehensive test coverage and reliable testing practices for the Calry app.
