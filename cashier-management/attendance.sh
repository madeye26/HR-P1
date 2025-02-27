#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ATTENDANCE_DIR="./data/attendance"
LOGS_DIR="./logs/attendance"
REPORTS_DIR="./reports/attendance"
TEMP_DIR="./temp/attendance"

# Attendance status types
declare -A ATTENDANCE_STATUS=(
    ["present"]="حاضر"
    ["absent"]="غائب"
    ["late"]="متأخر"
    ["leave"]="إجازة"
    ["sick"]="مريض"
)

# Create directories
mkdir -p "$ATTENDANCE_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to record attendance
record_attendance() {
    echo -e "${BLUE}Recording attendance...${NC}"
    
    read -p "Enter employee ID: " employee_id
    
    # Check if employee exists
    if [ ! -f "./data/employees/$employee_id.json" ]; then
        echo -e "${RED}Employee not found${NC}"
        return 1
    fi
    
    # Get current date
    local date=$(date +%Y%m%d)
    local attendance_file="$ATTENDANCE_DIR/${employee_id}_${date}.json"
    
    # Check if attendance already recorded
    if [ -f "$attendance_file" ]; then
        echo -e "${YELLOW}Attendance already recorded for today${NC}"
        return 1
    fi
    
    # Show status options
    echo -e "\n${YELLOW}Available Status:${NC}"
    for key in "${!ATTENDANCE_STATUS[@]}"; do
        echo "$key) ${ATTENDANCE_STATUS[$key]}"
    done
    
    read -p "Enter status: " status
    
    if [ -z "${ATTENDANCE_STATUS[$status]}" ]; then
        echo -e "${RED}Invalid status${NC}"
        return 1
    fi
    
    # Get time
    read -p "Enter check-in time (HH:MM, press enter for current time): " check_in
    check_in=${check_in:-$(date +%H:%M)}
    
    # Calculate if late
    if [ "$status" = "present" ] && [ "$(date -d "$check_in" +%s)" -gt "$(date -d "09:00" +%s)" ]; then
        status="late"
    fi
    
    # Record overtime if applicable
    local overtime=0
    if [ "$status" = "present" ]; then
        read -p "Enter overtime hours (0 for none): " overtime
    fi
    
    # Create attendance record
    {
        echo "{"
        echo "  \"employee_id\": \"$employee_id\","
        echo "  \"date\": \"$date\","
        echo "  \"status\": \"$status\","
        echo "  \"check_in\": \"$check_in\","
        echo "  \"check_out\": null,"
        echo "  \"overtime\": $overtime,"
        echo "  \"notes\": \"\","
        echo "  \"recorded_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
        echo "}"
    } > "$attendance_file"
    
    echo -e "${GREEN}Attendance recorded successfully${NC}"
    
    # Log action
    log_action "record" "$employee_id" "Recorded attendance: $status"
}

# Function to update attendance
update_attendance() {
    echo -e "${BLUE}Updating attendance...${NC}"
    
    read -p "Enter employee ID: " employee_id
    read -p "Enter date (YYYYMMDD, press enter for today): " date
    date=${date:-$(date +%Y%m%d)}
    
    local attendance_file="$ATTENDANCE_DIR/${employee_id}_${date}.json"
    
    if [ ! -f "$attendance_file" ]; then
        echo -e "${RED}Attendance record not found${NC}"
        return 1
    fi
    
    echo "1. Update check-out time"
    echo "2. Update overtime"
    echo "3. Add notes"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            read -p "Enter check-out time (HH:MM, press enter for current time): " check_out
            check_out=${check_out:-$(date +%H:%M)}
            
            jq --arg time "$check_out" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.check_out = $time | .updated_at = $date' "$attendance_file" > "${attendance_file}.tmp" && \
            mv "${attendance_file}.tmp" "$attendance_file"
            ;;
        2)
            read -p "Enter overtime hours: " overtime
            
            jq --arg overtime "$overtime" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.overtime = ($overtime|tonumber) | .updated_at = $date' "$attendance_file" > "${attendance_file}.tmp" && \
            mv "${attendance_file}.tmp" "$attendance_file"
            ;;
        3)
            read -p "Enter notes: " notes
            
            jq --arg notes "$notes" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.notes = $notes | .updated_at = $date' "$attendance_file" > "${attendance_file}.tmp" && \
            mv "${attendance_file}.tmp" "$attendance_file"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Attendance updated successfully${NC}"
    
    # Log action
    log_action "update" "$employee_id" "Updated attendance for $date"
}

