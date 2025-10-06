#!/bin/bash
# Test with CI-equivalent settings
# This script runs tests with the same settings used in CI

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
TEST_PLAN="FoodScanner-CI-Offline"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

# Clean derived data
clean_derived_data() {
    log_info "Cleaning derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Food_Scanner-*
    rm -rf "$DERIVED_DATA_PATH"
    log_success "Derived data cleaned"
}

# Setup simulator
setup_simulator() {
    log_info "Setting up iPhone 16 simulator..."
    
    # Find or create iPhone 16 simulator
    local simulator_id=$(xcrun simctl list devices | grep "iPhone 16" | grep -v "Unavailable" | head -1 | grep -o '[A-F0-9-]\{36\}' || echo "")
    
    if [[ -z "$simulator_id" ]]; then
        log_info "Creating iPhone 16 simulator..."
        
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
        simulator_id=$(xcrun simctl create "CI-iPhone-16" "iPhone 16" "$runtime" 2>/dev/null || echo "")
        
        if [[ -z "$simulator_id" ]]; then
            log_error "Failed to create iPhone 16 simulator"
            exit 1
        fi
        
        log_success "Created iPhone 16 simulator: $simulator_id"
    else
        log_success "Found iPhone 16 simulator: $simulator_id"
    fi
    
    # Boot simulator if not already booted
    local boot_status=$(xcrun simctl list devices | grep "$simulator_id" | grep "Booted" || echo "")
    if [[ -z "$boot_status" ]]; then
        log_info "Booting simulator..."
        xcrun simctl boot "$simulator_id" 2>/dev/null || true
        sleep 5
    fi
    
    # Grant permissions to prevent test interruptions
    log_info "Granting permissions..."
    xcrun simctl privacy "$simulator_id" grant camera app.tysonhu.calry 2>/dev/null || true
    xcrun simctl privacy "$simulator_id" grant photos app.tysonhu.calry 2>/dev/null || true
    xcrun simctl privacy "$simulator_id" grant microphone app.tysonhu.calry 2>/dev/null || true
    
    # Update destination to use specific simulator ID
    DESTINATION="id=$simulator_id"
    log_success "Simulator setup complete"
}

# Run tests
run_tests() {
    log_info "Running tests with CI-equivalent settings..."
    
    local start_time=$(date +%s)
    
    # Run tests with CI settings
    xcodebuild test \
        -scheme "Food Scanner" \
        -testPlan "$TEST_PLAN" \
        -destination "$DESTINATION" \
        -destination-timeout 60 \
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
        -skip-testing:FoodScannerUITests \
        -parallel-testing-enabled NO \
        -maximum-concurrent-test-simulator-destinations 1 \
        -test-timeouts-enabled YES \
        -default-test-execution-time-allowance 30 \
        -maximum-test-execution-time-allowance 60 \
        2>&1 | grep -v "appintentsmetadataprocessor.*warning: Metadata extraction skipped" || {
        log_error "Tests failed"
        return 1
    }
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "Tests completed successfully in ${duration}s"
}

# Show test summary
show_test_summary() {
    log_info "Test Summary:"
    
    # Count test results from the last run
    local test_log="/tmp/xcodebuild_test.log"
    if [[ -f "$test_log" ]]; then
        local total_tests=$(grep -c "◇ Test.*started" "$test_log" 2>/dev/null || echo "0")
        local passed_tests=$(grep -c "✔ Test.*passed" "$test_log" 2>/dev/null || echo "0")
        local failed_tests=$(grep -c "❌ Test.*failed" "$test_log" 2>/dev/null || echo "0")
        
        log_info "  Total tests: $total_tests"
        log_info "  Passed: $passed_tests"
        log_info "  Failed: $failed_tests"
        
        if [[ "$failed_tests" -gt 0 ]]; then
            log_warning "Some tests failed. Check the output above for details."
        fi
    else
        log_info "  Test summary not available"
    fi
}

# Main function
main() {
    log_info "🧪 Running tests with CI-equivalent settings..."
    echo
    
    # Check if we're in the right directory
    if [[ ! -f "Food Scanner.xcodeproj/project.pbxproj" ]]; then
        log_error "Food Scanner.xcodeproj not found. Run this script from the project root."
        exit 1
    fi
    
    # Check if test plan exists
    if [[ ! -f "$TEST_PLAN.xctestplan" ]]; then
        log_error "Test plan $TEST_PLAN.xctestplan not found"
        exit 1
    fi
    
    clean_derived_data
    setup_simulator
    run_tests
    show_test_summary
    
    echo
    log_success "✅ Tests completed successfully!"
    log_info "Derived data location: $DERIVED_DATA_PATH"
    log_info "To run build: ./scripts/build-local-ci.sh"
    log_info "To run linting: ./scripts/lint-local-ci.sh"
}

# Run main function
main "$@"
