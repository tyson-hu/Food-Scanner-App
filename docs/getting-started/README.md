# Getting Started

## 📁 Getting Started Documentation Structure

```
getting-started/
├── README.md                       # 📋 This file - Quick start guide
├── installation.md                 # 🛠️ Setup and installation
└── first-run.md                    # 🚀 Running the app for first time
```

## 🚀 Quick Start Guide

Welcome to the Food Scanner iOS app! This guide will get you up and running quickly.

## ⚡ 5-Minute Setup

### 1. **Prerequisites** (2 minutes)
- **Xcode**: 26.0 or later
- **iOS Deployment Target**: 26.0 or later  
- **Swift**: 6.2 or later  
- **macOS**: 26.0 or later (for development)

### 2. **Clone & Open** (1 minute)
```bash
git clone <repository-url>
cd "Food Scanner"
open "Food Scanner.xcodeproj"
```

### 3. **Setup Local CI Environment** (2 minutes)
```bash
# Run automated setup script
./scripts/setup-local-ci.sh

# Source CI environment variables
source .env.ci
```

### 4. **Build & Run** (2 minutes)
- Select iPhone simulator or device
- Press `Cmd+R` to build and run
- **No API key required** - uses calry.org proxy service

## 🎯 What You'll See

### Main Features
- **🔍 Search**: Text-based food search
- **📷 Scanner**: Barcode scanning with VisionKit
- **📅 Today**: Daily nutrition tracking
- **⚙️ Settings**: App configuration

### Data Sources
- **🇺🇸 FDC**: USDA Food Data Central (comprehensive nutrition)
- **🌍 OFF**: Open Food Facts (community data)

## 🏗️ Project Structure Overview

```
Sources/                           # 📱 All source code
├── App/                           # 🚀 App configuration
├── Config/                        # ⚙️ Configuration files
├── Models/                        # 📋 Data Models
│   ├── API/                       # 🌐 API models + converters
│   └── Core/                      # 🏛️ Core business models
├── Services/                      # 🔧 Business Logic
│   ├── Data/                      # 💾 Data services + processing
│   └── Networking/                # 🌍 Network services
├── ViewModels/                    # 🧠 MVVM ViewModels
└── Views/                         # 🎨 SwiftUI Views
```

## 🎯 Key Concepts

### MVVM Architecture
- **Models**: Data structures and business logic
- **ViewModels**: Business logic and state management  
- **Views**: SwiftUI presentation layer

### Data Flow
```
Raw Proxy Data → Envelope Wrapping → Source Detection → Normalization → Merging → Conversion → Display Models
```

**📖 See [Complete Data Journey](../api/data-journey.md)** for detailed technical flow.

## 🔧 Development Workflow

### 1. **Understanding the Code**
- **Start with [Architecture Overview](../architecture/README.md)**
- **Review [Project Structure](../architecture/project-structure.md)**
- **Study [Data Journey](../api/data-journey.md)**

### 2. **Making Changes**
- **Follow [Coding Standards](../development/coding-standards.md)**
- **Write tests** following [Testing Guidelines](../development/testing.md)
- **Update documentation** when adding new features

### 3. **Testing**
- **Unit tests**: `Tests/Unit/` (CI-friendly)
- **UI tests**: `Tests/UI/` (Local only)
- **Run tests**: `Cmd+U` in Xcode

## 🚨 Common Issues

### Build Issues
- **Clean build folder**: `Cmd+Shift+K`
- **Reset simulator**: Device → Erase All Content and Settings
- **Check deployment target**: iOS 26.0+

### Runtime Issues
- **Camera permissions**: Required for barcode scanning
- **Network connectivity**: Required for API calls
- **Simulator limitations**: Some features work better on device

## 📚 Next Steps

### For New Developers
1. **📖 [Installation Guide](installation.md)** - Detailed setup
2. **🏗️ [Architecture Overview](../architecture/README.md)** - System design
3. **🎯 [Data Journey](../api/data-journey.md)** - Backend flow
4. **💻 [Development Guide](../development/README.md)** - Workflows

### For API Integrators
1. **🌐 [API Overview](../api/README.md)** - API integration
2. **🎯 [Data Journey](../api/data-journey.md)** - Complete flow
3. **🇺🇸 [FDC Integration](../api/fdc-integration.md)** - USDA data
4. **🌍 [OFF Integration](../api/off-integration.md)** - Community data

### For DevOps/CI
1. **🔧 [CI/CD Overview](../ci-cd/README.md)** - Build system
2. **🧪 [Test Strategy](../ci-cd/test-strategy.md)** - Testing approach
3. **🚨 [Troubleshooting](../ci-cd/troubleshooting.md)** - Common issues

## 🎯 Key Files to Know

### Core Services
- **`ProxyClient.swift`**: API communication
- **`FoodNormalizationService.swift`**: Data processing
- **`FoodDataConverter.swift`**: Model conversion
- **`LoggedFoodRepository.swift`**: Database operations

### ViewModels
- **`AddFoodSearchViewModel.swift`**: Search functionality
- **`BarcodeScannerViewModel.swift`**: Scanner logic
- **`TodayViewModel.swift`**: Daily tracking

### Views
- **`AddFoodHomeView.swift`**: Main add food screen
- **`BarcodeScannerView.swift`**: Scanner interface
- **`TodayView.swift`**: Daily nutrition view

## 🔍 Debugging Tips

### 1. **Data Flow Debugging**
- **Check [Data Journey](../api/data-journey.md)** stages
- **Use breakpoints** at key functions
- **Review function headers** for expected behavior

### 2. **UI Debugging**
- **SwiftUI Inspector**: `Cmd+Shift+I`
- **View hierarchy**: Debug → View Debugging
- **State inspection**: Check ViewModel state

### 3. **Network Debugging**
- **Proxy service logs**: Check calry.org responses
- **Error handling**: Review error messages
- **Caching**: Check cache hit/miss rates

## 🚀 Ready to Go!

You're now ready to start developing with the Food Scanner app! 

- **📖 [Installation Guide](installation.md)** for detailed setup
- **🏗️ [Architecture Overview](../architecture/README.md)** for system understanding
- **🎯 [Data Journey](../api/data-journey.md)** for backend flow

Happy coding! 🎉
