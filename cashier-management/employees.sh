#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EMPLOYEES_DIR="./data/employees"
LOGS_DIR="./logs/employees"
REPORTS_DIR="./reports/employees"
DOCS_DIR="./docs/employees"

# Employee status types
declare -A EMPLOYEE_STATUS=(
    ["active"]="نشط"
    ["inactive"]="غير نشط"
    ["on_leave"]="في إجازة"
    ["terminated"]="منتهي الخدمة"
)

# Create directories
mkdir -p "$EMPLOYEES_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$DOCS_DIR"

# Function to add employee
add_employee() {
    echo -e "${BLUE}Adding new employee...${NC}"
    
    # Generate employee ID
    local id="EMP$(date +%Y%m%d%H%M%S)"
    
    # Get employee details
    read -p "Enter full name: " name
    read -p "Enter national ID: " national_id
    read -p "Enter position: " position
    read -p "Enter department: " department
    read -p "Enter base salary: " salary
    read -p "Enter join date (YYYY-MM-DD): " join_date
    
    # Create employee file
    local employee_file="$EMPLOYEES_DIR/$id.json"
    
    {
        echo "{"
        echo "  \"id\": \"$id\","
        echo "  \"name\": \"$name\","
        echo "  \"national_id\": \"$national_id\","
        echo "  \"position\": \"$position\","
        echo "  \"department\": \"$department\","
        echo "  \"salary\": $salary,"
        echo "  \"join_date\": \"$join_date\","
        echo "  \"status\": \"active\","
        echo "  \"allowances\": {},"
        echo "  \"contact\": {"
        read -p "Enter phone number: " phone
        echo "    \"phone\": \"$phone\","
        read -p "Enter email: " email
        echo "    \"email\": \"$email\","
        read -p "Enter address: " address
        echo "    \"address\": \"$address\""
        echo "  },"
        echo "  \"emergency_contact\": {"
        read -p "Enter emergency contact name: " emergency_name
        echo "    \"name\": \"$emergency_name\","
        read -p "Enter emergency contact phone: " emergency_phone
        echo "    \"phone\": \"$emergency_phone\""
        echo "  },"
        echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
        echo "}"
    } > "$employee_file"
    
    echo -e "${GREEN}Employee added successfully${NC}"
    echo "Employee ID: $id"
    
    # Log action
    log_action "add" "$id" "Added new employee: $name"
}

# Function to update employee
update_employee() {
    echo -e "${BLUE}Updating employee...${NC}"
    
    read -p "Enter employee ID: " id
    local employee_file="$EMPLOYEES_DIR/$id.json"
    
    if [ ! -f "$employee_file" ]; then
        echo -e "${RED}Employee not found${NC}"
        return 1
    fi
    
    echo "1. Update basic information"
    echo "2. Update salary"
    echo "3. Update status"
    echo "4. Update contact information"
    echo "5. Update emergency contact"
    echo "6. Add/Update allowance"
    read -p "Enter choice (1-6): " choice
    
    case $choice in
        1)
            read -p "Enter new position (or press enter to skip): " position
            read -p "Enter new department (or press enter to skip): " department
            
            local update_cmd="."
            [ -n "$position" ] && update_cmd="$update_cmd | .position = \"$position\""
            [ -n "$department" ] && update_cmd="$update_cmd | .department = \"$department\""
            
            jq "$update_cmd | .updated_at = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" \
                "$employee_file" > "${employee_file}.tmp" && \
            mv "${employee_file}.tmp" "$employee_file"
            ;;
        2)
            read -p "Enter new base salary: " salary
            
            jq --arg salary "$salary" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.salary = ($salary|tonumber) | .updated_at = $date' \
                "$employee_file" > "${employee_file}.tmp" && \
            mv "${employee_file}.tmp" "$employee_file"
            ;;
        3)
            echo -e "\n${YELLOW}Available Status:${NC}"
            for key in "${!EMPLOYEE_STATUS[@]}"; do
                echo "$key) ${EMPLOYEE_STATUS[$key]}"
            done
            
            read -p "Enter new status: " status
            
            if [ -z "${EMPLOYEE_STATUS[$status]}" ]; then
                echo -e "${RED}Invalid status${NC}"
                return 1
            fi
            
            jq --arg status "$status" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = $status | .updated_at = $date' \
                "$employee_file" > "${employee_file}.tmp" && \
            mv "${employee_file}.tmp" "$employee_file"
            ;;
        4)
            read -p "Enter new phone (or press enter to skip): " phone
            read -p "Enter new email (or press enter to skip): " email
            read -p "Enter new address (or press enter to skip): " address
            
            local update_cmd=".contact"
            [ -n "$phone" ] && update_cmd="$update_cmd | .contact.phone = \"$phone\""
            [ -n "$email" ] && update_cmd="$update_cmd | .contact.email = \"$email\""
            [ -n "$address" ] && update_cmd="$update_cmd | .contact.address = \"$address\""
            
            jq "$update_cmd | .updated_at = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" \
                "$employee_file" > "${employee_file}.tmp" && \
            mv "${employee_file}.tmp" "$employee_file"
            ;;
        5)
            read -p "Enter new emergency contact name: " emergency_name
            read -p "Enter new emergency contact phone: " emergency_phone
            
            jq --arg name "$emergency_name" \
               --arg phone "$emergency_phone" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.emergency_contact.name = $name | .emergency_contact.phone = $phone | .updated_at = $date' \
                "$employee_file" > "${employee_file}.tmp" && \
            mv "${employee_file}.tmp" "$employee_file"
            ;;
        6)
            read -p "Enter allowance name: " allowance_name
            read -p "Enter allowance amount: " allowance_amount
            
            jq --arg name "$allowance_name" \
               --arg amount "$allowance_amount" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               ".allowances[$name] = ($amount|tonumber) | .updated_at = \$date" \
                "$employee_file" > "${employee_file}.tmp" && \
            mv "${employee_file}.tmp" "$employee_file"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Employee updated successfully${NC}"
    
    # Log action
    log_action "update" "$id" "Updated employee information"
}

