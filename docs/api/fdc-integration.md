# FDC Integration Details

## 🇺🇸 FDC API Integration

This document provides detailed information about integrating with the USDA Food Data Central (FDC) API through the calry.org proxy service.

## 🎯 FDC Overview

**Food Data Central (FDC)** is the USDA's comprehensive food database providing detailed nutritional information for thousands of food items.

### Key Features
- **Comprehensive Data**: 300,000+ food items
- **Detailed Nutrition**: Complete nutritional breakdown
- **Multiple Data Types**: Foundation, Survey, Branded, SR Legacy
- **Serving Information**: Multiple serving sizes and portions
- **Quality Assurance**: Government-verified data

## 🔌 API Endpoints

### Base URL
```
https://api.calry.org
```

### Authentication
- **No API key required**
- **No authentication needed**
- **Rate limit**: 1000 requests/hour

### Key Endpoints

#### 1. **Search Foods**
```http
GET /search?query={query}&pageSize={limit}
```

**Parameters**:
- `query`: Search term (required)
- `pageSize`: Number of results (optional, default: 50)

**Response**: `ProxySearchResponse`

#### 2. **Get Food Details**
```http
GET /foodDetails/{gid}
```

**Parameters**:
- `gid`: Global ID (e.g., "fdc:123456")

**Response**: `ProxyFoodDetailResponse`

#### 3. **Barcode Lookup**
```http
GET /barcode/{barcode}
```

**Parameters**:
- `barcode`: UPC/EAN barcode

**Response**: `ProxyBarcodeResponse`

## 📋 Data Models

### FDC Raw Data Structure
```swift
struct FdcProduct: Codable {
    let fdcId: Int?
    let description: String?
    let dataType: FdcDataType?
    let brandName: String?
    let brandOwner: String?
    let ingredients: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let nutrients: [FdcNutrient]?
    let foodPortions: [FdcProductPortion]?
    let brandedFoodCategory: String?
    let gtinUpc: String?
    let publicationDate: String?
}
```

### FDC Data Types
```swift
enum FdcDataType: String, Codable {
    case branded = "Branded"
    case foundation = "Foundation"
    case surveyFNDDS = "Survey (FNDDS)"
    case srLegacy = "SR Legacy"
}
```

### FDC Nutrient Structure
```swift
struct FdcNutrient: Codable {
    let nutrientId: Int?
    let name: String?
    let amount: Double?
    let unitName: String?
    let derivationCode: String?
    let derivationDescription: String?
}
```

## 🔄 Data Processing Flow

### 1. **Raw FDC Data**
```json
{
  "fdcId": 123456,
  "description": "Apple, raw, with skin",
  "dataType": "Foundation",
  "nutrients": [
    {
      "nutrientId": 1008,
      "name": "Energy",
      "amount": 52.0,
      "unitName": "kcal"
    }
  ]
}
```

### 2. **Envelope Wrapping**
```swift
FdcEnvelope {
    gid: "fdc:123456",
    source: .fdc,
    raw: FdcProduct { ... }
}
```

### 3. **Normalization**
```swift
NormalizedFood {
    gid: "fdc:123456",
    primaryName: "Apple, raw, with skin",
    nutrients: [
        NormalizedNutrient(
            id: 1008,
            name: "Energy",
            amount: 52.0,
            unit: "kcal"
        )
    ]
}
```

### 4. **Public Model**
```swift
FoodCard {
    id: "fdc:123456",
    description: "Apple, raw, with skin",
    nutrients: [
        FoodNutrient(
            id: 1008,
            name: "Energy",
            amount: 52.0,
            unit: "kcal"
        )
    ]
}
```

## 🎯 FDC-Specific Processing

### Nutrient Mapping
FDC uses specific nutrient IDs that need to be mapped to standard values:

