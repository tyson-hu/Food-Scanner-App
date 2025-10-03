#!/bin/bash
# Lint with CI-equivalent settings
# This script runs linting with the same settings used in CI

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

# Check if tools are installed
check_tools() {
    log_info "Checking linting tools..."
    
    # Check SwiftLint
    if ! command -v swiftlint &> /dev/null; then
        log_error "SwiftLint not found. Install with: brew install swiftlint"
        exit 1
    fi
    
    # Check SwiftFormat
    if ! command -v swiftformat &> /dev/null; then
        log_error "SwiftFormat not found. Install with: brew install swiftformat"
        exit 1
    fi
    
    log_success "Linting tools found"
}

# Run SwiftFormat
run_swiftformat() {
    log_info "Running SwiftFormat (lint only)..."
    
    local start_time=$(date +%s)
    
    # Run SwiftFormat on Sources
    if ! swiftformat --lint Sources; then
        log_error "SwiftFormat failed on Sources directory"
        return 1
    fi
    
    # Run SwiftFormat on Tests
    if ! swiftformat --lint Tests; then
        log_error "SwiftFormat failed on Tests directory"
        return 1
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "SwiftFormat completed successfully in ${duration}s"
}

# Run SwiftLint
run_swiftlint() {
    log_info "Running SwiftLint (strict mode)..."
    
    local start_time=$(date +%s)
    
    # Run SwiftLint in strict mode (matches CI)
    if ! swiftlint --strict; then
        log_error "SwiftLint failed"
        return 1
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "SwiftLint completed successfully in ${duration}s"
}

# Show linting summary
show_linting_summary() {
    log_info "Linting Summary:"
    
    # Count SwiftLint violations
    local swiftlint_output=$(swiftlint lint --reporter json 2>/dev/null || echo "[]")
    local violation_count=$(echo "$swiftlint_output" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(len(data))
except:
    print('0')
" 2>/dev/null || echo "0")
    
    if [[ "$violation_count" -eq 0 ]]; then
        log_success "  SwiftLint: 0 violations"
    else
        log_warning "  SwiftLint: $violation_count violations found"
    fi
    
    # Check SwiftFormat status
    local swiftformat_sources=$(swiftformat --lint Sources 2>&1 | grep -c "require formatting" || echo "0")
    local swiftformat_tests=$(swiftformat --lint Tests 2>&1 | grep -c "require formatting" || echo "0")
    local total_formatting_issues=$((swiftformat_sources + swiftformat_tests))
    
    if [[ "$total_formatting_issues" -eq 0 ]]; then
        log_success "  SwiftFormat: 0 files require formatting"
    else
        log_warning "  SwiftFormat: $total_formatting_issues files require formatting"
    fi
}

# Main function
main() {
    log_info "🔍 Running linting with CI-equivalent settings..."
    echo
    
    # Check if we're in the right directory
    if [[ ! -f "Food Scanner.xcodeproj/project.pbxproj" ]]; then
        log_error "Food Scanner.xcodeproj not found. Run this script from the project root."
        exit 1
    fi
    
    check_tools
    run_swiftformat
    run_swiftlint
    show_linting_summary
    
    echo
    log_success "✅ Linting completed successfully!"
    log_info "To run build: ./scripts/build-local-ci.sh"
    log_info "To run tests: ./scripts/test-local-ci.sh"
}

# Run main function
main "$@"
