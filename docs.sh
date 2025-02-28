#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="./docs"
API_DOCS_DIR="$DOCS_DIR/api"
COMPONENT_DOCS_DIR="$DOCS_DIR/components"
GUIDES_DIR="$DOCS_DIR/guides"
LOGS_DIR="./logs/docs"

# Create directories
mkdir -p "$DOCS_DIR" "$API_DOCS_DIR" "$COMPONENT_DOCS_DIR" "$GUIDES_DIR" "$LOGS_DIR"

# Function to generate API documentation
generate_api_docs() {
    echo -e "${BLUE}Generating API documentation...${NC}"
    
    # Create OpenAPI specification
    local api_spec="$API_DOCS_DIR/openapi.yaml"
    
    if [ ! -f "$api_spec" ]; then
        cat > "$api_spec" << EOL
openapi: 3.0.0
info:
  title: نظام إدارة المحاسبة API
  version: 1.0.0
  description: توثيق واجهة برمجة التطبيقات لنظام إدارة المحاسبة
servers:
  - url: http://localhost:3000
    description: خادم التطوير
paths:
EOL
    fi
    
    # Generate API documentation using TypeDoc
    npx typedoc --out "$API_DOCS_DIR" src/api/**/*.ts
    
    echo -e "${GREEN}API documentation generated${NC}"
    
    # Log action
    log_action "generate" "api_docs" "Generated API documentation"
}

# Function to generate component documentation
generate_component_docs() {
    echo -e "${BLUE}Generating component documentation...${NC}"
    
    # Create component documentation using Storybook
    npm run storybook:build
    
    # Generate component documentation using TypeDoc
    npx typedoc --out "$COMPONENT_DOCS_DIR" src/components/**/*.tsx
    
    echo -e "${GREEN}Component documentation generated${NC}"
    
    # Log action
    log_action "generate" "component_docs" "Generated component documentation"
}

# Function to manage guides
manage_guides() {
    echo -e "${BLUE}Managing guides...${NC}"
    
    echo "Select action:"
    echo "1. Create new guide"
    echo "2. Update existing guide"
    echo "3. List guides"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            create_guide
            ;;
        2)
            update_guide
            ;;
        3)
            list_guides
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
}

# Function to create guide
create_guide() {
    read -p "Enter guide title: " title
    read -p "Enter guide category (user/admin/developer): " category
    
    local filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local guide_file="$GUIDES_DIR/${category}/${filename}.md"
    
    mkdir -p "$GUIDES_DIR/$category"
    
    cat > "$guide_file" << EOL
# $title

تاريخ الإنشاء: $(date)
آخر تحديث: $(date)

## المقدمة

## المحتويات

## التفاصيل

## الأمثلة

## المراجع
EOL
    
    echo -e "${GREEN}Guide created: $guide_file${NC}"
    
    # Log action
    log_action "create" "guide" "Created guide: $title"
}

# Function to update guide
update_guide() {
    echo -e "${YELLOW}Available guides:${NC}"
    find "$GUIDES_DIR" -type f -name "*.md" -exec basename {} .md \;
    
    read -p "Enter guide name to update: " guide_name
    local guide_file=$(find "$GUIDES_DIR" -type f -name "${guide_name}.md")
    
    if [ -f "$guide_file" ]; then
        ${EDITOR:-vim} "$guide_file"
        echo -e "${GREEN}Guide updated: $guide_file${NC}"
        
        # Update last modified date
        sed -i "s/آخر تحديث:.*/آخر تحديث: $(date)/" "$guide_file"
        
        # Log action
        log_action "update" "guide" "Updated guide: $guide_name"
    else
        echo -e "${RED}Guide not found${NC}"
    fi
}

# Function to list guides
list_guides() {
    echo -e "${BLUE}Available Guides${NC}"
    echo "------------------------"
    
    for category in user admin developer; do
        if [ -d "$GUIDES_DIR/$category" ]; then
            echo -e "\n${YELLOW}${category^} Guides:${NC}"
            find "$GUIDES_DIR/$category" -type f -name "*.md" -exec basename {} .md \;
        fi
    done
}

