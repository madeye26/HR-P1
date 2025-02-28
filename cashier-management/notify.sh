#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NOTIFY_DIR="./notifications"
LOGS_DIR="./logs/notifications"
REPORTS_DIR="./reports/notifications"
TEMPLATES_DIR="./templates/notifications"

# Notification types
declare -A NOTIFICATION_TYPES=(
    ["system"]="إشعارات النظام"
    ["inventory"]="إشعارات المخزون"
    ["sales"]="إشعارات المبيعات"
    ["employee"]="إشعارات الموظفين"
    ["security"]="إشعارات الأمان"
)

# Notification priorities
declare -A NOTIFICATION_PRIORITIES=(
    ["high"]="عالي"
    ["medium"]="متوسط"
    ["low"]="منخفض"
)

# Create directories
mkdir -p "$NOTIFY_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMPLATES_DIR"
for type in "${!NOTIFICATION_TYPES[@]}"; do
    mkdir -p "$NOTIFY_DIR/$type"
done

# Function to send notification
send_notification() {
    echo -e "${BLUE}Sending notification...${NC}"
    
    # Show notification types
    echo -e "\n${YELLOW}Available Notification Types:${NC}"
    for key in "${!NOTIFICATION_TYPES[@]}"; do
        echo "$key) ${NOTIFICATION_TYPES[$key]}"
    done
    
    read -p "Enter notification type: " type
    
    if [ -z "${NOTIFICATION_TYPES[$type]}" ]; then
        echo -e "${RED}Invalid notification type${NC}"
        return 1
    fi
    
    # Show priorities
    echo -e "\n${YELLOW}Available Priorities:${NC}"
    for key in "${!NOTIFICATION_PRIORITIES[@]}"; do
        echo "$key) ${NOTIFICATION_PRIORITIES[$key]}"
    done
    
    read -p "Enter priority: " priority
    
    if [ -z "${NOTIFICATION_PRIORITIES[$priority]}" ]; then
        echo -e "${RED}Invalid priority${NC}"
        return 1
    fi
    
    read -p "Enter notification title: " title
    read -p "Enter notification message: " message
    read -p "Enter recipient(s) (comma-separated): " recipients
    
    # Generate notification ID
    local id="NOTIF$(date +%Y%m%d%H%M%S)"
    
    # Create notification file
    local notif_file="$NOTIFY_DIR/$type/$id.json"
    
    {
        echo "{"
        echo "  \"id\": \"$id\","
        echo "  \"type\": \"$type\","
        echo "  \"priority\": \"$priority\","
        echo "  \"title\": \"$title\","
        echo "  \"message\": \"$message\","
        echo "  \"recipients\": [$(echo $recipients | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')],"
        echo "  \"status\": \"pending\","
        echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"sent_at\": null"
        echo "}"
    } > "$notif_file"
    
    # Send notification based on type
    case $type in
        system)
            # Send system notification
            echo -e "${YELLOW}System notification: $title${NC}"
            echo "$message"
            ;;
        inventory)
            # Send inventory notification
            echo -e "${YELLOW}Inventory alert: $title${NC}"
            echo "$message"
            ;;
        sales)
            # Send sales notification
            echo -e "${YELLOW}Sales update: $title${NC}"
            echo "$message"
            ;;
        employee)
            # Send employee notification
            echo -e "${YELLOW}Employee notice: $title${NC}"
            echo "$message"
            ;;
        security)
            # Send security notification
            echo -e "${RED}Security alert: $title${NC}"
            echo "$message"
            ;;
    esac
    
    # Update notification status
    jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.status = "sent" | .sent_at = $date' "$notif_file" > "${notif_file}.tmp" && \
    mv "${notif_file}.tmp" "$notif_file"
    
    echo -e "${GREEN}Notification sent with ID: $id${NC}"
    
    # Log action
    log_action "send" "$id" "Sent $type notification: $title"
}

