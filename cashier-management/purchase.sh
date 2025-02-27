#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PO_DIR="./data/purchase_orders"
REPORTS_DIR="./reports/purchase_orders"
TEMPLATES_DIR="./templates/purchase_orders"
LOGS_DIR="./logs/purchase_orders"
BACKUP_DIR="./backups/purchase_orders"

# Create directories
mkdir -p "$PO_DIR" "$REPORTS_DIR" "$TEMPLATES_DIR" "$LOGS_DIR" "$BACKUP_DIR"

# Create purchase order template if it doesn't exist
if [ ! -f "$TEMPLATES_DIR/po_template.json" ]; then
    cat > "$TEMPLATES_DIR/po_template.json" << EOL
{
    "id": "",
    "date": "",
    "supplier_id": "",
    "department_id": "",
    "requester_id": "",
    "items": [],
    "totals": {
        "subtotal": 0,
        "tax": 0,
        "shipping": 0,
        "total": 0
    },
    "payment": {
        "terms": "",
        "method": "",
        "status": "pending"
    },
    "delivery": {
        "address": "",
        "expected_date": "",
        "actual_date": null,
        "status": "pending"
    },
    "status": "draft",
    "approvals": [],
    "notes": "",
    "attachments": [],
    "created_at": "",
    "updated_at": ""
}
EOL
fi

# Function to create purchase order
create_po() {
    echo -e "${BLUE}Creating new purchase order...${NC}"
    
    # Generate PO ID
    local id="PO$(date +%Y%m)$(printf "%04d" $(( $(ls -1 "$PO_DIR" | wc -l) + 1 )))"
    
    # Get basic details
    read -p "Supplier ID: " supplier_id
    read -p "Department ID: " department_id
    read -p "Requester ID: " requester_id
    read -p "Payment Terms: " payment_terms
    read -p "Payment Method: " payment_method
    read -p "Delivery Address: " delivery_address
    read -p "Expected Delivery Date (YYYY-MM-DD): " delivery_date
    
    # Create temporary PO file
    local po_file="$PO_DIR/$id.json"
    
    # Initialize PO with basic details
    jq -n \
        --arg id "$id" \
        --arg date "$(date +%Y-%m-%d)" \
        --arg supplier "$supplier_id" \
        --arg dept "$department_id" \
        --arg requester "$requester_id" \
        --arg terms "$payment_terms" \
        --arg method "$payment_method" \
        --arg address "$delivery_address" \
        --arg delivery "$delivery_date" \
        --arg created "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            id: $id,
            date: $date,
            supplier_id: $supplier,
            department_id: $dept,
            requester_id: $requester,
            items: [],
            totals: {
                subtotal: 0,
                tax: 0,
                shipping: 0,
                total: 0
            },
            payment: {
                terms: $terms,
                method: $method,
                status: "pending"
            },
            delivery: {
                address: $address,
                expected_date: $delivery,
                actual_date: null,
                status: "pending"
            },
            status: "draft",
            approvals: [],
            notes: "",
            attachments: [],
            created_at: $created,
            updated_at: $created
        }' > "$po_file"
    
    # Add items
    while true; do
        echo -e "\n${YELLOW}Add Item${NC}"
        read -p "Item ID (or empty to finish): " item_id
        [ -z "$item_id" ] && break
        
        read -p "Quantity: " quantity
        read -p "Unit Price: " price
        read -p "Tax Rate (%): " tax_rate
        
        # Calculate item totals
        local subtotal=$(echo "$quantity * $price" | bc)
        local tax=$(echo "$subtotal * $tax_rate / 100" | bc)
        local total=$(echo "$subtotal + $tax" | bc)
        
        # Add item to PO
        jq --arg id "$item_id" \
           --arg qty "$quantity" \
           --arg price "$price" \
           --arg tax "$tax_rate" \
           --argjson subtotal "$subtotal" \
           --argjson tax_amount "$tax" \
           --argjson total "$total" \
           '.items += [{
                item_id: $id,
                quantity: ($qty|tonumber),
                unit_price: ($price|tonumber),
                tax_rate: ($tax|tonumber),
                subtotal: $subtotal,
                tax: $tax_amount,
                total: $total
            }] |
            .totals.subtotal += $subtotal |
            .totals.tax += $tax_amount |
            .totals.total = (.totals.subtotal + .totals.tax + .totals.shipping)' \
           "$po_file" > "${po_file}.tmp"
        
        mv "${po_file}.tmp" "$po_file"
    done
    
    # Add shipping cost
    read -p "Shipping Cost: " shipping
    jq --arg shipping "$shipping" \
       '.totals.shipping = ($shipping|tonumber) |
        .totals.total = (.totals.subtotal + .totals.tax + .totals.shipping)' \
       "$po_file" > "${po_file}.tmp"
    
    mv "${po_file}.tmp" "$po_file"
    
    echo -e "${GREEN}Purchase order created with ID: $id${NC}"
    
    # Log action
    log_action "create_po" "$id" "Created new purchase order"
}

