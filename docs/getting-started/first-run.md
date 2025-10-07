# First Run Guide

## 🚀 Running the App for First Time

This guide walks you through running the Food Scanner app for the first time and understanding its core features.

## ⚡ Quick Start

### 1. **Launch the App**
- **Select simulator** or device in Xcode
- **Press Cmd+R** to build and run
- **Wait for build** to complete
- **App launches** automatically

### 2. **Initial Setup**
- **Grant camera permissions** for barcode scanning
- **Allow network access** for API calls
- **Review privacy settings** if prompted

### 3. **Explore Main Features**
- **Search tab**: Text-based food search
- **Scanner tab**: Barcode scanning
- **Today tab**: Daily nutrition tracking
- **Settings tab**: App configuration

## 🎯 Core Features Walkthrough

### 🔍 **Search Functionality**
1. **Tap Search tab**
2. **Type food name** (e.g., "apple")
3. **View results** with nutrition info
4. **Tap item** for detailed view
5. **Add to log** with serving size

**What happens**: Text search → API call → Results display → Detail view

### 📷 **Barcode Scanning**
1. **Tap Scanner tab**
2. **Point camera** at barcode
3. **Wait for detection** (automatic)
4. **View product info** if found
5. **Add to log** if supported

**What happens**: Camera → Barcode detection → Product lookup → Display results

### 📅 **Today View**
1. **Tap Today tab**
2. **View daily totals** (calories, macros)
3. **See logged foods** for today
4. **Edit or remove** entries
5. **Track progress** toward goals

**What happens**: Database query → Calculate totals → Display summary

### ⚙️ **Settings**
1. **Tap Settings tab**
2. **Configure preferences**
3. **View app information**
4. **Manage data** and cache
5. **Review privacy** settings

## 🌐 Data Sources

### Supported Sources
- **🇺🇸 FDC**: USDA Food Data Central (comprehensive nutrition)
- **🌍 OFF**: Open Food Facts (community data)

### Data Quality
- **FDC**: High quality, government data
- **OFF**: Variable quality, community-driven
- **Merged**: Best data from both sources

## 🔍 Understanding the Interface

### Main Navigation
```
┌─────────────────────────────────────┐
│  🔍 Search  📷 Scanner  📅 Today  ⚙️ │
└─────────────────────────────────────┘
```

### Search Results
- **Generic foods**: FDC database items
- **Branded products**: Specific brand items
- **Nutrition info**: Calories, macros, micros
- **Serving sizes**: Multiple portion options

### Scanner Results
- **Supported products**: Full nutrition data
- **Unsupported products**: Limited information
- **Unknown products**: Not found in databases

## 🧪 Testing Features

### Search Testing
1. **Try common foods**: "apple", "banana", "chicken"
2. **Test brand names**: "Coca-Cola", "McDonald's"
3. **Check results**: Verify nutrition data
4. **Test pagination**: Scroll for more results

### Scanner Testing
1. **Use simulator**: Test with sample barcodes
2. **Try real products**: Scan actual barcodes
3. **Test unsupported**: Scan unknown products
4. **Check permissions**: Verify camera access

### Logging Testing
1. **Add foods**: From search or scanner
2. **Adjust servings**: Change portion sizes
3. **View totals**: Check daily calculations
4. **Edit entries**: Modify or remove items

## 🚨 Common Issues

### App Won't Launch
- **Check Xcode console** for errors
- **Verify simulator** is running
- **Clean build** and try again

### Search Not Working
- **Check internet connection**
- **Verify API accessibility**
- **Try different search terms**

### Scanner Not Working
- **Grant camera permissions**
- **Check simulator** camera settings
- **Try on real device** if possible

### Data Not Loading
- **Check network connectivity**
- **Verify API service** status
- **Clear app cache** if needed

## 🎯 What to Expect

### First Search
- **May take 2-3 seconds** for initial load
- **Results appear** as they load
- **Nutrition data** should be complete

### First Scan
- **Camera activates** immediately
- **Detection happens** automatically
- **Results show** if product found

### First Log Entry
- **Serving size** defaults to 1
- **Nutrition totals** update immediately
- **Data persists** between app launches

## 🔧 Debugging Tips

### Console Logs
- **Open Xcode console** to see logs
- **Look for API responses** and errors
- **Check network requests** and responses

### Network Issues
- **Test with different** search terms
- **Check calry.org** accessibility
- **Verify proxy service** status

### Performance
- **First launch** may be slower
- **Subsequent searches** should be faster
- **Caching improves** performance over time

## 📚 Next Steps

After successful first run:
1. **🏗️ [Architecture Overview](../architecture/README.md)** - Understand the system
2. **🎯 [Data Journey](../api/data-journey.md)** - Learn backend flow
3. **💻 [Development Guide](../development/README.md)** - Start developing
4. **🔧 [CI/CD Overview](../ci-cd/README.md)** - Build and deploy

## 🎉 Success!

If you've successfully:
- ✅ **Launched the app**
- ✅ **Searched for foods**
- ✅ **Scanned a barcode**
- ✅ **Added food to log**
- ✅ **Viewed daily totals**

You're ready to start developing with the Food Scanner app! The system is working correctly and you can begin exploring the codebase and adding new features.
