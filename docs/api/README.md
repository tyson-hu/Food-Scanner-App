# API Integration Documentation

## 📁 API Documentation Structure

```
api/
├── README.md                    # 📋 This file - API documentation index
├── data-journey.md              # 🎯 Complete data flow from proxy to UI
├── fdc-integration.md           # 🇺🇸 FDC API integration details
├── off-integration.md           # 🌍 OFF API integration details
├── proxy-service.md             # 🔌 Proxy service architecture
└── schemas/                     # 📄 API specifications
    ├── fdc-api.yaml            # OpenAPI 3.0 specification for FDC
    └── off-api.yaml            # OpenAPI 3.0 specification for OFF
```

## 🌐 Multi-Source API Integration

The Food Scanner app integrates with multiple data sources through a unified proxy API to provide comprehensive food and supplement information.

### Supported Data Sources

- **🇺🇸 FDC (Food Data Central)**: USDA's comprehensive food database
- **🌍 OFF (Open Food Facts)**: Community-driven food database
- **💊 DSLD (Dietary Supplement Label Database)**: NIH's supplement database (future)
- **🧪 DSID (Dietary Supplement Ingredient Database)**: Future support planned

### Global ID (GID) System

All food items are identified using GIDs with source prefixes:
- `fdc:12345` - FDC food item
- `off:67890` - OFF food item  
- `dsld:11111` - DSLD supplement item (future)
- `dsid:22222` - DSID supplement ingredient (future)

## 🎯 Data Journey Overview

The complete data flow from raw proxy responses to cooked display data follows this journey:

```
Raw Proxy Data → Envelope Wrapping → Source Detection → Normalization → Merging → Conversion → Display Models
```

**📖 See [Complete Data Journey](data-journey.md)** for the full technical flow with function headers and detailed explanations.

## 📋 Documentation Files

### [Complete Data Journey](data-journey.md) 🎯
**The main technical guide** showing how data flows from proxy to UI:
- **7-stage data journey** with visual diagrams
- **Function headers** with explanations for each stage
- **Code examples** showing data transformations
- **Error handling** at each stage
- **FDC vs OFF** processing differences
- **Merging logic** when both sources available

### [FDC Integration](fdc-integration.md) 🇺🇸
**FDC-specific integration details**:
- **API endpoints** and request/response formats
- **Data models** and field mappings
- **Nutrient standardization** and unit conversions
- **Error handling** for FDC-specific issues
- **Performance considerations** and caching

### [OFF Integration](off-integration.md) 🌍
**OFF-specific integration details**:
- **API endpoints** and request/response formats  
- **Data models** and field mappings
- **Image handling** and URL processing
- **Ingredient parsing** and text processing
- **Community data** quality considerations

### [Proxy Service](proxy-service.md) 🔌
**Proxy service architecture**:
- **calry.org integration** and authentication
- **Rate limiting** and request management
- **Error handling** and retry logic
- **Caching strategy** and performance
- **Monitoring** and debugging tools

### [API Schemas](schemas/) 📄
**OpenAPI specifications**:
- **fdc-api.yaml**: Complete FDC API schema
- **off-api.yaml**: Complete OFF API schema
- **Request/response models** with field descriptions
- **Error response schemas** and status codes

## 🚀 Quick Start

### For New Developers
1. **Start with [Data Journey](data-journey.md)** to understand the complete flow
2. **Review [FDC Integration](fdc-integration.md)** for USDA data processing
3. **Check [OFF Integration](off-integration.md)** for community data handling
4. **Understand [Proxy Service](proxy-service.md)** for API communication

### For API Integrators
1. **Study [API Schemas](schemas/)** for request/response formats
2. **Review data models** in each integration guide
3. **Understand error handling** patterns
4. **Check rate limiting** and performance considerations

### For Debugging
1. **Trace data flow** using [Data Journey](data-journey.md) stages
2. **Check function headers** to understand what each component does
3. **Review error handling** at each stage
4. **Use proxy service** debugging tools

## 🔧 Key Components

### Core Services
- **ProxyClient**: HTTP communication with calry.org
- **FoodNormalizationService**: Data normalization and merging
- **FoodDataConverter**: Public model conversion
- **ProductSourceDetection**: Source identification and support status

### Data Models
- **Envelope<T>**: Generic wrapper for raw data
- **NormalizedFood**: Canonical internal model
- **FoodMinimalCard**: Public search result model
- **FoodAuthoritativeDetail**: Public detail model

### Processing Pipeline
1. **Fetch**: Raw data from proxy service
2. **Wrap**: Envelope with metadata
3. **Detect**: Source and support status
4. **Normalize**: Canonical internal format
5. **Merge**: Combine multiple sources
6. **Convert**: Public API models
7. **Display**: UI-ready data

## 📊 Data Source Comparison

| Feature | FDC | OFF |
|---------|-----|-----|
| **Data Quality** | High (USDA) | Variable (Community) |
| **Nutrients** | Comprehensive | Basic |
| **Images** | Limited | Extensive |
| **Ingredients** | Basic | Detailed |
| **Barcodes** | Some | Extensive |
| **Update Frequency** | Regular | Real-time |

## 🎯 Best Practices

1. **Always check data completeness** before displaying
2. **Use merged data** when both FDC and OFF available
3. **Handle missing fields** gracefully
4. **Cache normalized data** for performance
5. **Track data sources** for debugging
6. **Validate GID format** before processing

This documentation provides everything needed to understand and work with the Food Scanner API integration system.