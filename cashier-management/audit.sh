#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AUDIT_DIR="./audit"
REPORTS_DIR="./reports/audit"
LOGS_DIR="./logs/audit"
TEMP_DIR="./temp/audit"

# Create directories
mkdir -p "$AUDIT_DIR" "$REPORTS_DIR" "$LOGS_DIR" "$TEMP_DIR"

# Function to audit dependencies
audit_dependencies() {
    echo -e "${BLUE}Auditing dependencies...${NC}"
    
    local report_file="$REPORTS_DIR/dependencies_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق التبعيات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تدقيق الأمان"
        echo "\`\`\`"
        npm audit
        echo "\`\`\`"
        echo
        
        echo "## التبعيات المهملة"
        echo "\`\`\`"
        npm outdated
        echo "\`\`\`"
        echo
        
        echo "## تحليل حجم الحزم"
        echo "\`\`\`"
        npm list --prod --parseable | \
        xargs -I {} du -sh {} 2>/dev/null | \
        sort -hr | head -n 10
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Dependencies audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "dependencies" "Audited project dependencies"
}

# Function to audit code quality
audit_code() {
    echo -e "${BLUE}Auditing code quality...${NC}"
    
    local report_file="$REPORTS_DIR/code_quality_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير جودة الكود"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تحليل ESLint"
        echo "\`\`\`"
        npx eslint . --ext .ts,.tsx --format json
        echo "\`\`\`"
        echo
        
        echo "## تحليل TypeScript"
        echo "\`\`\`"
        npx tsc --noEmit
        echo "\`\`\`"
        echo
        
        echo "## تعقيد الكود"
        echo "\`\`\`"
        npx complexity-report src/
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Code quality audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "code" "Audited code quality"
}

# Function to audit performance
audit_performance() {
    echo -e "${BLUE}Auditing performance...${NC}"
    
    local report_file="$REPORTS_DIR/performance_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق الأداء"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تحليل Lighthouse"
        echo "\`\`\`"
        npx lighthouse http://localhost:3000 --output=json | \
        jq '.categories.performance'
        echo "\`\`\`"
        echo
        
        echo "## تحليل حجم الحزمة"
        echo "\`\`\`"
        npm run build -- --stats
        echo "\`\`\`"
        echo
        
        echo "## تحليل زمن التحميل"
        echo "\`\`\`"
        curl -s -w "\nTime: %{time_total}s\n" http://localhost:3000
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Performance audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "performance" "Audited application performance"
}

# Function to audit security
audit_security() {
    echo -e "${BLUE}Auditing security...${NC}"
    
    local report_file="$REPORTS_DIR/security_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق الأمان"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تدقيق التبعيات"
        echo "\`\`\`"
        npm audit --audit-level=high
        echo "\`\`\`"
        echo
        
        echo "## فحص التكوين"
        echo "\`\`\`"
        # Check for sensitive files
        find . -type f -name "*.env*" -o -name "*.key" -o -name "*.pem"
        echo "\`\`\`"
        echo
        
        echo "## فحص الثغرات"
        echo "\`\`\`"
        # Run OWASP ZAP scan if available
        if command -v zap-cli &> /dev/null; then
            zap-cli quick-scan http://localhost:3000
        else
            echo "OWASP ZAP not installed"
        fi
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Security audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "security" "Audited application security"
}

# Function to audit accessibility
audit_accessibility() {
    echo -e "${BLUE}Auditing accessibility...${NC}"
    
    local report_file="$REPORTS_DIR/accessibility_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق إمكانية الوصول"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## تدقيق WCAG"
        echo "\`\`\`"
        npx pa11y http://localhost:3000
        echo "\`\`\`"
        echo
        
        echo "## فحص ARIA"
        echo "\`\`\`"
        find ./src -type f -name "*.tsx" -exec grep -l "aria-" {} \;
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Accessibility audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "accessibility" "Audited application accessibility"
}

# Function to audit database
audit_database() {
    echo -e "${BLUE}Auditing database...${NC}"
    
    local report_file="$REPORTS_DIR/database_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق قاعدة البيانات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إحصائيات البيانات"
        echo "\`\`\`"
        # Count records in each collection
        for dir in ./data/db/*; do
            if [ -d "$dir" ]; then
                echo "$(basename "$dir"): $(ls "$dir" | wc -l) records"
            fi
        done
        echo "\`\`\`"
        echo
        
        echo "## تحليل الحجم"
        echo "\`\`\`"
        du -sh ./data/db/*
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Database audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "database" "Audited database"
}

# Function to generate comprehensive report
generate_report() {
    echo -e "${BLUE}Generating comprehensive audit report...${NC}"
    
    local report_file="$REPORTS_DIR/comprehensive_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التدقيق الشامل"
        echo "تاريخ التقرير: $(date)"
        echo
        
        # Run all audits
        audit_dependencies > /dev/null
        audit_code > /dev/null
        audit_performance > /dev/null
        audit_security > /dev/null
        audit_accessibility > /dev/null
        audit_database > /dev/null
        
        # Combine reports
        echo "## ملخص التدقيق"
        echo
        echo "### التبعيات"
        tail -n +3 "$REPORTS_DIR/dependencies_"*
        echo
        echo "### جودة الكود"
        tail -n +3 "$REPORTS_DIR/code_quality_"*
        echo
        echo "### الأداء"
        tail -n +3 "$REPORTS_DIR/performance_"*
        echo
        echo "### الأمان"
        tail -n +3 "$REPORTS_DIR/security_"*
        echo
        echo "### إمكانية الوصول"
        tail -n +3 "$REPORTS_DIR/accessibility_"*
        echo
        echo "### قاعدة البيانات"
        tail -n +3 "$REPORTS_DIR/database_"*
        
    } > "$report_file"
    
    echo -e "${GREEN}Comprehensive audit report generated: $report_file${NC}"
    
    # Log action
    log_action "generate" "report" "Generated comprehensive audit report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/audit_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Audit Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Audit Dependencies"
    echo -e "${YELLOW}2.${NC} Audit Code Quality"
    echo -e "${YELLOW}3.${NC} Audit Performance"
    echo -e "${YELLOW}4.${NC} Audit Security"
    echo -e "${YELLOW}5.${NC} Audit Accessibility"
    echo -e "${YELLOW}6.${NC} Audit Database"
    echo -e "${YELLOW}7.${NC} Generate Comprehensive Report"
    echo -e "${YELLOW}8.${NC} View Audit Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-8): " choice
    
    case $choice in
        1)
            audit_dependencies
            ;;
        2)
            audit_code
            ;;
        3)
            audit_performance
            ;;
        4)
            audit_security
            ;;
        5)
            audit_accessibility
            ;;
        6)
            audit_database
            ;;
        7)
            generate_report
            ;;
        8)
            if [ -f "$LOGS_DIR/audit_actions.log" ]; then
                less "$LOGS_DIR/audit_actions.log"
            else
                echo -e "${YELLOW}No audit logs found${NC}"
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
