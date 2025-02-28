#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENV_DIR="./env"
LOGS_DIR="./logs/env"
REPORTS_DIR="./reports/env"
BACKUP_DIR="./backups/env"

# Environment types
declare -A ENV_TYPES=(
    ["development"]="Development Environment"
    ["staging"]="Staging Environment"
    ["production"]="Production Environment"
    ["testing"]="Testing Environment"
)

# Create directories
mkdir -p "$ENV_DIR" "$LOGS_DIR" "$REPORTS_DIR" "$BACKUP_DIR"

# Function to create environment
create_env() {
    echo -e "${BLUE}Creating environment...${NC}"
    
    # Show environment types
    echo -e "\n${YELLOW}Available Environment Types:${NC}"
    for key in "${!ENV_TYPES[@]}"; do
        echo "$key) ${ENV_TYPES[$key]}"
    done
    
    read -p "Enter environment type: " env_type
    
    if [ -z "${ENV_TYPES[$env_type]}" ]; then
        echo -e "${RED}Invalid environment type${NC}"
        return 1
    fi
    
    local env_file=".env.$env_type"
    
    # Backup existing env file if it exists
    if [ -f "$env_file" ]; then
        cp "$env_file" "$BACKUP_DIR/${env_file}_$(date +%Y%m%d_%H%M%S).bak"
    fi
    
    # Create environment file
    {
        echo "# ${ENV_TYPES[$env_type]}"
        echo "# Created: $(date)"
        echo
        echo "# Application"
        read -p "Enter NODE_ENV [$env_type]: " node_env
        echo "NODE_ENV=${node_env:-$env_type}"
        read -p "Enter PORT [3000]: " port
        echo "PORT=${port:-3000}"
        
        echo
        echo "# Database"
        read -p "Enter DB_HOST [localhost]: " db_host
        echo "DB_HOST=${db_host:-localhost}"
        read -p "Enter DB_PORT [5432]: " db_port
        echo "DB_PORT=${db_port:-5432}"
        read -p "Enter DB_NAME [cashier_$env_type]: " db_name
        echo "DB_NAME=${db_name:-cashier_$env_type}"
        read -p "Enter DB_USER [admin]: " db_user
        echo "DB_USER=${db_user:-admin}"
        read -p "Enter DB_PASSWORD: " db_password
        echo "DB_PASSWORD=${db_password}"
        
        echo
        echo "# Redis"
        read -p "Enter REDIS_HOST [localhost]: " redis_host
        echo "REDIS_HOST=${redis_host:-localhost}"
        read -p "Enter REDIS_PORT [6379]: " redis_port
        echo "REDIS_PORT=${redis_port:-6379}"
        
        echo
        echo "# Security"
        read -p "Enter JWT_SECRET: " jwt_secret
        echo "JWT_SECRET=${jwt_secret}"
        read -p "Enter API_KEY: " api_key
        echo "API_KEY=${api_key}"
        
    } > "$env_file"
    
    echo -e "${GREEN}Environment file created: $env_file${NC}"
    
    # Log action
    log_action "create" "$env_type" "Created environment file: $env_file"
}

# Function to validate environment
validate_env() {
    echo -e "${BLUE}Validating environment...${NC}"
    
    # Show available env files
    echo -e "\n${YELLOW}Available Environment Files:${NC}"
    ls -1 .env.* 2>/dev/null
    
    read -p "Enter environment file to validate: " env_file
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Environment file not found${NC}"
        return 1
    fi
    
    local report_file="$REPORTS_DIR/validation_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير التحقق من البيئة"
        echo "تاريخ التقرير: $(date)"
        echo "الملف: $env_file"
        echo
        
        echo "## المتغيرات المطلوبة"
        echo
        
        # Check required variables
        local required_vars=(
            "NODE_ENV"
            "PORT"
            "DB_HOST"
            "DB_PORT"
            "DB_NAME"
            "DB_USER"
            "DB_PASSWORD"
            "JWT_SECRET"
        )
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" "$env_file"; then
                echo "✅ $var: موجود"
            else
                echo "❌ $var: مفقود"
            fi
        done
        
        echo
        echo "## تحقق القيم"
        echo
        
        # Validate values
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^# ]] || [ -z "$key" ] && continue
            
            # Remove quotes from value
            value=$(echo "$value" | tr -d '"'"'")
            
            case $key in
                PORT)
                    if [[ $value =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ] && [ "$value" -lt 65536 ]; then
                        echo "✅ $key: قيمة صالحة"
                    else
                        echo "❌ $key: قيمة غير صالحة"
                    fi
                    ;;
                *_HOST)
                    if [[ $value =~ ^[a-zA-Z0-9.-]+$ ]]; then
                        echo "✅ $key: قيمة صالحة"
                    else
                        echo "❌ $key: قيمة غير صالحة"
                    fi
                    ;;
                *_PORT)
                    if [[ $value =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ] && [ "$value" -lt 65536 ]; then
                        echo "✅ $key: قيمة صالحة"
                    else
                        echo "❌ $key: قيمة غير صالحة"
                    fi
                    ;;
                *_SECRET|*_KEY)
                    if [ ${#value} -ge 32 ]; then
                        echo "✅ $key: قيمة صالحة"
                    else
                        echo "❌ $key: قيمة قصيرة جداً"
                    fi
                    ;;
            esac
        done < "$env_file"
        
    } > "$report_file"
    
    echo -e "${GREEN}Validation report generated: $report_file${NC}"
    
    # Log action
    log_action "validate" "$env_file" "Validated environment file"
}

