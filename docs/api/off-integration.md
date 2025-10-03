# OFF Integration Details

## 🌍 OFF API Integration

This document provides detailed information about integrating with the Open Food Facts (OFF) API through the calry.org proxy service.

## 🎯 OFF Overview

**Open Food Facts (OFF)** is a community-driven food database providing comprehensive product information including nutrition facts, ingredients, and images.

### Key Features
- **Community-Driven**: User-contributed data
- **Rich Media**: Extensive product images
- **Detailed Ingredients**: Complete ingredient lists
- **Global Coverage**: Worldwide product database
- **Real-Time Updates**: Continuous data updates

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

#### 1. **Search Products**
```http
GET /search?query={query}&pageSize={limit}
```

**Parameters**:
- `query`: Search term (required)
- `pageSize`: Number of results (optional, default: 50)

**Response**: `ProxySearchResponse`

#### 2. **Get Product Details**
```http
GET /foodDetails/{gid}
```

**Parameters**:
- `gid`: Global ID (e.g., "off:0123456789012")

**Response**: `ProxyFoodDetailResponse`

#### 3. **Barcode Lookup**
```http
GET /barcode/{barcode}
```

**Parameters**:
- `barcode`: UPC/EAN barcode

**Response**: `ProxyBarcodeResponse`

## 📋 Data Models

### OFF Raw Data Structure
```swift
struct OffProduct: Codable {
    let code: String?
    let productName: String?
    let brands: String?
    let categories: String?
    let ingredientsText: String?
    let imageURL: URL?
    let imageSmallURL: URL?
    let imageFrontURL: URL?
    let imageNutritionURL: URL?
    let nutriments: OffNutriments?
    let servingSize: String?
    let quantity: String?
    let packaging: String?
    let labels: String?
    let origins: String?
    let manufacturingPlaces: String?
    let countries: String?
    let stores: String?
    let purchasePlaces: String?
}
```

### OFF Nutriments Structure
```swift
struct OffNutriments: Codable {
    let energyKcal: Double?
    let energyKj: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let sugars: Double?
    let fat: Double?
    let saturatedFat: Double?
    let fiber: Double?
    let sodium: Double?
    let salt: Double?
    let calcium: Double?
    let iron: Double?
    let vitaminC: Double?
    let vitaminD: Double?
}
```

## 🔄 Data Processing Flow

### 1. **Raw OFF Data**
```json
{
  "code": "0123456789012",
  "product_name": "Coca-Cola",
  "brands": "Coca-Cola",
  "nutriments": {
    "energy-kcal": 42.0,
    "proteins": 0.0,
    "carbohydrates": 10.6,
    "sugars": 10.6,
    "fat": 0.0
  },
  "image_url": "https://...",
  "ingredients_text": "Carbonated water, sugar, caffeine..."
}
```

### 2. **Envelope Wrapping**
```swift
OffEnvelope {
    gid: "off:0123456789012",
    source: .off,
    raw: OffProduct { ... }
}
```

### 3. **Normalization**
```swift
NormalizedFood {
    gid: "off:0123456789012",
    primaryName: "Coca-Cola",
    brand: "Coca-Cola",
    nutrients: [
        NormalizedNutrient(
            id: 1008,
            name: "Energy",
            amount: 42.0,
            unit: "kcal"
        )
    ],
    imageUrl: "https://...",
    ingredientsText: "Carbonated water, sugar, caffeine..."
}
```

### 4. **Public Model**
```swift
FoodMinimalCard {
    id: "off:0123456789012",
    description: "Coca-Cola",
    brand: "Coca-Cola",
    nutrients: [
        FoodNutrient(
            id: 1008,
            name: "Energy",
            amount: 42.0,
            unit: "kcal"
        )
    ],
    imageUrl: "https://..."
}
```

## 🎯 OFF-Specific Processing

### Nutrient Mapping
OFF uses different nutrient field names that need to be mapped:

```swift
// OFF Nutrient Field Mapping
let offNutrientMapping = [
    "energy-kcal": (id: 1008, name: "Energy", unit: "kcal"),
    "proteins": (id: 1003, name: "Protein", unit: "g"),
    "carbohydrates": (id: 1005, name: "Carbohydrate", unit: "g"),
    "sugars": (id: 1010, name: "Sugars", unit: "g"),
    "fat": (id: 1004, name: "Total lipid (fat)", unit: "g"),
    "saturated-fat": (id: 1258, name: "Saturated fat", unit: "g"),
    "fiber": (id: 1009, name: "Fiber", unit: "g"),
    "sodium": (id: 1011, name: "Sodium", unit: "mg"),
    "salt": (id: 1012, name: "Salt", unit: "mg")
]
```