# Function to view employee
view_employee() {
    echo -e "${BLUE}Viewing employee details...${NC}"
    
    read -p "Enter employee ID (or 'all'): " id
    
    if [ "$id" = "all" ]; then
        echo -e "\n${YELLOW}Employee List:${NC}"
        echo "------------------------"
        
        for employee_file in "$EMPLOYEES_DIR"/*.json; do
            if [ -f "$employee_file" ]; then
                echo -e "\nID: $(jq -r .id "$employee_file")"
                echo "Name: $(jq -r .name "$employee_file")"
                echo "Position: $(jq -r .position "$employee_file")"
                echo "Department: $(jq -r .department "$employee_file")"
                echo "Status: $(jq -r .status "$employee_file")"
                echo "------------------------"
            fi
        done
    else
        local employee_file="$EMPLOYEES_DIR/$id.json"
        
        if [ ! -f "$employee_file" ]; then
            echo -e "${RED}Employee not found${NC}"
            return 1
        fi
        
        echo -e "\n${YELLOW}Employee Details:${NC}"
        echo "------------------------"
        jq '.' "$employee_file"
    fi
    
    # Log action
    log_action "view" "$id" "Viewed employee details"
}

# Function to generate employee report
generate_report() {
    echo -e "${BLUE}Generating employee report...${NC}"
    
    local report_file="$REPORTS_DIR/employees_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير الموظفين"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إحصائيات الموظفين"
        echo
        
        # Calculate statistics
        local total_employees=$(ls "$EMPLOYEES_DIR"/*.json 2>/dev/null | wc -l)
        local active_employees=$(find "$EMPLOYEES_DIR" -type f -name "*.json" -exec jq -r 'select(.status == "active") | .id' {} \; | wc -l)
        local total_salary=$(find "$EMPLOYEES_DIR" -type f -name "*.json" -exec jq -r '.salary' {} \; | awk '{sum += $1} END {print sum}')
        
        echo "- إجمالي الموظفين: $total_employees"
        echo "- الموظفين النشطين: $active_employees"
        echo "- إجمالي الرواتب: $total_salary"
        echo
        
        echo "## الموظفين حسب القسم"
        echo
        find "$EMPLOYEES_DIR" -type f -name "*.json" -exec jq -r '.department' {} \; | \
        sort | uniq -c | while read -r count dept; do
            echo "- $dept: $count موظف"
        done
        echo
        
        echo "## قائمة الموظفين"
        echo
        echo "| الرقم | الاسم | القسم | المنصب | الحالة |"
        echo "|-------|------|--------|---------|---------|"
        
        find "$EMPLOYEES_DIR" -type f -name "*.json" -exec sh -c '
            jq -r "[\(.id), \(.name), \(.department), \(.position), \(.status)] | @tsv" "$1"
        ' sh {} \; | while IFS=$'\t' read -r id name dept pos status; do
            printf "| %s | %s | %s | %s | %s |\n" "$id" "$name" "$dept" "$pos" "$status"
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Employee report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated employee report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/employee_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Employee Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Add Employee"
    echo -e "${YELLOW}2.${NC} Update Employee"
    echo -e "${YELLOW}3.${NC} View Employee"
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
            add_employee
            ;;
        2)
            update_employee
            ;;
        3)
            view_employee
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/employee_actions.log" ]; then
                less "$LOGS_DIR/employee_actions.log"
            else
                echo -e "${YELLOW}No employee logs found${NC}"
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
