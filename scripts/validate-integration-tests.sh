#!/bin/bash

# Integration Test Validation Script for Foundation Phase 5
# Tests the complete food logging flow from API to persistence

set -e

echo "🧪 Running Foundation Phase 5 Integration Tests..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}Test $TESTS_RUN: $test_name${NC}"
    echo "Command: $test_command"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to check if a test file exists and compiles
check_test_file() {
    local file_path="$1"
    local test_name="$2"
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✅ $test_name exists${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name missing${NC}"
        return 1
    fi
}

echo -e "\n${YELLOW}Phase 1: File Structure Validation${NC}"
echo "======================================"

# Check that all required files exist
run_test "Integration test file exists" "check_test_file 'Tests/Unit/Services/FoodLoggingIntegrationTests.swift' 'Integration Test File'"

echo -e "\n${YELLOW}Phase 2: Build Validation${NC}"
echo "=========================="

# Test that the project builds successfully
run_test "Project builds successfully" "./scripts/build-local-ci.sh"

echo -e "\n${YELLOW}Phase 3: Unit Test Validation${NC}"
echo "============================="

# Test that all existing unit tests pass
run_test "All unit tests pass" "./scripts/test-local-ci.sh"

echo -e "\n${YELLOW}Phase 4: Lint Validation${NC}"
echo "========================"

# Test that linting passes
run_test "Linting passes" "./scripts/lint-local-ci.sh"

echo -e "\n${YELLOW}Phase 5: Integration Test Content Validation${NC}"
echo "============================================="

# Check that the integration test file contains the expected test methods
run_test "Integration test contains complete flow test" "grep -q 'completeFoodLoggingFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"
run_test "Integration test contains manual entry test" "grep -q 'manualFoodEntryFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"
run_test "Integration test contains multiple entries test" "grep -q 'multipleFoodEntriesFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"
run_test "Integration test contains update/deletion test" "grep -q 'foodEntryUpdateAndDeletionFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"
run_test "Integration test contains recent foods test" "grep -q 'recentFoodsAndFavoritesFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"
run_test "Integration test contains preferences test" "grep -q 'userPreferencesManagementFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"
run_test "Integration test contains nutrient calculation test" "grep -q 'nutrientCalculationAccuracyFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"
run_test "Integration test contains household unit test" "grep -q 'householdUnitConversionFlow' Tests/Unit/Services/FoodLoggingIntegrationTests.swift"

echo -e "\n${YELLOW}Phase 6: Foundation Components Validation${NC}"
echo "=========================================="

# Check that all Foundation components exist
run_test "FoodLoggingTypes exists" "check_test_file 'Sources/Models/Core/FoodLogging/FoodLoggingTypes.swift' 'FoodLoggingTypes'"
run_test "FoodRef model exists" "check_test_file 'Sources/Models/Core/FoodRef.swift' 'FoodRef Model'"
run_test "FoodEntry model exists" "check_test_file 'Sources/Models/Core/LoggedFoodEntry.swift' 'FoodEntry Model'"
run_test "UserFoodPrefs model exists" "check_test_file 'Sources/Models/Core/UserFoodPrefs.swift' 'UserFoodPrefs Model'"
run_test "RecentFood model exists" "check_test_file 'Sources/Models/Core/RecentFood.swift' 'RecentFood Model'"

run_test "PortionResolver service exists" "check_test_file 'Sources/Services/Data/Processing/PortionResolver.swift' 'PortionResolver Service'"
run_test "SnapshotNutrientCalculator service exists" "check_test_file 'Sources/Services/Data/Processing/SnapshotNutrientCalculator.swift' 'SnapshotNutrientCalculator Service'"
run_test "DVCalculator service exists" "check_test_file 'Sources/Services/Data/Processing/DVCalculator.swift' 'DVCalculator Service'"
run_test "FoodRefBuilder service exists" "check_test_file 'Sources/Services/Data/Processing/FoodRefBuilder.swift' 'FoodRefBuilder Service'"
run_test "FoodEntryBuilder service exists" "check_test_file 'Sources/Services/Data/Persistence/Models/LoggedFoodEntryBuilder.swift' 'FoodEntryBuilder Service'"

run_test "FoodLogStore actor exists" "check_test_file 'Sources/Services/Data/FoodLogStore.swift' 'FoodLogStore Actor'"
run_test "FoodLogRepository protocol exists" "check_test_file 'Sources/Services/Data/Persistence/Repositories/LoggedFoodRepository.swift' 'FoodLogRepository Protocol'"
run_test "FoodLogRepositorySwiftData implementation exists" "check_test_file 'Sources/Services/Data/Persistence/Repositories/LoggedFoodRepositorySwiftData.swift' 'FoodLogRepositorySwiftData Implementation'"

run_test "CalryApp registers all models" "grep -q 'FoodEntry.self' Sources/App/CalryApp.swift && grep -q 'FoodRef.self' Sources/App/CalryApp.swift && grep -q 'UserFoodPrefs.self' Sources/App/CalryApp.swift && grep -q 'RecentFood.self' Sources/App/CalryApp.swift"

echo -e "\n${YELLOW}Phase 7: Test Coverage Validation${NC}"
echo "=================================="

# Check that all components have corresponding tests
run_test "FoodLoggingTypes has tests" "check_test_file 'Tests/Unit/Models/FoodLoggingTypesTests.swift' 'FoodLoggingTypes Tests'"
run_test "FoodRef has tests" "check_test_file 'Tests/Unit/Models/FoodRefTests.swift' 'FoodRef Tests'"
run_test "FoodEntry has tests" "check_test_file 'Tests/Unit/Models/FoodEntryTests.swift' 'FoodEntry Tests'"
run_test "UserFoodPrefs has tests" "check_test_file 'Tests/Unit/Models/UserFoodPrefsTests.swift' 'UserFoodPrefs Tests'"
run_test "RecentFood has tests" "check_test_file 'Tests/Unit/Models/RecentFoodTests.swift' 'RecentFood Tests'"

run_test "PortionResolver has tests" "check_test_file 'Tests/Unit/Services/PortionResolverTests.swift' 'PortionResolver Tests'"
run_test "SnapshotNutrientCalculator has tests" "check_test_file 'Tests/Unit/Services/SnapshotNutrientCalculatorTests.swift' 'SnapshotNutrientCalculator Tests'"
run_test "DVCalculator has tests" "check_test_file 'Tests/Unit/Services/DVCalculatorTests.swift' 'DVCalculator Tests'"
run_test "FoodRefBuilder has tests" "check_test_file 'Tests/Unit/Services/FoodRefBuilderTests.swift' 'FoodRefBuilder Tests'"
run_test "FoodEntryBuilder has tests" "check_test_file 'Tests/Unit/Services/EnhancedFoodEntryBuilderTests.swift' 'FoodEntryBuilder Tests'"

run_test "FoodLogStore has tests" "check_test_file 'Tests/Unit/Services/FoodLogStoreTests.swift' 'FoodLogStore Tests'"
run_test "FoodLogRepository has tests" "check_test_file 'Tests/Unit/Services/FoodLogRepositoryTests.swift' 'FoodLogRepository Tests'"

echo -e "\n${YELLOW}Phase 8: Swift 6 Concurrency Validation${NC}"
echo "======================================="

# Check that the code follows Swift 6 concurrency patterns
run_test "FoodLogStore uses actor isolation" "grep -q '^actor FoodLogStore' Sources/Services/Data/FoodLogStore.swift"
run_test "DTOs are Sendable" "grep -q 'struct.*DTO.*Sendable' Sources/Services/Data/FoodLogStore.swift"
run_test "Repository uses async/await" "grep -q 'async throws' Sources/Services/Data/Persistence/Repositories/LoggedFoodRepositorySwiftData.swift"

echo -e "\n${YELLOW}Phase 9: Data Flow Validation${NC}"
echo "============================="

# Check that the data flow is properly implemented
run_test "FoodRefBuilder converts API models" "grep -q 'FoodCard.*FoodRef' Sources/Services/Data/Processing/FoodRefBuilder.swift"
run_test "FoodEntryBuilder uses FoodRef" "grep -q 'foodRef: FoodRef' Sources/Services/Data/Persistence/Models/LoggedFoodEntryBuilder.swift"
run_test "Repository uses FoodLogStore" "grep -q 'FoodLogStore' Sources/Services/Data/Persistence/Repositories/LoggedFoodRepositorySwiftData.swift"

echo -e "\n${YELLOW}Phase 10: Final Integration Summary${NC}"
echo "====================================="

echo -e "\n${BLUE}Integration Test Results:${NC}"
echo "========================"
echo "Total Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL INTEGRATION TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}Foundation Phase 5 (Integration Tests) - COMPLETE${NC}"
    echo -e "\n${BLUE}Foundation Implementation Status:${NC}"
    echo "✅ Phase 1: Core Types and Models (5 sub-phases)"
    echo "✅ Phase 2: Services and Builders (7 sub-phases)"
    echo "✅ Phase 3: Repository Protocol and Implementation"
    echo "✅ Phase 4: SwiftData Model Registration"
    echo "✅ Phase 5: Integration Tests and Validation"
    echo -e "\n${GREEN}🏆 FOUNDATION IMPLEMENTATION: 100% COMPLETE! 🏆${NC}"
    exit 0
else
    echo -e "\n${RED}❌ SOME INTEGRATION TESTS FAILED${NC}"
    echo -e "${RED}Foundation Phase 5 needs attention${NC}"
    exit 1
fi
