#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EXPENSES_DIR="./data/expenses"
LOGS_DIR="./logs/expenses"
REPORTS_DIR="./reports/expenses"
RECEIPTS_DIR="./data/receipts"

# Expense categories
declare -A EXPENSE_CATEGORIES=(
    ["utilities"]="المرافق"
    ["supplies"]="المستلزمات"
    ["maintenance"]="الصيانة"
    ["salary"]="الرواتب"
    ["rent"]="الإيجار"
    ["other"]="أخرى"
)

# Expense status
declare -A EXPENSE_STATUS=(
    ["pending"]="قيد الانتظار"
    ["approved"]="موافق عليه"
    ["rejected"]="مرفوض"
    ["paid"]="مدفوع"
)

# Create directories
mkdir -p "$EXPENSES_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$RECEIPTS_DIR"

# Function to add expense
add_expense() {
    echo -e "${BLUE}Adding new expense...${NC}"
    
    # Generate expense ID
    local id="EXP$(date +%Y%m%d%H%M%S)"
    
    # Show categories
    echo -e "\n${YELLOW}Available Categories:${NC}"
    for key in "${!EXPENSE_CATEGORIES[@]}"; do
        echo "$key) ${EXPENSE_CATEGORIES[$key]}"
    done
    
    read -p "Enter category: " category
    
    if [ -z "${EXPENSE_CATEGORIES[$category]}" ]; then
        echo -e "${RED}Invalid category${NC}"
        return 1
    fi
    
    read -p "Enter amount: " amount
    read -p "Enter description: " description
    read -p "Enter department ID: " department_id
    
    # Check if department exists
    if [ ! -f "./data/departments/$department_id.json" ]; then
        echo -e "${RED}Department not found${NC}"
        return 1
    fi
    
    # Create expense file
    local expense_file="$EXPENSES_DIR/$id.json"
    
    {
        echo "{"
        echo "  \"id\": \"$id\","
        echo "  \"category\": \"$category\","
        echo "  \"amount\": $amount,"
        echo "  \"description\": \"$description\","
        echo "  \"department_id\": \"$department_id\","
        echo "  \"status\": \"pending\","
        echo "  \"created_by\": \"$(read -p "Enter your employee ID: " emp_id && echo $emp_id)\","
        echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"approved_by\": null,"
        echo "  \"approved_at\": null,"
        echo "  \"paid_at\": null,"
        echo "  \"payment_method\": null,"
        echo "  \"receipt_path\": null,"
        echo "  \"notes\": []"
        echo "}"
    } > "$expense_file"
    
    echo -e "${GREEN}Expense added successfully${NC}"
    echo "Expense ID: $id"
    
    # Log action
    log_action "add" "$id" "Added new expense: $amount for $category"
}

# Function to process expense
process_expense() {
    echo -e "${BLUE}Processing expense...${NC}"
    
    read -p "Enter expense ID: " id
    local expense_file="$EXPENSES_DIR/$id.json"
    
    if [ ! -f "$expense_file" ]; then
        echo -e "${RED}Expense not found${NC}"
        return 1
    fi
    
    # Show current status
    echo -e "\nCurrent Status: $(jq -r .status "$expense_file")"
    
    # Show status options
    echo -e "\n${YELLOW}Available Status:${NC}"
    for key in "${!EXPENSE_STATUS[@]}"; do
        echo "$key) ${EXPENSE_STATUS[$key]}"
    done
    
    read -p "Enter new status: " status
    
    if [ -z "${EXPENSE_STATUS[$status]}" ]; then
        echo -e "${RED}Invalid status${NC}"
        return 1
    fi
    
    read -p "Enter note: " note
    read -p "Enter your employee ID: " processor_id
    
    # Update expense status
    local update_cmd=".status = \"$status\" | .updated_at = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
    
    case $status in
        approved)
            update_cmd="$update_cmd | .approved_by = \"$processor_id\" | .approved_at = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
            ;;
        paid)
            read -p "Enter payment method: " payment_method
            update_cmd="$update_cmd | .paid_at = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\" | .payment_method = \"$payment_method\""
            
            # Handle receipt
            read -p "Upload receipt? (y/n): " upload_receipt
            if [[ $upload_receipt =~ ^[Yy]$ ]]; then
                read -p "Enter receipt path: " receipt_path
                if [ -f "$receipt_path" ]; then
                    local new_receipt_path="$RECEIPTS_DIR/${id}_$(basename "$receipt_path")"
                    cp "$receipt_path" "$new_receipt_path"
                    update_cmd="$update_cmd | .receipt_path = \"$new_receipt_path\""
                fi
            fi
            ;;
    esac
    
    # Add note
    update_cmd="$update_cmd | .notes += [{
        \"text\": \"$note\",
        \"by\": \"$processor_id\",
        \"at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }]"
    
    jq "$update_cmd" "$expense_file" > "${expense_file}.tmp" && \
    mv "${expense_file}.tmp" "$expense_file"
    
    echo -e "${GREEN}Expense processed successfully${NC}"
    
    # Log action
    log_action "process" "$id" "Updated expense status to $status"
}

