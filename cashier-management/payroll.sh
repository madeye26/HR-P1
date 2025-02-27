#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PAYROLL_DIR="./data/payroll"
LOGS_DIR="./logs/payroll"
REPORTS_DIR="./reports/payroll"
TEMP_DIR="./temp/payroll"

# Create directories
mkdir -p "$PAYROLL_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to calculate salary
calculate_salary() {
    echo -e "${BLUE}Calculating salary...${NC}"
    
    read -p "Enter employee ID: " employee_id
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    # Check if salary already calculated
    local salary_file="$PAYROLL_DIR/${employee_id}_${year}${month}.json"
    if [ -f "$salary_file" ]; then
        echo -e "${YELLOW}Salary already calculated for this period${NC}"
        return 1
    fi
    
    # Get employee details
    local employee_file="./data/employees/$employee_id.json"
    if [ ! -f "$employee_file" ]; then
        echo -e "${RED}Employee not found${NC}"
        return 1
    fi
    
    # Get base salary
    local base_salary=$(jq -r .salary "$employee_file")
    
    # Calculate working days
    local working_days=$(find "./data/attendance" -type f -name "${employee_id}_${year}${month}*.json" \
        -exec jq -r 'select(.status == "present") | .date' {} \; | wc -l)
    
    # Calculate overtime
    local overtime_hours=$(find "./data/attendance" -type f -name "${employee_id}_${year}${month}*.json" \
        -exec jq -r '.overtime // 0' {} \; | awk '{sum += $1} END {print sum}')
    
    # Calculate deductions
    local absent_days=$(find "./data/attendance" -type f -name "${employee_id}_${year}${month}*.json" \
        -exec jq -r 'select(.status == "absent") | .date' {} \; | wc -l)
    local deductions=$((absent_days * (base_salary / 30)))
    
    # Calculate allowances
    local allowances=$(jq -r '.allowances | add // 0' "$employee_file")
    
    # Calculate total salary
    local overtime_rate=$(echo "$base_salary / 30 / 8 * 1.5" | bc)
    local overtime_pay=$(echo "$overtime_hours * $overtime_rate" | bc)
    local total_salary=$(echo "$base_salary + $overtime_pay + $allowances - $deductions" | bc)
    
    # Create salary record
    {
        echo "{"
        echo "  \"employee_id\": \"$employee_id\","
        echo "  \"month\": \"$month\","
        echo "  \"year\": \"$year\","
        echo "  \"base_salary\": $base_salary,"
        echo "  \"working_days\": $working_days,"
        echo "  \"overtime_hours\": $overtime_hours,"
        echo "  \"overtime_pay\": $overtime_pay,"
        echo "  \"allowances\": $allowances,"
        echo "  \"deductions\": $deductions,"
        echo "  \"total_salary\": $total_salary,"
        echo "  \"status\": \"pending\","
        echo "  \"calculated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"paid_at\": null"
        echo "}"
    } > "$salary_file"
    
    echo -e "${GREEN}Salary calculated successfully${NC}"
    echo "Total Salary: $total_salary"
    
    # Log action
    log_action "calculate" "$employee_id" "Calculated salary for $month/$year"
}

# Function to process payroll
process_payroll() {
    echo -e "${BLUE}Processing payroll...${NC}"
    
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    # Find all pending salary records
    local pending_records=$(find "$PAYROLL_DIR" -type f -name "*_${year}${month}.json" \
        -exec jq -r 'select(.status == "pending") | .employee_id' {} \;)
    
    if [ -z "$pending_records" ]; then
        echo -e "${YELLOW}No pending salary records found${NC}"
        return 1
    fi
    
    echo -e "\n${YELLOW}Pending Salary Records:${NC}"
    for employee_id in $pending_records; do
        local salary_file="$PAYROLL_DIR/${employee_id}_${year}${month}.json"
        echo "Employee ID: $employee_id"
        echo "Total Salary: $(jq -r .total_salary "$salary_file")"
        echo "------------------------"
    done
    
    read -p "Process all salaries? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        for employee_id in $pending_records; do
            local salary_file="$PAYROLL_DIR/${employee_id}_${year}${month}.json"
            
            # Update salary status
            jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = "processed" | .paid_at = $date' "$salary_file" > "${salary_file}.tmp" && \
            mv "${salary_file}.tmp" "$salary_file"
            
            echo -e "${GREEN}Processed salary for employee: $employee_id${NC}"
        done
        
        # Log action
        log_action "process" "all" "Processed payroll for $month/$year"
    fi
}

