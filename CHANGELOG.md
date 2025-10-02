# Changelog

All notable changes to the Food Scanner app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **M2-02: FDC Proxy Client Architecture** - Implemented proxy-based architecture for Add Food (text) feature
  - `ProxyClient` - New client implementation that routes requests through `https://api.calry.org`
  - `ProxySearchResponse`, `ProxyFoodDetailResponse` - Response models matching FDC envelope structure
  - `FoodDataClientFactory` - Environment-based client selection (proxy vs mock)
  - **Search Endpoint**: `/foods/search` with proper query parameters (`query`, `dataType=Branded`, `pageSize`, `pageNumber`)
  - **Details Endpoint**: `/food/{fdcId}` for fetching individual food details
  - **Field Mapping**: Robust fallbacks for `title`, `brand`, `serving`, and `upc` fields
  - **Pagination**: Uses `currentPage` and `totalPages` from response envelope
  - **Error Handling**: Comprehensive error types with user-friendly messages and recovery suggestions
  - **Caching Layer**: `FDCCacheService` with 7-day TTL and LRU eviction policy
  - **Cache Management**: Settings UI with real-time statistics and manual clearing
  - **Integration Tests**: Comprehensive test suite with `@ProxyE2E` tagged tests
  - **Environment Configuration**: Runtime override and build-time remote mode selection

### Enhanced
- **Error Handling**: Added comprehensive error types (`decodingError`, `noResults`, `serverUnavailable`)
- **User Experience**: Clear, actionable error messages with specific guidance
- **Performance**: Intelligent caching reduces API calls and improves app responsiveness
- **Code Organization**: Split large model files into focused, maintainable modules
- **Testing**: Enhanced test coverage with both unit and integration tests

### Technical Details
- **Proxy Configuration**: Base URL `https://api.calry.org` with optional authentication headers
- **Cache Configuration**: 7-day TTL, 1000 item limit, LRU eviction policy
- **Error Recovery**: Specific guidance for 400, 401, 403, 404, 429, and 5xx HTTP errors
- **Network Optimization**: Request deduplication and intelligent retry strategies
- **Memory Management**: Automatic cache cleanup prevents memory bloat

### Security
- **No Authentication Required**: Uses proxy service without API keys or secrets
- **Request Security**: Optional authentication headers ready for production
- **Privacy**: Comprehensive privacy manifest with proper API usage declarations

## [0.1.0] - 2025-09-17

### Added
- Initial release of Food Scanner app
- Basic food logging functionality
- SwiftData persistence layer
- Mock FDC client for development
- Core UI components and navigation
- Today view with nutrition tracking
- Add Food functionality with search
- Settings and profile views

### Technical
- iOS 26 SDK with Swift 6.0
- SwiftData for data persistence
- SwiftUI for user interface
- Combine for reactive programming
- Modern async/await patterns throughout
