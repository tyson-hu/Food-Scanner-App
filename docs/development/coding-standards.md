# Coding Standards

## 📝 Code Style and Standards

This document defines the coding standards and style guidelines for the Food Scanner iOS app.

## 🎯 General Principles

### 1. **Clarity Over Cleverness**
- **Readable code** is more important than clever code
- **Clear naming** conveys intent
- **Simple solutions** are preferred

### 2. **Consistency**
- **Follow established** patterns
- **Use consistent** naming conventions
- **Maintain uniform** code style

### 3. **Maintainability**
- **Write code** for future developers
- **Document complex** logic
- **Use clear** structure and organization

## 📋 Naming Conventions

### Files and Directories
- **Files**: `PascalCase.swift` (e.g., `FoodDataClient.swift`)
- **Directories**: `kebab-case` (e.g., `food-data-client`)
- **Tests**: `*Tests.swift` (e.g., `FoodDataClientTests.swift`)

### Types and Protocols
```swift
// Classes and Structs
class FoodDataClient { }
struct FoodMinimalCard { }

// Protocols
protocol FoodDataClientProtocol { }

// Enums
enum FoodKind { }
enum RawSource { }
```

### Variables and Functions
```swift
// Variables (camelCase)
var searchResults: [FoodMinimalCard] = []
var isLoading: Bool = false

// Functions (camelCase)
func searchFoods(query: String) async throws -> FoodSearchResponse
func loadFoodDetails(gid: String) async throws -> FoodDetailResponse

// Constants (camelCase)
let maxRetries = 3
let timeoutInterval: TimeInterval = 30.0
```

### Private vs Public
```swift
// Public API
public func searchFoods(query: String) async throws -> FoodSearchResponse

// Internal implementation
private func processSearchResults(_ results: [SearchResult]) -> [FoodMinimalCard]

// File-private
fileprivate func validateInput(_ input: String) -> Bool
```

## 🏗️ Code Organization

### File Structure
```swift
// 1. Imports
import Foundation
import SwiftUI

// 2. Type definition
public struct FoodDataClient: FoodDataClientProtocol {
    
    // 3. Properties
    private let session: URLSession
    private let baseURL: String
    
    // 4. Initialization
    public init(session: URLSession = .shared, baseURL: String = "https://api.calry.org") {
        self.session = session
        self.baseURL = baseURL
    }
    
    // 5. Public methods
    public func searchFoods(query: String) async throws -> FoodSearchResponse {
        // Implementation
    }
    
    // 6. Private methods
    private func makeRequest<T>(_ request: URLRequest) async throws -> T {
        // Implementation
    }
}
```

### MARK Comments
```swift
// MARK: - Properties
private let client: FoodDataClient
private var searchResults: [FoodMinimalCard] = []

// MARK: - Initialization
init(client: FoodDataClient) {
    self.client = client
}

// MARK: - Public Methods
func search(query: String) async {
    // Implementation
}

// MARK: - Private Methods
private func processResults(_ results: [SearchResult]) {
    // Implementation
}
```

## 🎯 SwiftUI Guidelines

### View Structure
```swift
struct FoodSearchView: View {
    // MARK: - Properties
    @State private var viewModel = FoodSearchViewModel()
    @State private var searchText = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                searchField
                resultsList
            }
            .navigationTitle("Search Foods")
        }
    }
    
    // MARK: - Subviews
    private var searchField: some View {
        TextField("Search foods...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
                Task {
                    await viewModel.search(query: searchText)
                }
            }
    }
    
    private var resultsList: some View {
        List(viewModel.searchResults) { result in
            FoodResultRow(result: result)
        }
    }
}
```

### ViewModel Structure
```swift
@MainActor
@Observable
final class FoodSearchViewModel {
    // MARK: - Published Properties
    var searchResults: [FoodMinimalCard] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    private let client: FoodDataClient
    
    // MARK: - Initialization
    init(client: FoodDataClient = FoodDataClient()) {
        self.client = client
    }
    
    // MARK: - Public Methods
    func search(query: String) async {
        guard !query.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.searchFoods(query: query)
            searchResults = response.results
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
```

## 🔧 Error Handling

### Error Types
```swift
enum FoodDataError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)
    case noResults
    case customError(String)  // For preserving specific error messages
    case serverUnavailable
    case rateLimited(TimeInterval?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect to food database. Please check your internet connection."
        case .invalidResponse:
            return "Received invalid data from food database. Please try again."
        case let .httpError(code):
            return "Server error (\(code)). Please try again later."
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Unable to process food data. Please try again."
        case .noResults:
            return "No foods found matching your search. Try different keywords."
        case let .customError(message):
            return message  // Preserves specific error messages
        case .serverUnavailable:
            return "Food database is temporarily unavailable. Please try again later."
        case let .rateLimited(retryAfter):
            if let retryAfter {
                return "Too many requests. Please wait \(Int(retryAfter)) seconds and try again."
            } else {
                return "Too many requests. Please wait a moment and try again."
            }
        }
    }
}
```

