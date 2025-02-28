#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
I18N_DIR="./src/i18n"
LOCALES_DIR="$I18N_DIR/locales"
REPORTS_DIR="./reports/i18n"
LOGS_DIR="./logs/i18n"
TEMP_DIR="./temp/i18n"

# Supported languages
declare -A LANGUAGES=(
    ["ar"]="العربية"
    ["en"]="English"
)

# Create directories
mkdir -p "$I18N_DIR" "$LOCALES_DIR" "$REPORTS_DIR" "$LOGS_DIR" "$TEMP_DIR"

# Function to extract translation keys
extract_translations() {
    echo -e "${BLUE}Extracting translation keys...${NC}"
    
    local report_file="$REPORTS_DIR/translations_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير استخراج الترجمات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## المفاتيح المستخرجة"
        echo "\`\`\`"
        # Find all translation keys in source files
        find ./src -type f -name "*.tsx" -o -name "*.ts" | \
        xargs grep -h "t('[^']*'" | \
        sed "s/.*t('\([^']*\)'.*/\1/" | \
        sort -u
        echo "\`\`\`"
        echo
        
        echo "## الإحصائيات"
        echo "- عدد المفاتيح: $(find ./src -type f -name "*.tsx" -o -name "*.ts" | xargs grep -h "t('[^']*'" | wc -l)"
        echo "- عدد الملفات: $(find ./src -type f -name "*.tsx" -o -name "*.ts" | wc -l)"
        
    } > "$report_file"
    
    echo -e "${GREEN}Translation keys extracted: $report_file${NC}"
    
    # Log action
    log_action "extract" "translations" "Extracted translation keys"
}

# Function to manage translations
manage_translations() {
    echo -e "${BLUE}Managing translations...${NC}"
    
    echo "Select action:"
    echo "1. Add new translation"
    echo "2. Update existing translation"
    echo "3. Remove translation"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            add_translation
            ;;
        2)
            update_translation
            ;;
        3)
            remove_translation
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
}

# Function to add new translation
add_translation() {
    read -p "Enter translation key: " key
    
    for lang in "${!LANGUAGES[@]}"; do
        local file="$LOCALES_DIR/$lang.json"
        
        # Create language file if it doesn't exist
        if [ ! -f "$file" ]; then
            echo "{}" > "$file"
        fi
        
        read -p "Enter translation for ${LANGUAGES[$lang]}: " translation
        
        # Add translation to language file
        jq --arg key "$key" \
           --arg translation "$translation" \
           '. + {($key): $translation}' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    done
    
    echo -e "${GREEN}Translation added${NC}"
    
    # Log action
    log_action "add" "translation" "Added new translation: $key"
}

# Function to update translation
update_translation() {
    # Show existing keys
    echo -e "${YELLOW}Existing translation keys:${NC}"
    jq -r 'keys[]' "$LOCALES_DIR/ar.json" 2>/dev/null
    
    read -p "Enter key to update: " key
    
    for lang in "${!LANGUAGES[@]}"; do
        local file="$LOCALES_DIR/$lang.json"
        
        if [ -f "$file" ]; then
            read -p "Enter new translation for ${LANGUAGES[$lang]}: " translation
            
            jq --arg key "$key" \
               --arg translation "$translation" \
               '.[$key] = $translation' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        fi
    done
    
    echo -e "${GREEN}Translation updated${NC}"
    
    # Log action
    log_action "update" "translation" "Updated translation: $key"
}

# Function to remove translation
remove_translation() {
    # Show existing keys
    echo -e "${YELLOW}Existing translation keys:${NC}"
    jq -r 'keys[]' "$LOCALES_DIR/ar.json" 2>/dev/null
    
    read -p "Enter key to remove: " key
    
    for lang in "${!LANGUAGES[@]}"; do
        local file="$LOCALES_DIR/$lang.json"
        
        if [ -f "$file" ]; then
            jq --arg key "$key" 'del(.[$key])' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        fi
    done
    
    echo -e "${GREEN}Translation removed${NC}"
    
    # Log action
    log_action "remove" "translation" "Removed translation: $key"
}

