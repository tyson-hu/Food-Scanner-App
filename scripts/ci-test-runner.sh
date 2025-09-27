#!/bin/bash
# CI Test Runner - Enhanced robustness for CI builds
# This script provides better error handling, monitoring, and cleanup for CI builds

set -euo pipefail

# Configuration
MAX_ATTEMPTS=5
XCODEBUILD_TIMEOUT=600  # 10 minutes (reduced from 12)
STUCK_THRESHOLD=180     # 3 minutes (reduced from 5)
CHECK_INTERVAL=20       # 20 seconds (more frequent)
PROGRESS_TIMEOUT=40     # 40 seconds for progress detection (reduced from 60)

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

# Enhanced simulator cleanup
cleanup_simulator() {
    local udid="$1"
    log_info "Cleaning up simulator $udid..."
    
    # Shutdown simulator
    xcrun simctl shutdown "$udid" 2>/dev/null || true
    sleep 2
    
    # Erase simulator to reset state
    xcrun simctl erase "$udid" 2>/dev/null || true
    sleep 2
    
    # Boot simulator and wait for completion
    log_info "Booting simulator $udid..."
    if ! xcrun simctl boot "$udid" 2>/dev/null; then
        log_error "Failed to boot simulator $udid"
        return 1
    fi
    
    # Wait for simulator to be fully booted
    log_info "Waiting for simulator to boot..."
    local boot_timeout=60
    local boot_start=$(date +%s)
    
    while [ $(($(date +%s) - boot_start)) -lt $boot_timeout ]; do
        if xcrun simctl list devices 2>/dev/null | grep -q "${udid}.*Booted"; then
            log_success "Simulator $udid booted successfully"
            sleep 3  # Additional stability wait
            log_info "Simulator cleanup completed"
            return 0
        fi
        sleep 2
    done
    
    log_error "Simulator $udid failed to boot within ${boot_timeout} seconds"
    return 1
}

# Enhanced simulator health check
check_simulator_health() {
    local udid="$1"
    
    # Debug: Show current simulator status
    log_info "Checking simulator health for $udid..."
    local simulator_status=$(xcrun simctl list devices 2>/dev/null | grep "$udid" || echo "Not found")
    log_info "Simulator status: $simulator_status"
    
    # Check if simulator is booted
    if ! xcrun simctl list devices 2>/dev/null | grep -q "${udid}.*Booted"; then
        log_warning "Simulator $udid is not booted"
        return 1
    fi
    
    # Test simulator responsiveness with a simple command
    log_info "Testing simulator responsiveness..."
    if ! xcrun simctl list devices 2>/dev/null | grep -q "${udid}.*Booted"; then
        log_warning "Simulator $udid is not responsive"
        return 1
    fi
    
    log_success "Simulator $udid is healthy"
    return 0
}

# System cleanup
cleanup_system() {
    log_info "Performing system cleanup..."
    
    # Clear memory pressure
    sudo purge 2>/dev/null || true
    
    # Clear temporary files
    rm -rf /tmp/xcodebuild_* 2>/dev/null || true
    
    # Clear simulator logs
    xcrun simctl spawn booted log erase --all 2>/dev/null || true
    
    log_info "System cleanup completed"
}

