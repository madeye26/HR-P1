#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPT_DIR="./data/departments"
LOGS_DIR="./logs/departments"
REPORTS_DIR="./reports/departments"
TEMP_DIR="./temp/departments"

# Create directories
mkdir -p "$DEPT_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to add department
add_department() {
    echo -e "${BLUE}Adding new department...${NC}"
    
    # Generate department ID
    local id="DEPT$(date +%Y%m%d%H%M%S)"
    
    read -p "Enter department name: " name
    read -p "Enter department code: " code
    read -p "Enter manager ID: " manager_id
    
    # Check if manager exists
    if [ -n "$manager_id" ] && [ ! -f "./data/employees/$manager_id.json" ]; then
        echo -e "${RED}Manager not found${NC}"
        return 1
    fi
    
    # Create department file
    local dept_file="$DEPT_DIR/$id.json"
    
    {
        echo "{"
        echo "  \"id\": \"$id\","
        echo "  \"name\": \"$name\","
        echo "  \"code\": \"$code\","
        echo "  \"manager_id\": \"$manager_id\","
        echo "  \"budget\": {"
        read -p "Enter annual budget: " budget
        echo "    \"annual\": $budget,"
        echo "    \"remaining\": $budget,"
        echo "    \"year\": $(date +%Y)"
        echo "  },"
        echo "  \"status\": \"active\","
        echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"description\": \"$(read -p "Enter description: " desc && echo $desc)\","
        echo "  \"goals\": [],"
        echo "  \"metrics\": {}"
        echo "}"
    } > "$dept_file"
    
    echo -e "${GREEN}Department added successfully${NC}"
    echo "Department ID: $id"
    
    # Log action
    log_action "add" "$id" "Added new department: $name"
}

# Function to update department
update_department() {
    echo -e "${BLUE}Updating department...${NC}"
    
    read -p "Enter department ID: " id
    local dept_file="$DEPT_DIR/$id.json"
    
    if [ ! -f "$dept_file" ]; then
        echo -e "${RED}Department not found${NC}"
        return 1
    fi
    
    echo "1. Update basic information"
    echo "2. Update manager"
    echo "3. Update budget"
    echo "4. Add/Update goals"
    echo "5. Update metrics"
    echo "6. Update status"
    read -p "Enter choice (1-6): " choice
    
    case $choice in
        1)
            read -p "Enter new name (or press enter to skip): " name
            read -p "Enter new code (or press enter to skip): " code
            read -p "Enter new description (or press enter to skip): " description
            
            local update_cmd="."
            [ -n "$name" ] && update_cmd="$update_cmd | .name = \"$name\""
            [ -n "$code" ] && update_cmd="$update_cmd | .code = \"$code\""
            [ -n "$description" ] && update_cmd="$update_cmd | .description = \"$description\""
            
            jq "$update_cmd | .updated_at = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" \
                "$dept_file" > "${dept_file}.tmp" && \
            mv "${dept_file}.tmp" "$dept_file"
            ;;
        2)
            read -p "Enter new manager ID: " manager_id
            
            if [ ! -f "./data/employees/$manager_id.json" ]; then
                echo -e "${RED}Manager not found${NC}"
                return 1
            fi
            
            jq --arg mgr "$manager_id" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.manager_id = $mgr | .updated_at = $date' \
                "$dept_file" > "${dept_file}.tmp" && \
            mv "${dept_file}.tmp" "$dept_file"
            ;;
        3)
            read -p "Enter new annual budget: " budget
            
            jq --arg budget "$budget" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.budget.annual = ($budget|tonumber) | 
                .budget.remaining = ($budget|tonumber) | 
                .budget.year = '$(date +%Y)' | 
                .updated_at = $date' \
                "$dept_file" > "${dept_file}.tmp" && \
            mv "${dept_file}.tmp" "$dept_file"
            ;;
        4)
            read -p "Enter goal title: " goal_title
            read -p "Enter goal description: " goal_desc
            read -p "Enter target date (YYYY-MM-DD): " target_date
            
            jq --arg title "$goal_title" \
               --arg desc "$goal_desc" \
               --arg date "$target_date" \
               --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.goals += [{
                   "title": $title,
                   "description": $desc,
                   "target_date": $date,
                   "status": "pending",
                   "created_at": $now
               }] | .updated_at = $now' \
                "$dept_file" > "${dept_file}.tmp" && \
            mv "${dept_file}.tmp" "$dept_file"
            ;;
        5)
            read -p "Enter metric name: " metric_name
            read -p "Enter metric value: " metric_value
            
            jq --arg name "$metric_name" \
               --arg value "$metric_value" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.metrics[$name] = {
                   "value": ($value|tonumber),
                   "updated_at": $date
               } | .updated_at = $date' \
                "$dept_file" > "${dept_file}.tmp" && \
            mv "${dept_file}.tmp" "$dept_file"
            ;;
        6)
            read -p "Enter new status (active/inactive): " status
            
            jq --arg status "$status" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = $status | .updated_at = $date' \
                "$dept_file" > "${dept_file}.tmp" && \
            mv "${dept_file}.tmp" "$dept_file"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Department updated successfully${NC}"
    
    # Log action
    log_action "update" "$id" "Updated department information"
}

