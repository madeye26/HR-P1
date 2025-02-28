#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INVENTORY_DIR="./data/inventory"
REPORTS_DIR="./reports/inventory"
TEMPLATES_DIR="./templates/inventory"
LOGS_DIR="./logs/inventory"
BACKUP_DIR="./backups/inventory"

# Create directories
mkdir -p "$INVENTORY_DIR" "$REPORTS_DIR" "$TEMPLATES_DIR" "$LOGS_DIR" "$BACKUP_DIR"

# Create item template if it doesn't exist
if [ ! -f "$TEMPLATES_DIR/item_template.json" ]; then
    cat > "$TEMPLATES_DIR/item_template.json" << EOL
{
    "id": "",
    "name": {
        "en": "",
        "ar": ""
    },
    "category": "",
    "description": "",
    "unit": "",
    "quantity": 0,
    "minimum_quantity": 0,
    "cost": 0,
    "supplier": {
        "id": "",
        "name": "",
        "contact": ""
    },
    "location": {
        "warehouse": "",
        "section": "",
        "shelf": ""
    },
    "status": "active",
    "last_ordered": null,
    "last_received": null,
    "created_at": "",
    "updated_at": ""
}
EOL
fi

# Function to add new item
add_item() {
    echo -e "${BLUE}Adding new inventory item...${NC}"
    
    # Generate item ID
    local id="ITM$(date +%Y%m)$(printf "%04d" $(( $(ls -1 "$INVENTORY_DIR" | wc -l) + 1 )))"
    
    # Get item details
    read -p "Item Name (English): " name_en
    read -p "Item Name (Arabic): " name_ar
    read -p "Category: " category
    read -p "Description: " description
    read -p "Unit (piece/box/kg): " unit
    read -p "Initial Quantity: " quantity
    read -p "Minimum Quantity: " min_quantity
    read -p "Cost per Unit: " cost
    
    # Get supplier details
    read -p "Supplier ID: " supplier_id
    read -p "Supplier Name: " supplier_name
    read -p "Supplier Contact: " supplier_contact
    
    # Get location details
    read -p "Warehouse: " warehouse
    read -p "Section: " section
    read -p "Shelf: " shelf
    
    # Create item file
    local item_file="$INVENTORY_DIR/$id.json"
    
    jq -n \
        --arg id "$id" \
        --arg name_en "$name_en" \
        --arg name_ar "$name_ar" \
        --arg cat "$category" \
        --arg desc "$description" \
        --arg unit "$unit" \
        --arg qty "$quantity" \
        --arg min "$min_quantity" \
        --arg cost "$cost" \
        --arg sup_id "$supplier_id" \
        --arg sup_name "$supplier_name" \
        --arg sup_contact "$supplier_contact" \
        --arg warehouse "$warehouse" \
        --arg section "$section" \
        --arg shelf "$shelf" \
        --arg created "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            id: $id,
            name: {
                en: $name_en,
                ar: $name_ar
            },
            category: $cat,
            description: $desc,
            unit: $unit,
            quantity: ($qty|tonumber),
            minimum_quantity: ($min|tonumber),
            cost: ($cost|tonumber),
            supplier: {
                id: $sup_id,
                name: $sup_name,
                contact: $sup_contact
            },
            location: {
                warehouse: $warehouse,
                section: $section,
                shelf: $shelf
            },
            status: "active",
            last_ordered: null,
            last_received: null,
            created_at: $created,
            updated_at: $created
        }' > "$item_file"
    
    echo -e "${GREEN}Item added with ID: $id${NC}"
    
    # Log action
    log_action "add_item" "$id" "Added new item: $name_en"
}

