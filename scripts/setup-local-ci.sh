#!/bin/bash
# Setup Local CI Environment
# This script helps set up your local environment to match CI exactly

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

# Check Xcode version
check_xcode_version() {
    log_info "Checking Xcode version..."
    
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode not found. Please install Xcode 26.0.0"
        exit 1
    fi
    
    local xcode_version=$(xcodebuild -version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
    
    if [[ "$xcode_version" != "26.0.0" ]]; then
        log_warning "Xcode version $xcode_version detected. CI uses 26.0.0"
        log_warning "Consider updating to Xcode 26.0.0 for exact CI compatibility"
    else
        log_success "Xcode 26.0.0 detected ✓"
    fi
}

# Check iOS 26 runtime
check_ios_runtime() {
    log_info "Checking iOS 26 runtime..."
    
    local ios26_runtime=$(xcrun simctl list runtimes | grep "iOS 26" | head -1 || echo "")
    
    if [[ -z "$ios26_runtime" ]]; then
        log_error "iOS 26 runtime not found"
        log_info "Please install iOS 26 runtime through Xcode → Settings → Platforms"
        exit 1
    else
        log_success "iOS 26 runtime found ✓"
    fi
}

# Check iPhone 16 simulator
check_iphone16_simulator() {
    log_info "Checking iPhone 16 simulator..."
    
    local iphone16_device=$(xcrun simctl list devices | grep "iPhone 16" | head -1 || echo "")
    
    if [[ -z "$iphone16_device" ]]; then
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
            log_error "Could not find iOS 26 runtime for simulator creation"
            exit 1
        fi
        
        # Create iPhone 16 simulator
        local simulator_id=$(xcrun simctl create "CI-iPhone-16" "iPhone 16" "$runtime" 2>/dev/null || echo "")
        
        if [[ -z "$simulator_id" ]]; then
            log_error "Failed to create iPhone 16 simulator"
            exit 1
        fi
        
        log_success "Created iPhone 16 simulator: $simulator_id ✓"
    else
        log_success "iPhone 16 simulator found ✓"
    fi
}

# Check required tools
check_tools() {
    log_info "Checking required tools..."
    
    # Check SwiftLint
    if command -v swiftlint &> /dev/null; then
        local swiftlint_version=$(swiftlint version)
        log_success "SwiftLint $swiftlint_version found ✓"
    else
        log_error "SwiftLint not found. Install with: brew install swiftlint"
        exit 1
    fi
    
    # Check SwiftFormat
    if command -v swiftformat &> /dev/null; then
        local swiftformat_version=$(swiftformat --version)
        log_success "SwiftFormat $swiftformat_version found ✓"
    else
        log_error "SwiftFormat not found. Install with: brew install swiftformat"
        exit 1
    fi
}

# Check build settings
check_build_settings() {
    log_info "Checking build settings..."
    
    # Check if project exists
    if [[ ! -f "Calry.xcodeproj/project.pbxproj" ]]; then
        log_error "Calry.xcodeproj not found. Run this script from the project root."
        exit 1
    fi
    
    # Get build settings
    local build_settings=$(xcodebuild -project "Calry.xcodeproj" -scheme "Calry" -configuration Debug -showBuildSettings 2>/dev/null || echo "")
    
    if [[ -z "$build_settings" ]]; then
        log_warning "Could not retrieve build settings. Make sure the scheme exists."
        return
    fi
    
    # Check SWIFT_STRICT_CONCURRENCY
    local strict_concurrency=$(echo "$build_settings" | grep "SWIFT_STRICT_CONCURRENCY" | head -1 | awk '{print $3}' || echo "")
    if [[ "$strict_concurrency" == "complete" ]]; then
        log_success "SWIFT_STRICT_CONCURRENCY=complete ✓"
    else
        log_warning "SWIFT_STRICT_CONCURRENCY not set to 'complete'. CI uses 'complete'"
    fi
    
    # Check OTHER_SWIFT_FLAGS
    local swift_flags=$(echo "$build_settings" | grep "OTHER_SWIFT_FLAGS" | head -1 | awk '{print $3}' || echo "")
    if [[ "$swift_flags" == *"warnings-as-errors"* ]]; then
        log_success "OTHER_SWIFT_FLAGS includes warnings-as-errors ✓"
    else
        log_warning "OTHER_SWIFT_FLAGS doesn't include warnings-as-errors. CI uses '-warnings-as-errors'"
    fi
}

# Set up environment variables
setup_environment() {
    log_info "Setting up environment variables..."
    
    # Create environment file
    cat > .env.ci << EOF
# CI Environment Variables
export CI_OFFLINE_MODE=YES
export NETWORK_TESTING_DISABLED=YES
export ENABLE_PREVIEWS=NO

# Xcode Settings
export SWIFT_STRICT_CONCURRENCY=complete
export OTHER_SWIFT_FLAGS='-warnings-as-errors'
export DEFAULT_ISOLATION=MainActor
EOF
    
    log_success "Created .env.ci file with CI environment variables"
    log_info "To use these variables, run: source .env.ci"
}

# Main function
main() {
    log_info "🔧 Setting up local environment to match CI..."
    echo
    
    check_xcode_version
    check_ios_runtime
    check_iphone16_simulator
    check_tools
    check_build_settings
    setup_environment
    
    echo
    log_success "✅ Local CI environment setup complete!"
    echo
    log_info "Next steps:"
    log_info "1. Source the environment: source .env.ci"
    log_info "2. Run build script: ./scripts/build-local-ci.sh"
    log_info "3. Run test script: ./scripts/test-local-ci.sh"
    log_info "4. Run lint script: ./scripts/lint-local-ci.sh"
    echo
    log_info "For detailed setup instructions, see: docs/development/local-ci-setup.md"
}

# Run main function
main "$@"