### Error Handling Patterns
```swift
// Do-catch for async functions
func loadData() async {
    do {
        let data = try await fetchData()
        processData(data)
    } catch {
        handleError(error)
    }
}

// Result type for synchronous functions
func processData(_ data: Data) -> Result<ProcessedData, ProcessingError> {
    do {
        let processed = try parseData(data)
        return .success(processed)
    } catch {
        return .failure(.parsingError(error))
    }
}
```

### Error Semantics Preservation
When converting between error types, preserve specific error information:

```swift
// ✅ Good: Preserve specific error messages
private func convertProxyErrorToFoodDataError(_ error: ProxyError) -> FoodDataError {
    case let .proxyError(errorResponse):
        .customError(ProxyError.proxyError(errorResponse).errorDescription ?? "Proxy error occurred")
}

// ❌ Bad: Lose specific error information
private func convertProxyErrorToFoodDataError(_ error: ProxyError) -> FoodDataError {
    case .proxyError:
        .serverUnavailable  // Generic message loses context
}
```

**Benefits of Error Semantics Preservation:**
- **User-Friendly Messages**: Users see specific error details
- **Better Debugging**: Developers get detailed error information
- **Improved UX**: Appropriate error messages for different scenarios
- **Maintainability**: Error handling remains consistent across layers

## 🧪 Testing Standards

### Test Structure
```swift
@Test func testSearchFunctionality() async throws {
    // Arrange
    let mockClient = MockFoodDataClient()
    let viewModel = FoodSearchViewModel(client: mockClient)
    
    // Act
    await viewModel.search(query: "apple")
    
    // Assert
    #expect(viewModel.searchResults.count > 0)
    #expect(viewModel.isLoading == false)
    #expect(viewModel.errorMessage == nil)
}
```

### Mock Implementation
```swift
class MockFoodDataClient: FoodDataClientProtocol {
    var mockSearchResponse: FoodSearchResponse?
    var shouldThrowError: Error?
    
    func searchFoods(query: String) async throws -> FoodSearchResponse {
        if let error = shouldThrowError {
            throw error
        }
        return mockSearchResponse ?? createMockResponse()
    }
}
```

## 📝 Documentation Standards

### Function Documentation
```swift
/// Searches for foods using the specified query string
/// - Parameter query: The search term to use for finding foods
/// - Returns: A response containing the search results
/// - Throws: `FoodDataError` if the search fails
func searchFoods(query: String) async throws -> FoodSearchResponse
```

### Complex Logic Documentation
```swift
// Merge FDC and OFF data with proper precedence rules
// FDC preferred for: nutrients, servings, portions (more accurate)
// OFF preferred for: images, ingredients, front-of-pack info (more complete)
private func mergeFoodData(fdc: NormalizedFood?, off: NormalizedFood?) -> NormalizedFood? {
    // Implementation
}
```

## 🚨 Common Violations

### ❌ Avoid These Patterns
```swift
// Don't use force unwrapping
let value = optionalValue! // ❌

// Don't use implicitly unwrapped optionals unnecessarily
var text: String! // ❌

// Don't use abbreviations
let usr = user // ❌
let btn = button // ❌

// Don't use unclear variable names
let data = response.data // ❌
let result = process(data) // ❌
```

### ✅ Use These Patterns Instead
```swift
// Use safe unwrapping
guard let value = optionalValue else { return } // ✅

// Use explicit optionals
var text: String? // ✅

// Use full words
let user = currentUser // ✅
let button = submitButton // ✅

// Use descriptive names
let searchResults = response.searchResults // ✅
let processedData = processSearchResults(searchResults) // ✅
```

## 🔧 Configuration Management

### API Configuration Standards
The app uses a centralized configuration system for API endpoints and settings:

#### .xcconfig Files
```xcconfig
// API Configuration
API_SCHEME = https
API_HOST = api.calry.org
API_BASE_PATH = /v1

// Feature Flags
FEATURE_FDC_REMOTE = 0
```

#### Info.plist Integration
```xml
<key>APIScheme</key>
<string>$(API_SCHEME)</string>
<key>APIHost</key>
<string>$(API_HOST)</string>
<key>APIBasePath</key>
<string>$(API_BASE_PATH)</string>
```

