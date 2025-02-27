#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CACHE_DIR="./cache"
LOGS_DIR="./logs/cache"
REPORTS_DIR="./reports/cache"
TEMP_DIR="./temp/cache"

# Cache types
declare -A CACHE_TYPES=(
    ["build"]="Build Cache"
    ["deps"]="Dependencies Cache"
    ["static"]="Static Assets Cache"
    ["api"]="API Cache"
    ["data"]="Data Cache"
)

# Create directories
mkdir -p "$CACHE_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"
for type in "${!CACHE_TYPES[@]}"; do
    mkdir -p "$CACHE_DIR/$type"
done

# Function to clear cache
clear_cache() {
    echo -e "${BLUE}Clearing cache...${NC}"
    
    # Show cache types
    echo -e "\n${YELLOW}Available Cache Types:${NC}"
    for key in "${!CACHE_TYPES[@]}"; do
        echo "$key) ${CACHE_TYPES[$key]}"
    done
    
    read -p "Enter cache type (or 'all'): " type
    
    if [ "$type" != "all" ] && [ -z "${CACHE_TYPES[$type]}" ]; then
        echo -e "${RED}Invalid cache type${NC}"
        return 1
    fi
    
    # Backup cache before clearing
    local timestamp=$(date +%Y%m%d_%H%M%S)
    if [ "$type" = "all" ]; then
        tar -czf "$TEMP_DIR/cache_backup_${timestamp}.tar.gz" -C "$CACHE_DIR" .
        rm -rf "$CACHE_DIR"/*
        for t in "${!CACHE_TYPES[@]}"; do
            mkdir -p "$CACHE_DIR/$t"
        done
    else
        tar -czf "$TEMP_DIR/${type}_cache_backup_${timestamp}.tar.gz" -C "$CACHE_DIR" "$type"
        rm -rf "$CACHE_DIR/$type"/*
    fi
    
    # Clear specific caches
    case $type in
        all|build)
            rm -rf .cache/
            rm -rf dist/
            rm -rf .parcel-cache/
            ;;
        all|deps)
            rm -rf node_modules/.cache/
            npm cache clean --force
            ;;
        all|static)
            rm -rf public/cache/
            ;;
        all|api)
            rm -rf "$CACHE_DIR/api"/*
            ;;
        all|data)
            rm -rf "$CACHE_DIR/data"/*
            ;;
    esac
    
    echo -e "${GREEN}Cache cleared: ${type}${NC}"
    
    # Log action
    log_action "clear" "$type" "Cleared cache"
}

# Function to analyze cache
analyze_cache() {
    echo -e "${BLUE}Analyzing cache...${NC}"
    
    local report_file="$REPORTS_DIR/cache_analysis_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تحليل ذاكرة التخزين المؤقت"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## حجم التخزين المؤقت"
        echo
        
        # Analyze each cache type
        for type in "${!CACHE_TYPES[@]}"; do
            echo "### ${CACHE_TYPES[$type]}"
            echo "\`\`\`"
            du -sh "$CACHE_DIR/$type" 2>/dev/null || echo "Empty"
            echo "\`\`\`"
            echo
        done
        
        echo "## إحصائيات التخزين المؤقت"
        echo "\`\`\`"
        echo "Total cache size: $(du -sh "$CACHE_DIR" | cut -f1)"
        echo "Number of cache files: $(find "$CACHE_DIR" -type f | wc -l)"
        echo "Cache directories:"
        du -h --max-depth=1 "$CACHE_DIR"
        echo "\`\`\`"
        echo
        
        echo "## تحليل الأداء"
        echo "\`\`\`"
        echo "Build cache hits: $(find .cache -type f | wc -l)"
        echo "Dependencies cache size: $(du -sh node_modules/.cache 2>/dev/null || echo "N/A")"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Cache analysis report generated: $report_file${NC}"
    
    # Log action
    log_action "analyze" "all" "Generated cache analysis report"
}

# Function to optimize cache
optimize_cache() {
    echo -e "${BLUE}Optimizing cache...${NC}"
    
    # Show cache types
    echo -e "\n${YELLOW}Available Cache Types:${NC}"
    for key in "${!CACHE_TYPES[@]}"; do
        echo "$key) ${CACHE_TYPES[$key]}"
    done
    
    read -p "Enter cache type (or 'all'): " type
    
    if [ "$type" != "all" ] && [ -z "${CACHE_TYPES[$type]}" ]; then
        echo -e "${RED}Invalid cache type${NC}"
        return 1
    fi
    
    # Optimize specific caches
    case $type in
        all|build)
            # Clean and rebuild
            rm -rf .cache/
            npm run build
            ;;
        all|deps)
            # Clean and reinstall dependencies
            rm -rf node_modules/.cache/
            npm ci
            ;;
        all|static)
            # Optimize static assets
            find public/cache -type f -name "*.js" -exec uglifyjs {} -o {} \;
            find public/cache -type f -name "*.css" -exec cleancss -o {} {} \;
            ;;
        all|api)
            # Remove expired API cache
            find "$CACHE_DIR/api" -type f -mtime +7 -delete
            ;;
        all|data)
            # Compact data cache
            find "$CACHE_DIR/data" -type f -name "*.json" -exec sh -c '
                jq -c "." {} > {}.tmp && mv {}.tmp {}
            ' \;
            ;;
    esac
    
    echo -e "${GREEN}Cache optimized: ${type}${NC}"
    
    # Log action
    log_action "optimize" "$type" "Optimized cache"
}

# Function to manage cache settings
manage_settings() {
    echo -e "${BLUE}Managing cache settings...${NC}"
    
    local settings_file="$CACHE_DIR/settings.json"
    
    # Create default settings if not exists
    if [ ! -f "$settings_file" ]; then
        {
            echo "{"
            echo "  \"maxSize\": \"1GB\","
            echo "  \"retention\": {"
            echo "    \"build\": 7,"
            echo "    \"deps\": 30,"
            echo "    \"static\": 14,"
            echo "    \"api\": 1,"
            echo "    \"data\": 7"
            echo "  },"
            echo "  \"compression\": true,"
            echo "  \"autoClean\": true"
            echo "}"
        } > "$settings_file"
    fi
    
    # Show current settings
    echo -e "\n${YELLOW}Current Settings:${NC}"
    jq '.' "$settings_file"
    
    # Update settings
    echo -e "\n1. Update max size"
    echo "2. Update retention period"
    echo "3. Toggle compression"
    echo "4. Toggle auto-clean"
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            read -p "Enter new max size (e.g., 1GB): " size
            jq --arg size "$size" '.maxSize = $size' "$settings_file" > "${settings_file}.tmp" && \
            mv "${settings_file}.tmp" "$settings_file"
            ;;
        2)
            for type in "${!CACHE_TYPES[@]}"; do
                read -p "Enter retention days for $type: " days
                jq --arg type "$type" --arg days "$days" \
                   '.retention[$type] = ($days|tonumber)' "$settings_file" > "${settings_file}.tmp" && \
                mv "${settings_file}.tmp" "$settings_file"
            done
            ;;
        3)
            jq '.compression = !.compression' "$settings_file" > "${settings_file}.tmp" && \
            mv "${settings_file}.tmp" "$settings_file"
            ;;
        4)
            jq '.autoClean = !.autoClean' "$settings_file" > "${settings_file}.tmp" && \
            mv "${settings_file}.tmp" "$settings_file"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Settings updated${NC}"
    
    # Log action
    log_action "settings" "update" "Updated cache settings"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/cache_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Cache Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Clear Cache"
    echo -e "${YELLOW}2.${NC} Analyze Cache"
    echo -e "${YELLOW}3.${NC} Optimize Cache"
    echo -e "${YELLOW}4.${NC} Manage Settings"
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
            clear_cache
            ;;
        2)
            analyze_cache
            ;;
        3)
            optimize_cache
            ;;
        4)
            manage_settings
            ;;
        5)
            if [ -f "$LOGS_DIR/cache_actions.log" ]; then
                less "$LOGS_DIR/cache_actions.log"
            else
                echo -e "${YELLOW}No cache logs found${NC}"
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
