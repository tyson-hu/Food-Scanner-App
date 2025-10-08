# Food Scanner App Documentation

Welcome to the comprehensive documentation for the Food Scanner iOS app. This documentation covers all aspects of the project including architecture, API integration, development workflows, and CI/CD.

## 📁 Documentation Structure

```
docs/
├── README.md                           # 📋 This file - Main documentation index
├── getting-started/                     # 🚀 Getting Started
│   ├── README.md                       # Quick start guide with tree map
│   ├── installation.md                 # Setup and installation
│   └── first-run.md                    # Running the app for first time
├── architecture/                        # 🏗️ Architecture
│   ├── README.md                       # Architecture overview with tree map
│   ├── project-structure.md            # Current project organization with tree map
│   ├── mvvm-pattern.md                 # MVVM implementation details
│   └── data-flow.md                    # High-level data flow overview
├── api/                                 # 🌐 API Integration
│   ├── README.md                       # API overview with tree map
│   ├── data-journey.md                 # 🎯 Complete data flow from proxy to UI
│   ├── fdc-integration.md              # FDC-specific integration details
│   ├── off-integration.md              # OFF-specific integration details
│   ├── proxy-service.md                # Proxy service architecture
│   └── schemas/                        # API schemas
│       ├── fdc-api.yaml               # OpenAPI 3.0 specification for FDC
│       └── off-api.yaml               # OpenAPI 3.0 specification for OFF
├── development/                         # 💻 Development
│   ├── README.md                       # Development overview with tree map
│   ├── local-ci-setup.md               # Local CI environment setup guide
│   ├── coding-standards.md             # Code style and standards
│   ├── testing.md                      # Testing guidelines
│   └── debugging.md                    # Debugging guide
├── ci-cd/                               # 🔧 CI/CD
│   ├── README.md                       # CI/CD overview with tree map
│   ├── build-process.md                # Build configuration
│   ├── test-strategy.md                # Testing strategy
│   └── troubleshooting.md              # Common issues
└── changelog/                           # 📝 Change Logs
    ├── README.md                       # Changelog overview
    └── v0.3.0.md                       # Version 0.3.0 - Initial release + Code quality improvements
```

## 🚀 Quick Start

### For New Developers
1. **📖 [Getting Started](getting-started/README.md)** - Quick start guide
2. **🏗️ [Architecture Overview](architecture/README.md)** - Understand the system
3. **🎯 [Data Journey](api/data-journey.md)** - How data flows through the system
4. **💻 [Development Guide](development/README.md)** - Development workflows
5. **🔧 [Local CI Setup](development/local-ci-setup.md)** - Match CI environment locally

### For API Integrators
1. **🌐 [API Overview](api/README.md)** - API integration guide
2. **🎯 [Data Journey](api/data-journey.md)** - Complete data flow
3. **🇺🇸 [FDC Integration](api/fdc-integration.md)** - USDA data processing
4. **🌍 [OFF Integration](api/off-integration.md)** - Community data handling

### For DevOps/CI
1. **🔧 [CI/CD Overview](ci-cd/README.md)** - Build and deployment
2. **🧪 [Test Strategy](ci-cd/test-strategy.md)** - Testing approach
3. **🚨 [Troubleshooting](ci-cd/troubleshooting.md)** - Common issues

## 📋 Documentation Overview

### 🚀 Getting Started
**Essential guides for new team members**:
- **Quick Start**: Get up and running in minutes
- **Installation**: Setup and configuration
- **First Run**: Running the app for the first time
- **Local CI Setup**: Match CI environment for consistent development

### 🏗️ Architecture
**System design and structure**:
- **Project Structure**: Current organization with tree maps
- **MVVM Pattern**: Implementation details and patterns
- **Data Flow**: High-level system flow
- **Component Overview**: Key services and their roles

### 🌐 API Integration
**Backend data processing**:
- **Data Journey**: Complete flow from proxy to UI (⭐ **START HERE**)
- **FDC Integration**: USDA Food Data Central processing
- **OFF Integration**: Open Food Facts processing
- **Proxy Service**: calry.org integration
- **API Schemas**: OpenAPI specifications

### 💻 Development
**Development workflows and standards**:
- **Coding Standards**: Code style and conventions
- **Testing**: Unit, integration, and UI testing
- **Debugging**: Tools and techniques
- **Best Practices**: Development guidelines

### 🔧 CI/CD
**Build and deployment**:
- **Build Process**: Configuration and setup
- **Test Strategy**: Testing approach and coverage
- **Troubleshooting**: Common build issues
- **Performance**: Optimization and monitoring

## 🎯 Key Features

### 🍎 Core Functionality
- **Food Search**: Text-based search with real-time results
- **Barcode Scanning**: VisionKit-powered barcode recognition
- **Photo Recognition**: AI-powered food recognition (coming soon)
- **Nutrition Tracking**: Daily food intake logging
- **Multi-Source Data**: FDC and OFF support

### 🔧 Technical Features
- **Proxy Architecture**: Reliable data access through calry.org
- **Smart Caching**: Intelligent caching for performance
- **Data Normalization**: Unit conversion and standardization
- **Error Handling**: Comprehensive error management
- **Offline Support**: Cached data when network unavailable

