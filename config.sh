#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="./config"
LOGS_DIR="./logs/config"
REPORTS_DIR="./reports/config"
BACKUP_DIR="./backups/config"

# Configuration categories
declare -A CONFIG_CATEGORIES=(
    ["app"]="إعدادات التطبيق"
    ["db"]="إعدادات قاعدة البيانات"
    ["security"]="إعدادات الأمان"
    ["ui"]="إعدادات الواجهة"
    ["api"]="إعدادات API"
)

# Create directories
mkdir -p "$CONFIG_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$BACKUP_DIR"
for category in "${!CONFIG_CATEGORIES[@]}"; do
    mkdir -p "$CONFIG_DIR/$category"
done

# Function to edit configuration
edit_config() {
    echo -e "${BLUE}Editing configuration...${NC}"
    
    # Show categories
    echo -e "\n${YELLOW}Available Categories:${NC}"
    for key in "${!CONFIG_CATEGORIES[@]}"; do
        echo "$key) ${CONFIG_CATEGORIES[$key]}"
    done
    
    read -p "Enter category: " category
    
    if [ -z "${CONFIG_CATEGORIES[$category]}" ]; then
        echo -e "${RED}Invalid category${NC}"
        return 1
    fi
    
    # Create default config if not exists
    local config_file="$CONFIG_DIR/$category/config.json"
    if [ ! -f "$config_file" ]; then
        case $category in
            app)
                {
                    echo "{"
                    echo "  \"name\": \"Cashier Management System\","
                    echo "  \"version\": \"1.0.0\","
                    echo "  \"environment\": \"development\","
                    echo "  \"debug\": true,"
                    echo "  \"language\": \"ar\","
                    echo "  \"timezone\": \"Asia/Riyadh\""
                    echo "}"
                } > "$config_file"
                ;;
            db)
                {
                    echo "{"
                    echo "  \"host\": \"localhost\","
                    echo "  \"port\": 5432,"
                    echo "  \"database\": \"cashier_management\","
                    echo "  \"username\": \"admin\","
                    echo "  \"password\": \"\","
                    echo "  \"pool\": {"
                    echo "    \"min\": 2,"
                    echo "    \"max\": 10"
                    echo "  }"
                    echo "}"
                } > "$config_file"
                ;;
            security)
                {
                    echo "{"
                    echo "  \"jwt_secret\": \"\","
                    echo "  \"session_timeout\": 3600,"
                    echo "  \"max_login_attempts\": 5,"
                    echo "  \"password_policy\": {"
                    echo "    \"min_length\": 8,"
                    echo "    \"require_numbers\": true,"
                    echo "    \"require_symbols\": true,"
                    echo "    \"require_uppercase\": true"
                    echo "  }"
                    echo "}"
                } > "$config_file"
                ;;
            ui)
                {
                    echo "{"
                    echo "  \"theme\": \"light\","
                    echo "  \"direction\": \"rtl\","
                    echo "  \"font_size\": \"medium\","
                    echo "  \"colors\": {"
                    echo "    \"primary\": \"#007bff\","
                    echo "    \"secondary\": \"#6c757d\","
                    echo "    \"success\": \"#28a745\","
                    echo "    \"error\": \"#dc3545\""
                    echo "  }"
                    echo "}"
                } > "$config_file"
                ;;
            api)
                {
                    echo "{"
                    echo "  \"base_url\": \"http://localhost:3000\","
                    echo "  \"version\": \"v1\","
                    echo "  \"rate_limit\": {"
                    echo "    \"window\": 900,"
                    echo "    \"max_requests\": 100"
                    echo "  },"
                    echo "  \"timeout\": 30000"
                    echo "}"
                } > "$config_file"
                ;;
        esac
    fi
    
    # Backup current config
    cp "$config_file" "$BACKUP_DIR/${category}_$(date +%Y%m%d_%H%M%S).json"
    
    # Edit config
    ${EDITOR:-vim} "$config_file"
    
    # Validate JSON
    if jq empty "$config_file" 2>/dev/null; then
        echo -e "${GREEN}Configuration updated successfully${NC}"
        
        # Log action
        log_action "edit" "$category" "Updated configuration"
    else
        echo -e "${RED}Invalid JSON format${NC}"
        # Restore from backup
        mv "$BACKUP_DIR/${category}_$(date +%Y%m%d_%H%M%S).json" "$config_file"
        return 1
    fi
}