#### APIConfiguration Service
```swift
public struct APIConfiguration: Sendable {
    public let baseURL: URL
    public let basePath: String

    public init() throws {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            throw APIConfigurationError.missingInfoPlist
        }

        guard let scheme = infoDictionary["APIScheme"] as? String,
              let host = infoDictionary["APIHost"] as? String else {
            throw APIConfigurationError.invalidBaseURL
        }

        guard let basePath = infoDictionary["APIBasePath"] as? String else {
            throw APIConfigurationError.missingBasePath
        }

        guard let baseURL = URL(string: "\(scheme)://\(host)") else {
            throw APIConfigurationError.invalidBaseURL
        }

        self.baseURL = baseURL
        self.basePath = basePath
    }
}
```

### Configuration Best Practices
- **Split URLs**: Use separate scheme, host, and path components to avoid `.xcconfig` comment issues
- **Environment-specific**: Different values for Debug vs Release builds
- **Type safety**: Validate configuration at initialization time
- **Error handling**: Provide clear error messages for configuration issues
- **No hardcoding**: All API endpoints should be configurable

### .xcconfig Gotchas
- **Comments**: `//` starts a comment, so `https://api.calry.org` becomes `https:`
- **Quotes**: Use quotes for URLs: `API_BASE_URL = "https://api.calry.org"`
- **Variables**: Use `$(VARIABLE)` syntax in Info.plist for variable substitution
- **Build settings**: Verify with `xcodebuild -showBuildSettings | grep API_`

## 🔧 Code Formatting

### SwiftFormat Configuration
The project uses SwiftFormat for automatic code formatting. The configuration is defined in `.swiftformat`:

```bash
--swiftversion 6.2
--exclude Carthage,Pods,.build,DerivedData,Resources/Generated,**/*.generated.swift

--indent 4
--linebreaks lf
--trimwhitespace always

--maxwidth 120
--wraparguments before-first
--wrapcollections before-first

--stripunusedargs closure-only
--trailingcommas never
--importgrouping alphabetized

--disable wrapMultilineStatementBraces
--disable numberFormatting
```

**Important**: The `numberFormatting` rule is disabled to prevent conflicts with SwiftLint's `number_separator` rule.

### SwiftLint Configuration
The project uses SwiftLint for code style enforcement. Key rules include:

- **Number Separator**: Requires underscores for numbers >= 1,000 (e.g., `1_000`)
- **Closure Body Length**: Limits closure body length for readability
- **API Model Codable**: Ensures API models conform to `Codable`
- **Model Complexity**: Prevents overly complex model structures

### Tool Integration
Both SwiftFormat and SwiftLint are configured to work together without conflicts:

```bash
# Run SwiftLint
swiftlint

# Run SwiftFormat (dry run)
swiftformat --dryrun .

# Run SwiftFormat (apply changes)
swiftformat .
```

### Number Formatting Standards
The project follows specific number formatting rules enforced by SwiftLint:

```swift
// ✅ Correct - Use underscores for numbers >= 1,000
let calories = 1_008
let protein = 1_003
let fat = 1_004
let carbs = 1_005
let sodium = 1_258
let maxSize = 1_000

// ❌ Incorrect - Missing underscores
let calories = 1008
let protein = 1003
let maxSize = 1000

// ✅ Correct - Small numbers don't need underscores
let smallNumber = 100
let mediumNumber = 999
```

### Indentation and Spacing
```swift
// Use 4 spaces for indentation
if condition {
    // Nested code
    if anotherCondition {
        // More nested code
    }
}

// Use blank lines to separate logical sections
class ExampleClass {
    
    // MARK: - Properties
    private let property: String
    
    // MARK: - Initialization
    init(property: String) {
        self.property = property
    }
    
    // MARK: - Methods
    func method() {
        // Implementation
    }
}
```

## 🎯 Performance Guidelines

### Memory Management
```swift
// Use weak references to avoid retain cycles
class ViewController {
    weak var delegate: ViewControllerDelegate?
}

// Use lazy properties for expensive initialization
lazy var expensiveObject = ExpensiveObject()

// Use proper cleanup in deinit
deinit {
    // Cleanup resources
}
```

### Efficient Algorithms
```swift
// Use appropriate data structures
let set = Set<String>() // For uniqueness
let dictionary = [String: Int]() // For key-value pairs
let array = [String]() // For ordered collections

// Use lazy evaluation when appropriate
let filteredResults = results.lazy.filter { $0.isValid }
```

This coding standards guide ensures consistent, maintainable, and high-quality code across the Food Scanner app.
