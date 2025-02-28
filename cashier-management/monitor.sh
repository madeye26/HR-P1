#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MONITOR_DIR="./monitor"
LOGS_DIR="./logs/monitor"
REPORTS_DIR="./reports/monitor"
ALERTS_DIR="./alerts/monitor"

# Create directories
mkdir -p "$MONITOR_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$ALERTS_DIR"

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=90
API_TIMEOUT=5

# Function to monitor system resources
monitor_resources() {
    echo -e "${BLUE}Monitoring system resources...${NC}"
    
    local report_file="$REPORTS_DIR/resources_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير موارد النظام"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## استخدام المعالج"
        echo "\`\`\`"
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
        echo "\`\`\`"
        echo
        
        echo "## استخدام الذاكرة"
        echo "\`\`\`"
        free -h
        echo "\`\`\`"
        echo
        
        echo "## استخدام القرص"
        echo "\`\`\`"
        df -h
        echo "\`\`\`"
        echo
        
        echo "## العمليات النشطة"
        echo "\`\`\`"
        ps aux | head -n 11
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Resource monitoring report generated: $report_file${NC}"
    
    # Check thresholds and generate alerts
    check_thresholds
    
    # Log action
    log_action "monitor" "resources" "Generated resource monitoring report"
}

# Function to monitor application
monitor_application() {
    echo -e "${BLUE}Monitoring application...${NC}"
    
    local report_file="$REPORTS_DIR/application_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير حالة التطبيق"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## حالة الخدمات"
        echo "\`\`\`"
        # Check Node.js process
        pgrep -l "node"
        # Check database
        if nc -z localhost 5432; then
            echo "Database: Running"
        else
            echo "Database: Not running"
        fi
        # Check Redis
        if nc -z localhost 6379; then
            echo "Redis: Running"
        else
            echo "Redis: Not running"
        fi
        echo "\`\`\`"
        echo
        
        echo "## نقاط النهاية API"
        echo "\`\`\`"
        # Check API endpoints
        curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health
        echo "\`\`\`"
        echo
        
        echo "## سجلات الأخطاء"
        echo "\`\`\`"
        if [ -f "./logs/error.log" ]; then
            tail -n 10 "./logs/error.log"
        else
            echo "No error logs found"
        fi
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Application monitoring report generated: $report_file${NC}"
    
    # Log action
    log_action "monitor" "application" "Generated application monitoring report"
}

# Function to monitor performance
monitor_performance() {
    echo -e "${BLUE}Monitoring performance...${NC}"
    
    local report_file="$REPORTS_DIR/performance_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير الأداء"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## أداء الذاكرة"
        echo "\`\`\`"
        if [ -f "./logs/performance.log" ]; then
            grep "memory" "./logs/performance.log" | tail -n 10
        else
            echo "No performance logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## أوقات الاستجابة"
        echo "\`\`\`"
        if [ -f "./logs/access.log" ]; then
            awk '{print $NF}' "./logs/access.log" | \
            awk '{ total += $1; count++ } END { print "Average response time:", total/count, "ms" }'
        else
            echo "No access logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## استخدام الموارد"
        echo "\`\`\`"
        top -bn1 | head -n 12
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Performance monitoring report generated: $report_file${NC}"
    
    # Log action
    log_action "monitor" "performance" "Generated performance monitoring report"
}

# Function to monitor security
monitor_security() {
    echo -e "${BLUE}Monitoring security...${NC}"
    
    local report_file="$REPORTS_DIR/security_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير الأمان"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## محاولات تسجيل الدخول الفاشلة"
        echo "\`\`\`"
        if [ -f "./logs/auth.log" ]; then
            grep "Failed login" "./logs/auth.log" | tail -n 10
        else
            echo "No authentication logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## محاولات الوصول غير المصرح به"
        echo "\`\`\`"
        if [ -f "./logs/access.log" ]; then
            grep "403\|401" "./logs/access.log" | tail -n 10
        else
            echo "No access logs found"
        fi
        echo "\`\`\`"
        echo
        
        echo "## تحديثات الأمان المطلوبة"
        echo "\`\`\`"
        npm audit
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Security monitoring report generated: $report_file${NC}"
    
    # Log action
    log_action "monitor" "security" "Generated security monitoring report"
}