### Image Processing
OFF provides multiple image URLs:

```swift
struct OffImageUrls {
    let front: URL?        // Front of package
    let nutrition: URL?    // Nutrition label
    let ingredients: URL?  // Ingredients list
    let small: URL?        // Small thumbnail
    let large: URL?        // Large image
}
```

### Ingredient Processing
OFF provides detailed ingredient information:

```swift
// Parse ingredient text
let ingredients = parseIngredients(offProduct.ingredientsText)

// Extract allergens
let allergens = extractAllergens(offProduct.labels)

// Parse additives
let additives = parseAdditives(offProduct.additives)
```

## 🔧 OFF Normalizer

### Key Functions
```swift
// Main normalization entry point
func normalize(_ envelope: OffEnvelope) -> NormalizedFood

// Extract serving information
private func extractOFFServing(_ data: OffProduct) -> NormalizedServing?

// Extract portions
private func extractOFFPortions(_ data: OffProduct) -> [NormalizedPortion]

// Normalize nutrients
private func normalizeOFFNutrients(_ data: OffProduct) -> [NormalizedNutrient]

// Determine base unit
private func determineBaseUnit(from servingSize: String?, category: String?) -> BaseUnit
```

### Processing Steps
1. **Extract basic info**: Name, brand, barcode
2. **Determine food kind**: Always branded for OFF
3. **Extract serving info**: Serving size and unit
4. **Extract portions**: Multiple portion options
5. **Normalize nutrients**: Standard nutrient format
6. **Process images**: Multiple image URLs
7. **Parse ingredients**: Detailed ingredient text
8. **Determine completeness**: Data quality flags

## 🚨 Error Handling

### Common OFF Errors
- **Missing nutrition data**: Some products lack complete nutrition
- **Invalid images**: Broken or missing image URLs
- **Incomplete ingredients**: Partial ingredient lists
- **Data quality issues**: Community data inconsistencies

### Error Recovery
```swift
// Handle missing nutrition data
if nutriments.isEmpty {
    return createEmptyNormalizedFood(gid, .off)
}

// Handle invalid images
let imageUrl = validateImageUrl(offProduct.imageURL)

// Handle incomplete ingredients
let ingredients = offProduct.ingredientsText ?? "Ingredients not available"
```

## 📊 Data Quality

### OFF Data Strengths
- **Rich media**: Extensive product images
- **Detailed ingredients**: Complete ingredient lists
- **Global coverage**: Worldwide product database
- **Real-time updates**: Continuous data updates
- **Community input**: User-contributed data

### OFF Data Limitations
- **Variable quality**: Community-driven inconsistencies
- **Limited nutrition**: Basic nutrition data only
- **Language barriers**: Multiple languages
- **Data gaps**: Incomplete product information

## 🎯 Best Practices

### 1. **Data Validation**
- **Check image availability** before display
- **Validate ingredient text** for completeness
- **Handle missing nutrition** gracefully

### 2. **Performance Optimization**
- **Cache OFF responses** for repeated requests
- **Optimize image loading** with lazy loading
- **Use pagination** for large result sets

### 3. **Error Handling**
- **Provide fallback images** for missing images
- **Show data quality indicators** to users
- **Log errors** for debugging

## 🔍 Debugging OFF Integration

### Common Issues
1. **Missing images**: Check image URL validation
2. **Incomplete nutrition**: Verify nutrient mapping
3. **Ingredient parsing**: Handle text parsing errors
4. **Data quality**: Monitor community data quality

### Debug Tools
- **Console logging**: Track data processing steps
- **Image validation**: Verify image URL accessibility
- **Error tracking**: Monitor error rates
- **Performance monitoring**: Track processing time

## 🌍 Global Considerations

### Multi-Language Support
- **Product names**: Multiple languages
- **Ingredient text**: Various languages
- **Categories**: Localized categories
- **Labels**: Regional labeling

### Regional Differences
- **Nutrition standards**: Different regional standards
- **Ingredient regulations**: Varying regulations
- **Labeling requirements**: Regional requirements
- **Measurement units**: Metric vs Imperial

This OFF integration guide provides everything needed to work with Open Food Facts through the calry.org proxy service.
