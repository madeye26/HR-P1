#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TASKS_DIR="./tasks"
LOGS_DIR="./logs/tasks"
REPORTS_DIR="./reports/tasks"
ARCHIVE_DIR="./archives/tasks"

# Task status
declare -A TASK_STATUS=(
    ["todo"]="قيد الانتظار"
    ["in_progress"]="قيد التنفيذ"
    ["review"]="قيد المراجعة"
    ["done"]="مكتمل"
    ["blocked"]="متوقف"
)

# Task priorities
declare -A TASK_PRIORITIES=(
    ["high"]="عالي"
    ["medium"]="متوسط"
    ["low"]="منخفض"
)

# Create directories
mkdir -p "$TASKS_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$ARCHIVE_DIR"
for status in "${!TASK_STATUS[@]}"; do
    mkdir -p "$TASKS_DIR/$status"
done

# Function to create task
create_task() {
    echo -e "${BLUE}Creating new task...${NC}"
    
    # Generate task ID
    local id="TASK$(date +%Y%m%d%H%M%S)"
    
    # Get task details
    read -p "Enter task title: " title
    read -p "Enter task description: " description
    
    # Show priorities
    echo -e "\n${YELLOW}Available Priorities:${NC}"
    for key in "${!TASK_PRIORITIES[@]}"; do
        echo "$key) ${TASK_PRIORITIES[$key]}"
    done
    read -p "Enter priority: " priority
    
    read -p "Enter assignee: " assignee
    read -p "Enter due date (YYYY-MM-DD): " due_date
    
    # Create task file
    local task_file="$TASKS_DIR/todo/$id.json"
    
    {
        echo "{"
        echo "  \"id\": \"$id\","
        echo "  \"title\": \"$title\","
        echo "  \"description\": \"$description\","
        echo "  \"priority\": \"$priority\","
        echo "  \"assignee\": \"$assignee\","
        echo "  \"due_date\": \"$due_date\","
        echo "  \"status\": \"todo\","
        echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"comments\": []"
        echo "}"
    } > "$task_file"
    
    echo -e "${GREEN}Task created with ID: $id${NC}"
    
    # Log action
    log_action "create" "$id" "Created new task: $title"
}

# Function to update task status
update_status() {
    echo -e "${BLUE}Updating task status...${NC}"
    
    # Show available tasks
    echo -e "\n${YELLOW}Available Tasks:${NC}"
    find "$TASKS_DIR" -type f -name "*.json" -exec sh -c '
        echo "$(basename {} .json): $(jq -r .title {})"
    ' \;
    
    read -p "Enter task ID: " task_id
    
    # Find task file
    local task_file=$(find "$TASKS_DIR" -type f -name "${task_id}.json")
    
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}Task not found${NC}"
        return 1
    fi
    
    # Show status options
    echo -e "\n${YELLOW}Available Status:${NC}"
    for key in "${!TASK_STATUS[@]}"; do
        echo "$key) ${TASK_STATUS[$key]}"
    done
    
    read -p "Enter new status: " new_status
    
    if [ -z "${TASK_STATUS[$new_status]}" ]; then
        echo -e "${RED}Invalid status${NC}"
        return 1
    fi
    
    # Move task file to new status directory
    local new_file="$TASKS_DIR/$new_status/$(basename "$task_file")"
    mv "$task_file" "$new_file"
    
    # Update task status
    jq --arg status "$new_status" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.status = $status | .updated_at = $date' "$new_file" > "${new_file}.tmp" && \
    mv "${new_file}.tmp" "$new_file"
    
    echo -e "${GREEN}Task status updated${NC}"
    
    # Log action
    log_action "update" "$task_id" "Updated task status to $new_status"
}

