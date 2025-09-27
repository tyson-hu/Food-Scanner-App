# Food Scanner

A modern iOS app for tracking nutrition and food intake, built with SwiftUI and SwiftData.

## Features

### 🍎 Core Functionality
- **Food Search**: Search for foods using text queries with real-time results
- **Barcode Scanning**: Scan product barcodes using VisionKit for instant food lookup
- **Photo Recognition**: AI-powered food recognition from photos (coming soon)
- **Nutrition Tracking**: Log daily food intake with detailed nutrition information
- **Today View**: View daily nutrition totals and food entries
- **Smart Caching**: Intelligent caching system for improved performance and offline support

### 🔧 Technical Features
- **Proxy Architecture**: Routes requests through `https://api.calry.org` for reliable food data
- **Comprehensive Schema**: Full FDC API field coverage with proper normalization
- **Advanced Pagination**: Efficient pagination with "Load More" functionality
- **Retry Logic**: Exponential backoff for network failures and rate limits
- **Data Normalization**: Smart unit conversion and energy standardization
- **Offline Support**: Cached data available when network is unavailable
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Performance**: Optimized for speed with debounced search and intelligent caching

## Architecture

### Networking Layer
- **FDCProxyClient**: Routes requests through calry.org proxy with retry logic
- **FDCCachedClient**: Transparent caching wrapper for improved performance
- **FDCMock**: Mock client for development and testing
- **FDCClientFactory**: Environment-based client selection
- **DataNormalization**: Utility for unit conversion and data standardization

### Data Layer
- **SwiftData**: Modern data persistence with automatic sync
- **FDCCacheService**: In-memory caching with 7-day TTL
- **FoodEntry**: Core data model for logged foods

### UI Layer
- **SwiftUI**: Modern declarative UI framework
- **VisionKit**: Barcode scanning with DataScannerViewController
- **Observation**: Reactive state management
- **NavigationStack**: Modern navigation patterns

## Setup

### Prerequisites
- Xcode 16.0+
- iOS 18.0+ target
- Swift 6.0+

### Installation
1. Clone the repository
2. Open `Food Scanner.xcodeproj` in Xcode
3. Build and run on simulator or device

### Configuration
The app uses environment-based configuration:

- **Debug**: Mock client by default, proxy with override
- **Release**: Proxy client by default

To enable proxy client in debug mode:
```swift
UserDefaults.standard.set(true, forKey: "feature.fdcRemote")
```

## Testing

### Unit Tests
```bash
xcodebuild test -scheme "Food Scanner" -destination "platform=iOS Simulator,name=iPhone 16"
```

### Integration Tests
To run integration tests that make live API calls:
```bash
RUN_INTEGRATION_TESTS=1 xcodebuild test -scheme "Food Scanner"
```

### Test Categories
- **Unit Tests**: Fast, deterministic tests using mock data
- **Integration Tests**: Live API tests (disabled by default)
- **UI Tests**: End-to-end user flow testing

## API Integration

### FDC Proxy Client
The app integrates with the Food Data Central (FDC) API through a proxy service:

- **Base URL**: `https://api.calry.org`
- **Search Endpoint**: `/foods/search` (Branded foods only)
- **Details Endpoint**: `/food/{fdcId}`
- **Authentication**: Optional headers for production use

### M2-03 Enhancements
- **Comprehensive Schema**: Full field coverage including label nutrients, serving info, and metadata
- **Data Normalization**: Smart unit conversion (kJ→kcal, μg/mcg aliases, etc.)
- **Advanced Pagination**: Proper page handling with `hasMore` computation
- **Retry Logic**: Exponential backoff for 429/5xx errors with configurable retry attempts
- **Enhanced Caching**: Separate caches for paginated vs. simple search results

### Response Handling
- **Field Mapping**: Robust fallbacks for missing data with comprehensive schema coverage
- **Error Recovery**: User-friendly error messages with actionable guidance
- **Pagination**: Support for large result sets with stable "Load More" behavior

## Caching

