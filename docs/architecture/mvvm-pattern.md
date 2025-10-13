# MVVM Pattern Implementation

## 🧠 MVVM Implementation Details

This document explains how the MVVM (Model-View-ViewModel) pattern is implemented in the Calry app.

## 🎯 MVVM Overview

MVVM separates the app into three distinct layers:
- **Model**: Data structures and business logic
- **View**: SwiftUI presentation layer
- **ViewModel**: Business logic and state management

## 📊 MVVM Architecture Diagram

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
│                      Models Layer                                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Data      │ │   API       │ │   Core      │ │   Services  │ │
│  │  Models     │ │  Models     │ │  Models     │ │  Models     │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🏗️ Implementation Details

### 📱 **View Layer** (`Sources/Views/`)

**Responsibility**: User interface and user interaction

**Key Characteristics**:
- **SwiftUI Views**: Declarative UI components
- **No Business Logic**: Only presentation and user input
- **Reactive Updates**: Automatically updates on state changes
- **Composable**: Reusable components

**Example Structure**:
```swift
struct AddFoodSearchView: View {
    @State private var viewModel = AddFoodSearchViewModel()
    
    var body: some View {
        // UI implementation
    }
}
```

**Key Files**:
- `Sources/Views/AddFood/AddFoodSearchView.swift`
- `Sources/Views/Scanner/BarcodeScannerView.swift`
- `Sources/Views/Today/TodayView.swift`

### 🧠 **ViewModel Layer** (`Sources/ViewModels/`)

**Responsibility**: Business logic and state management

**Key Characteristics**:
- **Observable**: Uses `@Observable` for state management
- **Business Logic**: Processes user actions and data
- **Service Coordination**: Orchestrates service calls
- **State Management**: Manages UI state and data

**Example Structure**:
```swift
@MainActor
@Observable
final class AddFoodSearchViewModel {
    var searchResults: [FoodCard] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let client: FoodDataClient
    
    func searchFoods(query: String) async {
        // Business logic implementation
    }
}
```

**Key Files**:
- `Sources/ViewModels/AddFood/AddFoodSearchViewModel.swift`
- `Sources/ViewModels/Scanner/BarcodeScannerViewModel.swift`
- `Sources/ViewModels/Today/TodayViewModel.swift`

### 📋 **Model Layer** (`Sources/Models/`)

**Responsibility**: Data structures and business entities

**Key Characteristics**:
- **Data Structures**: Define app data models
- **Business Logic**: Core business rules
- **Service Interfaces**: Define service contracts
- **Data Validation**: Ensure data integrity

**Example Structure**:
```swift
struct FoodCard: Sendable, Codable, Equatable {
    let id: String
    let description: String
    let brand: String?
    let nutrients: [FoodNutrient]
    let serving: FoodServing?
}
```

**Key Files**:
- `Sources/Models/API/Common/FoodModels.swift`
- `Sources/Services/Data/Persistence/Models/LoggedFoodEntry.swift`
- `Sources/Services/Data/Processing/Normalization/FoodNormalizationService.swift`

## 🔄 Data Flow in MVVM

### 1. **User Interaction Flow**
```
User Action → View → ViewModel → Service → Model
     ↑                                    ↓
     └────────── UI Update ←──────────────┘
```

### 2. **State Management Flow**
```
ViewModel State → Observable → SwiftUI Binding → View Update
```

### 3. **Service Integration Flow**
```
ViewModel → Service Interface → Service Implementation → Data Source
```

## 🎯 Key MVVM Patterns

### 1. **Observable Pattern**
```swift
@Observable
final class ViewModel {
    var state: ViewState = .idle
    
    func updateState() {
        state = .loading
        // Update state
        state = .loaded(data)
    }
}
```

### 2. **Dependency Injection**
```swift
final class ViewModel {
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol) {
        self.service = service
    }
}
```

### 3. **Service Abstraction**
```swift
protocol FoodDataClient {
    func searchFoods(query: String) async throws -> FoodSearchResponse
}

class ViewModel {
    private let client: FoodDataClient
    
    func search(query: String) async {
        let results = try await client.searchFoods(query: query)
        // Process results
    }
}
```

## 🧪 Testing MVVM

### ViewModel Testing
```swift
@Test func testSearchFunctionality() async {
    let mockClient = MockFoodDataClient()
    let viewModel = AddFoodSearchViewModel(client: mockClient)
    
    await viewModel.searchFoods(query: "apple")
    
    #expect(viewModel.searchResults.count > 0)
    #expect(viewModel.isLoading == false)
}
```

### Service Testing
```swift
@Test func testServiceIntegration() async throws {
    let service = FoodNormalizationService()
    let result = service.normalize(envelope)
    
    #expect(result.primaryName != nil)
    #expect(result.nutrients.count > 0)
}
```

## 🎯 Benefits of This Implementation

### 1. **Separation of Concerns**
- **Views**: Only UI logic
- **ViewModels**: Only business logic
- **Models**: Only data logic

### 2. **Testability**
- **ViewModels**: Easy to unit test
- **Services**: Can be mocked
- **Models**: Pure data structures

### 3. **Maintainability**
- **Clear boundaries** between layers
- **Easy to modify** without affecting other layers
- **Consistent patterns** across the app

### 4. **SwiftUI Integration**
- **Natural fit** with SwiftUI
- **Reactive updates** automatic
- **State management** built-in

## 🚀 Best Practices

### 1. **ViewModel Design**
- **Single responsibility** per ViewModel
- **Observable state** for UI binding
- **Async/await** for service calls
- **Error handling** for user feedback

### 2. **View Design**
- **Composable components** for reusability
- **Minimal logic** in views
- **Clear data binding** to ViewModels
- **Consistent styling** across views

### 3. **Model Design**
- **Immutable data** where possible
- **Clear interfaces** for services
- **Validation logic** in models
- **Codable support** for persistence

## 🔧 Common Patterns

### 1. **Loading States**
```swift
enum ViewState {
    case idle
    case loading
    case loaded(Data)
    case error(String)
}
```

### 2. **Error Handling**
```swift
func handleError(_ error: Error) {
    errorMessage = error.localizedDescription
    state = .error
}
```

### 3. **Data Binding**
```swift
struct View: SwiftUI.View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            ContentView(data: viewModel.data)
        }
    }
}
```

This MVVM implementation provides a solid foundation for the Calry app with clear separation of concerns, excellent testability, and seamless SwiftUI integration.
