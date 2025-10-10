# Installation Guide

## 🛠️ Setup and Installation

This guide provides detailed setup instructions for the Calry iOS app development environment.

## 📋 Prerequisites

### Required Software
- **Xcode**: 26.0 or later
- **iOS Deployment Target**: 26.0 or later
- **Swift**: 6.2 or later
- **macOS**: 26.0 or later (for development)

### System Requirements
- **macOS**: 26.0 or later
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space for Xcode and simulators
- **Network**: Internet connection for API calls

## 🚀 Installation Steps

### 1. **Install Xcode**
```bash
# Install from App Store or Apple Developer Portal
# Xcode 26.0 or later required
```

### 2. **Install Command Line Tools**
```bash
xcode-select --install
```

### 3. **Clone Repository**
```bash
git clone <repository-url>
cd "Calry"
```

### 4. **Open Project**
```bash
open "Calry.xcodeproj"
```

### 5. **Verify Setup**
- Project opens without errors
- All dependencies resolve correctly
- Simulator is available

## 🔧 Configuration

### No API Key Required
The app uses the calry.org proxy service without authentication:
- **No API key setup** needed
- **No configuration files** required
- **Ready to run** immediately

### Simulator Setup
1. **Open Xcode**
2. **Go to**: Xcode → Settings → Platforms
3. **Download**: Latest iOS Simulator
4. **Select**: iPhone 16 or later

### Device Setup (Optional)
1. **Connect iOS device** via USB
2. **Trust computer** on device
3. **Select device** in Xcode
4. **Enable Developer Mode** on device

## 🧪 Testing Setup

### Unit Tests
- **No additional setup** required
- **Run with**: `Cmd+U` in Xcode
- **CI-friendly**: Works offline

### UI Tests
- **Requires simulator** or device
- **Camera permissions** needed for scanner tests
- **Network access** for API tests

## 🚨 Troubleshooting

### Common Issues

#### Xcode Version Issues
```bash
# Check Xcode version
xcodebuild -version

# Update if needed
# Download from App Store or Apple Developer Portal
```

#### Simulator Issues
```bash
# Reset simulator
xcrun simctl erase all

# List available simulators
xcrun simctl list devices
```

#### Build Issues
```bash
# Clean build folder
Cmd+Shift+K

# Reset derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

#### Network Issues
- **Check internet connection**
- **Verify calry.org accessibility**
- **Test with mock data** if needed

## ✅ Verification

### Build Test
1. **Select simulator** in Xcode
2. **Press Cmd+R** to build and run
3. **Verify app launches** successfully
4. **Check main features** work

### Feature Test
- **Search functionality**: Type food name
- **Barcode scanning**: Scan a product
- **Navigation**: Test all tabs
- **Settings**: Verify configuration

## 🎯 Next Steps

After successful installation:
1. **📖 [First Run Guide](first-run.md)** - Running the app
2. **🏗️ [Architecture Overview](../architecture/README.md)** - Understanding the system
3. **🎯 [Data Journey](../api/data-journey.md)** - Backend flow
4. **💻 [Development Guide](../development/README.md)** - Development workflows

## 🔧 Development Tools

### Recommended Extensions
- **SwiftLint**: Code style enforcement
- **SwiftFormat**: Code formatting
- **GitLens**: Git integration

### Useful Commands
```bash
# Build project
xcodebuild -scheme "Calry" -destination "platform=iOS Simulator,name=iPhone 16"

# Run tests
xcodebuild test -scheme "Calry" -destination "platform=iOS Simulator,name=iPhone 16"

# Clean build
xcodebuild clean -scheme "Calry"
```

## 📞 Support

### Installation Issues
- **Check Xcode version** compatibility
- **Verify macOS version** requirements
- **Review error messages** carefully

### Build Issues
- **Clean build folder** first
- **Check deployment target** settings
- **Verify simulator** availability

This installation guide ensures you have everything needed to start developing with the Calry app!