# Function to view attendance
view_attendance() {
    echo -e "${BLUE}Viewing attendance...${NC}"
    
    read -p "Enter employee ID (or 'all'): " employee_id
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    if [ "$employee_id" = "all" ]; then
        echo -e "\n${YELLOW}Attendance Summary for $month/$year:${NC}"
        echo "------------------------"
        
        for employee_file in ./data/employees/*.json; do
            local emp_id=$(basename "$employee_file" .json)
            local emp_name=$(jq -r .name "$employee_file")
            echo -e "\nEmployee: $emp_name ($emp_id)"
            
            local present=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "present") | .date' {} \; | wc -l)
            local absent=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "absent") | .date' {} \; | wc -l)
            local late=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "late") | .date' {} \; | wc -l)
            
            echo "Present: $present days"
            echo "Absent: $absent days"
            echo "Late: $late days"
        done
    else
        if [ ! -f "./data/employees/$employee_id.json" ]; then
            echo -e "${RED}Employee not found${NC}"
            return 1
        fi
        
        local employee_name=$(jq -r .name "./data/employees/$employee_id.json")
        echo -e "\n${YELLOW}Attendance Details for $employee_name:${NC}"
        echo "------------------------"
        
        find "$ATTENDANCE_DIR" -name "${employee_id}_${year}${month}*.json" -exec sh -c '
            for file do
                echo -e "\nDate: $(jq -r .date "$file")"
                echo "Status: $(jq -r .status "$file")"
                echo "Check-in: $(jq -r .check_in "$file")"
                echo "Check-out: $(jq -r .check_out "$file")"
                echo "Overtime: $(jq -r .overtime "$file") hours"
                echo "------------------------"
            done
        ' sh {} +
    fi
    
    # Log action
    log_action "view" "$employee_id" "Viewed attendance for $month/$year"
}

# Function to generate attendance report
generate_report() {
    echo -e "${BLUE}Generating attendance report...${NC}"
    
    read -p "Enter month (MM): " month
    read -p "Enter year (YYYY): " year
    
    local report_file="$REPORTS_DIR/attendance_${year}${month}.md"
    
    {
        echo "# تقرير الحضور والانصراف"
        echo "الفترة: $month/$year"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص الحضور"
        echo
        
        # Calculate totals
        local total_employees=$(ls ./data/employees/*.json 2>/dev/null | wc -l)
        local total_present=0
        local total_absent=0
        local total_late=0
        local total_overtime=0
        
        for employee_file in ./data/employees/*.json; do
            local emp_id=$(basename "$employee_file" .json)
            
            # Count attendance types
            local present=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "present") | .date' {} \; | wc -l)
            local absent=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "absent") | .date' {} \; | wc -l)
            local late=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "late") | .date' {} \; | wc -l)
            local overtime=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r '.overtime // 0' {} \; | awk '{sum += $1} END {print sum}')
            
            ((total_present += present))
            ((total_absent += absent))
            ((total_late += late))
            total_overtime=$(echo "$total_overtime + $overtime" | bc)
        done
        
        echo "- إجمالي الموظفين: $total_employees"
        echo "- إجمالي أيام الحضور: $total_present"
        echo "- إجمالي أيام الغياب: $total_absent"
        echo "- إجمالي حالات التأخير: $total_late"
        echo "- إجمالي ساعات العمل الإضافي: $total_overtime"
        echo
        
        echo "## تفاصيل الحضور حسب الموظف"
        echo
        echo "| الموظف | الحضور | الغياب | التأخير | العمل الإضافي |"
        echo "|---------|----------|---------|-----------|----------------|"
        
        for employee_file in ./data/employees/*.json; do
            local emp_id=$(basename "$employee_file" .json)
            local emp_name=$(jq -r .name "$employee_file")
            
            local present=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "present") | .date' {} \; | wc -l)
            local absent=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "absent") | .date' {} \; | wc -l)
            local late=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r 'select(.status == "late") | .date' {} \; | wc -l)
            local overtime=$(find "$ATTENDANCE_DIR" -name "${emp_id}_${year}${month}*.json" -exec jq -r '.overtime // 0' {} \; | awk '{sum += $1} END {print sum}')
            
            printf "| %s | %d | %d | %d | %.1f |\n" \
                "$emp_name" "$present" "$absent" "$late" "$overtime"
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Attendance report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated attendance report for $month/$year"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/attendance_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Attendance Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Record Attendance"
    echo -e "${YELLOW}2.${NC} Update Attendance"
    echo -e "${YELLOW}3.${NC} View Attendance"
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
            record_attendance
            ;;
        2)
            update_attendance
            ;;
        3)
            view_attendance
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/attendance_actions.log" ]; then
                less "$LOGS_DIR/attendance_actions.log"
            else
                echo -e "${YELLOW}No attendance logs found${NC}"
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