## 🏗️ Project Structure

The app follows a clean iOS-focused MVVM architecture:

```
Sources/                           # 📱 All source code
├── App/                          # 🚀 App configuration
├── Models/                       # 📋 Data Models
│   ├── API/                      # 🌐 API models + converters
│   │   ├── Common/              # 🔄 Shared API structures
│   │   ├── FDC/                 # 🇺🇸 USDA Food Data Central
│   │   └── OFF/                 # 🌍 Open Food Facts
│   └── Core/                    # 🏛️ Core business models
├── Services/                     # 🔧 Business Logic
│   ├── Data/                    # 💾 Data services + processing
│   │   ├── Caching/            # 🗄️ Cache services
│   │   ├── Persistence/        # 💿 Database layer
│   │   └── Processing/         # ⚙️ Data processing
│   └── Networking/             # 🌍 Network services
├── ViewModels/                  # 🧠 MVVM ViewModels
│   ├── AddFood/                # ➕ Add food flow
│   ├── Scanner/                # 📷 Barcode scanning
│   ├── Today/                  # 📅 Today view
│   └── PhotoIntake/            # 📸 Photo recognition
└── Views/                       # 🎨 SwiftUI Views
    ├── AddFood/                 # ➕ Add food screens
    │   ├── FoodView.swift       # Main food display (shared)
    │   ├── FoodDetailsView.swift # Detailed food display (shared)
    │   ├── Scanner/             # 📷 Scanner screens
    │   ├── PhotoIntake/         # 📸 Photo recognition
    │   └── Search/              # 🔍 Text search
    ├── Today/                   # 📅 Today screens
    ├── Settings/                # ⚙️ Settings screens
    ├── Profile/                 # 👤 Profile screens
    └── Design/                  # 🎨 Design system
        └── Components/          # 🧩 UI components
```

## 🧪 Testing Structure

Tests mirror the source structure for easy navigation:

```
Tests/                             # 🧪 Test code
├── Unit/                          # 🔬 Unit tests (CI-friendly)
│   ├── Models/                    # 📋 Model tests
│   ├── Services/                  # 🔧 Service tests
│   └── ViewModels/                # 🧠 ViewModel tests
└── UI/                            # 🎨 UI tests (Local only)
    ├── Screens/                   # 📱 Screen tests
    └── BaseUITestCase.swift       # 🧪 UI test base
```

## 🎯 Data Flow Journey

The complete data journey from raw proxy data to cooked display data:

```
Raw Proxy Data → Envelope Wrapping → Source Detection → Normalization → Merging → Conversion → Display Models
     ↓              ↓                    ↓              ↓            ↓         ↓           ↓
  JSON Response  Envelope<T>         RawSource      NormalizedFood  Merged   FoodCard  UI Display
```

**📖 See [Complete Data Journey](api/data-journey.md)** for detailed technical flow with function headers and visual diagrams.

## 🔧 Development Tools

### Required Tools
- **Xcode**: 26.0 or later
- **iOS Deployment Target**: 26.0 or later
- **Swift**: 6.2 or later
- **macOS**: 26.0 or later (for development)

### Key Dependencies
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Modern data persistence
- **VisionKit**: Barcode scanning capabilities
- **Observation**: Reactive state management

### Code Quality Tools
- **SwiftLint**: Code style enforcement (0 violations)
- **SwiftFormat**: Automatic code formatting (conflict-free)
- **Custom Rules**: Project-specific linting rules
- **CI/CD Integration**: Automated code quality checks

## 📊 Project Status

### ✅ Completed Features
- Multi-source data support (FDC, OFF)
- Barcode scanning with VisionKit
- Smart caching and offline support
- Comprehensive error handling
- Clean MVVM architecture
- CI/CD pipeline with offline mode
- Code quality tools integration (SwiftLint + SwiftFormat)
- Comprehensive documentation and changelog system

### 🚧 In Progress
- Photo recognition with AI
- Enhanced UI/UX improvements

### 📋 Planned Features
- **v0.3.1**: Food entry support for current food data
- **Enhanced Tracking**: Improved nutrition tracking capabilities
- **Data Management**: Better food data management and persistence

## 🤝 Contributing

### For Developers
1. **Read [Getting Started](getting-started/README.md)** first
2. **Understand [Architecture](architecture/README.md)** before coding
3. **Follow [Coding Standards](development/coding-standards.md)**
4. **Write tests** following [Testing Guidelines](development/testing.md)

### For Documentation
1. **Keep tree maps updated** when adding new files
2. **Include function headers** with explanations
3. **Use visual diagrams** for complex flows
4. **Cross-reference** related documents

## 📞 Support

### Documentation Issues
- **Missing information**: Check if it's in another document
- **Outdated content**: Create an issue with details
- **Unclear explanations**: Suggest improvements

### Development Issues
- **Build problems**: See [CI/CD Troubleshooting](ci-cd/troubleshooting.md)
- **API questions**: Check [Data Journey](api/data-journey.md)
- **Architecture questions**: Review [Architecture Overview](architecture/README.md)

This documentation provides everything needed to understand, develop, and maintain the Food Scanner iOS app.