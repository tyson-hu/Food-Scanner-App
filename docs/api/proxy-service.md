# Proxy Service Architecture

## 🔌 Proxy Service Details

This document explains the calry.org proxy service architecture and how it integrates with the Food Scanner app.

## 🎯 Proxy Service Overview

The **calry.org proxy service** acts as a unified gateway to multiple food data sources, providing a consistent API interface for the Food Scanner app.

### Key Benefits
- **Unified API**: Single endpoint for multiple data sources
- **No Authentication**: No API keys required
- **Rate Limiting**: Built-in rate limiting protection
- **Data Normalization**: Consistent response format
- **Reliability**: High availability and uptime

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Food Scanner App                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Search    │ │   Scanner   │ │   Today     │ │  Settings   │ │
│  │    UI       │ │     UI      │ │     UI      │ │     UI      │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ProxyClient                                  │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Search    │ │   Details   │ │   Barcode   │ │   Cache     │ │
│  │   Requests  │ │  Requests   │ │  Requests   │ │  Management │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    calry.org Proxy                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Request   │ │   Rate      │ │   Data      │ │   Response  │ │
│  │  Routing    │ │  Limiting   │ │  Fetching   │ │  Formatting │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Data Sources                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │     FDC     │ │     OFF     │ │    DSLD     │ │    DSID     │ │
│  │   (USDA)    │ │ (Community) │ │   (NIH)     │ │   (NIH)     │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🔌 ProxyClient Implementation

### Key Functions
```swift
// Search foods across all sources
func searchFoods(query: String, pageSize: Int?) async throws -> ProxySearchResponse

// Get detailed food information
func getFoodDetails(gid: String) async throws -> ProxyFoodDetailResponse

// Lookup food by barcode (returns union type for FDC or OFF)
func lookupByBarcode(barcode: String) async throws -> BarcodeLookupResult

// Handle network errors and retries
func handleNetworkError(_ error: Error) -> ProxyError
```

### Request Flow
1. **App makes request** to ProxyClient
2. **ProxyClient formats** request for calry.org
3. **HTTP request** sent to proxy service
4. **Proxy service routes** to appropriate data source
5. **Data source returns** raw data
6. **Proxy service normalizes** response format
7. **Response returned** to app

## 🌐 API Endpoints

### Base Configuration
```swift
struct ProxyConfiguration {
    static let baseURL = "https://api.calry.org"
    static let timeout: TimeInterval = 30.0
    static let retryCount = 3
    static let rateLimit = 1000 // requests per hour
}
```

### Search Endpoint
```http
GET /search?query={query}&pageSize={limit}
```

**Parameters**:
- `query`: Search term (required)
- `pageSize`: Number of results (optional, default: 50)

**Response**: `ProxySearchResponse`

### Food Details Endpoint
```http
GET /foodDetails/{gid}
```

**Parameters**:
- `gid`: Global ID (required)

**Response**: `ProxyFoodDetailResponse`

### Barcode Endpoint
```http
GET /barcode/{barcode}
```

**Parameters**:
- `barcode`: UPC/EAN barcode (required)

**Response**: `BarcodeLookupResult` (union type)

**Response Types**:
- `BarcodeLookupResult.fdc(FdcEnvelope)` - When barcode redirects to FDC
- `BarcodeLookupResult.off(Envelope<OffReadResponse>)` - When barcode redirects to OFF

**Redirect Handling**:
The barcode endpoint intelligently handles redirects:
- **FDC Redirects**: Returns actual FDC data (`.fdc` case)
- **OFF Redirects**: Returns actual OFF data (`.off` case)
- **No Data Conversion**: Preserves original data source and quality

## 📋 Response Models

### Barcode Lookup Result
```swift
// Union type for barcode lookup results (can be either FDC or OFF)
enum BarcodeLookupResult: Codable {
    case fdc(FdcEnvelope)
    case off(Envelope<OffReadResponse>)
    
    var gid: String {
        switch self {
        case .fdc(let envelope): return envelope.gid ?? "unknown"
        case .off(let envelope): return envelope.gid ?? "unknown"
        }
    }
    
    var source: RawSource {
        switch self {
        case .fdc(let envelope): return envelope.source
        case .off(let envelope): return envelope.source
        }
    }
}
```

### Search Response
```swift
struct ProxySearchResponse: Codable {
    let query: String
    let totalResults: Int
    let pageSize: Int
    let currentPage: Int
    let results: [ProxySearchResult]
}

struct ProxySearchResult: Codable {
    let gid: String
    let source: RawSource
    let description: String
    let brand: String?
    let barcode: String?
    let imageUrl: String?
    let nutritionSummary: NutritionSummary?
}
```

### Food Detail Response
```swift
struct ProxyFoodDetailResponse: Codable {
    let gid: String
    let source: RawSource
    let description: String
    let brand: String?
    let barcode: String?
    let imageUrl: String?
    let ingredients: String?
    let nutrition: [ProxyNutrient]
    let serving: ProxyServing?
    let portions: [ProxyPortion]
    let completeness: CompletenessFlags
}
```

## 🔄 Data Flow

### 1. **Request Processing**
```
App Request → ProxyClient → HTTP Request → calry.org → Data Source
```

### 2. **Response Processing**
```
Data Source → calry.org → HTTP Response → ProxyClient → App Response
```

