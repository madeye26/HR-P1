#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPORTS_DIR="./reports"
LOGS_DIR="./logs/reports"
TEMP_DIR="./temp/reports"
ARCHIVE_DIR="./archives/reports"

# Report types
declare -A REPORT_TYPES=(
    ["sales"]="تقارير المبيعات"
    ["inventory"]="تقارير المخزون"
    ["employees"]="تقارير الموظفين"
    ["financial"]="التقارير المالية"
    ["system"]="تقارير النظام"
)

# Create directories
mkdir -p "$REPORTS_DIR" "$LOGS_DIR" "$TEMP_DIR" "$ARCHIVE_DIR"
for type in "${!REPORT_TYPES[@]}"; do
    mkdir -p "$REPORTS_DIR/$type"
done

# Function to generate sales report
generate_sales_report() {
    echo -e "${BLUE}Generating sales report...${NC}"
    
    read -p "Enter start date (YYYY-MM-DD): " start_date
    read -p "Enter end date (YYYY-MM-DD): " end_date
    
    local report_file="$REPORTS_DIR/sales/sales_${start_date}_${end_date}.md"
    
    {
        echo "# تقرير المبيعات"
        echo "الفترة: $start_date إلى $end_date"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص المبيعات"
        echo "\`\`\`"
        # Add your sales data processing logic here
        find ./data/sales -type f -name "*.json" -exec cat {} \; | \
        jq -s "[.[] | select(.date >= \"$start_date\" and .date <= \"$end_date\")]" | \
        jq '{
            total_sales: length,
            total_revenue: map(.total) | add,
            average_sale: (map(.total) | add) / length,
            items_sold: map(.items | length) | add
        }'
        echo "\`\`\`"
        echo
        
        echo "## المبيعات حسب الفئة"
        echo "\`\`\`"
        find ./data/sales -type f -name "*.json" -exec cat {} \; | \
        jq -s "[.[] | select(.date >= \"$start_date\" and .date <= \"$end_date\")] | 
        group_by(.category) | map({category: .[0].category, total: map(.total) | add})"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Sales report generated: $report_file${NC}"
    
    # Log action
    log_action "generate" "sales" "Generated sales report for $start_date to $end_date"
}

# Function to generate inventory report
generate_inventory_report() {
    echo -e "${BLUE}Generating inventory report...${NC}"
    
    local report_file="$REPORTS_DIR/inventory/inventory_$(date +%Y%m%d).md"
    
    {
        echo "# تقرير المخزون"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## حالة المخزون"
        echo "\`\`\`"
        find ./data/inventory -type f -name "*.json" -exec cat {} \; | \
        jq -s 'group_by(.category) | map({
            category: .[0].category,
            total_items: length,
            total_value: map(.quantity * .price) | add,
            low_stock: map(select(.quantity <= .minimum_quantity)) | length
        })'
        echo "\`\`\`"
        echo
        
        echo "## الأصناف منخفضة المخزون"
        echo "\`\`\`"
        find ./data/inventory -type f -name "*.json" -exec cat {} \; | \
        jq -s 'map(select(.quantity <= .minimum_quantity)) | 
        map({name: .name, quantity: .quantity, minimum: .minimum_quantity})'
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Inventory report generated: $report_file${NC}"
    
    # Log action
    log_action "generate" "inventory" "Generated inventory report"
}

# Function to generate employee report
generate_employee_report() {
    echo -e "${BLUE}Generating employee report...${NC}"
    
    local report_file="$REPORTS_DIR/employees/employees_$(date +%Y%m%d).md"
    
    {
        echo "# تقرير الموظفين"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إحصائيات الموظفين"
        echo "\`\`\`"
        find ./data/employees -type f -name "*.json" -exec cat {} \; | \
        jq -s '{
            total_employees: length,
            departments: group_by(.department) | map({
                department: .[0].department,
                count: length,
                total_salary: map(.salary) | add
            }),
            average_salary: (map(.salary) | add) / length
        }'
        echo "\`\`\`"
        echo
        
        echo "## الحضور والغياب"
        echo "\`\`\`"
        find ./data/attendance -type f -name "*.json" -exec cat {} \; | \
        jq -s 'group_by(.employee_id) | map({
            employee_id: .[0].employee_id,
            present_days: map(select(.status == "present")) | length,
            absent_days: map(select(.status == "absent")) | length,
            late_days: map(select(.status == "late")) | length
        })'
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Employee report generated: $report_file${NC}"
    
    # Log action
    log_action "generate" "employees" "Generated employee report"
}