# Function to validate translations
validate_translations() {
    echo -e "${BLUE}Validating translations...${NC}"
    
    local report_file="$REPORTS_DIR/validation_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التحقق من الترجمات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## المفاتيح المفقودة"
        echo
        
        # Check for missing translations in each language
        for lang in "${!LANGUAGES[@]}"; do
            local file="$LOCALES_DIR/$lang.json"
            
            echo "### ${LANGUAGES[$lang]}"
            echo "\`\`\`"
            if [ -f "$file" ]; then
                # Compare with Arabic (primary) translations
                jq -r --arg lang "$lang" '
                    . as $current |
                    ($current | keys) as $currentKeys |
                    (input | keys) as $primaryKeys |
                    $primaryKeys - $currentKeys | .[]
                ' "$file" "$LOCALES_DIR/ar.json" 2>/dev/null
            else
                echo "Language file not found"
            fi
            echo "\`\`\`"
            echo
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Validation report generated: $report_file${NC}"
    
    # Log action
    log_action "validate" "translations" "Validated translations"
}

# Function to generate translation report
generate_report() {
    echo -e "${BLUE}Generating translation report...${NC}"
    
    local report_file="$REPORTS_DIR/translations_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير الترجمات"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إحصائيات الترجمة"
        echo
        
        for lang in "${!LANGUAGES[@]}"; do
            local file="$LOCALES_DIR/$lang.json"
            
            echo "### ${LANGUAGES[$lang]}"
            if [ -f "$file" ]; then
                echo "- عدد الترجمات: $(jq 'length' "$file")"
                echo "- حجم الملف: $(stat -f %z "$file") bytes"
            else
                echo "- ملف اللغة غير موجود"
            fi
            echo
        done
        
        echo "## المفاتيح المشتركة"
        echo "\`\`\`"
        jq -r 'keys[]' "$LOCALES_DIR/ar.json" 2>/dev/null
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Report generated: $report_file${NC}"
    
    # Log action
    log_action "report" "translations" "Generated translation report"
}

# Function to import translations
import_translations() {
    echo -e "${BLUE}Importing translations...${NC}"
    
    read -p "Enter path to import file: " import_file
    
    if [ ! -f "$import_file" ]; then
        echo -e "${RED}Import file not found${NC}"
        return 1
    fi
    
    read -p "Enter language code (${!LANGUAGES[*]}): " lang
    
    if [ ! ${LANGUAGES[$lang]+_} ]; then
        echo -e "${RED}Invalid language code${NC}"
        return 1
    fi
    
    local file="$LOCALES_DIR/$lang.json"
    
    # Merge imported translations
    jq -s '.[0] * .[1]' "$file" "$import_file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    
    echo -e "${GREEN}Translations imported${NC}"
    
    # Log action
    log_action "import" "translations" "Imported translations for $lang"
}

# Function to export translations
export_translations() {
    echo -e "${BLUE}Exporting translations...${NC}"
    
    read -p "Enter language code (${!LANGUAGES[*]}): " lang
    
    if [ ! ${LANGUAGES[$lang]+_} ]; then
        echo -e "${RED}Invalid language code${NC}"
        return 1
    fi
    
    local file="$LOCALES_DIR/$lang.json"
    local export_file="$REPORTS_DIR/translations_${lang}_$(date +%Y%m%d_%H%M%S).json"
    
    if [ -f "$file" ]; then
        cp "$file" "$export_file"
        echo -e "${GREEN}Translations exported to: $export_file${NC}"
    else
        echo -e "${RED}Language file not found${NC}"
        return 1
    fi
    
    # Log action
    log_action "export" "translations" "Exported translations for $lang"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/i18n_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Internationalization Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Extract Translation Keys"
    echo -e "${YELLOW}2.${NC} Manage Translations"
    echo -e "${YELLOW}3.${NC} Validate Translations"
    echo -e "${YELLOW}4.${NC} Generate Report"
    echo -e "${YELLOW}5.${NC} Import Translations"
    echo -e "${YELLOW}6.${NC} Export Translations"
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
            extract_translations
            ;;
        2)
            manage_translations
            ;;
        3)
            validate_translations
            ;;
        4)
            generate_report
            ;;
        5)
            import_translations
            ;;
        6)
            export_translations
            ;;
        7)
            if [ -f "$LOGS_DIR/i18n_actions.log" ]; then
                less "$LOGS_DIR/i18n_actions.log"
            else
                echo -e "${YELLOW}No i18n logs found${NC}"
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