# Enhanced test runner with progress monitoring
run_tests_with_monitoring() {
    local attempt="$1"
    local dest_id="$2"
    local derived_data_path="$3"
    
    log_info "Starting test attempt $attempt/$MAX_ATTEMPTS"
    
    # Pre-flight checks
    # Always reset simulator for clean state (CI best practice)
    log_info "Resetting simulator for clean test state..."
    if ! cleanup_simulator "$dest_id"; then
        log_error "Simulator cleanup failed"
        return 1
    fi
    
    # Check simulator health after reset
    if ! check_simulator_health "$dest_id"; then
        log_error "Simulator still unhealthy after reset"
        return 1
    fi
    
    # Create log file for monitoring
    local log_file="/tmp/xcodebuild_attempt_${attempt}.log"
    local start_time=$(date +%s)
    
    log_info "Starting xcodebuild with ${XCODEBUILD_TIMEOUT}s timeout..."
    
    # Start xcodebuild in background
    xcodebuild \
        -scheme "Food Scanner" \
        -testPlan "FoodScanner-CI-Offline" \
        -destination "id=$dest_id" \
        -destination-timeout 60 \
        -derivedDataPath "$derived_data_path" \
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
        test > "$log_file" 2>&1 &
    
    local xcodebuild_pid=$!
    log_info "xcodebuild PID: $xcodebuild_pid"
    
    # Monitor progress with timeout
    local last_activity=$start_time
    local last_log_size=0
    local stuck_count=0
    
    while kill -0 "$xcodebuild_pid" 2>/dev/null; do
        sleep $CHECK_INTERVAL
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # Check if process is still running
        if ! kill -0 "$xcodebuild_pid" 2>/dev/null; then
            log_info "xcodebuild process ended"
            break
        fi
        
        # Check for overall timeout
        if [ $elapsed -gt $XCODEBUILD_TIMEOUT ]; then
            log_error "xcodebuild timeout after ${XCODEBUILD_TIMEOUT} seconds, killing process..."
            kill -TERM "$xcodebuild_pid" 2>/dev/null || true
            sleep 5
            kill -KILL "$xcodebuild_pid" 2>/dev/null || true
            log_error "xcodebuild killed due to timeout"
            return 1
        fi
        
        # Check for progress in log file
        if [ -f "$log_file" ]; then
            local current_log_size=$(wc -c < "$log_file" 2>/dev/null || echo 0)
            local log_age=$(($(date +%s) - $(stat -f %m "$log_file" 2>/dev/null || echo 0)))
            
            # If log file is growing or recently modified, we have progress
            if [ $current_log_size -gt $last_log_size ] || [ $log_age -lt $PROGRESS_TIMEOUT ]; then
                last_activity=$current_time
                last_log_size=$current_log_size
                stuck_count=0
                log_info "Progress detected (log size: $current_log_size bytes)"
            else
                stuck_count=$((stuck_count + 1))
                log_warning "No progress detected for $((stuck_count * CHECK_INTERVAL)) seconds"
            fi
        fi
        
        # Check for stuck condition (no activity for 5 minutes)
        local activity_elapsed=$((current_time - last_activity))
        if [ $activity_elapsed -gt $STUCK_THRESHOLD ]; then
            log_error "xcodebuild appears stuck (no activity for $STUCK_THRESHOLD seconds), killing process..."
            kill -TERM "$xcodebuild_pid" 2>/dev/null || true
            sleep 5
            kill -KILL "$xcodebuild_pid" 2>/dev/null || true
            log_error "xcodebuild killed due to stuck condition"
            return 1
        fi
    done
    
    # Wait for process to complete
    wait "$xcodebuild_pid"
    local exit_code=$?
    local total_time=$(($(date +%s) - start_time))
    
    # Show results
    log_info "xcodebuild completed in ${total_time}s with exit code $exit_code"
    
    # Show last part of log for debugging
    if [ -f "$log_file" ] && [ -s "$log_file" ]; then
        echo "=== Last 50 lines of xcodebuild output ==="
        tail -50 "$log_file"
        echo "=== End of xcodebuild output ==="
    fi
    
    # Clean up log file
    rm -f "$log_file"
    
    return $exit_code
}

# Main retry logic
main() {
    local dest_id="$1"
    local derived_data_path="${2:-./DerivedData}"
    
    log_info "Starting CI test runner with $MAX_ATTEMPTS attempts"
    log_info "Destination ID: $dest_id"
    log_info "Derived Data Path: $derived_data_path"
    
    # Initial system cleanup
    cleanup_system
    
    # Enhanced retry logic
    for attempt in $(seq 1 $MAX_ATTEMPTS); do
        log_info "=== Starting attempt $attempt/$MAX_ATTEMPTS ==="
        
        if run_tests_with_monitoring "$attempt" "$dest_id" "$derived_data_path"; then
            log_success "Tests passed on attempt $attempt"
            exit 0
        else
            log_warning "Test attempt $attempt failed"
            
            if [ $attempt -lt $MAX_ATTEMPTS ]; then
                log_info "Preparing for retry $((attempt + 1))..."
                
                # Enhanced cleanup between retries
                cleanup_simulator "$dest_id"
                cleanup_system
                
                # Progressive backoff
                local wait_time=$((attempt * 15))
                log_info "Waiting $wait_time seconds before retry..."
                sleep $wait_time
                
                # Verify simulator is ready
                if ! check_simulator_health "$dest_id"; then
                    log_warning "Simulator not ready after cleanup, skipping to next attempt"
                    continue
                fi
            fi
        fi
    done
    
    log_error "All $MAX_ATTEMPTS test attempts failed"
    log_info "=== Final simulator status ==="
    xcrun simctl list devices
    exit 1
}

# Script entry point
if [ $# -lt 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 <destination_id> [derived_data_path]"
    echo "Example: $0 2A4C3F08-503C-410A-BF1E-5A5C1B2D0AC4 ./DerivedData"
    echo ""
    echo "Arguments:"
    echo "  destination_id: iOS Simulator UDID to run tests on"
    echo "  derived_data_path: Path to DerivedData directory (default: ./DerivedData)"
    exit 0
fi

main "$1" "${2:-./DerivedData}"
