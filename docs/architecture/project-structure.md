# Project Structure Documentation

## 🏗️ Current Project Organization

The Calry app follows a clean iOS-focused MVVM architecture with clear separation of concerns, enhanced with comprehensive food logging capabilities. This document provides a detailed tree map of the current project structure.

## 📁 Complete Project Structure

```
Calry/
├── Sources/                           # 📱 All source code
│   ├── App/                           # 🚀 App configuration
│   │   ├── CalryApp.swift                       # Main app entry point
│   │   ├── RootView.swift                             # Root view controller
│   │   ├── AppEnvironment.swift                       # Dependency injection
│   │   ├── AppLaunchEnvironment.swift                 # Launch environment
│   │   └── AppTab.swift                               # Tab bar configuration
│   ├── Config/                        # ⚙️ Configuration files
│   │   └── TestConfig.swift                           # Test configuration
│   ├── Models/                        # 📋 Data Models
│   │   ├── API/                       # 🌐 API models + converters
│   │   │   ├── Common/                # 🔄 Shared API structures
│   │   │   │   ├── FoodEnvelopeModels.swift    # Generic envelope wrapper
│   │   │   │   ├── FoodModels.swift             # Unified response models
│   │   │   │   ├── AddFoodLogPayload.swift      # Logging payload model
│   │   │   │   └── AnyCodable.swift             # Dynamic JSON handling
│   │   │   ├── FDC/                    # 🇺🇸 USDA Food Data Central
│   │   │   │   ├── FDCNutrientModels.swift      # FDC nutrient models
│   │   │   │   ├── FDCLegacyModels.swift         # Legacy FDC compatibility
│   │   │   │   └── Converters/                   # 🔄 FDC-specific converters
│   │   │   │       ├── FDCConversionExtensions.swift  # FDC conversion extensions
│   │   │   │       ├── FDCModelConverter.swift         # FDC model converter
│   │   │   │       └── FDCNutrientParser.swift         # FDC nutrient parser
│   │   │   └── OFF/                    # 🌍 Open Food Facts
│   │   │       └── OFFModels.swift     # OFF models (no converters needed)
│   │   └── Core/                       # 🏛️ Core business models
│   │       └── LoggedFoodEntry.swift   # User's logged food entries
│   ├── Services/                       # 🔧 Business Logic
│   │   ├── Data/                       # 💾 Data services + processing
│   │   │   ├── Caching/                # 🗄️ Cache services
│   │   │   │   └── FDCCacheService.swift    # Cache implementation
│   │   │   ├── Persistence/            # 💿 Database layer
│   │   │   │   ├── Models/             # 📋 Database models
│   │   │   │   │   └── LoggedFoodEntryBuilder.swift # Entry builder
│   │   │   │   └── Repositories/       # 📚 Database operations
│   │   │   │       ├── LoggedFoodRepository.swift          # Repository protocol
│   │   │   │       └── LoggedFoodRepositorySwiftData.swift # SwiftData implementation
│   │   │   └── Processing/             # ⚙️ Data processing
│   │   │       ├── Normalization/      # 🔄 Business logic normalization
│   │   │       │   ├── FoodNormalizationService.swift      # Main normalization service
│   │   │       │   ├── FDC/            # 🇺🇸 FDC normalization
│   │   │       │   │   └── FDCNormalizer.swift             # FDC-specific normalizer
│   │   │       │   └── OFF/            # 🌍 OFF normalization
│   │   │       │       └── OFFNormalizer.swift             # OFF-specific normalizer
│   │   │       └── Utilities/          # 🛠️ Unit conversion utilities
│   │   │           ├── UnitConversion.swift                # Unit conversion
│   │   │           └── ProductSourceDetection.swift        # Source detection
│   │   ├── Internal/                   # 🔧 Internal services
│   │   │   └── APIConfiguration.swift                     # API configuration service
│   │   └── Networking/                 # 🌍 Network services
│   │       ├── FoodDataClient.swift                    # Base API client protocol
│   │       ├── ProxyClient.swift                       # Proxy API client
│   │       ├── FoodDataCachedClient.swift              # Cached client wrapper
│   │       ├── FoodDataClientAdapter.swift             # Adapter implementation
│   │       ├── FoodDataConverter.swift                 # Public model converter
│   │       ├── FoodDataNormalizer.swift                # Search normalization
│   │       ├── FoodDataClientFactory.swift             # Client factory
│   │       └── FDCMock.swift                          # Mock client for testing
│   ├── ViewModels/                     # 🧠 MVVM ViewModels
│   │   ├── AddFood/                    # ➕ Add food flow
│   │   │   ├── FoodSearchViewModel.swift              # Search functionality
│   │   │   ├── FoodDetailsViewModel.swift             # Detail view logic
│   │   │   └── FoodViewModel.swift                    # Summary and logging
│   │   ├── Scanner/                    # 📷 Barcode scanning
│   │   │   └── BarcodeScannerViewModel.swift          # Scanner logic
│   │   ├── Today/                     # 📅 Today view
│   │   │   └── TodayViewModel.swift                   # Today view logic
│   │   └── PhotoIntake/               # 📸 Photo recognition
│   │       └── PhotoIntakeViewModel.swift             # Photo processing
│   └── Views/                          # 🎨 SwiftUI Views
│       ├── AddFood/                    # ➕ Add food screens
│       │   ├── AddFoodHomeView.swift                  # Add food home screen
│       │   ├── FoodView.swift                         # Main food display (shared)
│       │   ├── FoodDetailsView.swift                  # Detailed food display (shared)
│       │   ├── Scanner/                               # 📷 Scanner screens
│       │   │   ├── BarcodeScannerView.swift           # Scanner screen
│       │   │   └── BarcodeSearchResultsView.swift     # Barcode results
│       │   ├── PhotoIntake/                           # 📸 Photo recognition
│       │   │   └── PhotoIntakeView.swift              # Photo intake screen
│       │   └── Search/                                # 🔍 Text search
│       │       └── FoodSearchView.swift               # Search screen
│       ├── Scanner/                    # 📷 Scanner screens (legacy)
│       │   └── BarcodeScannerView.swift                # Scanner screen
│       ├── Today/                     # 📅 Today screens
│       │   └── TodayView.swift                        # Today view screen
│       ├── Settings/                  # ⚙️ Settings screens
│       │   └── SettingsView.swift                     # Settings screen
│       ├── Profile/                   # 👤 Profile screens
│       │   └── ProfileView.swift                      # Profile screen
│       └── Design/                     # 🎨 Design system
│           └── Components/             # 🧩 UI components
│               └── UnsupportedProductView.swift        # Unsupported product UI
├── Tests/                              # 🧪 Test code
│   ├── Unit/                           # 🔬 Unit tests (CI-friendly)
│   │   ├── Models/                     # 📋 Model tests
│   │   ├── Services/                   # 🔧 Service tests
│   │   │   ├── Data/                   # 💾 Data service tests
│   │   │   │   └── Processing/         # ⚙️ Processing tests
│   │   │   │       └── FoodNormalizationServiceTests.swift    # Normalization tests
│   │   │   └── External/               # 🌍 External service tests
│   │   │       └── Networking/        # 🌍 Network tests
│   │   │           ├── FoodDataClientAdapterTests.swift       # Adapter tests
│   │   │           ├── ProxyClientParsingTests.swift           # Parsing tests
│   │   │           ├── FDCMockTests.swift                      # Mock tests
│   │   │           └── FDCDISelectionTests.swift               # Selection tests
│   │   ├── ViewModels/                 # 🧠 ViewModel tests
│   │   │   ├── FoodSearchViewModelTests.swift                  # Search tests
│   │   │   ├── FoodDetailsViewModelTests.swift                 # Detail tests
│   │   │   └── BarcodeScannerViewModelTests.swift              # Scanner tests
│   │   ├── BaseUnitTests.swift                                 # Unit test base
│   │   └── CalryTests.swift                              # Main test file
│   └── UI/                             # 🎨 UI tests (Local only)
│       ├── Screens/                    # 📱 Screen tests
│       │   ├── AddFlowUITests.swift                             # Add flow tests
│       │   ├── CalryUITests.swift                         # Main UI tests
│       │   └── CalryUITestsLaunchTests.swift             # Launch tests
│       └── BaseUITestCase.swift                                # UI test base
├── Resources/                          # 📦 App resources
│   ├── Assets.xcassets/               # 🎨 Images and colors
│   ├── Samples/                        # 📄 Sample data
│   └── PrivacyInfo.xcprivacy          # 🔒 Privacy manifest
├── Config/                             # ⚙️ Configuration
│   ├── Config.Debug.xcconfig          # Debug configuration
│   └── Config.Release.xcconfig        # Release configuration
├── Scripts/                            # 🔧 Build scripts
│   ├── setup-local-ci.sh              # Local CI environment setup
│   ├── build-local-ci.sh              # CI-equivalent build script
│   ├── test-local-ci.sh               # CI-equivalent test script
│   ├── lint-local-ci.sh               # CI-equivalent lint script
│   ├── ci-test-runner.sh              # CI test runner with warning filtering
│   ├── simulator-manager.sh            # Simulator management
│   └── test-local-network.sh          # Local network testing
├── docs/                               # 📚 Documentation
├── Calry.xcodeproj/             # 🏗️ Xcode project
├── Calry.xctestplan              # 🧪 Test plan
├── Calry-CI-Offline.xctestplan  # 🧪 CI offline test plan
├── Info.plist                          # ℹ️ App information
└── README.md                           # 📋 Project overview
```