# Function to generate financial report
generate_financial_report() {
    echo -e "${BLUE}Generating financial report...${NC}"
    
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    local report_file="$REPORTS_DIR/financial/financial_${year}_${month}.md"
    
    {
        echo "# التقرير المالي"
        echo "الشهر: $month"
        echo "السنة: $year"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص مالي"
        echo "\`\`\`"
        # Add your financial data processing logic here
        jq -s '{
            revenue: map(.total) | add,
            expenses: map(.amount) | add,
            profit: (map(.total) | add) - (map(.amount) | add)
        }' ./data/sales/*.json ./data/expenses/*.json
        echo "\`\`\`"
        echo
        
        echo "## المصروفات حسب الفئة"
        echo "\`\`\`"
        find ./data/expenses -type f -name "*.json" -exec cat {} \; | \
        jq -s 'group_by(.category) | map({
            category: .[0].category,
            total: map(.amount) | add
        })'
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Financial report generated: $report_file${NC}"
    
    # Log action
    log_action "generate" "financial" "Generated financial report for $month/$year"
}

# Function to generate system report
generate_system_report() {
    echo -e "${BLUE}Generating system report...${NC}"
    
    local report_file="$REPORTS_DIR/system/system_$(date +%Y%m%d).md"
    
    {
        echo "# تقرير النظام"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## معلومات النظام"
        echo "\`\`\`"
        echo "OS: $(uname -a)"
        echo "Memory: $(free -h)"
        echo "Disk: $(df -h)"
        echo "\`\`\`"
        echo
        
        echo "## حالة الخدمات"
        echo "\`\`\`"
        systemctl status nginx mysql redis 2>/dev/null || echo "Services not available"
        echo "\`\`\`"
        echo
        
        echo "## سجلات النظام"
        echo "\`\`\`"
        tail -n 50 /var/log/syslog 2>/dev/null || echo "System logs not available"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}System report generated: $report_file${NC}"
    
    # Log action
    log_action "generate" "system" "Generated system report"
}

# Function to archive reports
archive_reports() {
    echo -e "${BLUE}Archiving reports...${NC}"
    
    read -p "Enter days to keep (default: 30): " days
    days=${days:-30}
    
    # Create archive
    local archive_name="reports_archive_$(date +%Y%m%d).tar.gz"
    
    # Find and archive old reports
    find "$REPORTS_DIR" -type f -mtime +$days -print0 | \
    tar czf "$ARCHIVE_DIR/$archive_name" --null -T -
    
    # Remove archived reports
    find "$REPORTS_DIR" -type f -mtime +$days -delete
    
    echo -e "${GREEN}Reports archived: $archive_name${NC}"
    
    # Log action
    log_action "archive" "reports" "Archived reports older than $days days"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/report_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Reports Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Generate Sales Report"
    echo -e "${YELLOW}2.${NC} Generate Inventory Report"
    echo -e "${YELLOW}3.${NC} Generate Employee Report"
    echo -e "${YELLOW}4.${NC} Generate Financial Report"
    echo -e "${YELLOW}5.${NC} Generate System Report"
    echo -e "${YELLOW}6.${NC} Archive Reports"
    echo -e "${YELLOW}7.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1)
            generate_sales_report
            ;;
        2)
            generate_inventory_report
            ;;
        3)
            generate_employee_report
            ;;
        4)
            generate_financial_report
            ;;
        5)
            generate_system_report
            ;;
        6)
            archive_reports
            ;;
        7)
            if [ -f "$LOGS_DIR/report_actions.log" ]; then
                less "$LOGS_DIR/report_actions.log"
            else
                echo -e "${YELLOW}No report logs found${NC}"
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