# Function to update PO status
update_po_status() {
    echo -e "${BLUE}Updating purchase order status...${NC}"
    
    # List POs
    echo -e "\n${YELLOW}Available Purchase Orders:${NC}"
    for file in "$PO_DIR"/*.json; do
        if [ -f "$file" ]; then
            jq -r '"\(.id): \(.status) - Total: \(.totals.total) SAR"' "$file"
        fi
    done
    
    read -p "Enter PO ID: " po_id
    local po_file="$PO_DIR/$po_id.json"
    
    if [ ! -f "$po_file" ]; then
        echo -e "${RED}Purchase order not found${NC}"
        return 1
    fi
    
    echo "Select action:"
    echo "1. Submit for Approval"
    echo "2. Approve/Reject"
    echo "3. Mark as Received"
    echo "4. Mark as Paid"
    read -p "Enter choice: " choice
    
    case $choice in
        1)
            jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = "pending_approval" |
                .updated_at = $date' "$po_file" > "${po_file}.tmp"
            ;;
        2)
            read -p "Action (approve/reject): " action
            read -p "Approver ID: " approver_id
            read -p "Comments: " comments
            
            jq --arg action "$action" \
               --arg approver "$approver_id" \
               --arg comments "$comments" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = if $action == "approve" then "approved" else "rejected" end |
                .approvals += [{
                    approver_id: $approver,
                    action: $action,
                    comments: $comments,
                    date: $date
                }] |
                .updated_at = $date' "$po_file" > "${po_file}.tmp"
            ;;
        3)
            read -p "Delivery Date (YYYY-MM-DD): " delivery_date
            read -p "Notes: " notes
            
            jq --arg date "$delivery_date" \
               --arg notes "$notes" \
               --arg updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.delivery.actual_date = $date |
                .delivery.status = "received" |
                .status = "received" |
                .notes = $notes |
                .updated_at = $updated' "$po_file" > "${po_file}.tmp"
            ;;
        4)
            jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.payment.status = "paid" |
                .status = "completed" |
                .updated_at = $date' "$po_file" > "${po_file}.tmp"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    mv "${po_file}.tmp" "$po_file"
    echo -e "${GREEN}Purchase order updated${NC}"
    
    # Log action
    log_action "update_po" "$po_id" "Updated purchase order status"
}

# Function to generate PO report
generate_report() {
    echo -e "${BLUE}Generating purchase order report...${NC}"
    
    read -p "Enter Month (MM): " month
    read -p "Enter Year (YYYY): " year
    
    local report_file="$REPORTS_DIR/po_report_${year}_${month}.md"
    
    {
        echo "# تقرير أوامر الشراء"
        echo "الشهر: $month"
        echo "السنة: $year"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص أوامر الشراء"
        echo
        echo "| رقم الطلب | المورد | القيمة | الحالة |"
        echo "|-----------|---------|---------|---------|"
        
        # Process all POs for the month
        for file in "$PO_DIR"/*.json; do
            if [ -f "$file" ]; then
                if [[ $(jq -r '.date' "$file") =~ ^$year-$month ]]; then
                    jq -r '[
                        .id,
                        .supplier_id,
                        .totals.total,
                        .status
                    ] | @tsv' "$file" | \
                    awk -F'\t' '{printf "| %s | %s | %.2f | %s |\n", $1, $2, $3, $4}'
                fi
            fi
        done
        
        echo
        echo "## إحصائيات"
        echo
        
        # Calculate statistics
        local stats=$(jq -s '
            map(select(.date | startswith("'"$year-$month"'"))) |
            {
                total_pos: length,
                total_value: (map(.totals.total) | add),
                approved: map(select(.status == "approved")) | length,
                pending: map(select(.status == "pending_approval")) | length,
                completed: map(select(.status == "completed")) | length
            }
        ' "$PO_DIR"/*.json)
        
        echo "- إجمالي أوامر الشراء: $(echo "$stats" | jq -r '.total_pos')"
        echo "- القيمة الإجمالية: $(echo "$stats" | jq -r '.total_value') ريال"
        echo "- الطلبات المعتمدة: $(echo "$stats" | jq -r '.approved')"
        echo "- الطلبات المعلقة: $(echo "$stats" | jq -r '.pending')"
        echo "- الطلبات المكتملة: $(echo "$stats" | jq -r '.completed')"
        
    } > "$report_file"
    
    echo -e "${GREEN}Report generated: $report_file${NC}"
    
    # Log action
    log_action "generate_report" "$month/$year" "Generated purchase order report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/po_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Purchase Order Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Create Purchase Order"
    echo -e "${YELLOW}2.${NC} Update PO Status"
    echo -e "${YELLOW}3.${NC} Generate Report"
    echo -e "${YELLOW}4.${NC} View Logs"
    echo -e "${YELLOW}0.${NC} Exit"
    echo "------------------------"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (0-4): " choice
    
    case $choice in
        1)
            create_po
            ;;
        2)
            update_po_status
            ;;
        3)
            generate_report
            ;;
        4)
            if [ -f "$LOGS_DIR/po_actions.log" ]; then
                less "$LOGS_DIR/po_actions.log"
            else
                echo -e "${YELLOW}No purchase order logs found${NC}"
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
