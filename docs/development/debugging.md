# Debugging Guide

## 🔍 Debugging Techniques

This document provides comprehensive debugging techniques and tools for the Food Scanner iOS app.

## 🎯 Debugging Strategy

### 1. **Systematic Approach**
- **Reproduce the issue** consistently
- **Isolate the problem** to specific components
- **Use appropriate tools** for each type of issue

### 2. **Debugging Levels**
- **UI Issues**: SwiftUI Inspector, View Debugging
- **Logic Issues**: Breakpoints, Console Logging
- **Network Issues**: Network Monitor, API Logging
- **Performance Issues**: Instruments, Memory Graph

### 3. **Documentation**
- **Log relevant information** for debugging
- **Document steps** to reproduce issues
- **Track resolution** for future reference

## 🛠️ Xcode Debugging Tools

### Breakpoints
```swift
// Conditional breakpoints
if searchResults.isEmpty {
    // Breakpoint with condition: searchResults.isEmpty
}

// Symbolic breakpoints
// Break on specific function calls
// Break on exceptions
```

### Console Logging
```swift
// Strategic logging
func searchFoods(query: String) async throws -> FoodSearchResponse {
    print("🔍 Starting search for: \(query)")
    
    do {
        let response = try await client.searchFoods(query: query)
        print("✅ Search successful: \(response.results.count) results")
        return response
    } catch {
        print("❌ Search failed: \(error)")
        throw error
    }
}
```

### View Debugging
```swift
// SwiftUI Inspector
struct DebugView: View {
    var body: some View {
        VStack {
            // View hierarchy inspection
            Text("Debug Info")
                .onAppear {
                    print("View appeared")
                }
        }
    }
}
```

## 🌐 Network Debugging

### Request/Response Logging
```swift
class NetworkLogger {
    static func logRequest(_ request: URLRequest) {
        print("🌐 Request:")
        print("  URL: \(request.url?.absoluteString ?? "nil")")
        print("  Method: \(request.httpMethod ?? "nil")")
        print("  Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = request.httpBody {
            print("  Body: \(String(data: body, encoding: .utf8) ?? "nil")")
        }
    }
    
    static func logResponse(_ response: URLResponse, data: Data) {
        print("📥 Response:")
        print("  Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        print("  Headers: \((response as? HTTPURLResponse)?.allHeaderFields ?? [:])")
        print("  Data: \(String(data: data, encoding: .utf8) ?? "nil")")
    }
}
```

### API Error Debugging
```swift
func handleAPIError(_ error: Error) {
    print("🚨 API Error:")
    print("  Type: \(type(of: error))")
    print("  Description: \(error.localizedDescription)")
    
    if let urlError = error as? URLError {
        print("  URLError Code: \(urlError.code)")
        print("  URLError Description: \(urlError.localizedDescription)")
    }
    
    if let decodingError = error as? DecodingError {
        print("  Decoding Error: \(decodingError)")
    }
}
```

## 🧠 State Debugging

### ViewModel State
```swift
@MainActor
@Observable
final class DebugViewModel {
    var state: ViewState = .idle {
        didSet {
            print("🔄 State changed: \(oldValue) -> \(state)")
        }
    }
    
    var searchResults: [FoodMinimalCard] = [] {
        didSet {
            print("📋 Results updated: \(searchResults.count) items")
        }
    }
}
```

### Observable State
```swift
// Monitor state changes
func observeStateChanges() {
    // Use breakpoints to monitor state changes
    // Log state transitions
    // Verify state consistency
}
```

## 🎨 UI Debugging

### SwiftUI Inspector
```swift
struct DebugView: View {
    var body: some View {
        VStack {
            Text("Debug View")
                .background(Color.red)
                .onTapGesture {
                    print("View tapped")
                }
        }
        .debugPrint("DebugView body")
    }
}

extension View {
    func debugPrint(_ message: String) -> some View {
        print("🎨 \(message)")
        return self
    }
}
```

### View Hierarchy
```swift
// Use Xcode's View Debugger
// Inspect view hierarchy
// Check view properties
// Verify layout constraints
```

## 📊 Performance Debugging

### Memory Usage
```swift
// Monitor memory usage
func logMemoryUsage() {
    let memoryInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        print("💾 Memory Usage: \(memoryInfo.resident_size / 1024 / 1024) MB")
    }
}
```

