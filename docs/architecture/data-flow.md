# Data Flow Overview

## 📊 High-Level Data Flow

This document provides a high-level overview of how data flows through the Food Scanner app system.

## 🎯 System Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Search    │ │   Scanner   │ │   Today     │ │  Settings   │ │
│  │    UI       │ │     UI      │ │     UI      │ │     UI      │ │
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

## 🔄 Key Data Flows

### 1. **Search Flow**
```
User Input → SearchViewModel → FoodDataClient → ProxyClient → API → Response → Normalization → Display
```

**Detailed Steps**:
1. **User types** search query
2. **SearchViewModel** processes input
3. **FoodDataClient** makes API call
4. **ProxyClient** sends request to calry.org
5. **API returns** raw JSON data
6. **Normalization** converts to canonical format
7. **ViewModel** updates state
8. **UI displays** results

### 2. **Barcode Flow**
```
Camera Input → ScannerViewModel → Barcode Detection → Product Lookup → API → Response → Display
```

**Detailed Steps**:
1. **Camera captures** barcode image
2. **ScannerViewModel** processes image
3. **VisionKit detects** barcode
4. **Product lookup** via API
5. **API returns** product data
6. **Normalization** processes data
7. **UI displays** product info

### 3. **Logging Flow**
```
Food Selection → DetailViewModel → Serving Input → FoodEntry Creation → Database Storage → Today View Update
```

**Detailed Steps**:
1. **User selects** food item
2. **DetailViewModel** loads food details
3. **User inputs** serving size
4. **FoodEntry** created with nutrition data
5. **Database stores** entry
6. **Today View** updates totals

### 4. **Sync Flow**
```
Local Changes → Repository → SwiftData → Cloud Sync → Conflict Resolution → UI Update
```

**Detailed Steps**:
1. **Local changes** made to data
2. **Repository** handles persistence
3. **SwiftData** manages local storage
4. **Cloud sync** updates remote data
5. **Conflict resolution** handles conflicts
6. **UI updates** with latest data

## 🌐 External Data Flow

### API Data Journey
```
External API → Proxy Service → Envelope Wrapping → Source Detection → Normalization → Merging → Conversion → ViewModels
```

**Key Stages**:
1. **External API**: FDC, OFF data sources
2. **Proxy Service**: calry.org proxy
3. **Envelope Wrapping**: Generic data wrapper
4. **Source Detection**: FDC vs OFF identification
5. **Normalization**: Canonical data format
6. **Merging**: Combine multiple sources
7. **Conversion**: Public API models
8. **ViewModels**: Business logic processing

## 🏗️ Data Processing Pipeline

### 1. **Input Processing**
- **User Input**: Text, barcode, touch gestures
- **Validation**: Input sanitization and validation
- **Formatting**: Consistent data format

### 2. **Service Processing**
- **Business Logic**: Core application logic
- **Data Transformation**: Convert between formats
- **Error Handling**: Graceful error management

### 3. **Data Persistence**
- **Local Storage**: SwiftData database
- **Caching**: In-memory and disk cache
- **Sync**: Cloud synchronization

### 4. **Output Processing**
- **UI Updates**: Reactive state changes
- **User Feedback**: Loading states, errors
- **Data Display**: Formatted presentation

## 🔄 State Management Flow

### Observable Pattern
```
ViewModel State → @Observable → SwiftUI Binding → View Update
```

**Key Components**:
- **ViewModel**: Manages state
- **@Observable**: Enables reactive updates
- **SwiftUI Binding**: Connects to UI
- **View**: Displays current state

### State Types
```swift
enum ViewState {
    case idle           // Initial state
    case loading        // Data loading
    case loaded(Data)   // Success with data
    case error(String)  // Error state
}
```

## 🧪 Data Flow Testing

### Unit Testing
- **ViewModel Logic**: Test business logic
- **Service Integration**: Test service calls
- **Data Transformation**: Test data conversion

### Integration Testing
- **End-to-End Flow**: Test complete user journeys
- **API Integration**: Test external service calls
- **Database Operations**: Test persistence

### UI Testing
- **User Interactions**: Test user input flows
- **State Updates**: Test UI state changes
- **Error Handling**: Test error scenarios

## 🎯 Key Data Flow Principles

### 1. **Single Source of Truth**
- **ViewModels** manage all state
- **Services** handle data processing
- **Models** define data structures

### 2. **Reactive Updates**
- **Observable state** triggers UI updates
- **Automatic binding** between ViewModels and Views
- **Consistent state** across the app

### 3. **Error Propagation**
- **Service errors** bubble up to ViewModels
- **ViewModel errors** display in UI
- **User feedback** for all error states

### 4. **Data Consistency**
- **Normalized data** across sources
- **Consistent formats** for display
- **Synchronized state** between components

## 🚀 Performance Considerations

### 1. **Caching Strategy**
- **API responses** cached for performance
- **Local data** persisted for offline access
- **Smart invalidation** of stale data

### 2. **Lazy Loading**
- **Data loaded** on demand
- **Pagination** for large datasets
- **Background processing** for heavy operations

### 3. **Memory Management**
- **Efficient data structures** for performance
- **Proper cleanup** of resources
- **Memory pressure** handling

## 🔧 Debugging Data Flow

### 1. **Flow Tracing**
- **Console logs** at each stage
- **State inspection** in ViewModels
- **Network monitoring** for API calls

### 2. **Error Tracking**
- **Error logging** throughout the flow
- **User feedback** for errors
- **Debug information** for developers

### 3. **Performance Monitoring**
- **Timing measurements** for each stage
- **Memory usage** tracking
- **Network performance** monitoring

This data flow overview provides a comprehensive understanding of how data moves through the Food Scanner app system, from user input to data persistence and display.
