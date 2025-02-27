#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_DIR="./tests"
COVERAGE_DIR="./coverage"
REPORTS_DIR="./reports/tests"
LOGS_DIR="./logs/tests"

# Create directories
mkdir -p "$TEST_DIR" "$COVERAGE_DIR" "$REPORTS_DIR" "$LOGS_DIR"

# Test types
declare -A TEST_TYPES=(
    ["unit"]="Unit Tests"
    ["integration"]="Integration Tests"
    ["e2e"]="End-to-End Tests"
    ["api"]="API Tests"
    ["ui"]="UI Tests"
    ["performance"]="Performance Tests"
)

# Function to run unit tests
run_unit_tests() {
    echo -e "${BLUE}Running unit tests...${NC}"
    
    # Run Jest unit tests
    if npm run test:unit -- --coverage; then
        echo -e "${GREEN}Unit tests passed${NC}"
        
        # Generate coverage report
        generate_coverage_report "unit"
        
        # Log action
        log_action "unit" "success" "Unit tests completed successfully"
    else
        echo -e "${RED}Unit tests failed${NC}"
        
        # Log action
        log_action "unit" "failure" "Unit tests failed"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    echo -e "${BLUE}Running integration tests...${NC}"
    
    # Start test database if needed
    docker-compose -f docker-compose.test.yml up -d db
    
    # Run integration tests
    if npm run test:integration; then
        echo -e "${GREEN}Integration tests passed${NC}"
        
        # Log action
        log_action "integration" "success" "Integration tests completed successfully"
    else
        echo -e "${RED}Integration tests failed${NC}"
        
        # Log action
        log_action "integration" "failure" "Integration tests failed"
        return 1
    fi
    
    # Stop test database
    docker-compose -f docker-compose.test.yml down
}

# Function to run E2E tests
run_e2e_tests() {
    echo -e "${BLUE}Running E2E tests...${NC}"
    
    # Start application in test mode
    npm run start:test &
    APP_PID=$!
    
    # Wait for application to start
    sleep 5
    
    # Run Cypress E2E tests
    if npm run test:e2e; then
        echo -e "${GREEN}E2E tests passed${NC}"
        
        # Log action
        log_action "e2e" "success" "E2E tests completed successfully"
    else
        echo -e "${RED}E2E tests failed${NC}"
        
        # Log action
        log_action "e2e" "failure" "E2E tests failed"
        return 1
    fi
    
    # Stop application
    kill $APP_PID
}

# Function to run API tests
run_api_tests() {
    echo -e "${BLUE}Running API tests...${NC}"
    
    # Start API server in test mode
    npm run start:api:test &
    API_PID=$!
    
    # Wait for API to start
    sleep 5
    
    # Run API tests
    if npm run test:api; then
        echo -e "${GREEN}API tests passed${NC}"
        
        # Log action
        log_action "api" "success" "API tests completed successfully"
    else
        echo -e "${RED}API tests failed${NC}"
        
        # Log action
        log_action "api" "failure" "API tests failed"
        return 1
    fi
    
    # Stop API server
    kill $API_PID
}

# Function to run UI tests
run_ui_tests() {
    echo -e "${BLUE}Running UI tests...${NC}"
    
    # Run React Testing Library tests
    if npm run test:ui; then
        echo -e "${GREEN}UI tests passed${NC}"
        
        # Generate screenshots
        npm run test:ui:screenshots
        
        # Log action
        log_action "ui" "success" "UI tests completed successfully"
    else
        echo -e "${RED}UI tests failed${NC}"
        
        # Log action
        log_action "ui" "failure" "UI tests failed"
        return 1
    fi
}

# Function to run performance tests
run_performance_tests() {
    echo -e "${BLUE}Running performance tests...${NC}"
    
    # Start application in production mode
    NODE_ENV=production npm start &
    APP_PID=$!
    
    # Wait for application to start
    sleep 5
    
    # Run Lighthouse performance tests
    if npm run test:performance; then
        echo -e "${GREEN}Performance tests passed${NC}"
        
        # Generate performance report
        generate_performance_report
        
        # Log action
        log_action "performance" "success" "Performance tests completed successfully"
    else
        echo -e "${RED}Performance tests failed${NC}"
        
        # Log action
        log_action "performance" "failure" "Performance tests failed"
        return 1
    fi
    
    # Stop application
    kill $APP_PID
}

