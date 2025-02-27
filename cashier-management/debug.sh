#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEBUG_DIR="./debug"
LOGS_DIR="./logs/debug"
REPORTS_DIR="./reports/debug"
TEMP_DIR="./temp/debug"

# Create directories
mkdir -p "$DEBUG_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to analyze error logs
analyze_errors() {
    echo -e "${BLUE}Analyzing error logs...${NC}"
    
    local report_file="$REPORTS_DIR/error_analysis_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحليل الأخطاء"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## أخطاء التطبيق"
        echo "\`\`\`"
        if [ -f "./logs/error.log" ]; then
            # Group errors by type and count occurrences
            sort "./logs/error.log" | uniq -c | sort -nr
        else
            echo "No error logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## الأخطاء المتكررة"
        echo "\`\`\`"
        if [ -f "./logs/error.log" ]; then
            # Find most frequent errors
            grep -i "error\|exception\|fail" "./logs/error.log" | \
            sort | uniq -c | sort -nr | head -n 10
        else
            echo "No error patterns found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## تتبع الأخطاء"
        echo "\`\`\`"
        if [ -f "./logs/error.log" ]; then
            # Extract stack traces
            grep -A 5 "Stack trace:" "./logs/error.log" | tail -n 20
        else
            echo "No stack traces found"
        fi
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Error analysis report generated: $report_file${NC}"
    
    # Log action
    log_action "analyze" "errors" "Generated error analysis report"
}

# Function to trace API calls
trace_api() {
    echo -e "${BLUE}Tracing API calls...${NC}"
    
    local report_file="$REPORTS_DIR/api_trace_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تتبع نداءات API"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## نداءات API الأخيرة"
        echo "\`\`\`"
        if [ -f "./logs/access.log" ]; then
            # Extract API calls with timing
            grep "api" "./logs/access.log" | \
            awk '{print $4, $5, $7, $10}' | \
            tail -n 20
        else
            echo "No API logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## نداءات API البطيئة"
        echo "\`\`\`"
        if [ -f "./logs/access.log" ]; then
            # Find slow API calls (>1s)
            awk '$10 > 1000 {print}' "./logs/access.log" | \
            grep "api" | tail -n 10
        else
            echo "No slow API calls found"
        fi
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}API trace report generated: $report_file${NC}"
    
    # Log action
    log_action "trace" "api" "Generated API trace report"
}

# Function to analyze memory usage
analyze_memory() {
    echo -e "${BLUE}Analyzing memory usage...${NC}"
    
    local report_file="$REPORTS_DIR/memory_analysis_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحليل استخدام الذاكرة"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## استخدام الذاكرة الحالي"
        echo "\`\`\`"
        free -h
        echo "\`\`\`"
        echo
        
        echo "## استخدام الذاكرة للعمليات"
        echo "\`\`\`"
        ps aux --sort=-%mem | head -n 11
        echo "\`\`\`"
        echo
        
        echo "## تسريبات الذاكرة المحتملة"
        echo "\`\`\`"
        if [ -f "./logs/memory.log" ]; then
            # Find increasing memory patterns
            grep "Memory usage" "./logs/memory.log" | \
            awk '{print $4}' | \
            sort -n | uniq -c
        else
            echo "No memory logs found"
        fi
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Memory analysis report generated: $report_file${NC}"
    
    # Log action
    log_action "analyze" "memory" "Generated memory analysis report"
}

# Function to debug performance issues
debug_performance() {
    echo -e "${BLUE}Debugging performance issues...${NC}"
    
    local report_file="$REPORTS_DIR/performance_debug_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تصحيح مشاكل الأداء"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## أوقات الاستجابة"
        echo "\`\`\`"
        if [ -f "./logs/access.log" ]; then
            # Calculate average response times
            awk '{sum+=$10; count++} END {print "Average response time:", sum/count, "ms"}' \
                "./logs/access.log"
        else
            echo "No access logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## النقاط الساخنة"
        echo "\`\`\`"
        if [ -f "./logs/performance.log" ]; then
            # Find performance bottlenecks
            grep -i "slow\|timeout\|bottleneck" "./logs/performance.log" | \
            sort | uniq -c | sort -nr
        else
            echo "No performance logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## استخدام المعالج"
        echo "\`\`\`"
        top -bn1 | head -n 12
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Performance debug report generated: $report_file${NC}"
    
    # Log action
    log_action "debug" "performance" "Generated performance debug report"
}

