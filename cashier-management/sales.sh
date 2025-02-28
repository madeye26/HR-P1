#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SALES_DIR="./data/sales"
INVOICES_DIR="./data/invoices"
REPORTS_DIR="./reports/sales"
TEMPLATES_DIR="./templates/sales"
LOGS_DIR="./logs/sales"
BACKUP_DIR="./backups/sales"

# Create directories
mkdir -p "$SALES_DIR" "$INVOICES_DIR" "$REPORTS_DIR" "$TEMPLATES_DIR" "$LOGS_DIR" "$BACKUP_DIR"

# Create sale template if it doesn't exist
if [ ! -f "$TEMPLATES_DIR/sale_template.json" ]; then
    cat > "$TEMPLATES_DIR/sale_template.json" << EOL
{
    "id": "",
    "date": "",
    "cashier_id": "",
    "customer": {
        "id": "",
        "name": "",
        "phone": "",
        "email": ""
    },
    "items": [],
    "payments": [],
    "totals": {
        "subtotal": 0,
        "tax": 0,
        "discount": 0,
        "total": 0
    },
    "status": "pending",
    "notes": "",
    "created_at": "",
    "updated_at": ""
}
EOL
fi

# Function to record sale
record_sale() {
    echo -e "${BLUE}Recording new sale...${NC}"
    
    # Generate sale ID
    local id="SALE$(date +%Y%m%d%H%M%S)"
    
    # Get basic details
    read -p "Cashier ID: " cashier_id
    read -p "Customer ID (leave empty for walk-in): " customer_id
    
    if [ -n "$customer_id" ]; then
        read -p "Customer Name: " customer_name
        read -p "Customer Phone: " customer_phone
        read -p "Customer Email: " customer_email
    else
        customer_name="Walk-in Customer"
        customer_phone=""
        customer_email=""
    fi
    
    # Create sale file
    local sale_file="$SALES_DIR/$id.json"
    
    # Initialize sale with basic details
    jq -n \
        --arg id "$id" \
        --arg date "$(date +%Y-%m-%d)" \
        --arg cashier "$cashier_id" \
        --arg cust_id "$customer_id" \
        --arg cust_name "$customer_name" \
        --arg cust_phone "$customer_phone" \
        --arg cust_email "$customer_email" \
        --arg created "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            id: $id,
            date: $date,
            cashier_id: $cashier,
            customer: {
                id: $cust_id,
                name: $cust_name,
                phone: $cust_phone,
                email: $cust_email
            },
            items: [],
            payments: [],
            totals: {
                subtotal: 0,
                tax: 0,
                discount: 0,
                total: 0
            },
            status: "pending",
            notes: "",
            created_at: $created,
            updated_at: $created
        }' > "$sale_file"
    
    # Add items
    while true; do
        echo -e "\n${YELLOW}Add Item${NC}"
        read -p "Item ID (or empty to finish): " item_id
        [ -z "$item_id" ] && break
        
        read -p "Quantity: " quantity
        read -p "Unit Price: " price
        read -p "Tax Rate (%): " tax_rate
        read -p "Discount (%): " discount_rate
        
        # Calculate item totals
        local subtotal=$(echo "$quantity * $price" | bc)
        local tax=$(echo "$subtotal * $tax_rate / 100" | bc)
        local discount=$(echo "$subtotal * $discount_rate / 100" | bc)
        local total=$(echo "$subtotal + $tax - $discount" | bc)
        
        # Add item to sale
        jq --arg id "$item_id" \
           --arg qty "$quantity" \
           --arg price "$price" \
           --arg tax "$tax_rate" \
           --arg disc "$discount_rate" \
           --argjson subtotal "$subtotal" \
           --argjson tax_amount "$tax" \
           --argjson disc_amount "$discount" \
           --argjson total "$total" \
           '.items += [{
                item_id: $id,
                quantity: ($qty|tonumber),
                unit_price: ($price|tonumber),
                tax_rate: ($tax|tonumber),
                discount_rate: ($disc|tonumber),
                subtotal: $subtotal,
                tax: $tax_amount,
                discount: $disc_amount,
                total: $total
            }] |
            .totals.subtotal += $subtotal |
            .totals.tax += $tax_amount |
            .totals.discount += $disc_amount |
            .totals.total = (.totals.subtotal + .totals.tax - .totals.discount)' \
           "$sale_file" > "${sale_file}.tmp"
        
        mv "${sale_file}.tmp" "$sale_file"
    done
    
    # Process payment
    echo -e "\n${YELLOW}Process Payment${NC}"
    echo "Total Amount: $(jq -r '.totals.total' "$sale_file") SAR"
    
    while true; do
        read -p "Payment Method (cash/card/other): " method
        read -p "Amount: " amount
        read -p "Reference (if applicable): " reference
        
        # Add payment to sale
        jq --arg method "$method" \
           --arg amount "$amount" \
           --arg ref "$reference" \
           --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.payments += [{
                method: $method,
                amount: ($amount|tonumber),
                reference: $ref,
                date: $date
            }]' "$sale_file" > "${sale_file}.tmp"
        
        mv "${sale_file}.tmp" "$sale_file"
        
        # Check if payment is complete
        local total=$(jq -r '.totals.total' "$sale_file")
        local paid=$(jq -r '.payments | map(.amount) | add' "$sale_file")
        
        if [ $(echo "$paid >= $total" | bc -l) -eq 1 ]; then
            # Update sale status
            jq --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = "completed" |
                .updated_at = $date' "$sale_file" > "${sale_file}.tmp"
            mv "${sale_file}.tmp" "$sale_file"
            break
        else
            echo -e "${YELLOW}Remaining: $(echo "$total - $paid" | bc) SAR${NC}"
            read -p "Add another payment? (y/n): " another
            [[ $another =~ ^[Nn]$ ]] && break
        fi
    done
    
    # Generate invoice
    local invoice_file="$INVOICES_DIR/${id}_invoice.txt"
    
    {
        echo "فاتورة مبيعات"
        echo "=============="
        echo "رقم الفاتورة: $id"
        echo "التاريخ: $(date)"
        echo "الكاشير: $cashier_id"
        echo
        echo "العميل: $customer_name"
        [ -n "$customer_phone" ] && echo "الهاتف: $customer_phone"
        [ -n "$customer_email" ] && echo "البريد: $customer_email"
        echo
        echo "الأصناف:"
        echo "--------"
        jq -r '.items[] | "\(.quantity)x \(.item_id) @ \(.unit_price) = \(.total)"' "$sale_file"
        echo
        echo "الإجمالي: $(jq -r '.totals.subtotal' "$sale_file") ريال"
        echo "الضريبة: $(jq -r '.totals.tax' "$sale_file") ريال"
        echo "الخصم: $(jq -r '.totals.discount' "$sale_file") ريال"
        echo "المجموع: $(jq -r '.totals.total' "$sale_file") ريال"
        echo
        echo "المدفوعات:"
        echo "---------"
        jq -r '.payments[] | "\(.method): \(.amount) ريال (\(.reference))"' "$sale_file"
        echo
        echo "شكراً لتسوقكم معنا"
        
    } > "$invoice_file"
    
    echo -e "${GREEN}Sale recorded and invoice generated${NC}"
    
    # Log action
    log_action "record_sale" "$id" "Recorded new sale: $(jq -r '.totals.total' "$sale_file") SAR"
}