# Function to generate coverage report
generate_coverage_report() {
    local test_type=$1
    echo -e "${BLUE}Generating coverage report...${NC}"
    
    local report_file="$REPORTS_DIR/coverage_${test_type}_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تغطية الاختبارات"
        echo "نوع الاختبار: ${TEST_TYPES[$test_type]}"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص التغطية"
        echo "\`\`\`"
        cat "$COVERAGE_DIR/coverage-summary.json" | jq '.'
        echo "\`\`\`"
        echo
        
        echo "## تفاصيل التغطية"
        echo "### الملفات غير المغطاة"
        echo "\`\`\`"
        find "$COVERAGE_DIR" -name "*.html" -exec grep -l "0%" {} \;
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Coverage report generated: $report_file${NC}"
}

# Function to generate performance report
generate_performance_report() {
    echo -e "${BLUE}Generating performance report...${NC}"
    
    local report_file="$REPORTS_DIR/performance_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير أداء التطبيق"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## مقاييس الأداء"
        echo "\`\`\`"
        lighthouse http://localhost:3000 --output=json | jq '.categories'
        echo "\`\`\`"
        echo
        
        echo "## توصيات التحسين"
        echo "\`\`\`"
        lighthouse http://localhost:3000 --output=json | jq '.audits[] | select(.score < 0.9)'
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Performance report generated: $report_file${NC}"
}

# Function to run all tests
run_all_tests() {
    echo -e "${BLUE}Running all tests...${NC}"
    
    local failed=0
    
    # Run each type of test
    run_unit_tests || ((failed++))
    run_integration_tests || ((failed++))
    run_e2e_tests || ((failed++))
    run_api_tests || ((failed++))
    run_ui_tests || ((failed++))
    run_performance_tests || ((failed++))
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All tests passed${NC}"
        
        # Log action
        log_action "all" "success" "All tests completed successfully"
    else
        echo -e "${RED}$failed test suites failed${NC}"
        
        # Log action
        log_action "all" "failure" "$failed test suites failed"
        return 1
    fi
}

# Function to watch tests
watch_tests() {
    echo -e "${BLUE}Starting test watch mode...${NC}"
    
    echo "Select test type to watch:"
    echo "1. Unit Tests"
    echo "2. UI Tests"
    read -p "Enter choice (1-2): " choice
    
    case $choice in
        1)
            npm run test:unit -- --watch
            ;;
        2)
            npm run test:ui -- --watch
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
}

# Function to log actions
log_action() {
    local test_type=$1
    local status=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $test_type - $status - $details" >> "$LOGS_DIR/test_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Testing Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Run All Tests"
    echo -e "${YELLOW}2.${NC} Run Unit Tests"
    echo -e "${YELLOW}3.${NC} Run Integration Tests"
    echo -e "${YELLOW}4.${NC} Run E2E Tests"
    echo -e "${YELLOW}5.${NC} Run API Tests"
    echo -e "${YELLOW}6.${NC} Run UI Tests"
    echo -e "${YELLOW}7.${NC} Run Performance Tests"
    echo -e "${YELLOW}8.${NC} Watch Tests"
    echo -e "${YELLOW}9.${NC} View Test Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1)
            run_all_tests
            ;;
        2)
            run_unit_tests
            ;;
        3)
            run_integration_tests
            ;;
        4)
            run_e2e_tests
            ;;
        5)
            run_api_tests
            ;;
        6)
            run_ui_tests
            ;;
        7)
            run_performance_tests
            ;;
        8)
            watch_tests
            ;;
        9)
            if [ -f "$LOGS_DIR/test_actions.log" ]; then
                less "$LOGS_DIR/test_actions.log"
            else
                echo -e "${YELLOW}No test logs found${NC}"
            fi
            ;;
        0)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
    
    echo -e "\nPress Enter to continue..."
    read
done
