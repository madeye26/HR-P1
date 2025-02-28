#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOGS_DIR="./logs"
REPORTS_DIR="./reports/logs"
ARCHIVES_DIR="./archives/logs"
TEMP_DIR="./temp/logs"

# Log categories
declare -A LOG_CATEGORIES=(
    ["app"]="Application Logs"
    ["error"]="Error Logs"
    ["access"]="Access Logs"
    ["audit"]="Audit Logs"
    ["performance"]="Performance Logs"
    ["security"]="Security Logs"
)

# Create directories
mkdir -p "$LOGS_DIR" "$REPORTS_DIR" "$ARCHIVES_DIR" "$TEMP_DIR"

# Function to view logs
view_logs() {
    echo -e "${BLUE}Viewing logs...${NC}"
    
    # Show available log categories
    echo -e "\n${YELLOW}Available Log Categories:${NC}"
    for key in "${!LOG_CATEGORIES[@]}"; do
        echo "$key) ${LOG_CATEGORIES[$key]}"
    done
    
    read -p "Enter category: " category
    
    if [ -z "${LOG_CATEGORIES[$category]}" ]; then
        echo -e "${RED}Invalid category${NC}"
        return 1
    fi
    
    # Show log files
    local log_files=("$LOGS_DIR/$category"*.log)
    if [ ${#log_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No logs found for this category${NC}"
        return 1
    fi
    
    echo -e "\n${YELLOW}Available Log Files:${NC}"
    select log_file in "${log_files[@]}"; do
        if [ -n "$log_file" ]; then
            less "$log_file"
            break
        else
            echo -e "${RED}Invalid selection${NC}"
            return 1
        fi
    done
    
    # Log action
    log_action "view" "$category" "Viewed logs"
}

# Function to analyze logs
analyze_logs() {
    echo -e "${BLUE}Analyzing logs...${NC}"
    
    local report_file="$REPORTS_DIR/analysis_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تحليل السجلات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص السجلات"
        echo
        
        for category in "${!LOG_CATEGORIES[@]}"; do
            echo "### ${LOG_CATEGORIES[$category]}"
            echo "\`\`\`"
            
            # Count log entries
            local count=$(find "$LOGS_DIR" -name "${category}*.log" -exec cat {} \; | wc -l)
            echo "عدد السجلات: $count"
            
            # Show most common entries
            echo -e "\nالسجلات الأكثر تكراراً:"
            find "$LOGS_DIR" -name "${category}*.log" -exec cat {} \; | \
            sort | uniq -c | sort -nr | head -n 5
            
            echo "\`\`\`"
            echo
        done
        
        echo "## تحليل الأخطاء"
        echo "\`\`\`"
        find "$LOGS_DIR" -name "error*.log" -exec grep -h "ERROR\|FATAL\|CRITICAL" {} \; | \
        sort | uniq -c | sort -nr | head -n 10
        echo "\`\`\`"
        echo
        
        echo "## إحصائيات السجلات"
        echo "- حجم السجلات: $(du -sh "$LOGS_DIR" | cut -f1)"
        echo "- عدد الملفات: $(find "$LOGS_DIR" -type f -name "*.log" | wc -l)"
        echo "- أقدم سجل: $(find "$LOGS_DIR" -type f -name "*.log" -exec ls -lt {} \; | tail -n 1)"
        echo "- أحدث سجل: $(find "$LOGS_DIR" -type f -name "*.log" -exec ls -lt {} \; | head -n 1)"
        
    } > "$report_file"
    
    echo -e "${GREEN}Log analysis report generated: $report_file${NC}"
    
    # Log action
    log_action "analyze" "all" "Generated log analysis report"
}

# Function to rotate logs
rotate_logs() {
    echo -e "${BLUE}Rotating logs...${NC}"
    
    # Archive logs older than 30 days
    local archive_name="logs_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    find "$LOGS_DIR" -type f -name "*.log" -mtime +30 -print0 | \
    tar czf "$ARCHIVES_DIR/$archive_name" --null -T -
    
    # Remove archived logs
    find "$LOGS_DIR" -type f -name "*.log" -mtime +30 -delete
    
    echo -e "${GREEN}Logs rotated and archived: $archive_name${NC}"
    
    # Log action
    log_action "rotate" "all" "Rotated and archived logs"
}

# Function to clean logs
clean_logs() {
    echo -e "${BLUE}Cleaning logs...${NC}"
    
    read -p "This will clean all logs older than 90 days. Continue? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        # Archive before cleaning
        local archive_name="logs_pre_clean_$(date +%Y%m%d_%H%M%S).tar.gz"
        tar czf "$ARCHIVES_DIR/$archive_name" "$LOGS_DIR"
        
        # Remove old logs
        find "$LOGS_DIR" -type f -name "*.log" -mtime +90 -delete
        
        # Remove empty directories
        find "$LOGS_DIR" -type d -empty -delete
        
        echo -e "${GREEN}Logs cleaned${NC}"
        
        # Log action
        log_action "clean" "all" "Cleaned logs older than 90 days"
    else
        echo -e "${YELLOW}Log cleaning cancelled${NC}"
    fi
}

# Function to search logs
search_logs() {
    echo -e "${BLUE}Searching logs...${NC}"
    
    read -p "Enter search term: " search_term
    read -p "Enter date range (YYYY-MM-DD YYYY-MM-DD) or press enter for all: " start_date end_date
    
    local report_file="$REPORTS_DIR/search_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# نتائج البحث في السجلات"
        echo "مصطلح البحث: $search_term"
        echo "تاريخ البحث: $(date)"
        echo
        
        if [ -n "$start_date" ] && [ -n "$end_date" ]; then
            echo "نطاق التاريخ: $start_date إلى $end_date"
            echo
            
            find "$LOGS_DIR" -type f -name "*.log" -exec sh -c "
                awk -v start=\"\$(date -d \"$start_date\" +%s)\" \
                    -v end=\"\$(date -d \"$end_date\" +%s)\" \
                    -v term=\"$search_term\" \
                '
                {
                    logdate = \$(date -d substr(\$0, 1, 19) +%s)
                    if (logdate >= start && logdate <= end && \$0 ~ term)
                        print FILENAME \":\", \$0
                }
                ' {} \;" \;
        else
            find "$LOGS_DIR" -type f -name "*.log" -exec grep -H "$search_term" {} \;
        fi
        
    } > "$report_file"
    
    echo -e "${GREEN}Search results saved to: $report_file${NC}"
    
    # Log action
    log_action "search" "$search_term" "Searched logs"
}

