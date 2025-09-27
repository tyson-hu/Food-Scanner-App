#!/bin/bash
# Simulator Manager - Enhanced simulator lifecycle management for CI
# This script provides robust simulator creation, booting, and cleanup

set -euo pipefail

# Configuration
BOOT_TIMEOUT=120
STABILITY_WAIT=10
MAX_RETRIES=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[SIM-MGR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SIM-MGR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SIM-MGR]${NC} $1"
}

log_error() {
    echo -e "${RED}[SIM-MGR]${NC} $1"
}

# Clean up all existing simulators
cleanup_all_simulators() {
    log_info "Cleaning up all existing simulators..."
    
    # Shutdown all simulators
    xcrun simctl shutdown all 2>/dev/null || true
    sleep 2
    
    # Delete unavailable simulators
    xcrun simctl delete unavailable 2>/dev/null || true
    sleep 2
    
    # Delete any CI simulators that might be left over
    xcrun simctl list devices | grep "CI-" | awk -F'[()]' '{print $2}' | while read -r udid; do
        if [ -n "$udid" ]; then
            log_info "Deleting leftover CI simulator: $udid"
            xcrun simctl delete "$udid" 2>/dev/null || true
        fi
    done
    
    log_success "Simulator cleanup completed"
}

# Find iOS runtime
find_ios_runtime() {
    local target_version="${1:-26}"
    
    log_info "Looking for iOS $target_version runtime..."
    
    # Try JSON parsing first
    local runtime=$(xcrun simctl list -j runtimes 2>/dev/null | \
        /usr/bin/python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for r in data.get('runtimes', []):
        if (r.get('platform') == 'iOS' and 
            str(r.get('version', '')).startswith('$target_version') and 
            r.get('identifier') and 
            r.get('isAvailable', True)):
            print(r['identifier'])
            break
except:
    sys.exit(1)
" 2>/dev/null)
    
    # Fallback to text parsing
    if [ -z "${runtime:-}" ]; then
        log_warning "JSON parsing failed, trying text parsing..."
        runtime=$(xcrun simctl list runtimes | \
            awk -v version="$target_version" '/iOS ' version '[.]0/ {for(i=1;i<=NF;i++){if($i ~ /com\.apple\.CoreSimulator\.SimRuntime\.iOS-' version '/){print $i; exit}}}')
    fi
    
    if [ -z "${runtime:-}" ]; then
        log_error "Could not find iOS $target_version runtime"
        xcrun simctl list runtimes
        return 1
    fi
    
    log_success "Found runtime: $runtime"
    echo "$runtime"
}

# Find device type
find_device_type() {
    local device_name="${1:-iPhone 16}"
    
    log_info "Looking for device type: $device_name"
    
    # Try JSON parsing first
    local devtype=$(xcrun simctl list -j devicetypes 2>/dev/null | \
        /usr/bin/python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for d in data.get('devicetypes', []):
        if d.get('name') == '$device_name' and d.get('identifier'):
            print(d['identifier'])
            break
except:
    sys.exit(1)
" 2>/dev/null)
    
    # Fallback to text parsing
    if [ -z "${devtype:-}" ]; then
        log_warning "JSON parsing failed, trying text parsing..."
        devtype=$(xcrun simctl list devicetypes | \
            awk -F '[()]' "/^$device_name[[:space:]]\\(/ {print \$2; exit}")
    fi
    
    if [ -z "${devtype:-}" ]; then
        log_error "Device type '$device_name' not found"
        xcrun simctl list devicetypes
        return 1
    fi
    
    log_success "Found device type: $devtype"
    echo "$devtype"
}

# Create simulator
create_simulator() {
    local device_type="$1"
    local runtime="$2"
    local name_prefix="${3:-CI-iPhone-16}"
    
    local name="${name_prefix}-$(date +%s)"
    log_info "Creating simulator: $name"
    
    local udid=$(xcrun simctl create "$name" "$device_type" "$runtime")
    
    if [ -z "$udid" ]; then
        log_error "Failed to create simulator"
        return 1
    fi
    
    log_success "Created simulator: $udid"
    echo "$udid"
}

# Boot simulator with enhanced stability
boot_simulator() {
    local udid="$1"
    local timeout="${2:-$BOOT_TIMEOUT}"
    
    log_info "Booting simulator: $udid"
    
    # Boot the simulator
    xcrun simctl boot "$udid" 2>/dev/null || {
        log_error "Failed to boot simulator $udid"
        return 1
    }
    
    # Wait for boot with progress indication
    log_info "Waiting for simulator to boot (timeout: ${timeout}s)..."
    local start_time=$(date +%s)
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            log_error "Simulator boot timeout after ${timeout} seconds"
            xcrun simctl list devices
            return 1
        fi
        
        if xcrun simctl list devices 2>/dev/null | grep -q "${udid}) (Booted"; then
            log_success "Simulator booted successfully after ${elapsed} seconds"
            break
        fi
        
        # Show progress every 10 seconds
        if [ $((elapsed % 10)) -eq 0 ] && [ $elapsed -gt 0 ]; then
            log_info "Still waiting... (${elapsed}s elapsed)"
        fi
        
        sleep 1
    done
    
    # Additional stability check
    log_info "Waiting for simulator to be fully ready..."
    sleep $STABILITY_WAIT
    
    # Verify final state
    if ! xcrun simctl list devices 2>/dev/null | grep -q "${udid}) (Booted"; then
        log_error "Simulator became unresponsive after boot"
        xcrun simctl list devices
        return 1
    fi
    
    log_success "Simulator $udid is ready and stable"
    return 0
}

# Health check simulator
check_simulator_health() {
    local udid="$1"
    
    if ! xcrun simctl list devices 2>/dev/null | grep -q "${udid}) (Booted"; then
        log_warning "Simulator $udid is not booted"
        return 1
    fi
    
    # Test responsiveness with a simple command
    if ! xcrun simctl list devices 2>/dev/null | grep -q "${udid}) (Booted"; then
        log_warning "Simulator $udid is not responsive"
        return 1
    fi
    
    log_success "Simulator $udid is healthy"
    return 0
}

# Reset simulator
reset_simulator() {
    local udid="$1"
    
    log_info "Resetting simulator: $udid"
    
    # Shutdown
    xcrun simctl shutdown "$udid" 2>/dev/null || true
    sleep 2
    
    # Erase to reset state
    xcrun simctl erase "$udid" 2>/dev/null || true
    sleep 2
    
    # Boot again
    boot_simulator "$udid"
}

# Main function to create and boot a fresh simulator
create_fresh_simulator() {
    local ios_version="${1:-26}"
    local device_name="${2:-iPhone 16}"
    local name_prefix="${3:-CI-iPhone-16}"
    
    log_info "Creating fresh simulator for CI"
    log_info "iOS Version: $ios_version"
    log_info "Device: $device_name"
    
    # Clean up existing simulators
    cleanup_all_simulators
    
    # Find runtime and device type
    local runtime=$(find_ios_runtime "$ios_version")
    local device_type=$(find_device_type "$device_name")
    
    # Create simulator
    local udid=$(create_simulator "$device_type" "$runtime" "$name_prefix")
    
    # Boot simulator with retries
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        log_info "Boot attempt $attempt/$MAX_RETRIES"
        
        if boot_simulator "$udid"; then
            # Final health check
            if check_simulator_health "$udid"; then
                log_success "Simulator $udid is ready for CI"
                echo "$udid"
                return 0
            else
                log_warning "Simulator health check failed"
            fi
        else
            log_warning "Boot attempt $attempt failed"
        fi
        
        if [ $attempt -lt $MAX_RETRIES ]; then
            log_info "Retrying in 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        else
            log_error "All boot attempts failed"
            return 1
        fi
    done
    
    return 1
}

# Cleanup function
cleanup_simulator() {
    local udid="$1"
    
    if [ -n "$udid" ]; then
        log_info "Cleaning up simulator: $udid"
        xcrun simctl shutdown "$udid" 2>/dev/null || true
        xcrun simctl delete "$udid" 2>/dev/null || true
    fi
}

# Script entry point
case "${1:-create}" in
    "create")
        create_fresh_simulator "${2:-26}" "${3:-iPhone 16}" "${4:-CI-iPhone-16}"
        ;;
    "cleanup")
        cleanup_simulator "${2:-}"
        ;;
    "cleanup-all")
        cleanup_all_simulators
        ;;
    "health")
        check_simulator_health "${2:-}"
        ;;
    "reset")
        reset_simulator "${2:-}"
        ;;
    *)
        echo "Usage: $0 {create|cleanup|cleanup-all|health|reset} [args...]"
        echo "  create [ios_version] [device_name] [name_prefix] - Create fresh simulator"
        echo "  cleanup [udid] - Cleanup specific simulator"
        echo "  cleanup-all - Cleanup all simulators"
        echo "  health [udid] - Check simulator health"
        echo "  reset [udid] - Reset simulator"
        exit 1
        ;;
esac
