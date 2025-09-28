# DSLD Integration Guide

This document provides comprehensive information about the DSLD (Dietary Supplement Label Database) integration in the Food Scanner app.

## Overview

The Food Scanner app now supports the NIH's Dietary Supplement Label Database (DSLD) as a data source for supplement information. This integration provides access to comprehensive supplement data including vitamins, minerals, and other dietary supplements.

## DSLD API Integration

### Data Source
- **API Endpoint**: `https://api.ods.od.nih.gov/dsld/v9/search-filter`
- **Documentation**: [DSLD API Guide](https://dsld.od.nih.gov/api-guide)
- **Response Format**: Elasticsearch-based JSON with nested `_source` data

### Data Structure
DSLD API returns data in the following format:
```json
{
  "hits": [
    {
      "_index": "dsldnxt_labels_syns1149",
      "_type": "_doc",
      "_id": "207381",
      "_score": 24.826374,
      "_source": {
        "brandName": "Kirkland Signature",
        "productName": "Active Vitamin Pack",
        "fullName": "Active Vitamin Pack",
        "upcSku": "1234567890123",
        "allIngredients": [
          {
            "ingredientGroup": "Vitamin A",
            "name": "Vitamin A",
            "category": "vitamin"
          }
        ]
      }
    }
  ]
}
```

## Implementation Details

### Global ID (GID) Format
DSLD items are identified using the format: `dsld:{supplement_id}`
- Example: `dsld:207381` for supplement ID 207381

### Product Support Status
DSLD items are classified as **supported** products with full nutritional information:
```swift
enum ProductSupportStatus {
    case supported(SourceTag)    // FDC, DSLD - full nutrition data
    case unsupported(SourceTag?) // DSID, OFF - limited data
    case unknown                 // Unrecognized source
}
```

### Data Validation and Debugging

The app includes comprehensive validation and debugging for DSLD data:

#### Empty Data Detection
```swift
// Detects when DSLD data is empty or invalid
if foodCard.description == nil, foodCard.brand == nil, foodCard.nutrients.isEmpty {
    print("⚠️ DSLD Warning: Received empty data for \(gid)")
    // Additional validation logic...
}
```

#### Invalid ID Detection
```swift
// Detects malformed DSLD IDs
if gid == "dsld:undefined" {
    print("Error: DSLD ID is 'undefined' - this suggests a problem with ID generation")
}
```

#### Response Logging
```swift
// Detailed logging of DSLD API responses
if gid.hasPrefix("dsld:") {
    if let jsonString = String(data: data, encoding: .utf8) {
        print("🔍 DSLD Raw Response for \(gid):")
        print(jsonString)
    }
}
```

## Error Handling

### Common DSLD Issues

1. **Empty Data Response**
   - **Cause**: Invalid DSLD ID or proxy service issue
   - **Detection**: All nutritional fields are null/empty
   - **User Message**: "Supplement data is not available"

2. **Invalid DSLD ID**
   - **Cause**: Malformed ID like "dsld:undefined"
   - **Detection**: ID contains "undefined" or invalid format
   - **User Message**: "Invalid supplement identifier"

3. **Proxy Service Issues**
   - **Cause**: Proxy API fails to fetch DSLD data
   - **Detection**: HTTP errors or empty responses
   - **User Message**: "Unable to load supplement information"

### Debugging Output
When DSLD issues are detected, the app provides detailed logging:
```
🔍 DSLD Raw Response for dsld:undefined:
{"id":"dsld:undefined","kind":"supplement","code":null,"description":null,"brand":null,"serving":null,"nutrients":[],"provenance":{"source":"dsld","id":"undefined","fetchedAt":"2025-09-27T23:18:22.011Z"}}

⚠️ DSLD Warning: Received empty data for dsld:undefined
   This might indicate the DSLD ID is invalid or the proxy service has an issue
   Error: DSLD ID is 'undefined' - this suggests a problem with ID generation or passing
```

## API Endpoints

### Search DSLD Supplements
```
GET https://api.calry.org/v1/search?q=vitamin&limit=20
```

**Response includes DSLD items in the `branded` array:**
```json
{
  "branded": [
    {
      "id": "dsld:207381",
      "kind": "supplement",
      "description": "Active Vitamin Pack",
      "brand": "Kirkland Signature",
      "provenance": {
        "source": "dsld",
        "id": "207381",
        "fetchedAt": "2025-09-27T23:26:48.663Z"
      }
    }
  ]
}
```

### Get DSLD Supplement Details
```
GET https://api.calry.org/v1/food/dsld:207381
```

**Response includes detailed supplement information:**
```json
{
  "id": "dsld:207381",
  "kind": "supplement",
  "description": "Active Vitamin Pack",
  "brand": "Kirkland Signature",
  "serving": {
    "amount": 1.0,
    "unit": "packet",
    "household": "1 packet"
  },
  "nutrients": [
    {
      "name": "Vitamin A",
      "amount": 1000.0,
      "unit": "μg",
      "category": "vitamin"
    }
  ],
  "provenance": {
    "source": "dsld",
    "id": "207381",
    "fetchedAt": "2025-09-27T23:26:48.663Z"
  }
}
```

## Testing

### Unit Tests
- `ProductSourceDetectionTests`: Tests for DSLD source detection
- `FDCProxyClientTests`: Tests for DSLD data handling
- `AddFoodSummaryViewModelTests`: Tests for DSLD error handling

### Test Data
Use valid DSLD IDs for testing:
- `dsld:207381` - Active Vitamin Pack (Kirkland Signature)
- `dsld:62677` - Extra Strength Vitamin D3 2000 IU
- `dsld:1872` - Vitamin D3 2000 IU

### Debugging Tests
```swift
// Test DSLD data validation
func testDSLDEmptyDataDetection() {
    let emptyDSLDData = FoodMinimalCard(
        id: "dsld:undefined",
        kind: .supplement,
        description: nil,
        brand: nil,
        code: nil,
        serving: nil,
        nutrients: [],
        provenance: FoodProvenance(source: .dsld, id: "undefined", fetchedAt: Date())
    )
    
    // Should detect empty data
    XCTAssertTrue(isDSLDDataEmpty(emptyDSLDData))
}
```

## Troubleshooting

### Common Issues

1. **DSLD items showing "n/a" and "undefined"**
   - **Cause**: Proxy service returning empty DSLD data
   - **Solution**: Check proxy service logs and DSLD API connectivity
   - **Debug**: Enable DSLD response logging

2. **DSLD search not returning results**
   - **Cause**: DSLD API connectivity issues
   - **Solution**: Verify DSLD API endpoint accessibility
   - **Debug**: Check network connectivity and API status

3. **Invalid DSLD IDs in search results**
   - **Cause**: Proxy service mapping issue
   - **Solution**: Update proxy service DSLD ID mapping logic
   - **Debug**: Check proxy service DSLD search implementation

### Debug Commands
```bash
# Test DSLD API connectivity
curl -I "https://api.ods.od.nih.gov/dsld/v9/search-filter?q=vitamin&size=1"

# Test proxy service DSLD search
curl "https://api.calry.org/v1/search?q=vitamin&limit=5"

# Check specific DSLD item
curl "https://api.calry.org/v1/food/dsld:207381"
```

## Future Enhancements

### Planned Improvements
1. **Enhanced DSLD Data Processing**: Better mapping of DSLD nutritional data
2. **Supplement-Specific UI**: Specialized interface for supplement information
3. **Ingredient Analysis**: Detailed ingredient breakdown for supplements
4. **Dosage Information**: Supplement dosage and serving recommendations

### Integration Opportunities
1. **DSID Integration**: Dietary Supplement Ingredient Database support
2. **Supplement Interactions**: Drug-supplement interaction warnings
3. **Regulatory Information**: FDA supplement regulation compliance
4. **Quality Metrics**: Supplement quality and purity indicators

## References

- [DSLD API Documentation](https://dsld.od.nih.gov/api-guide)
- [NIH Dietary Supplements](https://ods.od.nih.gov/)
- [DSLD Database](https://dsld.od.nih.gov/)
- [Food Scanner API Documentation](./M2-03_API_DOCUMENTATION.md)

---

**Last Updated**: September 2025  
**Version**: 1.0  
**Status**: Production Ready ✅