# Function to debug database issues
debug_database() {
    echo -e "${BLUE}Debugging database issues...${NC}"
    
    local report_file="$REPORTS_DIR/database_debug_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تصحيح مشاكل قاعدة البيانات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## حالة قاعدة البيانات"
        echo "\`\`\`"
        if nc -z localhost 5432; then
            echo "Database is running"
            # Add more database checks here
        else
            echo "Database is not running"
        fi
        echo "\`\`\`"
        echo
        
        echo "## أخطاء قاعدة البيانات"
        echo "\`\`\`"
        if [ -f "./logs/db.log" ]; then
            grep -i "error\|fail\|timeout" "./logs/db.log" | tail -n 20
        else
            echo "No database logs found"
        fi
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Database debug report generated: $report_file${NC}"
    
    # Log action
    log_action "debug" "database" "Generated database debug report"
}

# Function to start debug mode
start_debug() {
    echo -e "${BLUE}Starting application in debug mode...${NC}"
    
    # Set debug environment variables
    export DEBUG=true
    export NODE_ENV=development
    export LOG_LEVEL=debug
    
    # Start application with debugging enabled
    if node --inspect app.js; then
        echo -e "${GREEN}Application started in debug mode${NC}"
        echo "Debug port: 9229"
        
        # Log action
        log_action "start" "debug" "Started application in debug mode"
    else
        echo -e "${RED}Failed to start debug mode${NC}"
        return 1
    fi
}

# Function to collect debug information
collect_debug_info() {
    echo -e "${BLUE}Collecting debug information...${NC}"
    
    local debug_file="$DEBUG_DIR/debug_info_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Create temporary directory for debug info
    local temp_dir="$TEMP_DIR/debug_info"
    mkdir -p "$temp_dir"
    
    # Copy logs
    cp -r ./logs "$temp_dir/"
    
    # Copy configuration
    cp -r ./config "$temp_dir/"
    
    # Copy package info
    cp package.json "$temp_dir/"
    
    # Create system info file
    {
        echo "System Information"
        echo "=================="
        echo "Date: $(date)"
        echo "Node Version: $(node -v)"
        echo "NPM Version: $(npm -v)"
        echo "OS: $(uname -a)"
        echo
        echo "Process List"
        echo "============"
        ps aux | grep -i "node\|npm"
        echo
        echo "Memory Usage"
        echo "============"
        free -h
        echo
        echo "Disk Usage"
        echo "=========="
        df -h
    } > "$temp_dir/system_info.txt"
    
    # Create archive
    tar -czf "$debug_file" -C "$TEMP_DIR" debug_info
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}Debug information collected: $debug_file${NC}"
    
    # Log action
    log_action "collect" "debug_info" "Collected debug information"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/debug_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Debug Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Analyze Error Logs"
    echo -e "${YELLOW}2.${NC} Trace API Calls"
    echo -e "${YELLOW}3.${NC} Analyze Memory Usage"
    echo -e "${YELLOW}4.${NC} Debug Performance Issues"
    echo -e "${YELLOW}5.${NC} Debug Database Issues"
    echo -e "${YELLOW}6.${NC} Start Debug Mode"
    echo -e "${YELLOW}7.${NC} Collect Debug Information"
    echo -e "${YELLOW}8.${NC} View Debug Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-8): " choice
    
    case $choice in
        1)
            analyze_errors
            ;;
        2)
            trace_api
            ;;
        3)
            analyze_memory
            ;;
        4)
            debug_performance
            ;;
        5)
            debug_database
            ;;
        6)
            start_debug
            ;;
        7)
            collect_debug_info
            ;;
        8)
            if [ -f "$LOGS_DIR/debug_actions.log" ]; then
                less "$LOGS_DIR/debug_actions.log"
            else
                echo -e "${YELLOW}No debug logs found${NC}"
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
