# Complete Data Journey: From Raw Proxy to Cooked Display

## 🎯 Overview

This document traces the complete journey of food data from raw API responses to cooked data ready for display on screen, covering both FDC and OFF data sources. Think of this as a technical architecture guide for understanding how the backend processes data.

## 📊 High-Level Data Flow Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Raw Proxy     │───▶│   Envelope      │───▶│   Source        │───▶│  Normalization  │
│   JSON Data     │    │   Wrapping      │    │   Detection     │    │   Processing    │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │                       │
         ▼                       ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Request  │    │   Envelope<T>    │    │   RawSource     │    │  NormalizedFood │
│   to calry.org  │    │   with metadata  │    │   (.fdc/.off)   │    │   canonical     │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                                                              │
                                                                              ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Merging  │◀───│   Model         │◀───│   UI Display    │◀───│   ViewModels     │
│   (FDC + OFF)   │    │   Conversion     │    │   Preparation    │    │   Business Logic │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │                       │
         ▼                       ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Merged        │    │   Public API    │    │   SwiftUI       │    │   Observable    │
│   NormalizedFood│    │   Models        │    │   Views         │    │   State          │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Journey Stages

### Stage 1: Raw Data Fetching
**Location**: `Sources/Services/Networking/ProxyClient.swift`

The journey begins with HTTP requests to the calry.org proxy service.

**Key Functions**:
```swift
// Initiates search request to proxy service
func searchFoods(query: String, pageSize: Int?) async throws -> ProxySearchResponse

// Fetches detailed food information by GID
func getFoodDetails(gid: String) async throws -> ProxyFoodDetailResponse

// Looks up food by barcode (returns union type for FDC or OFF)
func lookupByBarcode(barcode: String) async throws -> BarcodeLookupResult
```

**What happens**: Raw JSON responses from calry.org proxy service containing FDC or OFF data.

---

### Stage 2: Envelope Wrapping
**Location**: `Sources/Models/API/Common/FoodEnvelopeModels.swift`

Raw data gets wrapped in a generic envelope structure with metadata.

**Key Structures**:
```swift
// Generic envelope wrapper for any data source
struct Envelope<T: Decodable>: Decodable {
    let gid: String?           // Global ID: "fdc:123456" | "off:0123456789012"
    let source: RawSource      // Data source: .fdc | .off
    let barcode: String?       // Barcode when available
    let fetchedAt: String      // ISO-8601 timestamp
    let raw: T                // Platform-specific raw payload
}

// Type aliases for specific data sources
typealias FdcEnvelope = Envelope<FdcFood>
typealias OffEnvelope = Envelope<OffProduct>

// Union type for barcode lookup results (can be either FDC or OFF)
enum BarcodeLookupResult: Codable {
    case fdc(FdcEnvelope)
    case off(Envelope<OffReadResponse>)
}
```

**What happens**: Raw JSON becomes a structured envelope with metadata about the data source and timing.

### Redirect Handling
**Location**: `Sources/Services/Networking/ProxyClient.swift`

When barcode lookups result in redirects, the system intelligently handles both FDC and OFF redirects:

**Key Functions**:
```swift
// Handles redirect responses from barcode lookup
func followRedirect(_ redirect: ProxyRedirect) async throws -> BarcodeLookupResult

// Fetches FDC details for FDC redirects
func getFoodDetails(fdcId: Int) async throws -> Envelope<FdcFood>

// Fetches OFF details for OFF redirects  
func getOFFProductDirect(barcode: String) async throws -> Envelope<OffReadResponse>
```

**Redirect Logic**:
```swift
if gid.hasPrefix("fdc:") {
    // FDC redirect: Return actual FDC data
    let fdcEnvelope = try await getFoodDetails(fdcId: fdcId)
    return .fdc(fdcEnvelope)
} else if gid.hasPrefix("off:") {
    // OFF redirect: Return actual OFF data
    let offEnvelope = try await getOFFProductDirect(barcode: barcode)
    return .off(offEnvelope)
}
```

**What happens**: Barcode lookups that redirect to FDC return FDC data, redirects to OFF return OFF data. No more confusing data conversions!

---

### Stage 3: Source Detection
**Location**: `Sources/Services/Data/Processing/Utilities/ProductSourceDetection.swift`

The system determines which data source the envelope contains and its support status.

