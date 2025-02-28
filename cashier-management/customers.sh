#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CUSTOMERS_DIR="./data/customers"
REPORTS_DIR="./reports/customers"
TEMPLATES_DIR="./templates/customers"
LOGS_DIR="./logs/customers"
BACKUP_DIR="./backups/customers"

# Create directories
mkdir -p "$CUSTOMERS_DIR" "$REPORTS_DIR" "$TEMPLATES_DIR" "$LOGS_DIR" "$BACKUP_DIR"

# Create customer template if it doesn't exist
if [ ! -f "$TEMPLATES_DIR/customer_template.json" ]; then
    cat > "$TEMPLATES_DIR/customer_template.json" << EOL
{
    "id": "",
    "name": {
        "first": "",
        "last": "",
        "arabic": ""
    },
    "contact": {
        "phone": "",
        "email": "",
        "address": {
            "street": "",
            "city": "",
            "state": "",
            "postal_code": "",
            "country": ""
        }
    },
    "profile": {
        "type": "regular",
        "membership_level": "standard",
        "points": 0,
        "registration_date": "",
        "last_visit": null
    },
    "preferences": {
        "language": "ar",
        "communication": [],
        "marketing_opt_in": false
    },
    "transactions": {
        "total_purchases": 0,
        "total_amount": 0,
        "average_purchase": 0,
        "last_purchase": null
    },
    "status": "active",
    "notes": "",
    "created_at": "",
    "updated_at": ""
}
EOL
fi

# Function to add customer
add_customer() {
    echo -e "${BLUE}Adding new customer...${NC}"
    
    # Generate customer ID
    local id="CUST$(date +%Y%m)$(printf "%04d" $(( $(ls -1 "$CUSTOMERS_DIR" | wc -l) + 1 )))"
    
    # Get customer details
    echo -e "\n${YELLOW}Personal Information${NC}"
    read -p "First Name: " first_name
    read -p "Last Name: " last_name
    read -p "Arabic Name: " arabic_name
    
    echo -e "\n${YELLOW}Contact Information${NC}"
    read -p "Phone: " phone
    read -p "Email: " email
    read -p "Street Address: " street
    read -p "City: " city
    read -p "State: " state
    read -p "Postal Code: " postal_code
    read -p "Country: " country
    
    echo -e "\n${YELLOW}Preferences${NC}"
    read -p "Preferred Language (ar/en): " language
    read -p "Marketing Opt-in (y/n): " marketing
    
    # Create customer file
    local customer_file="$CUSTOMERS_DIR/$id.json"
    
    jq -n \
        --arg id "$id" \
        --arg first "$first_name" \
        --arg last "$last_name" \
        --arg arabic "$arabic_name" \
        --arg phone "$phone" \
        --arg email "$email" \
        --arg street "$street" \
        --arg city "$city" \
        --arg state "$state" \
        --arg postal "$postal_code" \
        --arg country "$country" \
        --arg lang "$language" \
        --arg marketing "$marketing" \
        --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            id: $id,
            name: {
                first: $first,
                last: $last,
                arabic: $arabic
            },
            contact: {
                phone: $phone,
                email: $email,
                address: {
                    street: $street,
                    city: $city,
                    state: $state,
                    postal_code: $postal,
                    country: $country
                }
            },
            profile: {
                type: "regular",
                membership_level: "standard",
                points: 0,
                registration_date: $date,
                last_visit: null
            },
            preferences: {
                language: $lang,
                communication: ["email", "phone"],
                marketing_opt_in: ($marketing == "y")
            },
            transactions: {
                total_purchases: 0,
                total_amount: 0,
                average_purchase: 0,
                last_purchase: null
            },
            status: "active",
            notes: "",
            created_at: $date,
            updated_at: $date
        }' > "$customer_file"
    
    echo -e "${GREEN}Customer added with ID: $id${NC}"
    
    # Log action
    log_action "add_customer" "$id" "Added new customer: $first_name $last_name"
}