# Function to generate payslip
generate_payslip() {
    echo -e "${BLUE}Generating payslip...${NC}"
    
    read -p "Enter employee ID: " employee_id
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    local salary_file="$PAYROLL_DIR/${employee_id}_${year}${month}.json"
    if [ ! -f "$salary_file" ]; then
        echo -e "${RED}Salary record not found${NC}"
        return 1
    fi
    
    local employee_file="./data/employees/$employee_id.json"
    if [ ! -f "$employee_file" ]; then
        echo -e "${RED}Employee not found${NC}"
        return 1
    fi
    
    local payslip_file="$REPORTS_DIR/payslip_${employee_id}_${year}${month}.md"
    
    {
        echo "# قسيمة الراتب"
        echo "تاريخ القسيمة: $(date)"
        echo
        
        echo "## معلومات الموظف"
        echo "- الاسم: $(jq -r .name "$employee_file")"
        echo "- الرقم الوظيفي: $employee_id"
        echo "- القسم: $(jq -r .department "$employee_file")"
        echo
        
        echo "## تفاصيل الراتب"
        echo "- الشهر: $month/$year"
        echo "- الراتب الأساسي: $(jq -r .base_salary "$salary_file")"
        echo "- أيام العمل: $(jq -r .working_days "$salary_file")"
        echo "- ساعات العمل الإضافي: $(jq -r .overtime_hours "$salary_file")"
        echo "- مبلغ العمل الإضافي: $(jq -r .overtime_pay "$salary_file")"
        echo "- البدلات: $(jq -r .allowances "$salary_file")"
        echo "- الخصومات: $(jq -r .deductions "$salary_file")"
        echo "- إجمالي الراتب: $(jq -r .total_salary "$salary_file")"
        echo
        
        echo "## حالة الدفع"
        echo "- الحالة: $(jq -r .status "$salary_file")"
        echo "- تاريخ الدفع: $(jq -r .paid_at "$salary_file")"
        
    } > "$payslip_file"
    
    echo -e "${GREEN}Payslip generated: $payslip_file${NC}"
    
    # Log action
    log_action "generate" "$employee_id" "Generated payslip for $month/$year"
}

# Function to generate payroll report
generate_report() {
    echo -e "${BLUE}Generating payroll report...${NC}"
    
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    local report_file="$REPORTS_DIR/payroll_${year}${month}.md"
    
    {
        echo "# تقرير الرواتب"
        echo "الفترة: $month/$year"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص الرواتب"
        echo
        
        # Calculate totals
        local total_salaries=0
        local total_overtime=0
        local total_allowances=0
        local total_deductions=0
        
        for salary_file in "$PAYROLL_DIR"/*_${year}${month}.json; do
            if [ -f "$salary_file" ]; then
                total_salaries=$(echo "$total_salaries + $(jq -r .total_salary "$salary_file")" | bc)
                total_overtime=$(echo "$total_overtime + $(jq -r .overtime_pay "$salary_file")" | bc)
                total_allowances=$(echo "$total_allowances + $(jq -r .allowances "$salary_file")" | bc)
                total_deductions=$(echo "$total_deductions + $(jq -r .deductions "$salary_file")" | bc)
            fi
        done
        
        echo "- إجمالي الرواتب: $total_salaries"
        echo "- إجمالي العمل الإضافي: $total_overtime"
        echo "- إجمالي البدلات: $total_allowances"
        echo "- إجمالي الخصومات: $total_deductions"
        echo
        
        echo "## تفاصيل الرواتب"
        echo
        echo "| الموظف | الراتب الأساسي | العمل الإضافي | البدلات | الخصومات | الإجمالي |"
        echo "|--------|----------------|---------------|----------|------------|-----------|"
        
        for salary_file in "$PAYROLL_DIR"/*_${year}${month}.json; do
            if [ -f "$salary_file" ]; then
                local employee_id=$(jq -r .employee_id "$salary_file")
                local employee_name=$(jq -r .name "./data/employees/$employee_id.json")
                printf "| %s | %.2f | %.2f | %.2f | %.2f | %.2f |\n" \
                    "$employee_name" \
                    "$(jq -r .base_salary "$salary_file")" \
                    "$(jq -r .overtime_pay "$salary_file")" \
                    "$(jq -r .allowances "$salary_file")" \
                    "$(jq -r .deductions "$salary_file")" \
                    "$(jq -r .total_salary "$salary_file")"
            fi
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Payroll report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated payroll report for $month/$year"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/payroll_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Payroll Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Calculate Salary"
    echo -e "${YELLOW}2.${NC} Process Payroll"
    echo -e "${YELLOW}3.${NC} Generate Payslip"
    echo -e "${YELLOW}4.${NC} Generate Report"
    echo -e "${YELLOW}5.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-5): " choice
    
    case $choice in
        1)
            calculate_salary
            ;;
        2)
            process_payroll
            ;;
        3)
            generate_payslip
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/payroll_actions.log" ]; then
                less "$LOGS_DIR/payroll_actions.log"
            else
                echo -e "${YELLOW}No payroll logs found${NC}"
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
