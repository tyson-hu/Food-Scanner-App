# Swift 6 Concurrency Configuration Guide

This guide explains how to configure your local development environment to match the CI environment's Swift 6 strict concurrency checking.

## 🎯 Why This Matters

The CI environment uses **Xcode 26** with **Swift 6 strict concurrency checking** enabled. This catches concurrency issues that might not be visible in local development with Swift 5 compatibility mode.

**Common Issues Caught by Swift 6:**
- Main actor-isolated default values in nonisolated contexts
- Improper `@Sendable` conformance
- Missing `nonisolated` annotations
- Actor isolation violations

## 🔧 Configuration Options

### Option 1: Use Enhanced Build Scripts (Recommended)

We've created scripts that enable Swift 6 strict concurrency checking:

```bash
# Build with Swift 6 strict concurrency
./scripts/build-with-swift6-strict.sh

# Test with Swift 6 strict concurrency  
./scripts/test-with-swift6-strict.sh
```

These scripts use the same Swift 6 flags as CI:
- `SWIFT_UPCOMING_FEATURE_STRICT_CONCURRENCY=YES`
- `SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY=YES`
- `SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES=YES`
- `SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT=YES`
- `SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES=YES`
- `SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_INFERENCE=YES`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY=YES`

### Option 2: Update Project Settings in Xcode

1. Open `Food Scanner.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to **Build Settings**
4. Search for **"Swift Language Version"**
5. Change from **"Swift 5"** to **"Swift 6"**
6. Search for **"Swift Concurrency Checking"**
7. Set to **"Complete"** or **"Minimal"**

### Option 3: Use xcodebuild with Build Settings

```bash
# Build with Swift 6 strict concurrency
xcodebuild build \
    -scheme "Food Scanner" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    SWIFT_UPCOMING_FEATURE_STRICT_CONCURRENCY=YES \
    SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY=YES \
    SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES=YES \
    SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT=YES \
    SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES=YES \
    SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_INFERENCE=YES \
    SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY=YES
```

## 🚀 Workflow Integration

### Pre-commit Checks

Add Swift 6 strict concurrency checking to your pre-commit workflow:

```bash
#!/bin/bash
# pre-commit-check.sh

echo "🔍 Running pre-commit checks..."

# Swift 6 strict concurrency build
echo "📱 Building with Swift 6 strict concurrency..."
if ! ./scripts/build-with-swift6-strict.sh; then
    echo "❌ Swift 6 strict concurrency build failed"
    exit 1
fi

# Swift 6 strict concurrency tests
echo "🧪 Testing with Swift 6 strict concurrency..."
if ! ./scripts/test-with-swift6-strict.sh; then
    echo "❌ Swift 6 strict concurrency tests failed"
    exit 1
fi

echo "✅ All pre-commit checks passed!"
```

### VS Code / Cursor Integration

Add these tasks to your `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build Swift 6 Strict",
            "type": "shell",
            "command": "./scripts/build-with-swift6-strict.sh",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Test Swift 6 Strict",
            "type": "shell",
            "command": "./scripts/test-with-swift6-strict.sh",
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ]
}
```

## 🔍 Troubleshooting

### Common Swift 6 Concurrency Errors

#### 1. "Main actor-isolated default value in a nonisolated context"

**Problem:**
```swift
// ❌ This fails in Swift 6
nonisolated static func create(at date: Date = Date()) -> MyType
```

**Solution:**
```swift
// ✅ Use .now instead
nonisolated static func create(at date: Date = .now) -> MyType
```

#### 2. "Call to main actor-isolated static method in a synchronous nonisolated context"

**Problem:**
```swift
// ❌ This fails in Swift 6
static func from(data: Data) -> MyType {
    // Some main actor-isolated code
}
```

**Solution:**
```swift
// ✅ Mark as nonisolated
nonisolated static func from(data: Data) -> MyType {
    // Some main actor-isolated code
}
```

#### 3. "Conformance of 'MyType' to 'Sendable' cannot be used in nonisolated context"

**Problem:**
```swift
// ❌ This fails in Swift 6
struct MyType: @unchecked Sendable {
    // Implementation
}
```

**Solution:**
```swift
// ✅ Make it properly Sendable
struct MyType: Sendable {
    // Implementation with only Sendable properties
}
```

### Environment Differences

| Setting | Local (Default) | CI | Swift 6 Strict |
|---------|----------------|----|----------------|
| Swift Version | 5.0 | 6.0 | 6.0 |
| Concurrency Checking | Minimal | Strict | Strict |
| Actor Isolation | Relaxed | Strict | Strict |
| Sendable Inference | Basic | Advanced | Advanced |

## 📚 Additional Resources

- [Swift 6 Concurrency Migration Guide](https://docs.swift.org/swift-book/GuidedTour/Concurrency.html)
- [Swift 6 Language Guide](https://docs.swift.org/swift-book/)
- [Swift Concurrency Best Practices](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)

## 🎉 Benefits

By using Swift 6 strict concurrency checking locally:

✅ **Catch Issues Early**: Find concurrency problems before CI  
✅ **Consistent Environment**: Local matches CI exactly  
✅ **Better Code Quality**: Enforce proper concurrency patterns  
✅ **Faster Development**: No surprise CI failures  
✅ **Future-Proof**: Ready for Swift 6 adoption  

---

*This configuration ensures your local development environment matches the CI environment's Swift 6 strict concurrency checking, helping you catch concurrency issues early and maintain code quality.*