# Function to view notifications
view_notifications() {
    echo -e "${BLUE}Viewing notifications...${NC}"
    
    # Show notification types
    echo -e "\n${YELLOW}Available Notification Types:${NC}"
    for key in "${!NOTIFICATION_TYPES[@]}"; do
        echo "$key) ${NOTIFICATION_TYPES[$key]}"
    done
    
    read -p "Enter notification type (or 'all'): " type
    
    if [ "$type" != "all" ] && [ -z "${NOTIFICATION_TYPES[$type]}" ]; then
        echo -e "${RED}Invalid notification type${NC}"
        return 1
    fi
    
    # Display notifications
    if [ "$type" = "all" ]; then
        find "$NOTIFY_DIR" -type f -name "*.json" -exec sh -c '
            echo -e "\n${YELLOW}$(jq -r .type {})${NC}"
            echo "ID: $(jq -r .id {})"
            echo "Title: $(jq -r .title {})"
            echo "Priority: $(jq -r .priority {})"
            echo "Status: $(jq -r .status {})"
            echo "Created: $(jq -r .created_at {})"
        ' \;
    else
        find "$NOTIFY_DIR/$type" -type f -name "*.json" -exec sh -c '
            echo -e "\n${YELLOW}Notification Details:${NC}"
            echo "ID: $(jq -r .id {})"
            echo "Title: $(jq -r .title {})"
            echo "Message: $(jq -r .message {})"
            echo "Priority: $(jq -r .priority {})"
            echo "Status: $(jq -r .status {})"
            echo "Created: $(jq -r .created_at {})"
            echo "Sent: $(jq -r .sent_at {})"
        ' \;
    fi
    
    # Log action
    log_action "view" "$type" "Viewed notifications"
}

# Function to manage notification templates
manage_templates() {
    echo -e "${BLUE}Managing notification templates...${NC}"
    
    echo "1. Create template"
    echo "2. View templates"
    echo "3. Use template"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            read -p "Enter template name: " name
            read -p "Enter template title: " title
            read -p "Enter template message: " message
            
            local template_file="$TEMPLATES_DIR/${name}.json"
            
            {
                echo "{"
                echo "  \"name\": \"$name\","
                echo "  \"title\": \"$title\","
                echo "  \"message\": \"$message\","
                echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
                echo "}"
            } > "$template_file"
            
            echo -e "${GREEN}Template created: $name${NC}"
            ;;
        2)
            echo -e "\n${YELLOW}Available Templates:${NC}"
            find "$TEMPLATES_DIR" -type f -name "*.json" -exec sh -c '
                echo "\nTemplate: $(jq -r .name {})"
                echo "Title: $(jq -r .title {})"
                echo "Message: $(jq -r .message {})"
            ' \;
            ;;
        3)
            echo -e "\n${YELLOW}Available Templates:${NC}"
            ls -1 "$TEMPLATES_DIR"/*.json 2>/dev/null | sed 's/.*\///;s/\.json$//'
            
            read -p "Enter template name: " name
            local template_file="$TEMPLATES_DIR/${name}.json"
            
            if [ -f "$template_file" ]; then
                local title=$(jq -r .title "$template_file")
                local message=$(jq -r .message "$template_file")
                
                # Use template to send notification
                echo -e "\n${YELLOW}Using template: $name${NC}"
                echo "Title: $title"
                echo "Message: $message"
                
                read -p "Continue with this template? (y/n): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    send_notification
                fi
            else
                echo -e "${RED}Template not found${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Log action
    log_action "template" "$choice" "Managed notification templates"
}

# Function to generate notification report
generate_report() {
    echo -e "${BLUE}Generating notification report...${NC}"
    
    local report_file="$REPORTS_DIR/notifications_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير الإشعارات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص الإشعارات"
        echo
        
        # Count notifications by type
        for type in "${!NOTIFICATION_TYPES[@]}"; do
            local count=$(find "$NOTIFY_DIR/$type" -type f -name "*.json" | wc -l)
            echo "- ${NOTIFICATION_TYPES[$type]}: $count"
        done
        echo
        
        echo "## الإشعارات حسب الأولوية"
        echo
        for priority in "${!NOTIFICATION_PRIORITIES[@]}"; do
            echo "### ${NOTIFICATION_PRIORITIES[$priority]}"
            find "$NOTIFY_DIR" -type f -name "*.json" -exec sh -c "
                if jq -e '.priority == \"$priority\"' {} >/dev/null; then
                    echo \"- \$(jq -r .title {}): \$(jq -r .type {})\"
                fi
            " \;
            echo
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Notification report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated notification report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/notification_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Notifications Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Send Notification"
    echo -e "${YELLOW}2.${NC} View Notifications"
    echo -e "${YELLOW}3.${NC} Manage Templates"
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
            send_notification
            ;;
        2)
            view_notifications
            ;;
        3)
            manage_templates
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/notification_actions.log" ]; then
                less "$LOGS_DIR/notification_actions.log"
            else
                echo -e "${YELLOW}No notification logs found${NC}"
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
