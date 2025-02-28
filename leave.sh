#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LEAVE_DIR="./data/leave"
LOGS_DIR="./logs/leave"
REPORTS_DIR="./reports/leave"
TEMP_DIR="./temp/leave"

# Leave types
declare -A LEAVE_TYPES=(
    ["annual"]="إجازة سنوية"
    ["sick"]="إجازة مرضية"
    ["emergency"]="إجازة طارئة"
    ["unpaid"]="إجازة بدون راتب"
    ["other"]="إجازة أخرى"
)

# Leave status
declare -A LEAVE_STATUS=(
    ["pending"]="قيد الانتظار"
    ["approved"]="موافق عليها"
    ["rejected"]="مرفوضة"
    ["cancelled"]="ملغاة"
)

# Create directories
mkdir -p "$LEAVE_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to request leave
request_leave() {
    echo -e "${BLUE}Requesting leave...${NC}"
    
    read -p "Enter employee ID: " employee_id
    
    # Check if employee exists
    if [ ! -f "./data/employees/$employee_id.json" ]; then
        echo -e "${RED}Employee not found${NC}"
        return 1
    fi
    
    # Show leave types
    echo -e "\n${YELLOW}Available Leave Types:${NC}"
    for key in "${!LEAVE_TYPES[@]}"; do
        echo "$key) ${LEAVE_TYPES[$key]}"
    done
    
    read -p "Enter leave type: " leave_type
    
    if [ -z "${LEAVE_TYPES[$leave_type]}" ]; then
        echo -e "${RED}Invalid leave type${NC}"
        return 1
    fi
    
    read -p "Enter start date (YYYY-MM-DD): " start_date
    read -p "Enter end date (YYYY-MM-DD): " end_date
    read -p "Enter reason: " reason
    
    # Calculate number of days
    local days=$(( ($(date -d "$end_date" +%s) - $(date -d "$start_date" +%s)) / 86400 + 1 ))
    
    # Generate leave ID
    local leave_id="LEAVE$(date +%Y%m%d%H%M%S)"
    
    # Create leave request
    local leave_file="$LEAVE_DIR/${leave_id}.json"
    
    {
        echo "{"
        echo "  \"id\": \"$leave_id\","
        echo "  \"employee_id\": \"$employee_id\","
        echo "  \"type\": \"$leave_type\","
        echo "  \"start_date\": \"$start_date\","
        echo "  \"end_date\": \"$end_date\","
        echo "  \"days\": $days,"
        echo "  \"reason\": \"$reason\","
        echo "  \"status\": \"pending\","
        echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"approved_by\": null,"
        echo "  \"approved_at\": null,"
        echo "  \"comments\": []"
        echo "}"
    } > "$leave_file"
    
    echo -e "${GREEN}Leave request submitted successfully${NC}"
    echo "Leave ID: $leave_id"
    
    # Log action
    log_action "request" "$leave_id" "Requested $leave_type leave for $employee_id"
}

# Function to process leave request
process_leave() {
    echo -e "${BLUE}Processing leave request...${NC}"
    
    read -p "Enter leave ID: " leave_id
    
    local leave_file="$LEAVE_DIR/${leave_id}.json"
    
    if [ ! -f "$leave_file" ]; then
        echo -e "${RED}Leave request not found${NC}"
        return 1
    fi
    
    # Show current status
    echo -e "\nCurrent Status: $(jq -r .status "$leave_file")"
    
    # Show status options
    echo -e "\n${YELLOW}Available Status:${NC}"
    for key in "${!LEAVE_STATUS[@]}"; do
        echo "$key) ${LEAVE_STATUS[$key]}"
    done
    
    read -p "Enter new status: " status
    
    if [ -z "${LEAVE_STATUS[$status]}" ]; then
        echo -e "${RED}Invalid status${NC}"
        return 1
    fi
    
    read -p "Enter comment: " comment
    read -p "Enter your ID (approver): " approver_id
    
    # Update leave request
    jq --arg status "$status" \
       --arg approver "$approver_id" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --arg comment "$comment" \
       '.status = $status | 
        .approved_by = $approver | 
        .approved_at = $date | 
        .updated_at = $date | 
        .comments += [{
            "text": $comment,
            "by": $approver,
            "at": $date
        }]' "$leave_file" > "${leave_file}.tmp" && \
    mv "${leave_file}.tmp" "$leave_file"
    
    echo -e "${GREEN}Leave request processed successfully${NC}"
    
    # Log action
    log_action "process" "$leave_id" "Updated leave status to $status"
}