# Function to view configuration
view_config() {
    echo -e "${BLUE}Viewing configuration...${NC}"
    
    # Show categories
    echo -e "\n${YELLOW}Available Categories:${NC}"
    for key in "${!CONFIG_CATEGORIES[@]}"; do
        echo "$key) ${CONFIG_CATEGORIES[$key]}"
    done
    
    read -p "Enter category (or 'all'): " category
    
    if [ "$category" != "all" ] && [ -z "${CONFIG_CATEGORIES[$category]}" ]; then
        echo -e "${RED}Invalid category${NC}"
        return 1
    fi
    
    if [ "$category" = "all" ]; then
        for cat in "${!CONFIG_CATEGORIES[@]}"; do
            echo -e "\n${YELLOW}${CONFIG_CATEGORIES[$cat]}:${NC}"
            if [ -f "$CONFIG_DIR/$cat/config.json" ]; then
                jq '.' "$CONFIG_DIR/$cat/config.json"
            else
                echo "No configuration found"
            fi
        done
    else
        if [ -f "$CONFIG_DIR/$category/config.json" ]; then
            jq '.' "$CONFIG_DIR/$category/config.json"
        else
            echo -e "${RED}No configuration found${NC}"
        fi
    fi
    
    # Log action
    log_action "view" "$category" "Viewed configuration"
}

# Function to validate configuration
validate_config() {
    echo -e "${BLUE}Validating configuration...${NC}"
    
    local report_file="$REPORTS_DIR/validation_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التحقق من الإعدادات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        local issues=0
        
        for category in "${!CONFIG_CATEGORIES[@]}"; do
            echo "## ${CONFIG_CATEGORIES[$category]}"
            echo
            
            local config_file="$CONFIG_DIR/$category/config.json"
            
            if [ ! -f "$config_file" ]; then
                echo "❌ Configuration file missing"
                ((issues++))
                continue
            fi
            
            # Validate JSON format
            if ! jq empty "$config_file" 2>/dev/null; then
                echo "❌ Invalid JSON format"
                ((issues++))
                continue
            fi
            
            # Category-specific validation
            case $category in
                app)
                    if ! jq -e '.version and .environment and .language' "$config_file" >/dev/null; then
                        echo "❌ Missing required fields"
                        ((issues++))
                    fi
                    ;;
                db)
                    if ! jq -e '.host and .port and .database' "$config_file" >/dev/null; then
                        echo "❌ Missing required fields"
                        ((issues++))
                    fi
                    ;;
                security)
                    if ! jq -e '.jwt_secret and .session_timeout' "$config_file" >/dev/null; then
                        echo "❌ Missing required fields"
                        ((issues++))
                    fi
                    ;;
                ui)
                    if ! jq -e '.theme and .direction' "$config_file" >/dev/null; then
                        echo "❌ Missing required fields"
                        ((issues++))
                    fi
                    ;;
                api)
                    if ! jq -e '.base_url and .version' "$config_file" >/dev/null; then
                        echo "❌ Missing required fields"
                        ((issues++))
                    fi
                    ;;
            esac
            
            echo "✅ Configuration valid"
            echo
        done
        
        echo "## ملخص"
        echo "- عدد المشاكل: $issues"
        
    } > "$report_file"
    
    echo -e "${GREEN}Validation report generated: $report_file${NC}"
    
    # Log action
    log_action "validate" "all" "Validated configuration"
}

# Function to export configuration
export_config() {
    echo -e "${BLUE}Exporting configuration...${NC}"
    
    local export_file="$REPORTS_DIR/config_export_$(date +%Y%m%d_%H%M%S).json"
    
    # Combine all configs
    {
        echo "{"
        first=true
        for category in "${!CONFIG_CATEGORIES[@]}"; do
            if [ -f "$CONFIG_DIR/$category/config.json" ]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    echo ","
                fi
                echo "  \"$category\": $(cat "$CONFIG_DIR/$category/config.json")"
            fi
        done
        echo "}"
    } > "$export_file"
    
    echo -e "${GREEN}Configuration exported: $export_file${NC}"
    
    # Log action
    log_action "export" "all" "Exported configuration"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/config_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Configuration Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Edit Configuration"
    echo -e "${YELLOW}2.${NC} View Configuration"
    echo -e "${YELLOW}3.${NC} Validate Configuration"
    echo -e "${YELLOW}4.${NC} Export Configuration"
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
            edit_config
            ;;
        2)
            view_config
            ;;
        3)
            validate_config
            ;;
        4)
            export_config
            ;;
        5)
            if [ -f "$LOGS_DIR/config_actions.log" ]; then
                less "$LOGS_DIR/config_actions.log"
            else
                echo -e "${YELLOW}No configuration logs found${NC}"
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
