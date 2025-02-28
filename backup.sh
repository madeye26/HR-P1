#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
LOGS_DIR="./logs/backup"
REPORTS_DIR="./reports/backup"
TEMP_DIR="./temp/backup"

# Backup types
declare -A BACKUP_TYPES=(
    ["data"]="Database Data"
    ["files"]="File System"
    ["config"]="Configuration"
    ["logs"]="System Logs"
)

# Create directories
mkdir -p "$BACKUP_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$TEMP_DIR"

# Function to create backup
create_backup() {
    echo -e "${BLUE}Creating backup...${NC}"
    
    # Show backup types
    echo -e "\n${YELLOW}Available Backup Types:${NC}"
    for key in "${!BACKUP_TYPES[@]}"; do
        echo "$key) ${BACKUP_TYPES[$key]}"
    done
    
    read -p "Enter backup type: " backup_type
    
    if [ -z "${BACKUP_TYPES[$backup_type]}" ]; then
        echo -e "${RED}Invalid backup type${NC}"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/${backup_type}_backup_${timestamp}.tar.gz"
    
    case $backup_type in
        data)
            # Backup database data
            echo -e "${YELLOW}Backing up database...${NC}"
            tar -czf "$backup_file" ./data/db/
            ;;
        files)
            # Backup source files
            echo -e "${YELLOW}Backing up files...${NC}"
            tar -czf "$backup_file" ./src/
            ;;
        config)
            # Backup configuration files
            echo -e "${YELLOW}Backing up configuration...${NC}"
            tar -czf "$backup_file" ./*.json ./*.yaml ./*.env
            ;;
        logs)
            # Backup log files
            echo -e "${YELLOW}Backing up logs...${NC}"
            tar -czf "$backup_file" ./logs/
            ;;
        *)
            echo -e "${RED}Invalid backup type${NC}"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup created: $backup_file${NC}"
        
        # Generate backup report
        local report_file="$REPORTS_DIR/backup_${timestamp}.md"
        {
            echo "# تقرير النسخ الاحتياطي"
            echo "تاريخ النسخ: $(date)"
            echo
            echo "## تفاصيل النسخ الاحتياطي"
            echo "- النوع: ${BACKUP_TYPES[$backup_type]}"
            echo "- الملف: $backup_file"
            echo "- الحجم: $(du -h "$backup_file" | cut -f1)"
            echo "- MD5: $(md5sum "$backup_file" | cut -d' ' -f1)"
            
        } > "$report_file"
        
        # Log action
        log_action "create" "$backup_type" "Created backup: $backup_file"
    else
        echo -e "${RED}Backup failed${NC}"
        return 1
    fi
}

# Function to restore backup
restore_backup() {
    echo -e "${BLUE}Restoring backup...${NC}"
    
    # Show available backups
    echo -e "\n${YELLOW}Available Backups:${NC}"
    ls -lt "$BACKUP_DIR"/*.tar.gz 2>/dev/null
    
    read -p "Enter backup file name: " backup_file
    
    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        echo -e "${RED}Backup file not found${NC}"
        return 1
    fi
    
    read -p "This will overwrite existing data. Continue? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        # Create restore point
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local restore_point="$BACKUP_DIR/restore_point_${timestamp}.tar.gz"
        
        # Determine backup type from filename
        local backup_type=$(echo "$backup_file" | cut -d'_' -f1)
        
        case $backup_type in
            data)
                tar -czf "$restore_point" ./data/db/
                rm -rf ./data/db/*
                tar -xzf "$BACKUP_DIR/$backup_file" -C ./
                ;;
            files)
                tar -czf "$restore_point" ./src/
                rm -rf ./src/*
                tar -xzf "$BACKUP_DIR/$backup_file" -C ./
                ;;
            config)
                tar -czf "$restore_point" ./*.json ./*.yaml ./*.env
                tar -xzf "$BACKUP_DIR/$backup_file" -C ./
                ;;
            logs)
                tar -czf "$restore_point" ./logs/
                rm -rf ./logs/*
                tar -xzf "$BACKUP_DIR/$backup_file" -C ./
                ;;
            *)
                echo -e "${RED}Invalid backup type${NC}"
                return 1
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Backup restored successfully${NC}"
            echo -e "${YELLOW}Restore point created: $restore_point${NC}"
            
            # Log action
            log_action "restore" "$backup_type" "Restored backup: $backup_file"
        else
            echo -e "${RED}Restore failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Restore cancelled${NC}"
    fi
}

# Function to verify backup
verify_backup() {
    echo -e "${BLUE}Verifying backup...${NC}"
    
    # Show available backups
    echo -e "\n${YELLOW}Available Backups:${NC}"
    ls -lt "$BACKUP_DIR"/*.tar.gz 2>/dev/null
    
    read -p "Enter backup file name: " backup_file
    
    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        echo -e "${RED}Backup file not found${NC}"
        return 1
    fi
    
    local report_file="$REPORTS_DIR/verify_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التحقق من النسخ الاحتياطي"
        echo "تاريخ التحقق: $(date)"
        echo
        
        echo "## تفاصيل الملف"
        echo "- الملف: $backup_file"
        echo "- الحجم: $(du -h "$BACKUP_DIR/$backup_file" | cut -f1)"
        echo "- MD5: $(md5sum "$BACKUP_DIR/$backup_file" | cut -d' ' -f1)"
        echo
        
        echo "## محتويات النسخ الاحتياطي"
        echo "\`\`\`"
        tar -tvf "$BACKUP_DIR/$backup_file"
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Backup verification report generated: $report_file${NC}"
    
    # Log action
    log_action "verify" "$backup_file" "Verified backup integrity"
}

# Function to manage backup retention
manage_retention() {
    echo -e "${BLUE}Managing backup retention...${NC}"
    
    read -p "Enter retention period in days [30]: " days
    days=${days:-30}
    
    # Find and remove old backups
    local old_backups=$(find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +$days)
    
    if [ -n "$old_backups" ]; then
        echo -e "${YELLOW}The following backups will be removed:${NC}"
        echo "$old_backups"
        
        read -p "Continue? (y/n): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            rm -f $old_backups
            echo -e "${GREEN}Old backups removed${NC}"
            
            # Log action
            log_action "retention" "$days" "Removed backups older than $days days"
        else
            echo -e "${YELLOW}Retention management cancelled${NC}"
        fi
    else
        echo -e "${GREEN}No backups older than $days days found${NC}"
    fi
}

# Function to generate backup report
generate_report() {
    echo -e "${BLUE}Generating backup report...${NC}"
    
    local report_file="$REPORTS_DIR/backup_report_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير النسخ الاحتياطي"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص النسخ الاحتياطي"
        echo
        
        for type in "${!BACKUP_TYPES[@]}"; do
            echo "### ${BACKUP_TYPES[$type]}"
            echo "- عدد النسخ: $(find "$BACKUP_DIR" -type f -name "${type}_backup_*.tar.gz" | wc -l)"
            echo "- الحجم الإجمالي: $(du -sh "$BACKUP_DIR/${type}_backup_"* 2>/dev/null | cut -f1)"
            echo "- آخر نسخة: $(ls -lt "$BACKUP_DIR/${type}_backup_"* 2>/dev/null | head -n 1)"
            echo
        done
        
        echo "## إحصائيات التخزين"
        echo "- المساحة المتاحة: $(df -h "$BACKUP_DIR" | awk 'NR==2 {print $4}')"
        echo "- إجمالي حجم النسخ: $(du -sh "$BACKUP_DIR" | cut -f1)"
        
    } > "$report_file"
    
    echo -e "${GREEN}Backup report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "all" "Generated backup report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/backup_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Backup Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Create Backup"
    echo -e "${YELLOW}2.${NC} Restore Backup"
    echo -e "${YELLOW}3.${NC} Verify Backup"
    echo -e "${YELLOW}4.${NC} Manage Retention"
    echo -e "${YELLOW}5.${NC} Generate Report"
    echo -e "${YELLOW}6.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-6): " choice
    
    case $choice in
        1)
            create_backup
            ;;
        2)
            restore_backup
            ;;
        3)
            verify_backup
            ;;
        4)
            manage_retention
            ;;
        5)
            generate_report
            ;;
        6)
            if [ -f "$LOGS_DIR/backup_actions.log" ]; then
                less "$LOGS_DIR/backup_actions.log"
            else
                echo -e "${YELLOW}No backup logs found${NC}"
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
