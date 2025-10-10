# Architecture Documentation

## 📁 Architecture Documentation Structure

```
architecture/
├── README.md                       # 📋 This file - Architecture overview
├── project-structure.md            # 🏗️ Current project organization with tree map
├── mvvm-pattern.md                 # 🧠 MVVM implementation details
└── data-flow.md                    # 📊 High-level data flow overview
```

## 🏗️ Architecture Overview

The Calry app follows a clean iOS-focused MVVM architecture with clear separation of concerns and modular design.

## 🎯 Key Architectural Principles

### 1. **iOS-First Design**
- No unnecessary platform abstraction
- SwiftUI-native implementation
- iOS-specific optimizations

### 2. **MVVM Pattern**
- **Models**: Data structures and business logic
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI presentation layer

### 3. **Clean Separation**
- **API Layer**: External data sources
- **Local CI Environment**: Development environment matching CI exactly
- **Service Layer**: Business logic and processing
- **UI Layer**: Presentation and user interaction

### 4. **Modular Design**
- **Single Responsibility**: Each component has one clear purpose
- **Dependency Injection**: Loose coupling between components
- **Testable Architecture**: Easy to unit test each layer

## 📊 High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Search    │ │   Scanner   │ │   Today     │ │  Settings   │ │
│  │    View     │ │    View     │ │    View     │ │    View     │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ViewModels Layer                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Search    │ │   Scanner   │ │   Today     │ │  Settings   │ │
│  │ ViewModel   │ │ ViewModel   │ │ ViewModel   │ │ ViewModel   │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Services Layer                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Data      │ │   Caching   │ │   Network   │ │ Processing  │ │
│  │ Services    │ │  Services   │ │  Services   │ │  Services   │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   SwiftData │ │   Cache     │ │   Network   │ │   Models    │ │
│  │  Database   │ │   Storage   │ │   Requests  │ │   Storage   │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Component Responsibilities

### 📱 UI Layer (`Sources/UI/`)
**Responsibility**: User interface and user interaction
- **Screens**: Complete screen implementations
- **Components**: Reusable UI components
- **Design System**: Consistent visual elements

### 🧠 ViewModels Layer (`Sources/ViewModels/`)
**Responsibility**: Business logic and state management
- **State Management**: Observable state for UI
- **Business Logic**: User action processing
- **Data Coordination**: Orchestrating service calls

### 🔧 Services Layer (`Sources/Services/`)
**Responsibility**: Business logic and data processing
- **Data Services**: Persistence and caching
- **External Services**: API communication
- **Processing Services**: Data normalization and conversion

### 📋 Models Layer (`Sources/Models/`)
**Responsibility**: Data structures and business entities
- **API Models**: External data structures
- **Core Models**: Internal business entities
- **Converters**: Data transformation logic

## 🔄 Data Flow Architecture

### 1. **User Interaction Flow**
```
User Action → View → ViewModel → Service → Data Layer
     ↑                                    ↓
     └────────── UI Update ←──────────────┘
```

### 2. **Data Processing Flow**
```
External API → Proxy Client → Normalization → Merging → Conversion → ViewModel → View
```

### 3. **State Management Flow**
```
ViewModel State → Observable → SwiftUI Binding → View Update
```

## 🏗️ Project Structure

**📖 See [Project Structure](project-structure.md)** for detailed organization with tree maps.

### Key Directories
- **`Sources/Models/`**: Data structures and business entities
- **`Sources/Services/`**: Business logic and data processing
- **`Sources/ViewModels/`**: Business logic for UI
- **`Sources/Views/`**: User interface components
- **`Tests/`**: Test code mirroring source structure

## 🧠 MVVM Implementation

**📖 See [MVVM Pattern](mvvm-pattern.md)** for detailed implementation.

### Key Patterns
- **Observable ViewModels**: Using `@Observable` for state management
- **Dependency Injection**: Services injected into ViewModels
- **Single Source of Truth**: ViewModels manage all state
- **Reactive Updates**: SwiftUI automatically updates on state changes

## 📊 Data Flow

**📖 See [Data Flow](data-flow.md)** for high-level system flow.

### Key Flows
- **Search Flow**: Text input → API call → Results display
- **Barcode Flow**: Camera → Barcode detection → Product lookup
- **Logging Flow**: Food selection → Serving input → Database storage
- **Sync Flow**: Local changes → Cloud sync → Conflict resolution

## 🔧 Key Services

### Data Services
- **FoodNormalizationService**: Data normalization and merging
- **FoodDataConverter**: Public model conversion
- **LoggedFoodRepository**: Database operations
- **FDCCacheService**: Caching and offline support

### External Services
- **ProxyClient**: API communication
- **FoodDataClient**: Unified API interface
- **ProductSourceDetection**: Source identification

### Processing Services
- **FDCNormalizer**: FDC data processing
- **OFFNormalizer**: OFF data processing
- **UnitConversion**: Unit standardization

## 🧪 Testing Architecture

### Test Structure
- **Unit Tests**: Individual component testing
- **Integration Tests**: Service interaction testing
- **UI Tests**: User interface testing
- **Mock Services**: Test doubles for external dependencies

### Test Organization
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

## 🎯 Design Decisions

### 1. **Why MVVM?**
- **Separation of Concerns**: Clear boundaries between layers
- **Testability**: Easy to unit test business logic
- **SwiftUI Integration**: Natural fit with reactive UI
- **Maintainability**: Easy to modify and extend

### 2. **Why iOS-First?**
- **Simplicity**: No unnecessary abstraction overhead
- **Performance**: iOS-specific optimizations
- **Maintainability**: Easier to understand and modify
- **SwiftUI**: Leverages platform-specific features

### 3. **Why Modular Services?**
- **Single Responsibility**: Each service has one clear purpose
- **Testability**: Easy to mock and test individual services
- **Reusability**: Services can be used across multiple ViewModels
- **Maintainability**: Changes isolated to specific services

## 🚀 Future Considerations

### Scalability
- **Service Expansion**: Easy to add new data sources
- **Feature Addition**: Modular design supports new features
- **Performance**: Caching and optimization strategies in place

### Maintainability
- **Clear Boundaries**: Well-defined interfaces between layers
- **Documentation**: Comprehensive documentation for each component
- **Testing**: Good test coverage for reliability

This architecture provides a solid foundation for the Calry app with clear separation of concerns, good testability, and maintainable design.