# Function to view expenses
view_expenses() {
    echo -e "${BLUE}Viewing expenses...${NC}"
    
    read -p "Enter department ID (or 'all'): " department_id
    
    if [ "$department_id" = "all" ]; then
        echo -e "\n${YELLOW}All Expenses:${NC}"
        echo "------------------------"
        
        for expense_file in "$EXPENSES_DIR"/*.json; do
            if [ -f "$expense_file" ]; then
                echo -e "\nID: $(jq -r .id "$expense_file")"
                echo "Category: $(jq -r .category "$expense_file")"
                echo "Amount: $(jq -r .amount "$expense_file")"
                echo "Status: $(jq -r .status "$expense_file")"
                echo "------------------------"
            fi
        done
    else
        echo -e "\n${YELLOW}Expenses for Department $department_id:${NC}"
        echo "------------------------"
        
        find "$EXPENSES_DIR" -type f -name "*.json" -exec sh -c '
            if [ "$(jq -r .department_id "$1")" = "'$department_id'" ]; then
                echo -e "\nID: $(jq -r .id "$1")"
                echo "Category: $(jq -r .category "$1")"
                echo "Amount: $(jq -r .amount "$1")"
                echo "Status: $(jq -r .status "$1")"
                echo "------------------------"
            fi
        ' sh {} \;
    fi
    
    # Log action
    log_action "view" "$department_id" "Viewed expenses"
}

# Function to generate expense report
generate_report() {
    echo -e "${BLUE}Generating expense report...${NC}"
    
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    local report_file="$REPORTS_DIR/expenses_${year}${month}.md"
    
    {
        echo "# تقرير المصروفات"
        echo "الفترة: $month/$year"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص المصروفات"
        echo
        
        # Calculate totals by category
        for category in "${!EXPENSE_CATEGORIES[@]}"; do
            local total=$(find "$EXPENSES_DIR" -type f -name "*.json" -exec sh -c '
                if [[ "$(jq -r .category "$1")" = "'$category'" && 
                     "$(jq -r .created_at "$1")" =~ ^'$year-$month' ]]; then
                    jq -r .amount "$1"
                fi
            ' sh {} \; | awk '{sum += $1} END {print sum}')
            
            echo "- ${EXPENSE_CATEGORIES[$category]}: $total"
        done
        echo
        
        echo "## حالة المصروفات"
        echo
        for status in "${!EXPENSE_STATUS[@]}"; do
            local count=$(find "$EXPENSES_DIR" -type f -name "*.json" -exec sh -c '
                if [[ "$(jq -r .status "$1")" = "'$status'" && 
                     "$(jq -r .created_at "$1")" =~ ^'$year-$month' ]]; then
                    echo "1"
                fi
            ' sh {} \; | wc -l)
            
            echo "- ${EXPENSE_STATUS[$status]}: $count"
        done
        echo
        
        echo "## تفاصيل المصروفات"
        echo
        echo "| القسم | الفئة | المبلغ | الحالة | التاريخ |"
        echo "|-------|-------|--------|---------|----------|"
        
        find "$EXPENSES_DIR" -type f -name "*.json" -exec sh -c '
            if [[ "$(jq -r .created_at "$1")" =~ ^'$year-$month' ]]; then
                dept_id=$(jq -r .department_id "$1")
                dept_name=$(jq -r .name "./data/departments/$dept_id.json")
                printf "| %s | %s | %.2f | %s | %s |\n" \
                    "$dept_name" \
                    "$(jq -r .category "$1")" \
                    "$(jq -r .amount "$1")" \
                    "$(jq -r .status "$1")" \
                    "$(jq -r .created_at "$1")"
            fi
        ' sh {} \;
        
    } > "$report_file"
    
    echo -e "${GREEN}Expense report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated expense report for $month/$year"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/expense_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Expense Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Add Expense"
    echo -e "${YELLOW}2.${NC} Process Expense"
    echo -e "${YELLOW}3.${NC} View Expenses"
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
            add_expense
            ;;
        2)
            process_expense
            ;;
        3)
            view_expenses
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/expense_actions.log" ]; then
                less "$LOGS_DIR/expense_actions.log"
            else
                echo -e "${YELLOW}No expense logs found${NC}"
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