# Function to void sale
void_sale() {
    echo -e "${BLUE}Voiding sale...${NC}"
    
    # List recent sales
    echo -e "\n${YELLOW}Recent Sales:${NC}"
    ls -t "$SALES_DIR" | head -n 5 | while read file; do
        jq -r '"\(.id): \(.totals.total) SAR - \(.status)"' "$SALES_DIR/$file"
    done
    
    read -p "Enter Sale ID to void: " sale_id
    local sale_file="$SALES_DIR/$sale_id.json"
    
    if [ ! -f "$sale_file" ]; then
        echo -e "${RED}Sale not found${NC}"
        return 1
    fi
    
    read -p "Void reason: " reason
    read -p "Authorized by (ID): " auth_id
    
    # Update sale status
    jq --arg reason "$reason" \
       --arg auth "$auth_id" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.status = "voided" |
        .void_reason = $reason |
        .void_auth = $auth |
        .void_date = $date |
        .updated_at = $date' "$sale_file" > "${sale_file}.tmp"
    
    mv "${sale_file}.tmp" "$sale_file"
    
    echo -e "${GREEN}Sale voided${NC}"
    
    # Log action
    log_action "void_sale" "$sale_id" "Voided sale: $reason"
}

# Function to generate sales report
generate_report() {
    echo -e "${BLUE}Generating sales report...${NC}"
    
    read -p "Enter Month (MM): " month
    read -p "Enter Year (YYYY): " year
    
    local report_file="$REPORTS_DIR/sales_${year}_${month}.md"
    
    {
        echo "# تقرير المبيعات"
        echo "الشهر: $month"
        echo "السنة: $year"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## ملخص المبيعات"
        echo
        echo "| التاريخ | رقم الفاتورة | المبلغ | الحالة |"
        echo "|---------|---------------|--------|---------|"
        
        # Process all sales for the month
        for file in "$SALES_DIR"/*.json; do
            if [ -f "$file" ]; then
                if [[ $(jq -r '.date' "$file") =~ ^$year-$month ]]; then
                    jq -r '[
                        .date,
                        .id,
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
                total_sales: length,
                completed_sales: map(select(.status == "completed")) | length,
                voided_sales: map(select(.status == "voided")) | length,
                total_revenue: map(select(.status == "completed")) | map(.totals.total) | add,
                total_tax: map(select(.status == "completed")) | map(.totals.tax) | add,
                total_discount: map(select(.status == "completed")) | map(.totals.discount) | add,
                payment_methods: reduce .[].payments[] as $p (
                    {};
                    .[$p.method] += $p.amount
                )
            }
        ' "$SALES_DIR"/*.json)
        
        echo "- إجمالي المبيعات: $(echo "$stats" | jq -r '.total_sales')"
        echo "- المبيعات المكتملة: $(echo "$stats" | jq -r '.completed_sales')"
        echo "- المبيعات الملغاة: $(echo "$stats" | jq -r '.voided_sales')"
        echo "- إجمالي الإيرادات: $(echo "$stats" | jq -r '.total_revenue') ريال"
        echo "- إجمالي الضرائب: $(echo "$stats" | jq -r '.total_tax') ريال"
        echo "- إجمالي الخصومات: $(echo "$stats" | jq -r '.total_discount') ريال"
        echo
        echo "طرق الدفع:"
        echo "$stats" | jq -r '.payment_methods | to_entries[] | "- \(.key): \(.value) ريال"'
        
    } > "$report_file"
    
    echo -e "${GREEN}Report generated: $report_file${NC}"
    
    # Log action
    log_action "generate_report" "$month/$year" "Generated sales report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/sales_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Sales Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Record Sale"
    echo -e "${YELLOW}2.${NC} Void Sale"
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
            record_sale
            ;;
        2)
            void_sale
            ;;
        3)
            generate_report
            ;;
        4)
            if [ -f "$LOGS_DIR/sales_actions.log" ]; then
                less "$LOGS_DIR/sales_actions.log"
            else
                echo -e "${YELLOW}No sales logs found${NC}"
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