# Function to generate search index
generate_search_index() {
    echo -e "${BLUE}Generating search index...${NC}"
    
    local index_file="$DOCS_DIR/search-index.json"
    
    # Create search index from all documentation
    {
        echo "["
        find "$DOCS_DIR" -type f -name "*.md" -o -name "*.html" | \
        while read -r file; do
            title=$(head -n 1 "$file" | sed 's/^#\s*//')
            content=$(cat "$file" | tr -d '\n')
            echo "  {"
            echo "    \"title\": \"$title\","
            echo "    \"path\": \"${file#./docs/}\","
            echo "    \"content\": \"$content\""
            echo "  },"
        done | sed '$s/,$//'
        echo "]"
    } > "$index_file"
    
    echo -e "${GREEN}Search index generated${NC}"
    
    # Log action
    log_action "generate" "search_index" "Generated documentation search index"
}

# Function to validate documentation
validate_docs() {
    echo -e "${BLUE}Validating documentation...${NC}"
    
    local report_file="$LOGS_DIR/validation_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التحقق من التوثيق"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## روابط معطلة"
        echo "\`\`\`"
        find "$DOCS_DIR" -type f -name "*.md" -exec grep -l "]\[" {} \;
        echo "\`\`\`"
        echo
        
        echo "## صور مفقودة"
        echo "\`\`\`"
        find "$DOCS_DIR" -type f -name "*.md" -exec grep -l "![" {} \; | \
        while read -r file; do
            grep -o "!\\[.*\\]([^)]*)" "$file" | \
            while read -r image; do
                path=$(echo "$image" | sed 's/.*(\(.*\))/\1/')
                if [[ "$path" =~ ^http ]]; then
                    curl -s --head "$path" >/dev/null || echo "$file: $path"
                else
                    [ -f "$DOCS_DIR/$path" ] || echo "$file: $path"
                fi
            done
        done
        echo "\`\`\`"
        echo
        
        echo "## توثيق مفقود"
        echo "\`\`\`"
        # Check for components without documentation
        find ./src/components -type f -name "*.tsx" | while read -r component; do
            base=$(basename "$component" .tsx)
            [ -f "$COMPONENT_DOCS_DIR/$base.md" ] || echo "Missing docs: $component"
        done
        echo "\`\`\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}Documentation validation report generated: $report_file${NC}"
    
    # Log action
    log_action "validate" "docs" "Validated documentation"
}

# Function to generate changelog
generate_changelog() {
    echo -e "${BLUE}Generating changelog...${NC}"
    
    local changelog_file="$DOCS_DIR/CHANGELOG.md"
    
    # Get git tags and commits
    {
        echo "# سجل التغييرات"
        echo
        git tag --sort=-v:refname | while read -r tag; do
            echo "## $tag - $(git log -1 --format=%ad --date=short $tag)"
            echo
            git log --no-merges --format="* %s" $tag...$(git describe --abbrev=0 --tags $tag^)
            echo
        done
    } > "$changelog_file"
    
    echo -e "${GREEN}Changelog generated: $changelog_file${NC}"
    
    # Log action
    log_action "generate" "changelog" "Generated changelog"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/docs_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Documentation Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Generate API Documentation"
    echo -e "${YELLOW}2.${NC} Generate Component Documentation"
    echo -e "${YELLOW}3.${NC} Manage Guides"
    echo -e "${YELLOW}4.${NC} Generate Search Index"
    echo -e "${YELLOW}5.${NC} Validate Documentation"
    echo -e "${YELLOW}6.${NC} Generate Changelog"
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
            generate_api_docs
            ;;
        2)
            generate_component_docs
            ;;
        3)
            manage_guides
            ;;
        4)
            generate_search_index
            ;;
        5)
            validate_docs
            ;;
        6)
            generate_changelog
            ;;
        7)
            if [ -f "$LOGS_DIR/docs_actions.log" ]; then
                less "$LOGS_DIR/docs_actions.log"
            else
                echo -e "${YELLOW}No documentation logs found${NC}"
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