# Function to add comment
add_comment() {
    echo -e "${BLUE}Adding comment to task...${NC}"
    
    # Show available tasks
    echo -e "\n${YELLOW}Available Tasks:${NC}"
    find "$TASKS_DIR" -type f -name "*.json" -exec sh -c '
        echo "$(basename {} .json): $(jq -r .title {})"
    ' \;
    
    read -p "Enter task ID: " task_id
    
    # Find task file
    local task_file=$(find "$TASKS_DIR" -type f -name "${task_id}.json")
    
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}Task not found${NC}"
        return 1
    fi
    
    read -p "Enter comment: " comment
    read -p "Enter author: " author
    
    # Add comment
    jq --arg comment "$comment" \
       --arg author "$author" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.comments += [{
           "text": $comment,
           "author": $author,
           "date": $date
       }] | .updated_at = $date' "$task_file" > "${task_file}.tmp" && \
    mv "${task_file}.tmp" "$task_file"
    
    echo -e "${GREEN}Comment added${NC}"
    
    # Log action
    log_action "comment" "$task_id" "Added comment by $author"
}

# Function to view task details
view_task() {
    echo -e "${BLUE}Viewing task details...${NC}"
    
    # Show available tasks
    echo -e "\n${YELLOW}Available Tasks:${NC}"
    find "$TASKS_DIR" -type f -name "*.json" -exec sh -c '
        echo "$(basename {} .json): $(jq -r .title {})"
    ' \;
    
    read -p "Enter task ID: " task_id
    
    # Find task file
    local task_file=$(find "$TASKS_DIR" -type f -name "${task_id}.json")
    
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}Task not found${NC}"
        return 1
    fi
    
    # Display task details
    echo -e "\n${YELLOW}Task Details:${NC}"
    jq '.' "$task_file"
    
    # Log action
    log_action "view" "$task_id" "Viewed task details"
}

# Function to generate task report
generate_report() {
    echo -e "${BLUE}Generating task report...${NC}"
    
    local report_file="$REPORTS_DIR/tasks_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير المهام"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص المهام"
        echo
        
        # Count tasks by status
        for status in "${!TASK_STATUS[@]}"; do
            local count=$(find "$TASKS_DIR/$status" -type f -name "*.json" | wc -l)
            echo "- ${TASK_STATUS[$status]}: $count"
        done
        echo
        
        echo "## المهام المتأخرة"
        echo
        find "$TASKS_DIR" -type f -name "*.json" -exec sh -c '
            if jq -e ".due_date < \"$(date +%Y-%m-%d)\" and .status != \"done\"" {} >/dev/null; then
                echo "- $(jq -r .title {}): $(jq -r .due_date {})"
            fi
        ' \;
        echo
        
        echo "## المهام حسب الأولوية"
        echo
        for priority in "${!TASK_PRIORITIES[@]}"; do
            echo "### ${TASK_PRIORITIES[$priority]}"
            find "$TASKS_DIR" -type f -name "*.json" -exec sh -c "
                if jq -e '.priority == \"$priority\"' {} >/dev/null; then
                    echo \"- \$(jq -r .title {}): \$(jq -r .status {})\"
                fi
            " \;
            echo
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Task report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated task report"
}

# Function to archive completed tasks
archive_tasks() {
    echo -e "${BLUE}Archiving completed tasks...${NC}"
    
    read -p "Enter days completed (default: 30): " days
    days=${days:-30}
    
    # Create archive directory with timestamp
    local archive_dir="$ARCHIVE_DIR/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$archive_dir"
    
    # Find and move completed tasks
    find "$TASKS_DIR/done" -type f -name "*.json" -mtime +$days -exec sh -c '
        mv "$1" "'$archive_dir'/"
    ' _ {} \;
    
    echo -e "${GREEN}Completed tasks archived${NC}"
    
    # Log action
    log_action "archive" "tasks" "Archived tasks older than $days days"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/task_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Tasks Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Create Task"
    echo -e "${YELLOW}2.${NC} Update Task Status"
    echo -e "${YELLOW}3.${NC} Add Comment"
    echo -e "${YELLOW}4.${NC} View Task Details"
    echo -e "${YELLOW}5.${NC} Generate Report"
    echo -e "${YELLOW}6.${NC} Archive Tasks"
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
            create_task
            ;;
        2)
            update_status
            ;;
        3)
            add_comment
            ;;
        4)
            view_task
            ;;
        5)
            generate_report
            ;;
        6)
            archive_tasks
            ;;
        7)
            if [ -f "$LOGS_DIR/task_actions.log" ]; then
                less "$LOGS_DIR/task_actions.log"
            else
                echo -e "${YELLOW}No task logs found${NC}"
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