# Function to compare environments
compare_envs() {
    echo -e "${BLUE}Comparing environments...${NC}"
    
    read -p "Enter first environment file: " env1
    read -p "Enter second environment file: " env2
    
    if [ ! -f "$env1" ] || [ ! -f "$env2" ]; then
        echo -e "${RED}One or both environment files not found${NC}"
        return 1
    fi
    
    local report_file="$REPORTS_DIR/comparison_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# تقرير مقارنة البيئات"
        echo "تاريخ التقرير: $(date)"
        echo
        echo "مقارنة بين:"
        echo "- $env1"
        echo "- $env2"
        echo
        
        echo "## المتغيرات المختلفة"
        echo
        
        # Compare variables
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^# ]] || [ -z "$key" ] && continue
            
            # Get value from second env file
            value2=$(grep "^$key=" "$env2" | cut -d'=' -f2-)
            
            if [ "$value" != "$value2" ]; then
                echo "### $key"
                echo "- $env1: $value"
                echo "- $env2: $value2"
                echo
            fi
        done < "$env1"
        
        echo "## المتغيرات الفريدة"
        echo
        echo "### متغيرات فقط في $env1"
        comm -23 <(grep -v '^#' "$env1" | cut -d'=' -f1 | sort) \
                <(grep -v '^#' "$env2" | cut -d'=' -f1 | sort)
        echo
        echo "### متغيرات فقط في $env2"
        comm -13 <(grep -v '^#' "$env1" | cut -d'=' -f1 | sort) \
                <(grep -v '^#' "$env2" | cut -d'=' -f1 | sort)
        
    } > "$report_file"
    
    echo -e "${GREEN}Comparison report generated: $report_file${NC}"
    
    # Log action
    log_action "compare" "$env1 vs $env2" "Compared environment files"
}

# Function to encrypt sensitive values
encrypt_env() {
    echo -e "${BLUE}Encrypting sensitive values...${NC}"
    
    read -p "Enter environment file to encrypt: " env_file
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Environment file not found${NC}"
        return 1
    fi
    
    # Backup original file
    cp "$env_file" "$BACKUP_DIR/$(basename "$env_file")_$(date +%Y%m%d_%H%M%S).bak"
    
    # Encrypt sensitive values
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^# ]] || [ -z "$key" ] && continue
        
        # Check if value should be encrypted
        if [[ $key =~ PASSWORD|SECRET|KEY|TOKEN ]]; then
            # Simple encryption (for demonstration - use proper encryption in production)
            encrypted_value=$(echo "$value" | base64)
            sed -i "s|^$key=.*|$key=$encrypted_value|" "$env_file"
        fi
    done < "$env_file"
    
    echo -e "${GREEN}Sensitive values encrypted in: $env_file${NC}"
    
    # Log action
    log_action "encrypt" "$env_file" "Encrypted sensitive values"
}

# Function to log actions
log_action() {
    local action=$1
    local subject=$2
    local details=$3
    
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $action - $subject - $details" >> "$LOGS_DIR/env_actions.log"
}

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Environment Menu${NC}"
    echo "------------------------"
    echo -e "${YELLOW}1.${NC} Create Environment"
    echo -e "${YELLOW}2.${NC} Validate Environment"
    echo -e "${YELLOW}3.${NC} Compare Environments"
    echo -e "${YELLOW}4.${NC} Encrypt Sensitive Values"
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
            create_env
            ;;
        2)
            validate_env
            ;;
        3)
            compare_envs
            ;;
        4)
            encrypt_env
            ;;
        5)
            if [ -f "$LOGS_DIR/env_actions.log" ]; then
                less "$LOGS_DIR/env_actions.log"
            else
                echo -e "${YELLOW}No environment logs found${NC}"
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
