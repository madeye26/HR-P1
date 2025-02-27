#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
USERS_DIR="./data/users"
LOGS_DIR="./logs/users"
REPORTS_DIR="./reports/users"
TEMP_DIR="./temp/users"

# User roles
declare -A USER_ROLES=(
    ["admin"]="مدير النظام"
    ["manager"]="مدير"
    ["cashier"]="كاشير"
    ["accountant"]="محاسب"
    ["inventory"]="مسؤول المخزون"
)

# User permissions
declare -A USER_PERMISSIONS=(
    ["sales"]="إدارة المبيعات"
    ["inventory"]="إدارة المخزون"
    ["reports"]="إدارة التقارير"
    ["users"]="إدارة المستخدمين"
    ["settings"]="إدارة الإعدادات"
)

# Create directories
mkdir -p "$USERS_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to create user
create_user() {
    echo -e "${BLUE}Creating new user...${NC}"
    
    # Get user details
    read -p "Enter username: " username
    
    # Check if user exists
    if [ -f "$USERS_DIR/$username.json" ]; then
        echo -e "${RED}User already exists${NC}"
        return 1
    fi
    
    read -p "Enter full name: " fullname
    read -p "Enter email: " email
    
    # Show roles
    echo -e "\n${YELLOW}Available Roles:${NC}"
    for key in "${!USER_ROLES[@]}"; do
        echo "$key) ${USER_ROLES[$key]}"
    done
    read -p "Enter role: " role
    
    if [ -z "${USER_ROLES[$role]}" ]; then
        echo -e "${RED}Invalid role${NC}"
        return 1
    fi
    
    # Set permissions based on role
    declare -a permissions
    case $role in
        admin)
            permissions=(${!USER_PERMISSIONS[@]})
            ;;
        manager)
            permissions=("sales" "inventory" "reports")
            ;;
        cashier)
            permissions=("sales")
            ;;
        accountant)
            permissions=("reports")
            ;;
        inventory)
            permissions=("inventory")
            ;;
    esac
    
    # Generate password
    password=$(openssl rand -base64 12)
    
    # Create user file
    local user_file="$USERS_DIR/$username.json"
    
    {
        echo "{"
        echo "  \"username\": \"$username\","
        echo "  \"fullname\": \"$fullname\","
        echo "  \"email\": \"$email\","
        echo "  \"role\": \"$role\","
        echo "  \"permissions\": $(printf '%s\n' "${permissions[@]}" | jq -R . | jq -s .),"
        echo "  \"password_hash\": \"$(echo "$password" | sha256sum | cut -d' ' -f1)\","
        echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"last_login\": null,"
        echo "  \"status\": \"active\""
        echo "}"
    } > "$user_file"
    
    echo -e "${GREEN}User created successfully${NC}"
    echo -e "Username: $username"
    echo -e "Password: $password"
    echo -e "Please change password on first login"
    
    # Log action
    log_action "create" "$username" "Created new user with role $role"
}