### Performance Monitoring
```swift
func measurePerformance<T>(_ operation: () throws -> T) rethrows -> T {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("⏱️ Operation took \(timeElapsed) seconds")
    return result
}
```

## 🔧 Data Flow Debugging

### Data Journey Tracing
```swift
// Trace data through the system
func traceDataFlow() {
    print("🔄 Data Flow Trace:")
    print("  1. User input received")
    print("  2. ViewModel processes input")
    print("  3. Service makes API call")
    print("  4. Response received")
    print("  5. Data normalized")
    print("  6. UI updated")
}
```

### Service Integration
```swift
func debugServiceIntegration() {
    print("🔧 Service Integration Debug:")
    print("  - ProxyClient: \(proxyClient)")
    print("  - NormalizationService: \(normalizationService)")
    print("  - Converter: \(converter)")
}
```

## 🚨 Error Debugging

### Error Context
```swift
func debugError(_ error: Error, context: String) {
    print("🚨 Error in \(context):")
    print("  Error: \(error)")
    print("  Type: \(type(of: error))")
    print("  Description: \(error.localizedDescription)")
    
    if let nsError = error as NSError? {
        print("  Domain: \(nsError.domain)")
        print("  Code: \(nsError.code)")
        print("  UserInfo: \(nsError.userInfo)")
    }
}
```

### Stack Trace
```swift
func printStackTrace() {
    print("📚 Stack Trace:")
    Thread.callStackSymbols.forEach { symbol in
        print("  \(symbol)")
    }
}
```

## 🔍 Debugging Scenarios

### Search Not Working
```swift
func debugSearchIssue() {
    print("🔍 Debugging Search Issue:")
    print("  1. Check network connectivity")
    print("  2. Verify API endpoint")
    print("  3. Check request parameters")
    print("  4. Verify response format")
    print("  5. Check data processing")
}
```

### UI Not Updating
```swift
func debugUIUpdateIssue() {
    print("🎨 Debugging UI Update Issue:")
    print("  1. Check ViewModel state")
    print("  2. Verify @Observable")
    print("  3. Check SwiftUI binding")
    print("  4. Verify view hierarchy")
}
```

### Performance Issues
```swift
func debugPerformanceIssue() {
    print("⚡ Debugging Performance Issue:")
    print("  1. Check memory usage")
    print("  2. Monitor CPU usage")
    print("  3. Check network requests")
    print("  4. Verify data processing")
}
```

## 🛠️ Debug Tools

### Instruments
- **Time Profiler**: CPU usage analysis
- **Allocations**: Memory allocation tracking
- **Leaks**: Memory leak detection
- **Network**: Network activity monitoring

### Console Commands
```bash
# View device logs
xcrun simctl spawn booted log stream --predicate 'process == "Food Scanner"'

# Check simulator status
xcrun simctl list devices

# Reset simulator
xcrun simctl erase all
```

### Debug Configuration
```swift
struct DebugConfig {
    static let enableLogging = true
    static let logLevel: LogLevel = .debug
    static let enableNetworkLogging = true
    static let enableStateLogging = true
}
```

## 📝 Debugging Checklist

### Before Debugging
- [ ] **Reproduce the issue** consistently
- [ ] **Check recent changes** that might have caused it
- [ ] **Verify environment** (simulator vs device)
- [ ] **Check logs** for error messages

### During Debugging
- [ ] **Use appropriate tools** for the issue type
- [ ] **Log relevant information** at each step
- [ ] **Test hypotheses** systematically
- [ ] **Document findings** as you go

### After Debugging
- [ ] **Verify the fix** works correctly
- [ ] **Test edge cases** to prevent regression
- [ ] **Update documentation** if needed
- [ ] **Share learnings** with the team

## 🎯 Best Practices

### 1. **Systematic Approach**
- **Start with the obvious** and work systematically
- **Use the right tool** for each type of issue
- **Document your process** for future reference

### 2. **Prevention**
- **Write comprehensive tests** to catch issues early
- **Use proper error handling** throughout the app
- **Monitor performance** continuously

### 3. **Learning**
- **Understand the root cause** of issues
- **Learn from debugging** experiences
- **Share knowledge** with the team

This debugging guide provides comprehensive techniques and tools for effectively debugging issues in the Food Scanner app.