# Function to export logs
export_logs() {
    echo -e "${BLUE}Exporting logs...${NC}"
    
    read -p "Enter export format (json/csv): " format
    
    local export_file="$REPORTS_DIR/logs_export_$(date +%Y%m%d_%H%M%S).$format"
    
    case $format in
        json)
            # Convert logs to JSON format
            {
                echo "{"
                echo "  \"logs\": ["
                find "$LOGS_DIR" -type f -name "*.log" -exec cat {} \; | \
                awk '{printf "    {\"timestamp\":\"%s\",\"message\":\"%s\"},\n", $1, substr($0,index($0,$2))}' | \
                sed '$ s/,$//'
                echo "  ]"
                echo "}"
            } > "$export_file"
            ;;
        csv)
            # Convert logs to CSV format
            {
                echo "timestamp,category,message"
                find "$LOGS_DIR" -type f -name "*.log" -exec cat {} \; | \
                awk -F'[][]' '{printf "%s,%s,%s\n", $1, $2, $3}'
            } > "$export_file"
            ;;
        *)
            echo -e "${RED}Invalid format${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Logs exported to: $export_file${NC}"
    
    # Log action
    log_action "export" "$format" "Exported logs"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/logs_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Logs Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} View Logs"
    echo -e "${YELLOW}2.${NC} Analyze Logs"
    echo -e "${YELLOW}3.${NC} Rotate Logs"
    echo -e "${YELLOW}4.${NC} Clean Logs"
    echo -e "${YELLOW}5.${NC} Search Logs"
    echo -e "${YELLOW}6.${NC} Export Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-6): " choice
    
    case $choice in
        1)
            view_logs
            ;;
        2)
            analyze_logs
            ;;
        3)
            rotate_logs
            ;;
        4)
            clean_logs
            ;;
        5)
            search_logs
            ;;
        6)
            export_logs
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