# Function to modify user
modify_user() {
    echo -e "${BLUE}Modifying user...${NC}"
    
    # Show available users
    echo -e "\n${YELLOW}Available Users:${NC}"
    for user in "$USERS_DIR"/*.json; do
        echo "$(basename "$user" .json): $(jq -r .fullname "$user") ($(jq -r .role "$user"))"
    done
    
    read -p "Enter username to modify: " username
    local user_file="$USERS_DIR/$username.json"
    
    if [ ! -f "$user_file" ]; then
        echo -e "${RED}User not found${NC}"
        return 1
    fi
    
    echo "1. Change role"
    echo "2. Update permissions"
    echo "3. Reset password"
    echo "4. Change status"
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            # Show roles
            echo -e "\n${YELLOW}Available Roles:${NC}"
            for key in "${!USER_ROLES[@]}"; do
                echo "$key) ${USER_ROLES[$key]}"
            done
            read -p "Enter new role: " new_role
            
            if [ -z "${USER_ROLES[$new_role]}" ]; then
                echo -e "${RED}Invalid role${NC}"
                return 1
            fi
            
            jq --arg role "$new_role" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.role = $role | .updated_at = $date' "$user_file" > "${user_file}.tmp" && \
            mv "${user_file}.tmp" "$user_file"
            ;;
        2)
            # Show permissions
            echo -e "\n${YELLOW}Available Permissions:${NC}"
            for key in "${!USER_PERMISSIONS[@]}"; do
                echo "$key) ${USER_PERMISSIONS[$key]}"
            done
            
            read -p "Enter permissions (comma-separated): " perms
            IFS=',' read -ra perm_array <<< "$perms"
            
            jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               --arg perms "$(printf '%s\n' "${perm_array[@]}" | jq -R . | jq -s .)" \
               '.permissions = $perms | .updated_at = $date' "$user_file" > "${user_file}.tmp" && \
            mv "${user_file}.tmp" "$user_file"
            ;;
        3)
            # Generate new password
            new_password=$(openssl rand -base64 12)
            
            jq --arg hash "$(echo "$new_password" | sha256sum | cut -d' ' -f1)" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.password_hash = $hash | .updated_at = $date' "$user_file" > "${user_file}.tmp" && \
            mv "${user_file}.tmp" "$user_file"
            
            echo -e "${GREEN}New password: $new_password${NC}"
            ;;
        4)
            read -p "Enter new status (active/inactive): " status
            
            jq --arg status "$status" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = $status | .updated_at = $date' "$user_file" > "${user_file}.tmp" && \
            mv "${user_file}.tmp" "$user_file"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}User modified successfully${NC}"
    
    # Log action
    log_action "modify" "$username" "Modified user settings"
}

# Function to list users
list_users() {
    echo -e "${BLUE}Listing users...${NC}"
    
    echo -e "\n${YELLOW}User List:${NC}"
    echo "------------------------"
    
    for user in "$USERS_DIR"/*.json; do
        echo -e "\nUsername: $(jq -r .username "$user")"
        echo "Full Name: $(jq -r .fullname "$user")"
        echo "Role: $(jq -r .role "$user")"
        echo "Status: $(jq -r .status "$user")"
        echo "Last Login: $(jq -r .last_login "$user")"
        echo "------------------------"
    done
    
    # Log action
    log_action "list" "all" "Listed all users"
}

# Function to generate user report
generate_report() {
    echo -e "${BLUE}Generating user report...${NC}"
    
    local report_file="$REPORTS_DIR/users_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير المستخدمين"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إحصائيات المستخدمين"
        echo
        echo "- إجمالي المستخدمين: $(find "$USERS_DIR" -type f -name "*.json" | wc -l)"
        echo "- المستخدمين النشطين: $(find "$USERS_DIR" -type f -name "*.json" -exec jq -r .status {} \; | grep -c "active")"
        echo
        
        echo "## المستخدمين حسب الدور"
        echo
        for role in "${!USER_ROLES[@]}"; do
            count=$(find "$USERS_DIR" -type f -name "*.json" -exec jq -r .role {} \; | grep -c "$role")
            echo "- ${USER_ROLES[$role]}: $count"
        done
        echo
        
        echo "## آخر تسجيلات الدخول"
        echo
        find "$USERS_DIR" -type f -name "*.json" -exec sh -c '
            jq -r "[.username, .last_login] | @tsv" {} | sort -k2 -r | head -n 10
        ' \; | while IFS=$'\t' read -r username last_login; do
            echo "- $username: $last_login"
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}User report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated user report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/user_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}User Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Create User"
    echo -e "${YELLOW}2.${NC} Modify User"
    echo -e "${YELLOW}3.${NC} List Users"
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
            create_user
            ;;
        2)
            modify_user
            ;;
        3)
            list_users
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/user_actions.log" ]; then
                less "$LOGS_DIR/user_actions.log"
            else
                echo -e "${YELLOW}No user logs found${NC}"
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