# Function to update stock
update_stock() {
    echo -e "${BLUE}Updating stock...${NC}"
    
    # List items
    echo -e "\n${YELLOW}Available Items:${NC}"
    for file in "$INVENTORY_DIR"/*.json; do
        if [ -f "$file" ]; then
            jq -r '"\(.id): \(.name.en) - Current: \(.quantity) \(.unit)"' "$file"
        fi
    done
    
    read -p "Enter Item ID: " item_id
    local item_file="$INVENTORY_DIR/$item_id.json"
    
    if [ ! -f "$item_file" ]; then
        echo -e "${RED}Item not found${NC}"
        return 1
    fi
    
    echo "Select action:"
    echo "1. Add Stock"
    echo "2. Remove Stock"
    read -p "Enter choice: " choice
    
    read -p "Enter quantity: " quantity
    read -p "Enter reference (order/usage/adjustment): " reference
    read -p "Enter notes: " notes
    
    # Update stock
    case $choice in
        1)
            jq --arg qty "$quantity" \
               --arg ref "$reference" \
               --arg notes "$notes" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.quantity += ($qty|tonumber) |
                .last_received = $date |
                .updated_at = $date' "$item_file" > "${item_file}.tmp"
            ;;
        2)
            # Check if enough stock
            local current=$(jq -r '.quantity' "$item_file")
            if [ $(echo "$quantity > $current" | bc -l) -eq 1 ]; then
                echo -e "${RED}Insufficient stock${NC}"
                return 1
            fi
            
            jq --arg qty "$quantity" \
               --arg ref "$reference" \
               --arg notes "$notes" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.quantity -= ($qty|tonumber) |
                .updated_at = $date' "$item_file" > "${item_file}.tmp"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    mv "${item_file}.tmp" "$item_file"
    
    # Check if below minimum quantity
    if [ $(echo "$(jq -r '.quantity' "$item_file") < $(jq -r '.minimum_quantity' "$item_file")" | bc -l) -eq 1 ]; then
        echo -e "${YELLOW}Warning: Item is below minimum quantity${NC}"
    fi
    
    echo -e "${GREEN}Stock updated${NC}"
    
    # Log action
    log_action "update_stock" "$item_id" "Updated stock: $quantity $reference"
}

# Function to generate inventory report
generate_report() {
    echo -e "${BLUE}Generating inventory report...${NC}"
    
    local report_file="$REPORTS_DIR/inventory_$(date +%Y%m%d).md"
    
    {
        echo "# تقرير المخزون"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## المخزون حسب الفئة"
        echo
        echo "| الفئة | عدد الأصناف | القيمة الإجمالية |"
        echo "|-------|--------------|------------------|"
        
        # Calculate category totals
        jq -s '
            group_by(.category) |
            map({
                category: .[0].category,
                count: length,
                value: (map(.quantity * .cost) | add)
            }) |
            .[] |
            [.category, .count, .value] |
            @tsv
        ' "$INVENTORY_DIR"/*.json 2>/dev/null | \
        while IFS=$'\t' read -r cat count value; do
            printf "| %s | %d | %.2f |\n" "$cat" "$count" "$value"
        done
        
        echo
        echo "## الأصناف تحت الحد الأدنى"
        echo
        echo "| الصنف | الكمية الحالية | الحد الأدنى | الفرق |"
        echo "|-------|-----------------|-------------|--------|"
        
        # Find items below minimum quantity
        jq -r 'select(.quantity < .minimum_quantity) |
            [.name.ar, .quantity, .minimum_quantity, (.minimum_quantity - .quantity)] |
            @tsv
        ' "$INVENTORY_DIR"/*.json 2>/dev/null | \
        while IFS=$'\t' read -r name current min diff; do
            printf "| %s | %d | %d | %d |\n" "$name" "$current" "$min" "$diff"
        done
        
        echo
        echo "## إحصائيات المخزون"
        echo
        
        # Calculate overall statistics
        local stats=$(jq -s '
            {
                total_items: length,
                total_value: (map(.quantity * .cost) | add),
                low_stock: map(select(.quantity < .minimum_quantity)) | length,
                zero_stock: map(select(.quantity == 0)) | length
            }
        ' "$INVENTORY_DIR"/*.json)
        
        echo "- إجمالي الأصناف: $(echo "$stats" | jq -r '.total_items')"
        echo "- القيمة الإجمالية للمخزون: $(echo "$stats" | jq -r '.total_value') ريال"
        echo "- الأصناف تحت الحد الأدنى: $(echo "$stats" | jq -r '.low_stock')"
        echo "- الأصناف نفذت كمياتها: $(echo "$stats" | jq -r '.zero_stock')"
        
    } > "$report_file"
    
    echo -e "${GREEN}Report generated: $report_file${NC}"
    
    # Log action
    log_action "generate_report" "all" "Generated inventory report"
}

# Function to search inventory
search_inventory() {
    echo -e "${BLUE}Searching inventory...${NC}"
    
    read -p "Enter search term: " search_term
    
    echo -e "\n${YELLOW}Search Results:${NC}"
    echo "------------------------"
    
    for file in "$INVENTORY_DIR"/*.json; do
        if [ -f "$file" ]; then
            if jq -e --arg term "$search_term" '
                .name.en | ascii_downcase | contains($term | ascii_downcase) or
                .name.ar | contains($term) or
                .category | ascii_downcase | contains($term | ascii_downcase) or
                .description | ascii_downcase | contains($term | ascii_downcase)
            ' "$file" > /dev/null; then
                jq -r '"\(.id): \(.name.en) (\(.name.ar))\n  Quantity: \(.quantity) \(.unit)\n  Location: \(.location.warehouse) - \(.location.section) - \(.location.shelf)\n"' "$file"
            fi
        fi
    done
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/inventory_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Inventory Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Add New Item"
    echo -e "${YELLOW}2.${NC} Update Stock"
    echo -e "${YELLOW}3.${NC} Generate Report"
    echo -e "${YELLOW}4.${NC} Search Inventory"
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
            add_item
            ;;
        2)
            update_stock
            ;;
        3)
            generate_report
            ;;
        4)
            search_inventory
            ;;
        5)
            if [ -f "$LOGS_DIR/inventory_actions.log" ]; then
                less "$LOGS_DIR/inventory_actions.log"
            else
                echo -e "${YELLOW}No inventory logs found${NC}"
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
