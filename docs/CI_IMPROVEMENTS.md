# CI Improvements - Enhanced Robustness and Reliability

This document outlines the comprehensive improvements made to the CI system to prevent builds from getting stuck and timing out.

## Problem Analysis

The original CI system had several issues that led to frequent timeouts and stuck builds:

1. **Insufficient timeout handling** - Only 15 minutes for entire build+test process
2. **Poor simulator state management** - Simulators could get stuck in various states
3. **Inadequate cleanup** - Not enough cleanup between retries
4. **No progress monitoring** - No way to detect if xcodebuild was actually stuck
5. **Limited retry strategy** - Only 3 attempts with basic simulator reset
6. **No system resource management** - Memory pressure could cause issues

## Solution Overview

The new CI system implements a multi-layered approach to prevent stuck builds:

### 1. Enhanced Timeout Management
- **Increased overall timeout**: 25 minutes (was 15)
- **Per-attempt timeout**: 12 minutes with progress monitoring
- **Stuck detection**: Kills processes that show no activity for 5 minutes
- **Progressive backoff**: 15s, 30s, 45s, 60s between retries

### 2. Robust Simulator Management
- **Fresh simulator creation** for each CI run
- **Enhanced boot process** with stability checks
- **Comprehensive cleanup** between retries
- **Health monitoring** before each test run
- **Automatic recovery** from simulator issues

### 3. Progress Monitoring System
- **Real-time monitoring** of xcodebuild progress
- **Log file analysis** to detect activity
- **Automatic process termination** for stuck builds
- **Detailed logging** for debugging

### 4. Enhanced Retry Logic
- **5 attempts** instead of 3 (configurable)
- **Intelligent cleanup** between retries
- **System resource management**
- **Simulator state verification**

## New Scripts

### 1. `scripts/ci-test-runner.sh`
Main test runner with enhanced monitoring and retry logic.

**Features:**
- Progress monitoring with stuck detection
- Enhanced simulator health checks
- System resource cleanup
- Detailed logging and debugging
- Configurable timeouts and retry counts

**Usage:**
```bash
./scripts/ci-test-runner.sh <destination_id> [derived_data_path]
```

### 2. `scripts/simulator-manager.sh`
Comprehensive simulator lifecycle management.

**Features:**
- Fresh simulator creation with retries
- Enhanced boot process with stability checks
- Comprehensive cleanup functions
- Health monitoring and verification
- Support for different iOS versions and device types

**Usage:**
```bash
# Create fresh simulator
./scripts/simulator-manager.sh create [ios_version] [device_name] [name_prefix]

# Cleanup specific simulator
./scripts/simulator-manager.sh cleanup [udid]

# Cleanup all simulators
./scripts/simulator-manager.sh cleanup-all

# Check simulator health
./scripts/simulator-manager.sh health [udid]

# Reset simulator
./scripts/simulator-manager.sh reset [udid]
```

## Configuration

### Timeout Settings
```bash
MAX_ATTEMPTS=5                    # Number of retry attempts
XCODEBUILD_TIMEOUT=720           # 12 minutes per attempt
STUCK_THRESHOLD=300              # 5 minutes stuck detection
CHECK_INTERVAL=30                # 30 seconds progress check
PROGRESS_TIMEOUT=60              # 1 minute progress detection
```

### Simulator Settings
```bash
BOOT_TIMEOUT=120                 # 2 minutes boot timeout
STABILITY_WAIT=10                # 10 seconds stability wait
MAX_RETRIES=3                    # 3 retries for simulator operations
```

## Key Improvements

### 1. Stuck Build Prevention
- **Process monitoring**: Tracks xcodebuild process activity
- **Log analysis**: Monitors log file growth and modification times
- **Automatic termination**: Kills stuck processes after 5 minutes of inactivity
- **Resource cleanup**: Clears memory pressure and temporary files

### 2. Simulator Reliability
- **Fresh creation**: Creates new simulator for each CI run
- **Enhanced boot**: Multiple retry attempts with stability checks
- **Health verification**: Tests simulator responsiveness before use
- **Comprehensive cleanup**: Resets simulator state between retries

### 3. Better Error Handling
- **Detailed logging**: Color-coded output with timestamps
- **Progress indication**: Shows what's happening during long operations
- **Debug information**: Logs last 50 lines of xcodebuild output on failure
- **Status reporting**: Final simulator status on failure

### 4. Resource Management
- **Memory cleanup**: Runs `sudo purge` between retries
- **File cleanup**: Removes temporary log files
- **Simulator cleanup**: Deletes old/unavailable simulators
- **Process cleanup**: Ensures no orphaned processes

## Monitoring and Debugging

### Log Output
The new system provides detailed, color-coded logging:
- **Blue**: Information messages
- **Green**: Success messages
- **Yellow**: Warning messages
- **Red**: Error messages

### Debug Information
On failure, the system provides:
- Last 50 lines of xcodebuild output
- Final simulator status
- Process IDs and timing information
- Detailed error messages

### Progress Tracking
- Real-time progress updates during long operations
- Timeout warnings before process termination
- Retry attempt tracking with timing information

## Benefits

1. **Reduced CI failures**: Comprehensive retry logic with intelligent cleanup
2. **Faster recovery**: Automatic detection and recovery from stuck states
3. **Better debugging**: Detailed logging and error information
4. **Resource efficiency**: Proper cleanup prevents resource exhaustion
5. **Maintainability**: Modular scripts that are easy to understand and modify

## Usage in CI

The enhanced CI system is now much more robust:

```yaml
- name: Preboot iOS 26 (create fresh iPhone 16; robust detection)
  run: |
    UDID=$(./scripts/simulator-manager.sh create 26 "iPhone 16" "CI-iPhone-16")
    echo "DEST_ID=${UDID}" >> "$GITHUB_ENV"

- name: Build & Unit Tests (PR plan, no coverage)
  run: |
    ./scripts/ci-test-runner.sh "$DEST_ID" "./DerivedData"

- name: Cleanup Simulators
  if: always()
  run: |
    ./scripts/simulator-manager.sh cleanup-all
```

## Future Enhancements

Potential future improvements:
1. **Metrics collection**: Track success rates and failure patterns
2. **Adaptive timeouts**: Adjust timeouts based on historical data
3. **Parallel testing**: Support for multiple simulator instances
4. **Cloud simulators**: Integration with cloud-based testing services
5. **Notification system**: Alert on persistent failures

## Troubleshooting

### Common Issues

1. **Simulator creation fails**
   - Check iOS runtime availability
   - Verify device type exists
   - Check system resources

2. **Tests still timeout**
   - Increase `XCODEBUILD_TIMEOUT` if needed
   - Check for test-specific issues
   - Review simulator health

3. **Cleanup issues**
   - Run `./scripts/simulator-manager.sh cleanup-all`
   - Check for permission issues
   - Verify simulator state

### Debug Commands

```bash
# Check simulator status
xcrun simctl list devices

# Check available runtimes
xcrun simctl list runtimes

# Check device types
xcrun simctl list devicetypes

# Manual cleanup
./scripts/simulator-manager.sh cleanup-all
```

This enhanced CI system should significantly reduce the occurrence of stuck builds and provide much better reliability for continuous integration.