# Function to update customer
update_customer() {
    echo -e "${BLUE}Updating customer...${NC}"
    
    # List customers
    echo -e "\n${YELLOW}Available Customers:${NC}"
    for file in "$CUSTOMERS_DIR"/*.json; do
        if [ -f "$file" ]; then
            jq -r '"\(.id): \(.name.first) \(.name.last) (\(.name.arabic))"' "$file"
        fi
    done
    
    read -p "Enter Customer ID: " customer_id
    local customer_file="$CUSTOMERS_DIR/$customer_id.json"
    
    if [ ! -f "$customer_file" ]; then
        echo -e "${RED}Customer not found${NC}"
        return 1
    fi
    
    echo "Select information to update:"
    echo "1. Contact Information"
    echo "2. Address"
    echo "3. Preferences"
    echo "4. Membership Level"
    echo "5. Status"
    read -p "Enter choice: " choice
    
    case $choice in
        1)
            read -p "Phone: " phone
            read -p "Email: " email
            
            jq --arg phone "$phone" \
               --arg email "$email" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.contact.phone = $phone |
                .contact.email = $email |
                .updated_at = $date' "$customer_file" > "${customer_file}.tmp"
            ;;
        2)
            read -p "Street Address: " street
            read -p "City: " city
            read -p "State: " state
            read -p "Postal Code: " postal_code
            read -p "Country: " country
            
            jq --arg street "$street" \
               --arg city "$city" \
               --arg state "$state" \
               --arg postal "$postal_code" \
               --arg country "$country" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.contact.address = {
                    street: $street,
                    city: $city,
                    state: $state,
                    postal_code: $postal,
                    country: $country
                } |
                .updated_at = $date' "$customer_file" > "${customer_file}.tmp"
            ;;
        3)
            read -p "Preferred Language (ar/en): " language
            read -p "Marketing Opt-in (y/n): " marketing
            
            jq --arg lang "$language" \
               --arg marketing "$marketing" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.preferences.language = $lang |
                .preferences.marketing_opt_in = ($marketing == "y") |
                .updated_at = $date' "$customer_file" > "${customer_file}.tmp"
            ;;
        4)
            read -p "Membership Level (standard/silver/gold/platinum): " level
            
            jq --arg level "$level" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.profile.membership_level = $level |
                .updated_at = $date' "$customer_file" > "${customer_file}.tmp"
            ;;
        5)
            read -p "Status (active/inactive/blocked): " status
            
            jq --arg status "$status" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = $status |
                .updated_at = $date' "$customer_file" > "${customer_file}.tmp"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    mv "${customer_file}.tmp" "$customer_file"
    echo -e "${GREEN}Customer updated${NC}"
    
    # Log action
    log_action "update_customer" "$customer_id" "Updated customer information"
}

# Function to search customers
search_customers() {
    echo -e "${BLUE}Searching customers...${NC}"
    
    read -p "Enter search term: " search_term
    
    echo -e "\n${YELLOW}Search Results:${NC}"
    echo "------------------------"
    
    for file in "$CUSTOMERS_DIR"/*.json; do
        if [ -f "$file" ]; then
            if jq -e --arg term "$search_term" '
                .name.first | ascii_downcase | contains($term | ascii_downcase) or
                .name.last | ascii_downcase | contains($term | ascii_downcase) or
                .name.arabic | contains($term) or
                .contact.phone | contains($term) or
                .contact.email | ascii_downcase | contains($term | ascii_downcase)
            ' "$file" > /dev/null; then
                jq -r '"\(.id): \(.name.first) \(.name.last) (\(.name.arabic))\n  Phone: \(.contact.phone)\n  Email: \(.contact.email)\n  Level: \(.profile.membership_level)\n"' "$file"
            fi
        fi
    done
}

# Function to generate customer report
generate_report() {
    echo -e "${BLUE}Generating customer report...${NC}"
    
    local report_file="$REPORTS_DIR/customers_$(date +%Y%m%d).md"
    
    {
        echo "# تقرير العملاء"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## إحصائيات العملاء"
        echo
        
        # Calculate statistics
        local stats=$(jq -s '
            {
                total: length,
                active: map(select(.status == "active")) | length,
                inactive: map(select(.status == "inactive")) | length,
                blocked: map(select(.status == "blocked")) | length,
                membership_levels: group_by(.profile.membership_level) | map({
                    key: .[0].profile.membership_level,
                    count: length
                }),
                total_revenue: map(.transactions.total_amount) | add,
                avg_purchase: (map(.transactions.total_amount) | add) / length
            }
        ' "$CUSTOMERS_DIR"/*.json)
        
        echo "- إجمالي العملاء: $(echo "$stats" | jq -r '.total')"
        echo "- العملاء النشطون: $(echo "$stats" | jq -r '.active')"
        echo "- العملاء غير النشطين: $(echo "$stats" | jq -r '.inactive')"
        echo "- العملاء المحظورون: $(echo "$stats" | jq -r '.blocked')"
        echo
        echo "مستويات العضوية:"
        echo "$stats" | jq -r '.membership_levels[] | "- \(.key): \(.count) عميل"'
        echo
        echo "إحصائيات المبيعات:"
        echo "- إجمالي المبيعات: $(echo "$stats" | jq -r '.total_revenue') ريال"
        echo "- متوسط قيمة المشتريات: $(echo "$stats" | jq -r '.avg_purchase') ريال"
        
        echo
        echo "## العملاء الأكثر نشاطاً"
        echo
        echo "| العميل | المستوى | عدد المشتريات | إجمالي المشتريات |"
        echo "|--------|----------|----------------|-------------------|"
        
        # List top customers
        jq -s '
            sort_by(.transactions.total_amount) |
            reverse |
            .[0:10] |
            .[] |
            [
                "\(.name.first) \(.name.last)",
                .profile.membership_level,
                .transactions.total_purchases,
                .transactions.total_amount
            ] |
            @tsv
        ' "$CUSTOMERS_DIR"/*.json | \
        while IFS=$'\t' read -r name level purchases amount; do
            printf "| %s | %s | %d | %.2f |\n" "$name" "$level" "$purchases" "$amount"
        done
        
    } > "$report_file"
    
    echo -e "${GREEN}Report generated: $report_file${NC}"
    
    # Log action
    log_action "generate_report" "all" "Generated customer report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/customer_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Customer Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Add Customer"
    echo -e "${YELLOW}2.${NC} Update Customer"
    echo -e "${YELLOW}3.${NC} Search Customers"
    echo -e "${YELLOW}4.${NC} Generate Report"
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
            add_customer
            ;;
        2)
            update_customer
            ;;
        3)
            search_customers
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/customer_actions.log" ]; then
                less "$LOGS_DIR/customer_actions.log"
            else
                echo -e "${YELLOW}No customer logs found${NC}"
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