# Function to view department
view_department() {
    echo -e "${BLUE}Viewing department details...${NC}"
    
    read -p "Enter department ID (or 'all'): " id
    
    if [ "$id" = "all" ]; then
        echo -e "\n${YELLOW}Department List:${NC}"
        echo "------------------------"
        
        for dept_file in "$DEPT_DIR"/*.json; do
            if [ -f "$dept_file" ]; then
                echo -e "\nID: $(jq -r .id "$dept_file")"
                echo "Name: $(jq -r .name "$dept_file")"
                echo "Code: $(jq -r .code "$dept_file")"
                echo "Status: $(jq -r .status "$dept_file")"
                echo "------------------------"
            fi
        done
    else
        local dept_file="$DEPT_DIR/$id.json"
        
        if [ ! -f "$dept_file" ]; then
            echo -e "${RED}Department not found${NC}"
            return 1
        fi
        
        echo -e "\n${YELLOW}Department Details:${NC}"
        echo "------------------------"
        jq '.' "$dept_file"
        
        # Show department employees
        echo -e "\n${YELLOW}Department Employees:${NC}"
        echo "------------------------"
        find "./data/employees" -type f -name "*.json" -exec sh -c '
            if [ "$(jq -r .department "$1")" = "'$(jq -r .name "$dept_file")" ]; then
                echo "- $(jq -r .name "$1") ($(jq -r .position "$1"))"
            fi
        ' sh {} \;
    fi
    
    # Log action
    log_action "view" "$id" "Viewed department details"
}

# Function to generate department report
generate_report() {
    echo -e "${BLUE}Generating department report...${NC}"
    
    local report_file="$REPORTS_DIR/departments_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير الأقسام"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص الأقسام"
        echo
        
        # Calculate statistics
        local total_depts=$(ls "$DEPT_DIR"/*.json 2>/dev/null | wc -l)
        local active_depts=$(find "$DEPT_DIR" -type f -name "*.json" -exec jq -r 'select(.status == "active") | .id' {} \; | wc -l)
        local total_budget=$(find "$DEPT_DIR" -type f -name "*.json" -exec jq -r '.budget.annual' {} \; | awk '{sum += $1} END {print sum}')
        
        echo "- إجمالي الأقسام: $total_depts"
        echo "- الأقسام النشطة: $active_depts"
        echo "- إجمالي الميزانية: $total_budget"
        echo
        
        echo "## تفاصيل الأقسام"
        echo
        echo "| القسم | الرمز | المدير | الميزانية | الحالة |"
        echo "|-------|-------|---------|------------|---------|"
        
        find "$DEPT_DIR" -type f -name "*.json" -exec sh -c '
            dept_name=$(jq -r .name "$1")
            dept_code=$(jq -r .code "$1")
            manager_id=$(jq -r .manager_id "$1")
            manager_name=$(jq -r .name "./data/employees/$manager_id.json" 2>/dev/null || echo "N/A")
            budget=$(jq -r .budget.annual "$1")
            status=$(jq -r .status "$1")
            printf "| %s | %s | %s | %.2f | %s |\n" \
                "$dept_name" "$dept_code" "$manager_name" "$budget" "$status"
        ' sh {} \;
        echo
        
        echo "## أهداف الأقسام"
        echo
        find "$DEPT_DIR" -type f -name "*.json" -exec sh -c '
            dept_name=$(jq -r .name "$1")
            echo "### $dept_name"
            echo
            jq -r ".goals[] | \"- \(.title) (حتى \(.target_date)): \(.status)\"" "$1"
            echo
        ' sh {} \;
        
    } > "$report_file"
    
    echo -e "${GREEN}Department report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated department report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/department_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Department Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Add Department"
    echo -e "${YELLOW}2.${NC} Update Department"
    echo -e "${YELLOW}3.${NC} View Department"
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
            add_department
            ;;
        2)
            update_department
            ;;
        3)
            view_department
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/department_actions.log" ]; then
                less "$LOGS_DIR/department_actions.log"
            else
                echo -e "${YELLOW}No department logs found${NC}"
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