## 🎯 Key Structural Decisions

### 1. **Sources/ Directory**
**Purpose**: All source code in one place
- **Clear separation** from tests, docs, and resources
- **Easy navigation** for developers
- **Consistent organization** across the project

### 2. **Models/ Organization**
**Purpose**: Clear separation of data concerns
- **API/**: External data structures and converters
- **Core/**: Core business models (LoggedFoodEntry)
- **FDC/OFF separation**: Clear data source boundaries

### 3. **Services/ Structure**
**Purpose**: Logical grouping by functionality
- **Data/**: All data-related services (Caching, Persistence, Processing)
- **Internal/**: Internal configuration and utility services
- **Networking/**: External API communication
- **Processing/**: Data transformation and normalization

### 4. **API Configuration Service**
**Purpose**: Centralized API configuration management
- **APIConfiguration.swift**: Reads configuration from `.xcconfig` and `Info.plist`
- **Split components**: Scheme, host, and path for flexible configuration
- **Environment support**: Easy switching between Debug/Release configurations
- **Type safety**: Compile-time configuration validation
**Purpose**: App-level configuration and setup
- **App/**: Main app entry point and configuration
- **Config/**: Configuration files and settings
- **Clean separation** from business logic

### 4. **API Configuration Service**
**Purpose**: Centralized API configuration management
- **APIConfiguration.swift**: Reads configuration from `.xcconfig` and `Info.plist`
- **Split components**: Scheme, host, and path for flexible configuration
- **Environment support**: Easy switching between Debug/Release configurations
- **Type safety**: Compile-time configuration validation

### 5. **App/ Configuration**
**Purpose**: App-level configuration and setup
- **App/**: Main app entry point and configuration
- **Config/**: Configuration files and settings
- **Clean separation** from business logic

### 6. **Views/ and ViewModels/ Separation**
**Purpose**: Clean MVVM separation
- **Views/**: SwiftUI view implementations
- **ViewModels/**: Business logic for views
- **Clear boundaries** between presentation and logic

### 7. **Tests/ Mirroring**
**Purpose**: Easy test navigation
- **Unit/**: Unit tests (CI-friendly)
- **UI/**: UI tests (Local only)
- **Mirrors Sources/**: Easy to find corresponding tests

## 🔄 Data Flow Through Structure

### 1. **API Data Flow**
```
External API → Sources/Services/Networking/ → Sources/Models/API/ → Sources/Services/Data/Processing/
```

### 2. **UI Data Flow**
```
Sources/Views/ → Sources/ViewModels/ → Sources/Services/ → Sources/Models/
```

### 3. **Test Flow**
```
Tests/Unit/ → Sources/Services/ (mocked) → Sources/Models/
Tests/UI/ → Sources/Views/ → Sources/ViewModels/
```

## 🎯 File Naming Conventions

### 1. **Service Files**
- **`*Service.swift`**: Main service implementations
- **`*Normalizer.swift`**: Data normalization logic
- **`*Converter.swift`**: Data conversion logic
- **`*Repository.swift`**: Data persistence interfaces

### 2. **Model Files**
- **`*Models.swift`**: Data structure definitions
- **`*Extensions.swift`**: Model extensions
- **`*Builder.swift`**: Model construction logic

### 3. **ViewModel Files**
- **`*ViewModel.swift`**: ViewModel implementations
- **`*Tests.swift`**: Corresponding test files

### 4. **View Files**
- **`*View.swift`**: SwiftUI view implementations
- **`*Tests.swift`**: Corresponding UI test files

## 🚀 Benefits of This Structure

### 1. **Clear Navigation**
- **Easy to find** any file or component
- **Logical grouping** by functionality
- **Consistent naming** conventions

### 2. **Maintainability**
- **Single responsibility** for each directory
- **Clear boundaries** between layers
- **Easy to modify** without affecting other parts

### 3. **Scalability**
- **Easy to add** new features
- **Clear patterns** for new components
- **Modular design** supports growth

### 4. **Testability**
- **Tests mirror** source structure
- **Easy to find** corresponding tests
- **Clear separation** of test types

This project structure provides a solid foundation for the Calry app with clear organization, easy navigation, and maintainable design.
