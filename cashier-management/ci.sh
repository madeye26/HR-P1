#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CI_DIR="./ci"
REPORTS_DIR="./reports/ci"
LOGS_DIR="./logs/ci"
TEMP_DIR="./temp/ci"

# Create directories
mkdir -p "$CI_DIR" "$REPORTS_DIR" "$LOGS_DIR" "$TEMP_DIR"

# Pipeline stages
declare -a STAGES=(
    "lint"
    "test"
    "build"
    "security"
    "deploy"
)

# Function to run linting stage
run_lint() {
    echo -e "${BLUE}Running linting stage...${NC}"
    
    # Run ESLint
    if npm run lint; then
        echo -e "${GREEN}ESLint passed${NC}"
    else
        echo -e "${RED}ESLint failed${NC}"
        return 1
    fi
    
    # Run TypeScript type checking
    if npm run type-check; then
        echo -e "${GREEN}TypeScript check passed${NC}"
    else
        echo -e "${RED}TypeScript check failed${NC}"
        return 1
    fi
    
    # Run Prettier check
    if npm run format:check; then
        echo -e "${GREEN}Prettier check passed${NC}"
    else
        echo -e "${RED}Prettier check failed${NC}"
        return 1
    fi
    
    # Log action
    log_action "lint" "success" "Linting stage completed successfully"
    return 0
}

# Function to run test stage
run_test() {
    echo -e "${BLUE}Running test stage...${NC}"
    
    # Run unit tests
    if npm run test:unit -- --coverage; then
        echo -e "${GREEN}Unit tests passed${NC}"
    else
        echo -e "${RED}Unit tests failed${NC}"
        return 1
    fi
    
    # Run integration tests
    if npm run test:integration; then
        echo -e "${GREEN}Integration tests passed${NC}"
    else
        echo -e "${RED}Integration tests failed${NC}"
        return 1
    fi
    
    # Run E2E tests
    if npm run test:e2e; then
        echo -e "${GREEN}E2E tests passed${NC}"
    else
        echo -e "${RED}E2E tests failed${NC}"
        return 1
    fi
    
    # Log action
    log_action "test" "success" "Test stage completed successfully"
    return 0
}

# Function to run build stage
run_build() {
    echo -e "${BLUE}Running build stage...${NC}"
    
    # Clean build directory
    rm -rf dist/
    
    # Run build
    if npm run build; then
        echo -e "${GREEN}Build passed${NC}"
        
        # Run bundle analysis
        npm run analyze
        
        # Log action
        log_action "build" "success" "Build stage completed successfully"
        return 0
    else
        echo -e "${RED}Build failed${NC}"
        log_action "build" "failure" "Build stage failed"
        return 1
    fi
}

# Function to run security stage
run_security() {
    echo -e "${BLUE}Running security stage...${NC}"
    
    # Run dependency audit
    if npm audit --audit-level=high; then
        echo -e "${GREEN}Security audit passed${NC}"
    else
        echo -e "${RED}Security audit failed${NC}"
        return 1
    fi
    
    # Run SAST scan
    if npm run security:scan; then
        echo -e "${GREEN}SAST scan passed${NC}"
    else
        echo -e "${RED}SAST scan failed${NC}"
        return 1
    fi
    
    # Log action
    log_action "security" "success" "Security stage completed successfully"
    return 0
}

# Function to run deploy stage
run_deploy() {
    echo -e "${BLUE}Running deploy stage...${NC}"
    
    # Set environment
    local env=${1:-staging}
    
    # Run deployment
    if npm run deploy:$env; then
        echo -e "${GREEN}Deployment to $env passed${NC}"
        
        # Run smoke tests
        if npm run test:smoke -- --env=$env; then
            echo -e "${GREEN}Smoke tests passed${NC}"
            
            # Log action
            log_action "deploy" "success" "Deploy stage completed successfully"
            return 0
        else
            echo -e "${RED}Smoke tests failed${NC}"
            log_action "deploy" "failure" "Smoke tests failed"
            return 1
        fi
    else
        echo -e "${RED}Deployment failed${NC}"
        log_action "deploy" "failure" "Deployment failed"
        return 1
    fi
}