**Key Functions**:
```swift
// Determines the data source from GID
func detectSource(from gid: String) -> RawSource

// Checks if a product is supported (has detailed nutrition data)
func isProductSupported(gid: String) -> Bool

// Extracts source-specific ID from GID
func extractSourceId(from gid: String) -> String?
```

**What happens**: GID parsing determines if this is FDC or OFF data and whether it's fully supported.

---

### Stage 4: Data Normalization
**Location**: `Sources/Services/Data/Processing/Normalization/FoodNormalizationService.swift`

Raw data gets normalized into a canonical internal model.

**Key Functions**:
```swift
// Main normalization entry point for any envelope
func normalize(_ envelope: Envelope<AnyCodable>) -> NormalizedFood

// FDC-specific normalization
func normalizeFDC(_ envelope: FdcEnvelope) -> NormalizedFood

// OFF-specific normalization  
func normalizeOFF(_ envelope: OffEnvelope) -> NormalizedFood

// Merges FDC and OFF data with precedence rules
func mergeFoodData(fdc: NormalizedFood?, off: NormalizedFood?) -> NormalizedFood?
```

**FDC Normalization** (`Sources/Services/Data/Processing/Normalization/FDC/FDCNormalizer.swift`):
```swift
// Converts FDC raw data to canonical format
func normalize(_ envelope: FdcEnvelope) -> NormalizedFood
```

**OFF Normalization** (`Sources/Services/Data/Processing/Normalization/OFF/OFFNormalizer.swift`):
```swift
// Converts OFF raw data to canonical format
func normalize(_ envelope: OffEnvelope) -> NormalizedFood
```

**What happens**: Raw FDC/OFF data becomes `NormalizedFood` with standardized nutrients, units, and structure.

---

### Stage 5: Data Merging (FDC + OFF)
**Location**: Integrated in `FoodNormalizationService.swift`

When both FDC and OFF data exist for the same product, they get merged with smart precedence rules.

**Key Functions**:
```swift
// Merges nutrients from both sources (FDC preferred)
private func mergeNutrients(fdc: [NormalizedNutrient], off: [NormalizedNutrient]) -> [NormalizedNutrient]

// Merges portion information (FDC preferred)
private func mergePortions(fdc: [NormalizedPortion], off: [NormalizedPortion]) -> [NormalizedPortion]

// Determines data completeness flags
private func determineCompleteness(hasNutrients: Bool, hasServing: Bool, ...) -> CompletenessFlags
```

**Precedence Rules**:
- **FDC preferred for**: Nutrients, servings, portions (more accurate)
- **OFF preferred for**: Images, ingredients, front-of-pack info (more complete)
- **Conflict resolution**: FDC data takes precedence, OFF fills gaps

**What happens**: Best data from both sources combined into single `NormalizedFood` with source tracking.

---

### Stage 6: Model Conversion
**Location**: `Sources/Services/Networking/FoodDataConverter.swift`

Internal normalized data gets converted to public API models for UI consumption.

**Key Functions**:
```swift
// Converts to search result model
func convertToFoodCard(_ normalizedFood: NormalizedFood) -> FoodCard

// Converts to detail view model
func convertToFoodDetails(_ normalizedFood: NormalizedFood) -> FoodDetails

// Converts serving information
func convertToFoodServing(_ serving: NormalizedServing?) -> FoodServing?

// Converts portion information
func convertToFoodPortion(_ portion: NormalizedPortion) -> FoodPortion

// Converts nutrient information
func convertToFoodNutrient(_ nutrient: NormalizedNutrient) -> FoodNutrient
```

**What happens**: `NormalizedFood` becomes clean public models (`FoodCard`, `FoodDetails`) ready for UI.

---

### Stage 7: UI Display Preparation
**Location**: `Sources/ViewModels/`

Public models get processed by ViewModels for UI consumption.

**Key ViewModels**:
```swift
// FoodSearchViewModel.swift
// Handles search functionality and result processing
func searchFoods(query: String) async
func loadMoreResults() async

// FoodDetailsViewModel.swift  
// Manages detailed food information display
func loadFoodDetails(gid: String) async
func calculateNutrients(for serving: Double) -> [FoodNutrient]

// FoodViewModel.swift
// Handles food summary and logging preparation
func load() async
func prepareForLogging() -> FoodEntry
```