# Function to check thresholds and generate alerts
check_thresholds() {
    # Check CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    if [ $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) -eq 1 ]; then
        generate_alert "CPU" "High CPU usage: $cpu_usage%"
    fi
    
    # Check memory usage
    local memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    if [ $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) -eq 1 ]; then
        generate_alert "Memory" "High memory usage: $memory_usage%"
    fi
    
    # Check disk usage
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        generate_alert "Disk" "High disk usage: $disk_usage%"
    fi
}

# Function to generate alert
generate_alert() {
    local type=$1
    local message=$2
    
    local alert_file="$ALERTS_DIR/alert_$(date +%Y%m%d_%H%M%S).json"
    
    # Create alert
    cat > "$alert_file" << EOL
{
    "type": "$type",
    "message": "$message",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "severity": "high"
}
EOL
    
    # Send notification
    if [ -f "./notify.sh" ]; then
        ./notify.sh "$type Alert" "$message"
    fi
    
    # Log action
    log_action "alert" "$type" "$message"
}

# Function to view alerts
view_alerts() {
    echo -e "${BLUE}Recent Alerts${NC}"
    echo "------------------------"
    
    if [ -d "$ALERTS_DIR" ]; then
        for alert in $(ls -t "$ALERTS_DIR"/*.json 2>/dev/null | head -n 5); do
            jq -r '"\(.timestamp) [\(.type)] \(.message)"' "$alert"
        done
    else
        echo -e "${YELLOW}No alerts found${NC}"
    fi
}

# Function to generate comprehensive report
generate_report() {
    echo -e "${BLUE}Generating comprehensive monitoring report...${NC}"
    
    local report_file="$REPORTS_DIR/monitoring_$(date +%Y%m%d).md"
    
    {
        echo "# تقرير المراقبة الشامل"
        echo "تاريخ التقرير: $(date)"
        echo
        
        # Include resource monitoring
        monitor_resources > /dev/null
        echo "## موارد النظام"
        cat "$REPORTS_DIR/resources_"*
        echo
        
        # Include application monitoring
        monitor_application > /dev/null
        echo "## حالة التطبيق"
        cat "$REPORTS_DIR/application_"*
        echo
        
        # Include performance monitoring
        monitor_performance > /dev/null
        echo "## الأداء"
        cat "$REPORTS_DIR/performance_"*
        echo
        
        # Include security monitoring
        monitor_security > /dev/null
        echo "## الأمان"
        cat "$REPORTS_DIR/security_"*
        
    } > "$report_file"
    
    echo -e "${GREEN}Comprehensive monitoring report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "comprehensive" "Generated comprehensive monitoring report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/monitor_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Monitoring Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Monitor System Resources"
    echo -e "${YELLOW}2.${NC} Monitor Application"
    echo -e "${YELLOW}3.${NC} Monitor Performance"
    echo -e "${YELLOW}4.${NC} Monitor Security"
    echo -e "${YELLOW}5.${NC} View Alerts"
    echo -e "${YELLOW}6.${NC} Generate Comprehensive Report"
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
            monitor_resources
            ;;
        2)
            monitor_application
            ;;
        3)
            monitor_performance
            ;;
        4)
            monitor_security
            ;;
        5)
            view_alerts
            ;;
        6)
            generate_report
            ;;
        7)
            if [ -f "$LOGS_DIR/monitor_actions.log" ]; then
                less "$LOGS_DIR/monitor_actions.log"
            else
                echo -e "${YELLOW}No monitoring logs found${NC}"
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
