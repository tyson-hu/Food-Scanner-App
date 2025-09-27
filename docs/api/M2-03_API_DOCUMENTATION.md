# M2-03 API Documentation

## Overview

This document describes the enhanced FDC API integration implemented in M2-03, including barcode scanning functionality, comprehensive schema coverage, pagination, caching, and error handling.

## API Endpoints

### Search Foods (`/foods/search`)

**Purpose**: Search for branded foods using text queries with pagination support.

**Parameters**:
- `query` (string, required): Search term (minimum 2 characters)
- `dataType` (string): Always "Branded" for branded food products
- `pageSize` (integer): Number of results per page (default: 25, max: 50)
- `pageNumber` (integer): Page number (1-based)

**Example Request**:
```
GET https://api.calry.org/foods/search?query=apple&dataType=Branded&pageSize=25&pageNumber=1
```

**Response Schema**:
```json
{
  "totalHits": 150,
  "currentPage": 1,
  "totalPages": 6,
  "pageList": [1, 2, 3, 4, 5, 6],
  "foodSearchCriteria": {
    "dataType": ["Branded"],
    "query": "apple",
    "generalSearchInput": "apple",
    "pageNumber": 1,
    "numberOfResultsPerPage": 25,
    "pageSize": 25,
    "requireAllWords": false,
    "foodTypes": []
  },
  "foods": [
    {
      "fdcId": 12345,
      "description": "Apple, raw",
      "dataType": "Branded",
      "gtinUpc": "1234567890123",
      "publishedDate": "2023-01-01",
      "brandOwner": "Test Brand",
      "brandName": "Test Brand",
      "ingredients": "Apple",
      "marketCountry": "US",
      "foodCategory": "Fruits",
      "modifiedDate": "2023-01-01",
      "dataSource": "Test",
      "packageWeight": "100g",
      "servingSizeUnit": "g",
      "servingSize": 100.0,
      "householdServingFullText": "1 medium apple",
      "tradeChannels": ["Retail"],
      "foodNutrients": [
        {
          "nutrient": {
            "id": 1008,
            "name": "Energy",
            "unitName": "kcal"
          },
          "amount": 52.0
        }
      ]
    }
  ],
  "aggregations": {
    "dataType": {
      "Branded": 150
    }
  }
}
```

### Food Details (`/food/{fdcId}`)

**Purpose**: Get detailed information for a specific food item.

**Parameters**:
- `fdcId` (integer, required): Food Data Central ID

**Example Request**:
```
GET https://api.calry.org/food/12345
```

**Response Schema**:
```json
{
  "fdcId": 12345,
  "description": "Apple, raw",
  "publicationDate": "2023-01-01",
  "dataType": "Branded",
  "foodClass": "FinalFood",
  "brandOwner": "Test Brand",
  "brandName": "Test Brand",
  "gtinUpc": "1234567890123",
  "marketCountry": "US",
  "servingSize": 100.0,
  "servingSizeUnit": "g",
  "householdServingFullText": "1 medium apple",
  "ingredients": "Apple",
  "packageWeight": "100g",
  "foodCategory": {
    "id": 9,
    "code": "0900",
    "description": "Fruits and Fruit Juices"
  },
  "foodNutrients": [
    {
      "nutrient": {
        "id": 1008,
        "name": "Energy",
        "unitName": "kcal"
      },
      "amount": 52.0,
      "type": "FoodNutrient"
    }
  ],
  "labelNutrients": {
    "calories": { "value": 52.0 },
    "fat": { "value": 0.2 },
    "saturatedFat": { "value": 0.0 },
    "transFat": { "value": 0.0 },
    "cholesterol": { "value": 0.0 },
    "sodium": { "value": 1.0 },
    "carbohydrates": { "value": 13.8 },
    "fiber": { "value": 2.4 },
    "sugars": { "value": 10.4 },
    "protein": { "value": 0.3 },
    "calcium": { "value": 6.0 },
    "iron": { "value": 0.1 },
    "potassium": { "value": 107.0 }
  }
}
```

## Field Coverage

### Core Identity Fields
- `fdcId` (integer): Unique identifier
- `description` (string): Food name/description
- `dataType` (string): Always "Branded" for branded products
- `brandName` (string): Brand name
- `brandOwner` (string): Brand owner company
- `gtinUpc` (string): Barcode/UPC code

### Serving Information
- `servingSize` (double): Serving size amount
- `servingSizeUnit` (string): Serving size unit (g, ml, etc.)
- `householdServingFullText` (string): Human-readable serving description
- `packageWeight` (string): Total package weight

### Classification & Metadata
- `foodCategory` (string/object): Food category name or object with id/name
- `foodCategoryId` (integer): Category ID
- `publicationDate` (string): When data was published
- `modifiedDate` (string): When data was last modified
- `marketCountry` (string): Country where product is sold
- `tradeChannels` (array): Distribution channels (Retail, etc.)

### Ingredients
- `ingredients` (string): Ingredient list

