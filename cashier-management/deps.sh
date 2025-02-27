#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPS_DIR="./deps"
LOGS_DIR="./logs/deps"
REPORTS_DIR="./reports/deps"
BACKUP_DIR="./backups/deps"

# Create directories
mkdir -p "$DEPS_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$BACKUP_DIR"

# Function to analyze dependencies
analyze_deps() {
    echo -e "${BLUE}Analyzing dependencies...${NC}"
    
    local report_file="$REPORTS_DIR/deps_analysis_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تحليل التبعيات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص التبعيات"
        echo "\`\`\`"
        npm list --depth=0
        echo "\`\`\`"
        echo
        
        echo "## التبعيات المهملة"
        echo "\`\`\`"
        npm outdated
        echo "\`\`\`"
        echo
        
        echo "## تدقيق الأمان"
        echo "\`\`\`"
        npm audit
        echo "\`\`\`"
        echo
        
        echo "## حجم الحزم"
        echo "\`\`\`"
        du -sh node_modules/* | sort -hr | head -n 10
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Dependency analysis report generated: $report_file${NC}"
    
    # Log action
    log_action "analyze" "all" "Generated dependency analysis report"
}

# Function to update dependencies
update_deps() {
    echo -e "${BLUE}Updating dependencies...${NC}"
    
    # Backup package files
    cp package.json "$BACKUP_DIR/package.json.$(date +%Y%m%d_%H%M%S)"
    [ -f package-lock.json ] && cp package-lock.json "$BACKUP_DIR/package-lock.json.$(date +%Y%m%d_%H%M%S)"
    
    # Show outdated packages
    echo -e "${YELLOW}Outdated packages:${NC}"
    npm outdated
    
    read -p "Update all dependencies? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        if npm update; then
            echo -e "${GREEN}Dependencies updated successfully${NC}"
            
            # Generate update report
            local report_file="$REPORTS_DIR/update_$(date +%Y%m%d_%H%M%S).md"
            {
                echo "# تقرير تحديث التبعيات"
                echo "تاريخ التحديث: $(date)"
                echo
                echo "## التغييرات"
                echo "\`\`\`"
                diff "$BACKUP_DIR/package.json."* package.json || echo "No changes detected"
                echo "\`\`\`"
            } > "$report_file"
            
            # Log action
            log_action "update" "all" "Updated all dependencies"
        else
            echo -e "${RED}Update failed${NC}"
            return 1
        fi
    else
        read -p "Enter specific package to update (or empty to cancel): " package
        if [ -n "$package" ]; then
            if npm update "$package"; then
                echo -e "${GREEN}Package $package updated successfully${NC}"
                
                # Log action
                log_action "update" "$package" "Updated single package"
            else
                echo -e "${RED}Update failed${NC}"
                return 1
            fi
        fi
    fi
}

# Function to clean dependencies
clean_deps() {
    echo -e "${BLUE}Cleaning dependencies...${NC}"
    
    # Backup node_modules size
    local before_size=$(du -sh node_modules 2>/dev/null | cut -f1)
    
    # Clean npm cache
    npm cache clean --force
    
    # Remove node_modules
    rm -rf node_modules
    
    # Remove lock files
    rm -f package-lock.json
    rm -f yarn.lock
    
    # Reinstall dependencies
    if npm install; then
        local after_size=$(du -sh node_modules | cut -f1)
        echo -e "${GREEN}Dependencies cleaned successfully${NC}"
        echo "Before: $before_size"
        echo "After: $after_size"
        
        # Log action
        log_action "clean" "all" "Cleaned and reinstalled dependencies"
    else
        echo -e "${RED}Clean failed${NC}"
        return 1
    fi
}

# Function to audit dependencies
audit_deps() {
    echo -e "${BLUE}Auditing dependencies...${NC}"
    
    local report_file="$REPORTS_DIR/audit_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تدقيق التبعيات"
        echo "تاريخ التدقيق: $(date)"
        echo
        
        echo "## تدقيق الأمان"
        echo "\`\`\`"
        npm audit
        echo "\`\`\`"
        echo
        
        echo "## التبعيات المباشرة مقابل التبعيات غير المباشرة"
        echo "\`\`\`"
        npm ls --all > temp_deps.txt
        echo "Direct dependencies: $(npm ls --depth=0 | wc -l)"
        echo "All dependencies: $(cat temp_deps.txt | wc -l)"
        rm temp_deps.txt
        echo "\`\`\`"
        echo
        
        echo "## تحليل التراخيص"
        echo "\`\`\`"
        npm license-checker
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Dependency audit report generated: $report_file${NC}"
    
    # Log action
    log_action "audit" "all" "Generated dependency audit report"
}

# Function to manage peer dependencies
manage_peer_deps() {
    echo -e "${BLUE}Managing peer dependencies...${NC}"
    
    # Check for peer dependency warnings
    local peer_warnings=$(npm ls 2>&1 | grep "peer dep missing")
    
    if [ -n "$peer_warnings" ]; then
        echo -e "${YELLOW}Peer dependency warnings found:${NC}"
        echo "$peer_warnings"
        
        read -p "Install missing peer dependencies? (y/n): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Extract and install peer dependencies
            echo "$peer_warnings" | while read -r line; do
                local package=$(echo "$line" | awk '{print $NF}')
                if npm install --save-peer "$package"; then
                    echo -e "${GREEN}Installed peer dependency: $package${NC}"
                    
                    # Log action
                    log_action "install" "peer" "Installed peer dependency: $package"
                else
                    echo -e "${RED}Failed to install: $package${NC}"
                fi
            done
        fi
    else
        echo -e "${GREEN}No peer dependency warnings found${NC}"
    fi
}

# Function to generate dependency graph
generate_graph() {
    echo -e "${BLUE}Generating dependency graph...${NC}"
    
    # Check if dependency-cruiser is installed
    if ! command -v depcruise &> /dev/null; then
        npm install -g dependency-cruiser
    fi
    
    local graph_file="$REPORTS_DIR/deps_graph_$(date +%Y%m%d_%H%M%S).svg"
    
    if depcruise --include-only "^src" --output-type dot src | dot -T svg > "$graph_file"; then
        echo -e "${GREEN}Dependency graph generated: $graph_file${NC}"
        
        # Log action
        log_action "graph" "all" "Generated dependency graph"
    else
        echo -e "${RED}Failed to generate dependency graph${NC}"
        return 1
    fi
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/deps_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Dependencies Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Analyze Dependencies"
    echo -e "${YELLOW}2.${NC} Update Dependencies"
    echo -e "${YELLOW}3.${NC} Clean Dependencies"
    echo -e "${YELLOW}4.${NC} Audit Dependencies"
    echo -e "${YELLOW}5.${NC} Manage Peer Dependencies"
    echo -e "${YELLOW}6.${NC} Generate Dependency Graph"
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
            analyze_deps
            ;;
        2)
            update_deps
            ;;
        3)
            clean_deps
            ;;
        4)
            audit_deps
            ;;
        5)
            manage_peer_deps
            ;;
        6)
            generate_graph
            ;;
        7)
            if [ -f "$LOGS_DIR/deps_actions.log" ]; then
                less "$LOGS_DIR/deps_actions.log"
            else
                echo -e "${YELLOW}No dependency logs found${NC}"
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
