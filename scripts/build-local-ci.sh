#!/bin/bash
# Build with CI-equivalent settings
# This script builds the project with the same settings used in CI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
DERIVED_DATA_PATH="./DerivedData"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

# Clean derived data
clean_derived_data() {
    log_info "Cleaning derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Food_Scanner-*
    rm -rf "$DERIVED_DATA_PATH"
    log_success "Derived data cleaned"
}

# Check simulator availability
check_simulator() {
    log_info "Checking iPhone 16 simulator availability..."
    
    local simulator_status=$(xcrun simctl list devices | grep "iPhone 16" | grep -v "Unavailable" | head -1 || echo "")
    
    if [[ -z "$simulator_status" ]]; then
        log_warning "iPhone 16 simulator not found. Creating one..."
        
        # Find iOS 26 runtime
        local runtime=$(xcrun simctl list -j runtimes | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('runtimes', []):
    if r.get('platform') == 'iOS' and str(r.get('version', '')).startswith('26'):
        print(r['identifier'])
        break
" 2>/dev/null || echo "")
        
        if [[ -z "$runtime" ]]; then
            log_error "Could not find iOS 26 runtime"
            exit 1
        fi
        
        # Create iPhone 16 simulator
        local simulator_id=$(xcrun simctl create "CI-iPhone-16" "iPhone 16" "$runtime" 2>/dev/null || echo "")
        
        if [[ -z "$simulator_id" ]]; then
            log_error "Failed to create iPhone 16 simulator"
            exit 1
        fi
        
        log_success "Created iPhone 16 simulator: $simulator_id"
    else
        log_success "iPhone 16 simulator available"
    fi
}

# Build the project
build_project() {
    log_info "Building project with CI-equivalent settings..."
    
    local start_time=$(date +%s)
    
    # Build with CI settings
    xcodebuild build \
        -scheme "Food Scanner" \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        CODE_SIGNING_ALLOWED=NO \
        ENABLE_PREVIEWS=NO \
        SWIFT_STRICT_CONCURRENCY=complete \
        OTHER_SWIFT_FLAGS='-warnings-as-errors' \
        CI_OFFLINE_MODE=YES \
        NETWORK_TESTING_DISABLED=YES \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        -disableAutomaticPackageResolution \
        2>&1 | grep -v "appintentsmetadataprocessor.*warning: Metadata extraction skipped" || {
        log_error "Build failed"
        return 1
    }
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "Build completed successfully in ${duration}s"
}

# Main function
main() {
    log_info "🔨 Building with CI-equivalent settings..."
    echo
    
    # Check if we're in the right directory
    if [[ ! -f "Food Scanner.xcodeproj/project.pbxproj" ]]; then
        log_error "Food Scanner.xcodeproj not found. Run this script from the project root."
        exit 1
    fi
    
    clean_derived_data
    check_simulator
    build_project
    
    echo
    log_success "✅ Build completed successfully!"
    log_info "Derived data location: $DERIVED_DATA_PATH"
    log_info "To run tests: ./scripts/test-local-ci.sh"
    log_info "To run linting: ./scripts/lint-local-ci.sh"
}

# Run main function
main "$@"