### 3. **Error Handling**
```
Error → ProxyClient → Retry Logic → Fallback → App Error
```

## 🚨 Error Handling

### Proxy Error Types
```swift
enum ProxyError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case serverUnavailable
    case rateLimited(TimeInterval?)
    case invalidGID(String)
    case proxyError(ProxyApiError)  // Contains specific error details
}
```

### User-Friendly Error Messages
The `ProxyError` enum provides specific, user-friendly error messages:

```swift
// NOT_FOUND cases show specific messages
case let .proxyError(errorResponse):
    if errorResponse.error == "NOT_FOUND" {
        "Product not found in database. Please try a different barcode or search manually."
    } else {
        "Proxy error: \(errorResponse.error)"
    }
```

### Error Conversion Flow
```
ProxyError.proxyError(ProxyApiError) 
    ↓ (FoodDataClientAdapter)
FoodDataError.customError(String)
    ↓ (AddFoodSummaryViewModel)
error.localizedDescription
    ↓ (UI)
User sees specific error message
```

### Retry Logic
```swift
func retryRequest<T>(_ request: () async throws -> T) async throws -> T {
    for attempt in 1...maxRetries {
        do {
            return try await request()
        } catch {
            if attempt == maxRetries {
                throw error
            }
            try await Task.sleep(nanoseconds: UInt64(attempt * 1000) * 1_000_000)
        }
    }
}
```

### Rate Limiting
```swift
class RateLimiter {
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    private var requestTimes: [Date] = []
    
    func canMakeRequest() -> Bool {
        let now = Date()
        requestTimes = requestTimes.filter { now.timeIntervalSince($0) < timeWindow }
        return requestTimes.count < maxRequests
    }
}
```

## 📊 Performance Optimization

### Caching Strategy
```swift
class ProxyCache {
    private let cache = NSCache<NSString, AnyObject>()
    private let ttl: TimeInterval = 3600 // 1 hour
    
    func get<T>(_ key: String) -> T? {
        guard let cached = cache.object(forKey: key as NSString) as? CacheEntry<T> else {
            return nil
        }
        
        if Date().timeIntervalSince(cached.timestamp) > ttl {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        
        return cached.value
    }
}
```

### Request Optimization
- **Batch requests** when possible
- **Pagination** for large result sets
- **Compression** for large responses
- **Connection pooling** for efficiency

## 🔧 Configuration

### API Configuration Service
The app uses a configurable API setup that reads from `.xcconfig` files and `Info.plist`:

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

### Build Configuration (.xcconfig)
```xcconfig
// API Configuration
API_SCHEME = https
API_HOST = api.calry.org
API_BASE_PATH = /v1
```

### Info.plist Configuration
```xml
<key>APIScheme</key>
<string>$(API_SCHEME)</string>
<key>APIHost</key>
<string>$(API_HOST)</string>
<key>APIBasePath</key>
<string>$(API_BASE_PATH)</string>
```

### Environment Settings
```swift
enum ProxyEnvironment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://dev-api.calry.org"
        case .staging:
            return "https://staging-api.calry.org"
        case .production:
            return "https://api.calry.org"
        }
    }
}
```

### Debug Configuration
```swift
struct ProxyDebugConfig {
    let enableLogging: Bool
    let logLevel: LogLevel
    let mockResponses: Bool
    let simulateErrors: Bool
}
```

## 🧪 Testing

### Mock Implementation
```swift
class MockProxyClient: ProxyClient {
    var mockSearchResponse: ProxySearchResponse?
    var mockDetailResponse: ProxyFoodDetailResponse?
    var shouldThrowError: Error?
    
    func searchFoods(query: String, pageSize: Int?) async throws -> ProxySearchResponse {
        if let error = shouldThrowError {
            throw error
        }
        return mockSearchResponse ?? createMockSearchResponse()
    }
}
```

### Integration Testing
```swift
@Test func testProxyIntegration() async throws {
    let client = ProxyClient()
    let response = try await client.searchFoods(query: "apple", pageSize: 10)
    
    #expect(response.results.count > 0)
    #expect(response.query == "apple")
}
```

## 🔍 Monitoring and Debugging

### Request Logging
```swift
func logRequest(_ request: URLRequest) {
    print("🌐 Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
    if let body = request.httpBody {
        print("📦 Body: \(String(data: body, encoding: .utf8) ?? "")")
    }
}
```

### Response Logging
```swift
func logResponse(_ response: URLResponse, data: Data) {
    print("📥 Response: \(response)")
    print("📦 Data: \(String(data: data, encoding: .utf8) ?? "")")
}
```

### Performance Metrics
- **Request duration**: Track response times
- **Success rate**: Monitor success/failure rates
- **Cache hit rate**: Track cache effectiveness
- **Rate limit usage**: Monitor rate limit consumption

## 🎯 Best Practices

### 1. **Error Handling**
- **Graceful degradation** for network issues
- **User-friendly error messages**
- **Retry logic** for transient failures
- **Fallback data** when possible

### 2. **Performance**
- **Cache responses** for repeated requests
- **Use pagination** for large datasets
- **Optimize request size** and frequency
- **Monitor performance** metrics

### 3. **Reliability**
- **Handle rate limits** gracefully
- **Implement retry logic** for failures
- **Use timeouts** to prevent hanging
- **Monitor service health**

This proxy service architecture provides a robust foundation for the Food Scanner app's data integration needs.
