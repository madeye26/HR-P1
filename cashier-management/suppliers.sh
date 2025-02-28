#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUPPLIERS_DIR="./data/suppliers"
CONTRACTS_DIR="./data/contracts"
REPORTS_DIR="./reports/suppliers"
TEMPLATES_DIR="./templates/suppliers"
LOGS_DIR="./logs/suppliers"
BACKUP_DIR="./backups/suppliers"

# Create directories
mkdir -p "$SUPPLIERS_DIR" "$CONTRACTS_DIR" "$REPORTS_DIR" "$TEMPLATES_DIR" "$LOGS_DIR" "$BACKUP_DIR"

# Create supplier template if it doesn't exist
if [ ! -f "$TEMPLATES_DIR/supplier_template.json" ]; then
    cat > "$TEMPLATES_DIR/supplier_template.json" << EOL
{
    "id": "",
    "name": {
        "en": "",
        "ar": ""
    },
    "contact": {
        "primary": {
            "name": "",
            "phone": "",
            "email": "",
            "position": ""
        },
        "secondary": {
            "name": "",
            "phone": "",
            "email": "",
            "position": ""
        }
    },
    "address": {
        "street": "",
        "city": "",
        "state": "",
        "postal_code": "",
        "country": ""
    },
    "business": {
        "type": "",
        "registration_no": "",
        "tax_no": "",
        "categories": []
    },
    "banking": {
        "bank_name": "",
        "account_holder": "",
        "account_number": "",
        "iban": "",
        "swift": ""
    },
    "rating": {
        "score": 0,
        "reviews": [],
        "last_review_date": null
    },
    "status": "active",
    "created_at": "",
    "updated_at": ""
}
EOL
fi

# Function to add supplier
add_supplier() {
    echo -e "${BLUE}Adding new supplier...${NC}"
    
    # Generate supplier ID
    local id="SUP$(date +%Y%m)$(printf "%03d" $(( $(ls -1 "$SUPPLIERS_DIR" | wc -l) + 1 )))"
    
    # Get supplier details
    echo -e "\n${YELLOW}Basic Information${NC}"
    read -p "Name (English): " name_en
    read -p "Name (Arabic): " name_ar
    read -p "Business Type: " business_type
    read -p "Registration Number: " reg_no
    read -p "Tax Number: " tax_no
    
    echo -e "\n${YELLOW}Primary Contact${NC}"
    read -p "Contact Name: " contact_name
    read -p "Phone: " phone
    read -p "Email: " email
    read -p "Position: " position
    
    echo -e "\n${YELLOW}Address${NC}"
    read -p "Street: " street
    read -p "City: " city
    read -p "State: " state
    read -p "Postal Code: " postal_code
    read -p "Country: " country
    
    echo -e "\n${YELLOW}Banking Information${NC}"
    read -p "Bank Name: " bank_name
    read -p "Account Holder: " account_holder
    read -p "Account Number: " account_number
    read -p "IBAN: " iban
    read -p "SWIFT Code: " swift
    
    # Create supplier file
    local supplier_file="$SUPPLIERS_DIR/$id.json"
    
    jq -n \
        --arg id "$id" \
        --arg name_en "$name_en" \
        --arg name_ar "$name_ar" \
        --arg contact_name "$contact_name" \
        --arg phone "$phone" \
        --arg email "$email" \
        --arg position "$position" \
        --arg street "$street" \
        --arg city "$city" \
        --arg state "$state" \
        --arg postal "$postal_code" \
        --arg country "$country" \
        --arg type "$business_type" \
        --arg reg "$reg_no" \
        --arg tax "$tax_no" \
        --arg bank "$bank_name" \
        --arg holder "$account_holder" \
        --arg account "$account_number" \
        --arg iban "$iban" \
        --arg swift "$swift" \
        --arg created "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            id: $id,
            name: {
                en: $name_en,
                ar: $name_ar
            },
            contact: {
                primary: {
                    name: $contact_name,
                    phone: $phone,
                    email: $email,
                    position: $position
                },
                secondary: {
                    name: "",
                    phone: "",
                    email: "",
                    position: ""
                }
            },
            address: {
                street: $street,
                city: $city,
                state: $state,
                postal_code: $postal,
                country: $country
            },
            business: {
                type: $type,
                registration_no: $reg,
                tax_no: $tax,
                categories: []
            },
            banking: {
                bank_name: $bank,
                account_holder: $holder,
                account_number: $account,
                iban: $iban,
                swift: $swift
            },
            rating: {
                score: 0,
                reviews: [],
                last_review_date: null
            },
            status: "active",
            created_at: $created,
            updated_at: $created
        }' > "$supplier_file"
    
    echo -e "${GREEN}Supplier added with ID: $id${NC}"
    
    # Log action
    log_action "add_supplier" "$id" "Added new supplier: $name_en"
}