# Function to view leave requests
view_leave() {
    echo -e "${BLUE}Viewing leave requests...${NC}"
    
    read -p "Enter employee ID (or 'all'): " employee_id
    
    if [ "$employee_id" = "all" ]; then
        echo -e "\n${YELLOW}All Leave Requests:${NC}"
        echo "------------------------"
        
        for leave_file in "$LEAVE_DIR"/*.json; do
            if [ -f "$leave_file" ]; then
                local emp_id=$(jq -r .employee_id "$leave_file")
                local emp_name=$(jq -r .name "./data/employees/$emp_id.json")
                
                echo -e "\nLeave ID: $(jq -r .id "$leave_file")"
                echo "Employee: $emp_name"
                echo "Type: $(jq -r .type "$leave_file")"
                echo "Period: $(jq -r .start_date "$leave_file") to $(jq -r .end_date "$leave_file")"
                echo "Status: $(jq -r .status "$leave_file")"
                echo "------------------------"
            fi
        done
    else
        echo -e "\n${YELLOW}Leave Requests for Employee $employee_id:${NC}"
        echo "------------------------"
        
        find "$LEAVE_DIR" -type f -name "*.json" -exec sh -c '
            if [ "$(jq -r .employee_id "$1")" = "'$employee_id'" ]; then
                echo -e "\nLeave ID: $(jq -r .id "$1")"
                echo "Type: $(jq -r .type "$1")"
                echo "Period: $(jq -r .start_date "$1") to $(jq -r .end_date "$1")"
                echo "Status: $(jq -r .status "$1")"
                echo "------------------------"
            fi
        ' sh {} \;
    fi
    
    # Log action
    log_action "view" "$employee_id" "Viewed leave requests"
}

# Function to generate leave report
generate_report() {
    echo -e "${BLUE}Generating leave report...${NC}"
    
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    local report_file="$REPORTS_DIR/leave_${year}${month}.md"
    
    {
        echo "# تقرير الإجازات"
        echo "الفترة: $month/$year"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص الإجازات"
        echo
        
        # Calculate statistics
        for type in "${!LEAVE_TYPES[@]}"; do
            local count=$(find "$LEAVE_DIR" -type f -name "*.json" -exec sh -c '
                if [[ "$(jq -r .type "$1")" = "'$type'" && 
                     "$(jq -r .start_date "$1")" =~ ^'$year-$month' ]]; then
                    echo "1"
                fi
            ' sh {} \; | wc -l)
            
            echo "- ${LEAVE_TYPES[$type]}: $count"
        done
        echo
        
        echo "## حالة الإجازات"
        echo
        for status in "${!LEAVE_STATUS[@]}"; do
            local count=$(find "$LEAVE_DIR" -type f -name "*.json" -exec sh -c '
                if [[ "$(jq -r .status "$1")" = "'$status'" && 
                     "$(jq -r .start_date "$1")" =~ ^'$year-$month' ]]; then
                    echo "1"
                fi
            ' sh {} \; | wc -l)
            
            echo "- ${LEAVE_STATUS[$status]}: $count"
        done
        echo
        
        echo "## تفاصيل الإجازات"
        echo
        echo "| الموظف | نوع الإجازة | من | إلى | الأيام | الحالة |"
        echo "|---------|-------------|-----|-----|--------|---------|"
        
        find "$LEAVE_DIR" -type f -name "*.json" -exec sh -c '
            if [[ "$(jq -r .start_date "$1")" =~ ^'$year-$month' ]]; then
                emp_id=$(jq -r .employee_id "$1")
                emp_name=$(jq -r .name "./data/employees/$emp_id.json")
                printf "| %s | %s | %s | %s | %d | %s |\n" \
                    "$emp_name" \
                    "$(jq -r .type "$1")" \
                    "$(jq -r .start_date "$1")" \
                    "$(jq -r .end_date "$1")" \
                    "$(jq -r .days "$1")" \
                    "$(jq -r .status "$1")"
            fi
        ' sh {} \;
        
    } > "$report_file"
    
    echo -e "${GREEN}Leave report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated leave report for $month/$year"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/leave_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Leave Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Request Leave"
    echo -e "${YELLOW}2.${NC} Process Leave Request"
    echo -e "${YELLOW}3.${NC} View Leave Requests"
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
            request_leave
            ;;
        2)
            process_leave
            ;;
        3)
            view_leave
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/leave_actions.log" ]; then
                less "$LOGS_DIR/leave_actions.log"
            else
                echo -e "${YELLOW}No leave logs found${NC}"
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