```swift
// Key FDC Nutrient IDs
let fdcNutrientIds = [
    1008: "Energy",           // kcal
    1003: "Protein",          // g
    1004: "Total lipid (fat)", // g
    1005: "Carbohydrate",     // g
    1009: "Fiber",            // g
    1010: "Sugars",           // g
    1011: "Sodium",           // mg
    1012: "Calcium",          // mg
    1013: "Iron",             // mg
    1014: "Vitamin C"         // mg
]
```

### Data Type Handling
Different FDC data types require different processing:

- **Foundation**: Generic foods, comprehensive nutrition
- **Survey**: Survey foods, detailed nutrition
- **Branded**: Brand-specific products, label nutrients
- **SR Legacy**: Legacy data, basic nutrition

### Serving Size Processing
FDC provides multiple serving size options:

```swift
struct FdcProductPortion: Codable {
    let amount: Double?
    let gramWeight: Double?
    let portionDescription: String?
    let measureUnit: FdcMeasureUnit?
}
```

## 🔧 FDC Normalizer

### Key Functions
```swift
// Main normalization entry point
func normalize(_ envelope: FdcEnvelope) -> NormalizedFood

// Extract serving information
private func extractFDCServing(_ data: FdcProduct) -> NormalizedServing?

// Extract portions
private func extractFDCPortions(_ data: FdcProduct) -> [NormalizedPortion]

// Normalize nutrients
private func normalizeFDCNutrients(_ data: FdcProduct) -> [NormalizedNutrient]

// Determine base unit
private func determineBaseUnit(from servingSizeUnit: String?, category: String?) -> BaseUnit
```

### Processing Steps
1. **Extract basic info**: Name, brand, barcode
2. **Determine food kind**: Generic vs Branded
3. **Extract serving info**: Serving size and unit
4. **Extract portions**: Multiple portion options
5. **Normalize nutrients**: Standard nutrient format
6. **Calculate density**: If possible from portions
7. **Determine completeness**: Data quality flags

## 🚨 Error Handling

### Common FDC Errors
- **Missing nutrients**: Some foods lack complete nutrition data
- **Invalid serving sizes**: Incorrect or missing serving information
- **Data type conflicts**: Mismatched data types
- **Nutrient mapping**: Unknown nutrient IDs

### Error Recovery
```swift
// Handle missing nutrients
if nutrients.isEmpty {
    return createEmptyNormalizedFood(gid, .fdc)
}

// Handle invalid serving sizes
let serving = extractFDCServing(data) ?? createDefaultServing()

// Handle data type conflicts
let kind: FoodKind = data.dataType == .branded ? .branded : .generic
```

## 📊 Data Quality

### FDC Data Strengths
- **High accuracy**: Government-verified data
- **Comprehensive**: Complete nutritional breakdown
- **Consistent**: Standardized data format
- **Reliable**: Stable data source

### FDC Data Limitations
- **Limited images**: Few food images available
- **Basic ingredients**: Simple ingredient lists
- **US-focused**: Primarily US food data
- **Update frequency**: Periodic updates only

## 🎯 Best Practices

### 1. **Data Validation**
- **Check nutrient completeness** before display
- **Validate serving sizes** for accuracy
- **Handle missing fields** gracefully

### 2. **Performance Optimization**
- **Cache FDC responses** for repeated requests
- **Use pagination** for large result sets
- **Batch requests** when possible

### 3. **Error Handling**
- **Provide fallback data** for missing information
- **Show data quality indicators** to users
- **Log errors** for debugging

## 🔍 Debugging FDC Integration

### Common Issues
1. **Missing nutrition data**: Check data completeness flags
2. **Incorrect serving sizes**: Validate serving size calculations
3. **Nutrient mapping errors**: Verify nutrient ID mappings
4. **Data type confusion**: Check data type handling

### Debug Tools
- **Console logging**: Track data processing steps
- **Data validation**: Verify normalized data
- **Error tracking**: Monitor error rates
- **Performance monitoring**: Track processing time

This FDC integration guide provides everything needed to work with USDA Food Data Central through the calry.org proxy service.