### Label Nutrients (when available)
- `calories` (double): Energy in kcal
- `fat` (double): Total fat
- `saturatedFat` (double): Saturated fat
- `transFat` (double): Trans fat
- `cholesterol` (double): Cholesterol
- `sodium` (double): Sodium
- `carbohydrates` (double): Total carbohydrates
- `fiber` (double): Dietary fiber
- `sugars` (double): Total sugars
- `protein` (double): Protein
- `calcium` (double): Calcium
- `iron` (double): Iron
- `potassium` (double): Potassium

### Food Nutrients Array
- Complete nutrient data with amounts and units
- Supports macro summaries for quick glance
- Tolerates unit/name variants

## Data Normalization Rules

### Energy Conversion
- Convert kJ → kcal when necessary (1 kcal = 4.184 kJ)
- Prefer kcal for UI display
- Handle both "kcal" and "calorie" units

### Unit Normalization
- Standardize unit aliases (`μg`/`mcg`, capitalization, spacing)
- Common conversions:
  - `μg`, `mcg`, `microgram` → `μg`
  - `mg`, `milligram` → `mg`
  - `g`, `gram` → `g`
  - `kg`, `kilogram` → `kg`
  - `ml`, `milliliter` → `ml`
  - `l`, `liter`, `litre` → `L`

### String Hygiene
- Trim and collapse whitespace
- Provide "Unknown/—" fallbacks for missing values
- Normalize brand names and descriptions

## Pagination Behavior

### Parameters
- `pageSize`: Number of results per page (default: 25, max: 50)
- `pageNumber`: Page number (1-based)

### Response Fields
- `totalHits`: Total number of matching results
- `currentPage`: Current page number
- `totalPages`: Total number of pages
- `hasMore`: Computed as `currentPage < totalPages`

### UI Behavior
- "Load more" button appears when `hasMore` is true
- Stable pagination under rapid searches
- Request cancellation on new searches

## Caching Strategy

### Cache Configuration
- **TTL**: 7 days (604,800 seconds)
- **Max Size**: 1000 items (LRU eviction)
- **Separate Namespaces**: Search results vs. detail responses

### Cache Keys
- Search: `normalizedQuery_pageSize_pageNumber`
- Details: `fdcId`
- Normalized queries: lowercase, trimmed

### Cache Behavior
- Deterministic keying per normalized query + page
- Separate cache for paginated vs. simple search results
- Automatic cleanup of expired entries
- LRU eviction when cache size exceeds limit

## Error Handling

### Error Types
- `invalidURL`: Malformed request URL
- `invalidResponse`: Invalid HTTP response
- `httpError(Int)`: HTTP status code errors
- `networkError(Error)`: Network connectivity issues
- `decodingError(Error)`: JSON parsing failures
- `noResults`: Empty search results
- `serverUnavailable`: Service unavailable
- `rateLimited(TimeInterval?)`: Rate limit exceeded

### HTTP Status Code Handling
- **400**: Invalid search request
- **401**: Authentication failed
- **403**: Access denied
- **404**: Food not found
- **429**: Rate limit exceeded (with retry-after)
- **5xx**: Server errors

### Retry Logic
- **Max Retries**: 3 attempts
- **Base Delay**: 1 second
- **Exponential Backoff**: `baseDelay * 2^attempt`
- **Retryable Errors**: Network errors, 5xx, 429
- **Non-retryable**: 4xx (except 429), invalid URL, decoding errors

### User-Friendly Messages
- Clear, actionable error descriptions
- Recovery suggestions for each error type
- Specific guidance for network issues

## Barcode Scanning

### VisionKit Integration
- Uses `DataScannerViewController` for iOS 16+
- Supports UPC/EAN barcode formats
- Real-time barcode detection
- Haptic feedback on successful scan

### Permission Handling
- Camera permission request
- Graceful fallback for denied permissions
- Settings redirect for permission management

### Barcode Processing
- Notification-based architecture
- Automatic barcode clearing after 1 second
- Simulated FDC ID mapping (for demo purposes)
- Error handling for invalid barcodes

## Testing

### Unit Tests
- `BarcodeScannerViewModelTests`: Scanner functionality
- `DataNormalizationTests`: Data normalization rules
- `FDCProxyClientTests`: API client with retry logic

### Test Coverage
- Permission handling
- Barcode scanning flow
- Data normalization edge cases
- API error scenarios
- Retry logic behavior
- Cache hit/miss scenarios

## Performance Considerations

### Network Optimization
- Request cancellation on rapid typing
- Debounced search (250ms)
- Exponential backoff for retries
- Efficient pagination

### Memory Management
- LRU cache eviction
- Automatic cleanup of expired entries
- Weak references in notification observers
- Proper task cancellation

### UI Responsiveness
- Background network operations
- MainActor isolation for UI updates
- Haptic feedback for user interactions
- Loading states and error handling

## Privacy & Security

### Data Handling
- No images persisted without consent
- Camera access usage strings
- Secure API communication
- No sensitive data in logs

### Permissions
- Camera access for barcode scanning
- Network access for API calls
- Clear permission prompts
- Graceful degradation without permissions