# Function to update supplier
update_supplier() {
    echo -e "${BLUE}Updating supplier...${NC}"
    
    # List suppliers
    echo -e "\n${YELLOW}Available Suppliers:${NC}"
    for file in "$SUPPLIERS_DIR"/*.json; do
        if [ -f "$file" ]; then
            jq -r '"\(.id): \(.name.en) (\(.name.ar))"' "$file"
        fi
    done
    
    read -p "Enter Supplier ID: " supplier_id
    local supplier_file="$SUPPLIERS_DIR/$supplier_id.json"
    
    if [ ! -f "$supplier_file" ]; then
        echo -e "${RED}Supplier not found${NC}"
        return 1
    fi
    
    echo "Select information to update:"
    echo "1. Contact Information"
    echo "2. Address"
    echo "3. Banking Information"
    echo "4. Business Information"
    echo "5. Status"
    read -p "Enter choice: " choice
    
    case $choice in
        1)
            echo -e "\n${YELLOW}Update Contact Information${NC}"
            read -p "Contact Name: " contact_name
            read -p "Phone: " phone
            read -p "Email: " email
            read -p "Position: " position
            
            jq --arg name "$contact_name" \
               --arg phone "$phone" \
               --arg email "$email" \
               --arg pos "$position" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.contact.primary = {
                    name: $name,
                    phone: $phone,
                    email: $email,
                    position: $pos
                } |
                .updated_at = $date' "$supplier_file" > "${supplier_file}.tmp"
            ;;
        2)
            echo -e "\n${YELLOW}Update Address${NC}"
            read -p "Street: " street
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
               '.address = {
                    street: $street,
                    city: $city,
                    state: $state,
                    postal_code: $postal,
                    country: $country
                } |
                .updated_at = $date' "$supplier_file" > "${supplier_file}.tmp"
            ;;
        3)
            echo -e "\n${YELLOW}Update Banking Information${NC}"
            read -p "Bank Name: " bank_name
            read -p "Account Holder: " account_holder
            read -p "Account Number: " account_number
            read -p "IBAN: " iban
            read -p "SWIFT Code: " swift
            
            jq --arg bank "$bank_name" \
               --arg holder "$account_holder" \
               --arg account "$account_number" \
               --arg iban "$iban" \
               --arg swift "$swift" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.banking = {
                    bank_name: $bank,
                    account_holder: $holder,
                    account_number: $account,
                    iban: $iban,
                    swift: $swift
                } |
                .updated_at = $date' "$supplier_file" > "${supplier_file}.tmp"
            ;;
        4)
            echo -e "\n${YELLOW}Update Business Information${NC}"
            read -p "Business Type: " business_type
            read -p "Registration Number: " reg_no
            read -p "Tax Number: " tax_no
            
            jq --arg type "$business_type" \
               --arg reg "$reg_no" \
               --arg tax "$tax_no" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.business = {
                    type: $type,
                    registration_no: $reg,
                    tax_no: $tax,
                    categories: .business.categories
                } |
                .updated_at = $date' "$supplier_file" > "${supplier_file}.tmp"
            ;;
        5)
            echo -e "\n${YELLOW}Update Status${NC}"
            read -p "New Status (active/inactive/blacklisted): " status
            
            jq --arg status "$status" \
               --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = $status |
                .updated_at = $date' "$supplier_file" > "${supplier_file}.tmp"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    mv "${supplier_file}.tmp" "$supplier_file"
    echo -e "${GREEN}Supplier updated${NC}"
    
    # Log action
    log_action "update_supplier" "$supplier_id" "Updated supplier information"
}

# Function to rate supplier
rate_supplier() {
    echo -e "${BLUE}Rating supplier...${NC}"
    
    # List suppliers
    echo -e "\n${YELLOW}Available Suppliers:${NC}"
    for file in "$SUPPLIERS_DIR"/*.json; do
        if [ -f "$file" ]; then
            jq -r '"\(.id): \(.name.en) - Current Rating: \(.rating.score)"' "$file"
        fi
    done
    
    read -p "Enter Supplier ID: " supplier_id
    local supplier_file="$SUPPLIERS_DIR/$supplier_id.json"
    
    if [ ! -f "$supplier_file" ]; then
        echo -e "${RED}Supplier not found${NC}"
        return 1
    fi
    
    read -p "Enter rating (1-5): " rating
    read -p "Enter review comments: " comments
    
    # Update rating
    jq --arg rating "$rating" \
       --arg comments "$comments" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.rating.score = ((.rating.score * (.rating.reviews | length) + ($rating|tonumber)) / ((.rating.reviews | length) + 1)) |
        .rating.reviews += [{
            date: $date,
            score: ($rating|tonumber),
            comments: $comments
        }] |
        .rating.last_review_date = $date |
        .updated_at = $date' "$supplier_file" > "${supplier_file}.tmp"
    
    mv "${supplier_file}.tmp" "$supplier_file"
    echo -e "${GREEN}Supplier rated${NC}"
    
    # Log action
    log_action "rate_supplier" "$supplier_id" "Added rating: $rating"
}

# Function to generate supplier report
generate_report() {
    echo -e "${BLUE}Generating supplier report...${NC}"
    
    local report_file="$REPORTS_DIR/suppliers_$(date +%Y%m%d).md"
    
    {
        echo "# تقرير الموردين"
        echo "تاريخ التقرير: $(date)"
        echo
        
        echo "## قائمة الموردين النشطين"
        echo
        echo "| المورد | نوع العمل | التقييم | الحالة |"
        echo "|--------|------------|----------|---------|"
        
        # List all active suppliers
        for file in "$SUPPLIERS_DIR"/*.json; do
            if [ -f "$file" ]; then
                jq -r 'select(.status == "active") |
                    [.name.ar, .business.type, .rating.score, .status] |
                    @tsv' "$file" | \
                while IFS=$'\t' read -r name type rating status; do
                    printf "| %s | %s | %.1f | %s |\n" "$name" "$type" "$rating" "$status"
                done
            fi
        done
        
        echo
        echo "## إحصائيات الموردين"
        echo
        
        # Calculate statistics
        local stats=$(jq -s '
            {
                total: length,
                active: map(select(.status == "active")) | length,
                inactive: map(select(.status == "inactive")) | length,
                blacklisted: map(select(.status == "blacklisted")) | length,
                avg_rating: (map(.rating.score) | add) / length
            }
        ' "$SUPPLIERS_DIR"/*.json)
        
        echo "- إجمالي الموردين: $(echo "$stats" | jq -r '.total')"
        echo "- الموردين النشطين: $(echo "$stats" | jq -r '.active')"
        echo "- الموردين غير النشطين: $(echo "$stats" | jq -r '.inactive')"
        echo "- الموردين المحظورين: $(echo "$stats" | jq -r '.blacklisted')"
        echo "- متوسط التقييم: $(echo "$stats" | jq -r '.avg_rating')"
        
    } > "$report_file"
    
    echo -e "${GREEN}Report generated: $report_file${NC}"
    
    # Log action
    log_action "generate_report" "all" "Generated supplier report"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/supplier_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Supplier Management Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Add Supplier"
    echo -e "${YELLOW}2.${NC} Update Supplier"
    echo -e "${YELLOW}3.${NC} Rate Supplier"
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
            add_supplier
            ;;
        2)
            update_supplier
            ;;
        3)
            rate_supplier
            ;;
        4)
            generate_report
            ;;
        5)
            if [ -f "$LOGS_DIR/supplier_actions.log" ]; then
                less "$LOGS_DIR/supplier_actions.log"
            else
                echo -e "${YELLOW}No supplier logs found${NC}"
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