**What happens**: Public models get processed into observable state for SwiftUI views.

---

## 🔍 Detailed Flow Examples

### FDC Data Journey Example

```
1. Raw FDC JSON:
   {
     "fdcId": 123456,
     "description": "Apple, raw, with skin",
     "nutrients": [{"nutrientId": 1008, "amount": 52.0, "unitName": "kcal"}]
   }

2. Envelope Wrapped:
   Envelope<FdcFood> {
     gid: "fdc:123456",
     source: .fdc,
     raw: FdcFood { ... }
   }

3. Normalized:
   NormalizedFood {
     gid: "fdc:123456",
     primaryName: "Apple, raw, with skin",
     nutrients: [NormalizedNutrient(id: 1008, name: "Energy", amount: 52.0, unit: "kcal")]
   }

4. Public Model:
   FoodCard {
     id: "fdc:123456",
     description: "Apple, raw, with skin",
     nutrients: [FoodNutrient(id: 1008, name: "Energy", amount: 52.0, unit: "kcal")]
   }
```

### OFF Data Journey Example

```
1. Raw OFF JSON:
   {
     "code": "0123456789012",
     "product_name": "Coca-Cola",
     "brands": "Coca-Cola",
     "nutriments": {"energy-kcal": 42.0}
   }

2. Envelope Wrapped:
   Envelope<OffProduct> {
     gid: "off:0123456789012",
     source: .off,
     raw: OffProduct { ... }
   }

3. Normalized:
   NormalizedFood {
     gid: "off:0123456789012", 
     primaryName: "Coca-Cola",
     brand: "Coca-Cola",
     nutrients: [NormalizedNutrient(id: 1008, name: "Energy", amount: 42.0, unit: "kcal")]
   }

4. Public Model:
   FoodCard {
     id: "off:0123456789012",
     description: "Coca-Cola", 
     brand: "Coca-Cola",
     nutrients: [FoodNutrient(id: 1008, name: "Energy", amount: 42.0, unit: "kcal")]
   }
```

### Merged Data Journey Example

```
1. FDC NormalizedFood: { nutrients: [Energy: 52], imageUrl: nil }
2. OFF NormalizedFood: { nutrients: [Energy: 42], imageUrl: "https://..." }

3. Merged Result:
   NormalizedFood {
     nutrients: [Energy: 52],        // FDC preferred (more accurate)
     imageUrl: "https://...",         // OFF preferred (more complete)
     fieldSources: {
       nutrients: .fdc,              // Track which source provided data
       imageUrl: .off
     }
   }
```

## 🚨 Error Handling Journey

### Network Errors
**Location**: `ProxyClient.swift`
```swift
// Handles HTTP errors and retries
func handleNetworkError(_ error: Error) -> ProxyError
```

### Error Semantics Preservation
**Location**: `FoodDataClientAdapter.swift`
```swift
// Preserves specific error messages from ProxyError
private func convertProxyErrorToFoodDataError(_ error: ProxyError) -> FoodDataError {
    case let .proxyError(errorResponse):
        .customError(ProxyError.proxyError(errorResponse).errorDescription ?? "Proxy error occurred")
}
```

### User-Facing Error Display
**Location**: `FoodViewModel.swift`
```swift
// Displays specific error messages to users
catch {
    phase = .error(error.localizedDescription)  // Shows "Product not found..." for NOT_FOUND
}
```

### Parsing Errors  
**Location**: `FoodNormalizationService.swift`
```swift
// Creates fallback data for parsing failures
private func createEmptyNormalizedFood(_ gid: String, _ source: RawSource) -> NormalizedFood
```

### Data Quality Issues
**Location**: `ProductSourceDetection.swift`
```swift
// Determines if data is sufficient for display
func isDataComplete(_ normalizedFood: NormalizedFood) -> Bool
```

## 🎯 Key Takeaways

1. **Raw data flows through 7 distinct stages** from proxy to UI
2. **Envelope wrapping** provides metadata and type safety
3. **Normalization** creates canonical internal models
4. **Merging** combines best data from multiple sources
5. **Conversion** creates clean public APIs
6. **ViewModels** prepare data for UI consumption
7. **Error handling** exists at every stage with fallbacks

This architecture ensures data consistency, source tracking, and clean separation between internal processing and public APIs.
