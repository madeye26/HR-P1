#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_DIR="./data/db"
LOGS_DIR="./logs/db"
REPORTS_DIR="./reports/db"
BACKUP_DIR="./backups/db"

# Create directories
mkdir -p "$DB_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$BACKUP_DIR"

# Function to initialize database
init_db() {
    echo -e "${BLUE}Initializing database...${NC}"
    
    # Create required tables
    local tables=(
        "employees"
        "departments"
        "attendance"
        "leave"
        "payroll"
        "expenses"
    )
    
    for table in "${tables[@]}"; do
        mkdir -p "$DB_DIR/$table"
        touch "$DB_DIR/$table/.metadata"
        
        # Create table metadata
        {
            echo "{"
            echo "  \"table\": \"$table\","
            echo "  \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
            echo "  \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
            echo "  \"schema_version\": \"1.0\""
            echo "}"
        } > "$DB_DIR/$table/.metadata"
    done
    
    echo -e "${GREEN}Database initialized successfully${NC}"
    
    # Log action
    log_action "init" "all" "Initialized database structure"
}

# Function to backup database
backup_db() {
    echo -e "${BLUE}Creating database backup...${NC}"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/db_backup_$timestamp.tar.gz"
    
    # Create backup
    if tar -czf "$backup_file" -C "$DB_DIR" .; then
        echo -e "${GREEN}Backup created successfully: $backup_file${NC}"
        
        # Generate backup report
        local report_file="$REPORTS_DIR/backup_$timestamp.md"
        {
            echo "# تقرير النسخ الاحتياطي"
            echo "تاريخ النسخ: $(date)"
            echo
            echo "## تفاصيل النسخ الاحتياطي"
            echo "- الملف: $backup_file"
            echo "- الحجم: $(du -h "$backup_file" | cut -f1)"
            echo "- MD5: $(md5sum "$backup_file" | cut -d' ' -f1)"
            echo
            echo "## محتويات النسخ الاحتياطي"
            echo "\`\`\`"
            tar -tvf "$backup_file"
            echo "\`\`\`"
        } > "$report_file"
        
        # Log action
        log_action "backup" "all" "Created database backup: $backup_file"
    else
        echo -e "${RED}Backup failed${NC}"
        return 1
    fi
}

# Function to restore database
restore_db() {
    echo -e "${BLUE}Restoring database...${NC}"
    
    # List available backups
    echo -e "\n${YELLOW}Available Backups:${NC}"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null
    
    read -p "Enter backup file name: " backup_name
    local backup_file="$BACKUP_DIR/$backup_name"
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Backup file not found${NC}"
        return 1
    fi
    
    read -p "This will overwrite current data. Continue? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        # Create restore point
        backup_db
        
        # Clear current data
        rm -rf "$DB_DIR"/*
        
        # Restore from backup
        if tar -xzf "$backup_file" -C "$DB_DIR"; then
            echo -e "${GREEN}Database restored successfully${NC}"
            
            # Log action
            log_action "restore" "all" "Restored database from: $backup_name"
        else
            echo -e "${RED}Restore failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Restore cancelled${NC}"
    fi
}

# Function to verify database integrity
verify_db() {
    echo -e "${BLUE}Verifying database integrity...${NC}"
    
    local report_file="$REPORTS_DIR/integrity_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير سلامة قاعدة البيانات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## فحص الجداول"
        echo
        
        local issues=0
        
        # Check each table
        for table_dir in "$DB_DIR"/*; do
            if [ -d "$table_dir" ]; then
                local table=$(basename "$table_dir")
                echo "### جدول $table"
                
                # Check metadata
                if [ ! -f "$table_dir/.metadata" ]; then
                    echo "❌ ملف البيانات الوصفية مفقود"
                    ((issues++))
                else
                    echo "✅ ملف البيانات الوصفية موجود"
                    
                    # Validate metadata JSON
                    if ! jq empty "$table_dir/.metadata" 2>/dev/null; then
                        echo "❌ تنسيق البيانات الوصفية غير صالح"
                        ((issues++))
                    else
                        echo "✅ تنسيق البيانات الوصفية صالح"
                    fi
                fi
                
                # Check records
                local record_count=$(find "$table_dir" -type f -name "*.json" ! -name ".metadata" | wc -l)
                echo "- عدد السجلات: $record_count"
                
                # Validate each record
                local invalid_records=0
                find "$table_dir" -type f -name "*.json" ! -name ".metadata" -exec sh -c '
                    if ! jq empty "$1" 2>/dev/null; then
                        echo "❌ سجل غير صالح: $(basename "$1")"
                        invalid_records=$((invalid_records + 1))
                    fi
                ' sh {} \;
                
                if [ $invalid_records -gt 0 ]; then
                    echo "❌ $invalid_records سجلات غير صالحة"
                    ((issues++))
                else
                    echo "✅ جميع السجلات صالحة"
                fi
                
                echo
            fi
        done
        
        echo "## ملخص"
        echo "- عدد المشاكل: $issues"
        
    } > "$report_file"
    
    echo -e "${GREEN}Database integrity report generated: $report_file${NC}"
    
    # Log action
    log_action "verify" "all" "Verified database integrity"
}

# Function to optimize database
optimize_db() {
    echo -e "${BLUE}Optimizing database...${NC}"
    
    local report_file="$REPORTS_DIR/optimization_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير تحسين قاعدة البيانات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إجراءات التحسين"
        echo
        
        # Compact JSON files
        echo "### ضغط الملفات"
        find "$DB_DIR" -type f -name "*.json" -exec sh -c '
            original_size=$(stat -f %z "$1")
            jq -c "." "$1" > "$1.tmp" && mv "$1.tmp" "$1"
            new_size=$(stat -f %z "$1")
            saved=$((original_size - new_size))
            echo "- $(basename "$1"): توفير $saved بايت"
        ' sh {} \;
        
        # Remove empty files
        echo
        echo "### إزالة الملفات الفارغة"
        find "$DB_DIR" -type f -empty -delete -print | while read -r file; do
            echo "- تم حذف: $(basename "$file")"
        done
        
        # Clean up temporary files
        echo
        echo "### تنظيف الملفات المؤقتة"
        find "$DB_DIR" -type f -name "*.tmp" -delete -print | while read -r file; do
            echo "- تم حذف: $(basename "$file")"
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Database optimization completed${NC}"
    
    # Log action
    log_action "optimize" "all" "Optimized database"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/db_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Database Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Initialize Database"
    echo -e "${YELLOW}2.${NC} Backup Database"
    echo -e "${YELLOW}3.${NC} Restore Database"
    echo -e "${YELLOW}4.${NC} Verify Database Integrity"
    echo -e "${YELLOW}5.${NC} Optimize Database"
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
            init_db
            ;;
        2)
            backup_db
            ;;
        3)
            restore_db
            ;;
        4)
            verify_db
            ;;
        5)
            optimize_db
            ;;
        6)
            if [ -f "$LOGS_DIR/db_actions.log" ]; then
                less "$LOGS_DIR/db_actions.log"
            else
                echo -e "${YELLOW}No database logs found${NC}"
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