# Function to run full pipeline
run_pipeline() {
    echo -e "${BLUE}Running CI pipeline...${NC}"
    
    local start_time=$(date +%s)
    local failed_stages=()
    
    # Run each stage
    for stage in "${STAGES[@]}"; do
        echo -e "\n${YELLOW}Stage: $stage${NC}"
        if ! run_$stage; then
            failed_stages+=("$stage")
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Generate pipeline report
    local report_file="$REPORTS_DIR/pipeline_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير خط الأنابيب CI"
        echo "تاريخ التقرير: $(date)"
        echo
        echo "## ملخص التنفيذ"
        echo "- وقت البدء: $(date -d @$start_time)"
        echo "- وقت الانتهاء: $(date -d @$end_time)"
        echo "- المدة: $duration ثانية"
        echo
        echo "## نتائج المراحل"
        for stage in "${STAGES[@]}"; do
            if [[ " ${failed_stages[@]} " =~ " ${stage} " ]]; then
                echo "- $stage: ❌ فشل"
            else
                echo "- $stage: ✅ نجاح"
            fi
        done
        
    } > "$report_file"
    
    # Check if any stage failed
    if [ ${#failed_stages[@]} -eq 0 ]; then
        echo -e "\n${GREEN}Pipeline completed successfully${NC}"
        log_action "pipeline" "success" "Pipeline completed successfully"
        return 0
    else
        echo -e "\n${RED}Pipeline failed. Failed stages: ${failed_stages[*]}${NC}"
        log_action "pipeline" "failure" "Pipeline failed at stages: ${failed_stages[*]}"
        return 1
    fi
}

# Function to show pipeline status
show_status() {
    echo -e "${BLUE}Pipeline Status${NC}"
    echo "------------------------"
    
    # Show last pipeline run
    if [ -f "$LOGS_DIR/ci_actions.log" ]; then
        echo "Last pipeline run:"
        tail -n 10 "$LOGS_DIR/ci_actions.log"
    else
        echo "No pipeline history found"
    fi
    
    # Show current branch status
    echo -e "\nCurrent branch status:"
    git status --short
    
    # Show last commit
    echo -e "\nLast commit:"
    git log -1 --oneline
}

# Function to clean CI artifacts
clean_artifacts() {
    echo -e "${BLUE}Cleaning CI artifacts...${NC}"
    
    # Clean temporary files
    rm -rf "$TEMP_DIR"/*
    
    # Archive old reports
    local archive_dir="$REPORTS_DIR/archive"
    mkdir -p "$archive_dir"
    find "$REPORTS_DIR" -type f -name "pipeline_*.md" -mtime +30 -exec mv {} "$archive_dir/" \;
    
    # Clean old logs
    find "$LOGS_DIR" -type f -name "*.log" -mtime +30 -delete
    
    echo -e "${GREEN}CI artifacts cleaned${NC}"
    
    # Log action
    log_action "clean" "artifacts" "Cleaned CI artifacts"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/ci_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}CI Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Run Full Pipeline"
    echo -e "${YELLOW}2.${NC} Run Lint Stage"
    echo -e "${YELLOW}3.${NC} Run Test Stage"
    echo -e "${YELLOW}4.${NC} Run Build Stage"
    echo -e "${YELLOW}5.${NC} Run Security Stage"
    echo -e "${YELLOW}6.${NC} Run Deploy Stage"
    echo -e "${YELLOW}7.${NC} Show Pipeline Status"
    echo -e "${YELLOW}8.${NC} Clean Artifacts"
    echo -e "${YELLOW}9.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1)
            run_pipeline
            ;;
        2)
            run_lint
            ;;
        3)
            run_test
            ;;
        4)
            run_build
            ;;
        5)
            run_security
            ;;
        6)
            read -p "Enter environment (staging/production): " env
            run_deploy "$env"
            ;;
        7)
            show_status
            ;;
        8)
            clean_artifacts
            ;;
        9)
            if [ -f "$LOGS_DIR/ci_actions.log" ]; then
                less "$LOGS_DIR/ci_actions.log"
            else
                echo -e "${YELLOW}No CI logs found${NC}"
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