### Cache Strategy
- **TTL**: 7-day expiration for cached data
- **Size Limit**: 1000 items maximum
- **Eviction**: LRU (Least Recently Used) policy
- **Types**: Separate caches for search results and food details

### Cache Management
- **Settings UI**: View cache statistics and clear cache manually
- **Automatic Cleanup**: Expired entries removed automatically
- **Memory Management**: Prevents memory bloat with size limits

## Error Handling

### Error Types
- **Network Errors**: Connection issues, timeouts
- **API Errors**: HTTP status codes (400, 401, 403, 404, 429, 5xx)
- **Data Errors**: JSON parsing failures, missing fields
- **User Errors**: Empty searches, invalid inputs

### Recovery
- **Retry Logic**: Automatic retry for transient failures with exponential backoff
- **User Guidance**: Clear error messages with actionable advice
- **Fallback**: Graceful degradation when services unavailable

## Barcode Scanning

### VisionKit Integration
- **DataScannerViewController**: Modern barcode scanning with iOS 16+ support
- **Real-time Detection**: Instant barcode recognition with visual feedback
- **Permission Handling**: Graceful camera permission management
- **Haptic Feedback**: Tactile confirmation on successful scans

### Supported Formats
- **UPC/EAN**: Standard product barcodes
- **Code128**: Extended barcode support
- **QR Codes**: Additional format support

### User Experience
- **Camera Overlay**: Clear scanning instructions and guidance
- **Error Handling**: User-friendly messages for permission issues
- **Settings Integration**: Direct link to camera settings when needed

## Performance

### Optimization Features
- **Debounced Search**: 250ms delay prevents excessive API calls
- **Request Cancellation**: Previous searches cancelled when new input received
- **Caching**: Instant results for previously searched terms
- **Memory Management**: Automatic cleanup prevents memory leaks

### Metrics
- **Search Latency**: < 250ms for first search on CI
- **Cache Hit Rate**: Monitored for optimization opportunities
- **Memory Usage**: Tracked to prevent bloat

## Privacy & Security

### Data Protection
- **Local Storage**: Food entries stored locally using SwiftData
- **No Personal Data**: No user accounts or personal information collected
- **API Keys**: No hardcoded secrets, proper configuration management
- **Privacy Manifest**: Comprehensive privacy declarations

### Network Security
- **HTTPS**: All API calls use secure connections
- **Authentication**: Ready for production authentication headers
- **Rate Limiting**: Respects API rate limits with backoff

## Development

### Code Organization
- **Models**: Split into focused files by domain
- **Services**: Clear separation of concerns
- **Views**: SwiftUI components with proper state management
- **Tests**: Comprehensive test coverage

### Dependencies
- **SwiftData**: Data persistence
- **SwiftUI**: User interface
- **Combine**: Reactive programming
- **Foundation**: Core system APIs

### Build Configuration
- **Debug**: Development settings with mock client
- **Release**: Production settings with proxy client
- **Testing**: Separate test plans for different test categories

## Contributing

### Development Workflow
1. Create feature branch from `master`
2. Implement changes with tests
3. Run full test suite including integration tests
4. Submit pull request with proper documentation

### Code Standards
- **Swift 6.0**: Modern Swift with strict concurrency
- **SwiftUI**: Declarative UI patterns
- **Testing**: Comprehensive test coverage
- **Documentation**: Clear code documentation and comments

### Pull Request Requirements
- [ ] iOS 26 SDK; no deprecated APIs
- [ ] Feature flagged if risky
- [ ] Tests updated/added (unit/UI/snapshot)
- [ ] Accessibility pass (VoiceOver, Dynamic Type)
- [ ] Performance considered (debounce, caching, main-thread)
- [ ] Privacy reviewed; no secrets in code
- [ ] docs/CHANGELOG updated

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the GitHub Issues system.

## Acknowledgments

- Food Data Central (FDC) for providing comprehensive nutrition data
- Apple for SwiftUI and SwiftData frameworks
- The Swift community for best practices and patterns
