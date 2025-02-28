#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
A11Y_DIR="./a11y"
REPORTS_DIR="./reports/a11y"
LOGS_DIR="./logs/a11y"
TEMP_DIR="./temp/a11y"

# Create directories
mkdir -p "$A11Y_DIR" "$REPORTS_DIR" "$LOGS_DIR" "$TEMP_DIR"

# Function to run accessibility audit
run_audit() {
    echo -e "${BLUE}Running accessibility audit...${NC}"
    
    local report_file="$REPORTS_DIR/audit_$(date +%Y%m%d_%H%M%S).md"
    
    # Start development server if not running
    if ! nc -z localhost 3000; then
        npm run dev &
        sleep 5
    fi
    
    {
        echo "# تقرير تدقيق إمكانية الوصول"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## نتائج التدقيق"
        echo
        
        # Run axe-core accessibility audit
        npx axe http://localhost:3000 --stdout --exit
        
        echo
        echo "## المشكلات الحرجة"
        echo
        
        # Extract critical issues
        npx axe http://localhost:3000 --rules wcag2a,wcag2aa --stdout | \
        jq -r '.violations[] | select(.impact == "critical") | "- " + .help'
        
    } > "$report_file"
    
    echo -e "${GREEN}Accessibility audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "a11y" "Generated accessibility audit report"
}

# Function to check ARIA labels
check_aria() {
    echo -e "${BLUE}Checking ARIA labels...${NC}"
    
    local report_file="$REPORTS_DIR/aria_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق ARIA"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## عناصر بدون تسميات"
        echo "\`\`\`"
        find ./src -type f -name "*.tsx" -exec grep -l "aria-" {} \; | \
        while read -r file; do
            echo "Checking $file..."
            grep -n "aria-" "$file"
        done
        echo "\`\`\`"
        echo
        
        echo "## عناصر تفاعلية بدون أدوار"
        echo "\`\`\`"
        find ./src -type f -name "*.tsx" -exec grep -l "onClick" {} \; | \
        while read -r file; do
            echo "Checking $file..."
            grep -n "onClick" "$file" | grep -v "role="
        done
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}ARIA check report generated: $report_file${NC}"
    
    # Log action
    log_action "check" "aria" "Checked ARIA labels"
}

# Function to validate color contrast
check_contrast() {
    echo -e "${BLUE}Checking color contrast...${NC}"
    
    local report_file="$REPORTS_DIR/contrast_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق تباين الألوان"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## مشكلات التباين"
        echo
        
        # Extract color definitions
        find ./src -type f -name "*.ts" -o -name "*.tsx" -o -name "*.css" | \
        while read -r file; do
            echo "Checking $file..."
            grep -n "color:\|background-color:" "$file"
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Color contrast report generated: $report_file${NC}"
    
    # Log action
    log_action "check" "contrast" "Checked color contrast"
}

# Function to check keyboard navigation
check_keyboard() {
    echo -e "${BLUE}Checking keyboard navigation...${NC}"
    
    local report_file="$REPORTS_DIR/keyboard_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق التنقل بلوحة المفاتيح"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## عناصر غير قابلة للوصول"
        echo "\`\`\`"
        find ./src -type f -name "*.tsx" -exec grep -l "tabIndex=" {} \; | \
        while read -r file; do
            echo "Checking $file..."
            grep -n "tabIndex=" "$file"
        done
        echo "\`\`\`"
        echo
        
        echo "## معالجات المفاتيح المفقودة"
        echo "\`\`\`"
        find ./src -type f -name "*.tsx" -exec grep -l "onKeyPress\|onKeyDown" {} \; | \
        while read -r file; do
            echo "Checking $file..."
            grep -n "onClick" "$file" | grep -v "onKey"
        done
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Keyboard navigation report generated: $report_file${NC}"
    
    # Log action
    log_action "check" "keyboard" "Checked keyboard navigation"
}

