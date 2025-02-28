#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LINT_DIR="./lint"
REPORTS_DIR="./reports/lint"
LOGS_DIR="./logs/lint"
TEMP_DIR="./temp/lint"

# Create directories
mkdir -p "$LINT_DIR" "$REPORTS_DIR" "$LOGS_DIR" "$TEMP_DIR"

# Function to run ESLint
run_eslint() {
    echo -e "${BLUE}Running ESLint...${NC}"
    
    local report_file="$REPORTS_DIR/eslint_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير ESLint"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## نتائج التدقيق"
        echo "\`\`\`"
        npx eslint . --ext .ts,.tsx,.js,.jsx --format stylish
        echo "\`\`\`"
        echo
        
        echo "## ملخص الأخطاء"
        echo "\`\`\`"
        npx eslint . --ext .ts,.tsx,.js,.jsx --format json | \
        jq -r '.[] | select(.errorCount > 0) | "\(.filePath): \(.errorCount) errors"'
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}ESLint report generated: $report_file${NC}"
    
    # Log action
    log_action "eslint" "run" "Generated ESLint report"
}

# Function to run Prettier
run_prettier() {
    echo -e "${BLUE}Running Prettier...${NC}"
    
    local report_file="$REPORTS_DIR/prettier_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير Prettier"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## الملفات غير المنسقة"
        echo "\`\`\`"
        npx prettier --check "src/**/*.{ts,tsx,js,jsx,json,css,scss}"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Prettier report generated: $report_file${NC}"
    
    # Log action
    log_action "prettier" "run" "Generated Prettier report"
}

# Function to run TypeScript type checking
run_typescript() {
    echo -e "${BLUE}Running TypeScript type checking...${NC}"
    
    local report_file="$REPORTS_DIR/typescript_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير TypeScript"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## نتائج التدقيق"
        echo "\`\`\`"
        npx tsc --noEmit
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}TypeScript report generated: $report_file${NC}"
    
    # Log action
    log_action "typescript" "run" "Generated TypeScript report"
}

# Function to run style linting
run_stylelint() {
    echo -e "${BLUE}Running StyleLint...${NC}"
    
    local report_file="$REPORTS_DIR/stylelint_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير StyleLint"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## نتائج التدقيق"
        echo "\`\`\`"
        npx stylelint "src/**/*.{css,scss}"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}StyleLint report generated: $report_file${NC}"
    
    # Log action
    log_action "stylelint" "run" "Generated StyleLint report"
}

# Function to fix linting issues
fix_issues() {
    echo -e "${BLUE}Fixing linting issues...${NC}"
    
    # Fix ESLint issues
    echo -e "${YELLOW}Fixing ESLint issues...${NC}"
    npx eslint . --ext .ts,.tsx,.js,.jsx --fix
    
    # Fix Prettier issues
    echo -e "${YELLOW}Fixing Prettier issues...${NC}"
    npx prettier --write "src/**/*.{ts,tsx,js,jsx,json,css,scss}"
    
    # Fix StyleLint issues
    echo -e "${YELLOW}Fixing StyleLint issues...${NC}"
    npx stylelint "src/**/*.{css,scss}" --fix
    
    echo -e "${GREEN}Linting issues fixed${NC}"
    
    # Log action
    log_action "fix" "all" "Fixed linting issues"
}

# Function to run all linters
run_all() {
    echo -e "${BLUE}Running all linters...${NC}"
    
    local start_time=$(date +%s)
    local failed=0
    
    # Run all linters
    run_eslint || ((failed++))
    run_prettier || ((failed++))
    run_typescript || ((failed++))
    run_stylelint || ((failed++))
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Generate summary report
    local report_file="$REPORTS_DIR/summary_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التدقيق الشامل"
        echo "تاريخ التقرير: $(date)"
        echo
        echo "## ملخص التنفيذ"
        echo "- وقت البدء: $(date -d @$start_time)"
        echo "- وقت الانتهاء: $(date -d @$end_time)"
        echo "- المدة: $duration ثانية"
        echo "- عدد الأخطاء: $failed"
        
    } > "$report_file"
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All linters passed${NC}"
    else
        echo -e "${RED}$failed linter(s) failed${NC}"
    fi
    
    # Log action
    log_action "all" "run" "Ran all linters with $failed failures"
}

# Function to configure linters
configure_linters() {
    echo -e "${BLUE}Configuring linters...${NC}"
    
    # Configure ESLint
    if [ ! -f ".eslintrc.json" ]; then
        npx eslint --init
    fi
    
    # Configure Prettier
    if [ ! -f ".prettierrc" ]; then
        echo '{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}' > .prettierrc
    fi
    
    # Configure StyleLint
    if [ ! -f ".stylelintrc" ]; then
        echo '{
  "extends": "stylelint-config-standard"
}' > .stylelintrc
    fi
    
    echo -e "${GREEN}Linters configured${NC}"
    
    # Log action
    log_action "configure" "all" "Configured linters"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/lint_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Lint Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Run ESLint"
    echo -e "${YELLOW}2.${NC} Run Prettier"
    echo -e "${YELLOW}3.${NC} Run TypeScript Check"
    echo -e "${YELLOW}4.${NC} Run StyleLint"
    echo -e "${YELLOW}5.${NC} Fix Issues"
    echo -e "${YELLOW}6.${NC} Run All Linters"
    echo -e "${YELLOW}7.${NC} Configure Linters"
    echo -e "${YELLOW}8.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-8): " choice
    
    case $choice in
        1)
            run_eslint
            ;;
        2)
            run_prettier
            ;;
        3)
            run_typescript
            ;;
        4)
            run_stylelint
            ;;
        5)
            fix_issues
            ;;
        6)
            run_all
            ;;
        7)
            configure_linters
            ;;
        8)
            if [ -f "$LOGS_DIR/lint_actions.log" ]; then
                less "$LOGS_DIR/lint_actions.log"
            else
                echo -e "${YELLOW}No lint logs found${NC}"
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