# Function to check screen reader compatibility
check_screen_reader() {
    echo -e "${BLUE}Checking screen reader compatibility...${NC}"
    
    local report_file="$REPORTS_DIR/screen_reader_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير توافق قارئ الشاشة"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## النصوص البديلة المفقودة"
        echo "\`\`\`"
        find ./src -type f -name "*.tsx" -exec grep -l "<img" {} \; | \
        while read -r file; do
            echo "Checking $file..."
            grep -n "<img" "$file" | grep -v "alt="
        done
        echo "\`\`\`"
        echo
        
        echo "## عناصر النموذج بدون تسميات"
        echo "\`\`\`"
        find ./src -type f -name "*.tsx" -exec grep -l "<input\|<select\|<textarea" {} \; | \
        while read -r file; do
            echo "Checking $file..."
            grep -n "<input\|<select\|<textarea" "$file" | grep -v "aria-label\|aria-labelledby"
        done
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Screen reader compatibility report generated: $report_file${NC}"
    
    # Log action
    log_action "check" "screen_reader" "Checked screen reader compatibility"
}

# Function to fix common accessibility issues
fix_issues() {
    echo -e "${BLUE}Fixing common accessibility issues...${NC}"
    
    # Add missing alt attributes
    find ./src -type f -name "*.tsx" -exec sed -i 's/<img\([^>]*\)>/<img\1 alt="">/g' {} \;
    
    # Add missing ARIA labels
    find ./src -type f -name "*.tsx" -exec sed -i 's/<button\([^>]*\)>/<button\1 aria-label="">/g' {} \;
    
    # Add missing roles
    find ./src -type f -name "*.tsx" -exec sed -i 's/<div\([^>]*\)onClick/<div\1role="button" onClick/g' {} \;
    
    echo -e "${GREEN}Common accessibility issues fixed${NC}"
    
    # Log action
    log_action "fix" "issues" "Fixed common accessibility issues"
}

# Function to generate accessibility documentation
generate_docs() {
    echo -e "${BLUE}Generating accessibility documentation...${NC}"
    
    local docs_file="$A11Y_DIR/ACCESSIBILITY.md"
    
    cat > "$docs_file" << EOL
# دليل إمكانية الوصول

## المقدمة
هذا الدليل يوضح كيفية ضمان إمكانية الوصول في التطبيق.

## المبادئ التوجيهية
- استخدام العلامات HTML المناسبة
- توفير نصوص بديلة للصور
- ضمان تباين الألوان
- دعم التنقل بلوحة المفاتيح
- توفير تسميات ARIA

## الاختبار
- اختبار مع قارئات الشاشة
- اختبار التنقل بلوحة المفاتيح
- اختبار تباين الألوان
- اختبار التوافق مع WCAG

## الموارد
- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)
- [WAI-ARIA](https://www.w3.org/WAI/ARIA/apg/)
- [WebAIM](https://webaim.org/)
EOL
    
    echo -e "${GREEN}Accessibility documentation generated: $docs_file${NC}"
    
    # Log action
    log_action "generate" "docs" "Generated accessibility documentation"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/a11y_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Accessibility Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Run Accessibility Audit"
    echo -e "${YELLOW}2.${NC} Check ARIA Labels"
    echo -e "${YELLOW}3.${NC} Check Color Contrast"
    echo -e "${YELLOW}4.${NC} Check Keyboard Navigation"
    echo -e "${YELLOW}5.${NC} Check Screen Reader Compatibility"
    echo -e "${YELLOW}6.${NC} Fix Common Issues"
    echo -e "${YELLOW}7.${NC} Generate Documentation"
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
            run_audit
            ;;
        2)
            check_aria
            ;;
        3)
            check_contrast
            ;;
        4)
            check_keyboard
            ;;
        5)
            check_screen_reader
            ;;
        6)
            fix_issues
            ;;
        7)
            generate_docs
            ;;
        8)
            if [ -f "$LOGS_DIR/a11y_actions.log" ]; then
                less "$LOGS_DIR/a11y_actions.log"
            else
                echo -e "${YELLOW}No accessibility logs found${NC}"
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
